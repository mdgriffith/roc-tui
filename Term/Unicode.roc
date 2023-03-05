interface Term.Unicode
    exposes 
        [ red, cyan, white, yellow, color255,
          reset,
          dash, longDash,
          clearLinesAboveBase
        ]
    imports []

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
    command "0m"

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



toPreviousLineStart : Nat -> Str
toPreviousLineStart = \count ->
    command (Str.concat (Num.toStr count) "F")



toNextLineStart : Nat -> Str
toNextLineStart = \count ->
    command (Str.concat (Num.toStr count) "E")



toLastLineStart : Str
toLastLineStart =
    command (Str.concat "2000" "E")


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
        [ toLastLineStart
        , Str.repeat
            (Str.concat
                (moveUpLines 1)
                clearLine
            )
            lineCount
         
        ]
        ""


clearToBottomOfScreen : Str
clearToBottomOfScreen =
    command "0J"

clearLine : Str
clearLine =
    Str.concat 
        (command "2K")
        "\r"