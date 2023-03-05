interface Term.Unicode
    exposes 
        [ red,
          cyan,
          white,
          yellow,
          color255,
          reset,
          dash,
          longDash
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