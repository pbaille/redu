Red []

u: context load %utils.red

upperchar: charset [#"A" - #"Z"]
uppercase?: func [x][parse to-string x [upperchar to end]] 
mfn-var?: func [x][all [word? x uppercase? x]]

split-where: func [s f][
    also ret: copy []
    until [
        x: take s
        ?? x
        either f x [
           append/only ret reduce [x]
        ][
            unless last ret [append/only ret copy []]
            append/only last ret x
        ]
        tail? s
    ]
]

mfn: function [body] [
    
    cases: copy []

    arity: none

    spec: none

    until [

        body: find body '->
 
        rules: u/expr-split-all u/prevs body

        ;; arity check
        either arity [
            u/assert
              equal? length? rules arity
              "mfn: arity error"
        ][
            arity: length? rules
            spec: collect [loop arity [keep u/gensym]]
        ]

        take body ;; skip '->

        expr: u/expr-split body

        rules: to-block u/foldl rules :append

        ;; replacing vars syms
        rules: u/traverse rules func ['w][
            s: get w
            either mfn-var? s/1 [
                insert s 'set
                set w skip s 2
            ][set w next s]
        ]

        append cases reduce ['parse 'reduce spec rules expr]

        body: copy body ;; reset index

        tail? body
    ]

    probe function spec reduce ['case cases]
]


[
    mfn1: mfn [
        (X integer!) (Y integer!) -> add X Y
        (X series!) (Y series!) -> append X Y
    ]

    X
    Y

    probe :mfn1

    mfn1 1 2
    mfn1 [a z] [r t]
]