Red []

u: context load %utils.red
ar: context load %arity.red

pfn: function [spec body][
    
    arity: length? spec
    cases: copy []

    until [

        body: find body '->
 
        rule: u/prevs body

        take body ;; skip '->

        expr: u/expr-split body
 
        append cases reduce ['parse 'reduce spec rule expr]

        body: copy body ;; reset index

        tail? body
    ]

    function spec reduce ['case cases]
]

[
    f: pfn [a b][
        2 integer! -> add a b
        'foo any-type! -> 'foooooooo...
        2 block! -> append/only  next a b
        string! into [some integer!] -> do [print "pouet" 42]
        2 any-type! -> "blaz"
    ]

    f 1 2 ; 3
    f 'foo 2 ; 'fooo...
    f [a b c] [b c d] ; [b c [b c d]]
    f "i" [1 2 3] ; "123" ?!
    f 1.2.3 #() ; "blaz
]



