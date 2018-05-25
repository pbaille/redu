Red []

u: context load %utils.red

;; @dockimbel
λc: func [
    vars [block!]
    spec [block!] 
    body [block!] 
][
    func spec bind body context vars
]

λw: func [
    words [block!]
    spec [block!] 
    body [block!] 
][
    ctx: copy []
    foreach w words [
        append ctx compose [
            (to-set-word w)
            (all [value? w v: get w
                  either function? :v [quote :v][v]])
        ]
    ]
    func spec bind body context ctx
]

context [

    fn: :function

    a: 10
    f: λw[a][c][c + a]
    f1: f 1

    g: fn [x][x + 1]
    h: λw[g][x][g x]
    h1: h 1

]

