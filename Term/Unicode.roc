interface Term.Unicode
    exposes 
        [ red, cyan, white, yellow, color255,
          reset,
          dash, longDash,
          clearLinesAboveBase
        ]
    imports 
        [
        ]

#  ANSI code reference!
#  https://gist.github.com/fnky/458719343aabd01cfb17a3a4f7296797
# 

esc : Str
esc = 
    "\u(001b)"


command : Str -> Str
command = \inner ->
    "\(esc)[\(inner)"

color255 : U8 -> Str
color255 = \colorCode ->
    colorStr = Num.toStr colorCode
    "\(esc)[38;5;\(colorStr)m"


reset : Str
reset = 
    Str.concat esc "[0m"

cyan : Str
cyan =
    color255 6


yellow : Str
yellow =
    color255 3

red : Str
red =
     color255 1

white : Str
white =
     color255 15



# Characters

longDash : Str
longDash =
    "─"

dash : Str
dash =
    "-"


# Cursor movement

moveToHome : Str
moveToHome =
    command "H"


moveUpLines : Nat -> Str
moveUpLines = \count ->
    command (Str.concat (Num.toStr count) "A") 

moveDownLines : Nat -> Str
moveDownLines = \count ->
    command (Str.concat (Num.toStr count) "B") 



toPreviousLineStart : Str
toPreviousLineStart =
    command (Str.concat "1" "F")

toNextLineStart : Str
toNextLineStart =
    command (Str.concat "1" "E")


toLastLineStart : Str
toLastLineStart =
    command (Str.concat "100" "E")


# Cursor State

saveCursorPosition : Str
saveCursorPosition =
    "\(esc) 7"

restoreCursorPosition : Str
restoreCursorPosition =
    "\(esc) 8"


# Edits

clearLinesAboveBase : Nat -> Str
clearLinesAboveBase = \lineCount ->
    Str.joinWith 
        [ saveCursorPosition
        , toLastLineStart
        , (Str.repeat 
            (Str.concat toPreviousLineStart clearLine) lineCount
          )
        , restoreCursorPosition
        ]
        ""
    # toPreviousLine
#    Str.repeat (Str.concat toPreviousLineStart "--->") lineCount
    # if lineCount == 0 then 
    #     ""
    # else 
    #     Str.concat toPreviousLineStart clearLine




clearLine : Str
clearLine =
    command "2K"