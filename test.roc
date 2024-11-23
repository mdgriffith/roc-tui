app "tui"
    packages { pf: "https://github.com/roc-lang/basic-cli/releases/download/0.2.0/8tCohJeXMBUnjo_zdMq0jSaqdYoCWJkWazBd4wa8cQU.tar.br" }
    imports [pf.Stdin, pf.Stdout, pf.Task.{ Task }, Term, Term.Unicode]
    provides [main] to pf


exampleStuff =
    [ Term.empty
    , Term.empty
    , Term.empty
    , Term.empty
    , Term.text "Hello!!!"
        |> Term.with [ Term.yellow ]
    , Term.row [ Term.yellow ]
        [ Term.text "──"
        , Term.text " Welcome to Roc Terminal UI! "
        , Term.fill "─"
        , Term.text "Term.roc"
            |> Term.with [ Term.cyan ]
        ]
    , Term.lines [ Term.indent 3 ]
        [ Term.empty
        , Term.text "An indented thing!"
        , Term.text "and another"
        , Term.text "Maybe we want a list of other stuff!"
        , Term.empty
        , Term.lines [ Term.yellow ]
            [ Term.row []
                [ Term.text "Intro to Terminal UI"
                , Term.fill "."
                , Term.text "Page 5"
                    |> Term.with [ Term.red ]
                ]
            , Term.row []
                [ Term.text "Intro to Roc"
                , Term.fill "."
                , Term.text "Page 6"
                    |> Term.with [ Term.red ]
                ]
            ]
        ]
    # , Term.empty
    # , Term.fill "─"
    # , Term.text "Hello!!!!!!"
    #     |> Term.with [ Term.indent 5, Term.red ]
    ]


largeBlock =
    [ Term.empty
    , Term.text "two"
    , Term.text "three"
    , Term.text "four"
    , Term.text "five"
    , Term.text "one"
    , Term.lines [ Term.yellow, Term.indent 5 ] 
        [ Term.row [ Term.cyan ]
            [ Term.text "Intro to Terminal UI"
            , Term.fill "."
            , Term.text "Page 5"
                |> Term.with [ Term.red ]
            ]
        , Term.text "two"
        , Term.text "three"
        , Term.text "four"
        , Term.text "five"
        ]
    , Term.text "one"
    , Term.text "two"
    , Term.text "three"
    , Term.text "four"
    , Term.text "five"
    , Term.fill "-"
    ]



print = \terms ->
    Stdout.write (Term.format terms)

printAnim = \terms ->
    Stdout.line (Term.formatAnimated terms)


runClear = \anim ->
    Stdout.write (Term.clear anim)



main =
 
    anim = Term.init   
    nextAnim = Term.update anim exampleStuff
    _ <- Task.await (printAnim nextAnim)



    _ <- Task.await (runClear nextAnim)
    largeBlockAnim = Term.update nextAnim largeBlock
    _ <- Task.await (printAnim largeBlockAnim)
 



    Task.succeed {}


