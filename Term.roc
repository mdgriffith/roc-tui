interface Term
    exposes 
        [ empty, text, fill
        , row, lines
        , with
        , indent
        , cyan, yellow, red
        
        , init, update
        , format, print
        ]
    imports 
        [ pf.Stdout
        , pf.Task.{ Task }
        , Term.Unicode
        ]


totalWidth : Nat
totalWidth =
    80

Term : [
   Text (List Attr) Str,
   Fill Nat (List Attr) Str,
   Layout LayoutOptions (List Attr) (List Term)
]

LayoutOptions : [
    Row,
    Column
]

Attr : [ 
    TextColor Str,
    Indent Nat,
]


indent : U8 -> Attr
indent = \x ->
    Indent (Num.toNat x)


fill : Str -> Term
fill = \filler ->
    Fill 1 [] filler

empty : Term
empty =
    text ""

text : Str -> Term
text = \str ->
    # Newlines aren't allowed as we need to calculate some stuff.
    # when Str.split "\n" str is
    #     [] -> Text [] str
    #     [single] -> Text [] single
    #     many ->
    #         Layout Column [] (List.map many (\manyStr -> Text [] manyStr))
    Text [] str


with : Term, List Attr -> Term
with = \term, attrs ->
    when term is
        Text existingAttrs str ->
            Text (List.concat existingAttrs attrs) str
        
        Fill portion existingAttrs str ->
            Fill portion (List.concat existingAttrs attrs) str
        
        Layout layout existingAttrs str ->
            Layout layout (List.concat existingAttrs attrs) str
    
row : List Attr, List Term -> Term
row = \attrs, children ->
    Layout Row attrs children


lines : List Attr, List Term -> Term
lines = \attrs, children ->
    Layout Column attrs children



print : List Term -> Task {} *
print = \terms ->
    format terms
        |> Stdout.line


format : List Term -> Str
format = \terms ->
    postProcess terms
        |> .term
        |> formatTerm


Processed : { term : Term, cursor : ReplacementCursor }

postProcess : List Term -> Processed
postProcess = \terms ->
    term = Layout Column [] terms

    lineIndexToWidths = 
        getLineIndexToWidths 
            { current : emptyWidthCalc 
            , lines : (Dict.empty {})
            }
            term

        
    term 
        |> replaceWidths { rowIndex : 0, widths : lineIndexToWidths.lines }
        




ReplacementCursor: {
    widths : Dict Nat WidthCalc,
    rowIndex : Nat
}

termHeight : Term -> Nat
termHeight = \term ->
    when term is
        Text _ _ -> 1
        Fill _ _ _ -> 1
        Layout Row _ _ -> 1
        Layout Column _ _ -> 0

replaceWidths : Term, ReplacementCursor -> { term : Term, cursor : ReplacementCursor }
replaceWidths = \term, cursor ->
    when term is
        Text _ _ -> 
            { term : term, cursor : cursor }

        Fill portion attrs str ->
            when Dict.get cursor.widths cursor.rowIndex is
                Err _ ->
                    { term : term, cursor : cursor }

                Ok width ->
                    portionSize = 
                        getPortionSize width
                    newTerm = Fill (portion * portionSize) attrs str
                    { term : newTerm, cursor : cursor }

        Layout Row attrs content -> 
            # This is a single line
            newContents =
                content
                    |> List.walk 
                        { cursor : cursor,
                          items : []
                        }
                        (\innerCursor, rowTerm ->
                            
                            new = replaceWidths rowTerm innerCursor.cursor
                            
                            { items : List.append innerCursor.items new.term
                            , cursor : new.cursor
                            }
                        )
            { term : Layout Row attrs newContents.items
            , cursor : newContents.cursor
            }
            

        Layout Column attrs rows ->
            # This is multiple lines
            newContents =
                rows
                    |> List.walk
                        { cursor : cursor,
                          items : []
                        }
                        (\innerCursor, colTerm ->
                            replaced = replaceWidths colTerm innerCursor.cursor
                            replacedCursor = replaced.cursor
                            
                            { cursor :
                                { replacedCursor 
                                    & rowIndex : replacedCursor.rowIndex + termHeight colTerm,
                                },
                              items : List.append innerCursor.items replaced.term
                            }
                         )
            { term : Layout Column attrs newContents.items
            , cursor : newContents.cursor
            }
            
            

gatherAttrIndentation : WidthCalc, List Attr  -> WidthCalc
gatherAttrIndentation = \cursor, attrs ->
    attrs 
        |> List.walk cursor
            (\innerCursor, attr -> 
                when attr is
                    Indent x ->
                        { innerCursor &
                            usedChars : innerCursor.usedChars + x
                        }

                    TextColor _ ->
                        innerCursor
            
            )



getLineIndexToWidths : { current: WidthCalc, lines: Dict Nat WidthCalc }, Term-> { current: WidthCalc, lines: Dict Nat WidthCalc }
getLineIndexToWidths = \cursor, term ->
    when term is
        Text attrs str -> 
            currentWithIndentation = gatherAttrIndentation cursor.current attrs

            usedChars = currentWithIndentation.usedChars + Str.countGraphemes str
         
            { cursor &
                current : { currentWithIndentation & usedChars : usedChars }
            }

        Fill portion attrs _ ->
            currentWithIndentation =  gatherAttrIndentation cursor.current attrs
            {  cursor &  
                current : { currentWithIndentation & portions : currentWithIndentation.portions + portion }
            
            }

        Layout Row attrs content -> 
            # This is a single line
            currentWithIndentation = gatherAttrIndentation cursor.current attrs

            content
                |> List.walk { cursor & current : currentWithIndentation }
                    (\innerCusor, rowTerm ->
                        getLineIndexToWidths innerCusor rowTerm
                    )
            

        Layout Column attrs rows ->
            currentWithIndentation = gatherAttrIndentation cursor.current attrs

            # This is multiple lines
            rows
                |> List.walk { cursor & current : currentWithIndentation }
                    (\innerCursor, colTerm ->
                        innerCursorCurrent = innerCursor.current
                        
                        lineInfo = getLineIndexToWidths 
                            innerCursor
                            colTerm
                      
                        lineInnerCursor = lineInfo.current
                        
                        # This is a new line
                        # At this point we have enough information to 'commit' information about this line and clear the cursor
                        { current :
                            # Note, we are updating the innerCursor
                            # This is because any "indent" it already has will apply to future rows.
                            { innerCursorCurrent 
                                & index : lineInnerCursor.index + 1,
                            },
                          lines : 
                            lineInfo.lines
                                |> Dict.insert lineInfo.current.index lineInfo.current
                        }
                    )


WidthCalc: {
    portions: Nat,
    usedChars: Nat,
    index: Nat
}


emptyWidthCalc : WidthCalc
emptyWidthCalc =
    { portions : 0, usedChars : 0, index : 0 }

getPortionSize : WidthCalc -> Nat
getPortionSize = \calc ->
    remainingChars = totalWidth - calc.usedChars
    
    Num.divTrunc remainingChars calc.portions


formatTerm : Term -> Str
formatTerm = \term ->
    when term is
        Text attrs str -> 
            wrapAttrs str attrs 

        Fill i attrs str ->
            wrapAttrs (Str.repeat str (Num.toNat i)) attrs 

        Layout layout attrs innerTerms ->
            str = innerTerms 
                    |> List.map formatTerm
                    |> Str.joinWith (layoutCharacter layout)
            
            wrapAttrs str attrs
            

layoutCharacter : LayoutOptions -> Str
layoutCharacter = \layout ->
    when layout is
        Row -> ""
        Column -> "\n"

wrapAttrs : Str, List Attr -> Str
wrapAttrs = \str, attrs ->
    Str.concat 
        (formatAttrStart str attrs)
        (formatAttrEnd attrs)
    


formatAttrStart : Str, List Attr -> Str
formatAttrStart = \contentStr, attrs ->
    {content, prefix} =
        attrs
            |> List.walk
                { content: contentStr
                , prefix: ""
                }
                walkAttrs
    
    Str.concat prefix content


walkAttrs : { prefix: Str, content: Str }, Attr -> { prefix: Str, content: Str } 
walkAttrs = \state, attr ->
    when attr is
        TextColor color ->
            { prefix : Str.concat state.prefix color
            , content : state.content
            }

        Indent x ->
            indentStr = Str.repeat " " (Num.toNat x)
            contentLines = Str.split state.content "\n"

            { prefix : state.prefix
            , content : 
                Str.concat indentStr
                    (contentLines
                        |> Str.joinWith (Str.concat "\n" indentStr)
                    )

            }

                
                

formatAttrEnd : List Attr -> Str
formatAttrEnd = \attrs ->
   List.map attrs formatAttrEndHelper
      |> Str.joinWith ""


formatAttrEndHelper : Attr -> Str
formatAttrEndHelper = \attr ->
    when attr is
        TextColor _ -> Term.Unicode.reset
        Indent _ -> ""

#  Colors

cyan : Attr
cyan =
    TextColor Term.Unicode.cyan


yellow : Attr
yellow =
    TextColor Term.Unicode.yellow


red : Attr
red =
    TextColor Term.Unicode.red



## ANIMATION

Animated := {
    previous: Processed ,
    current: Processed
}

emptyProcessed : Processed
emptyProcessed =
    { term :  Layout Column [] [],
      cursor : 
        { widths : Dict.empty {},
          rowIndex : 0
        }
    }

## Generate the ansi codes necessary to clear the given term.
init : Animated
init =
    @Animated 
        { previous : emptyProcessed,
          current : emptyProcessed
        }

## Generate the ansi codes necessary to clear the given term.
clear : Processed -> Str
clear = \processed ->
    rowIndex =
        if processed.cursor.rowIndex < 3 then 
            processed.cursor.rowIndex
        else 
            processed.cursor.rowIndex 

    # dbg "CLEARING"
    # dbg processed.cursor.rowIndex

    Term.Unicode.clearLinesAboveBase rowIndex
    # skipping = Num.toStr rowIndex
    # "-> ERASING \(skipping)\n"


update : Animated, List Term -> Task Animated *
update = \@Animated anim, newTerms ->
    processed = postProcess newTerms
    Stdout.line
        (Str.concat 
            (clear anim.current)
            (formatTerm processed.term)
        )
        |> Task.map 
            (\{} ->
                @Animated
                    { previous : anim.current,
                      current : processed
                    }
            )


