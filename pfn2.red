Red []

u: context load %utils.red

;; impl -----------------------------------------------------

dbg: func ['a b] [print [a b]]

traverse: func [x f /only /deep dive?][
    until [
        x: case [
            all [deep dive? x/1] [traverse/deep x/1 :f :dive? next x]
            all [not deep not only series? x/1] [traverse/deep x/1 :f :series? next x]
            'else [f x] 
        ]
        tail? x
    ]
    head x
]
[
    do load %lambda.red
    dbg: :u/???
    visit-leaf: λ[dbg leaf mold first _ next _]
    traverse [a b c [d e] f] :visit-leaf
    traverse/deep [a b c (y o !) [f g h] 42] :visit-leaf :paren?
    traverse/only [a b c [f g h] 42] :visit-leaf
]

;; ----------------------------------------------------------

upperchar: charset [#"A" - #"Z"]
uppercase: [_: if (parse to-string _ [upperchar to end]) skip]

compile-binding-rule: func [
    "turn a binding rule into native parse rule"
    word
    rule
][
    rule: either block? rule [rule] [compose/only [(rule)]]
    compose/only [
        cbr_:
        if (to-paren compose [not value? quote (word)]
        ) (compose/only [m1: (rule) m2: ()  | break])
        | if (to-paren compose [equal? get quote (word) cbr_/1]
        ) (rule)
    ]
]
do [
    t!: func [x r] [dbg 't! parse x r u/assert parse x r reduce ['should-be-true x]]
    f!: func [x r] [dbg 'f! parse x r u/assert not parse x r reduce ['should-be-false x]]

    A: none 
    r1: compile-binding-rule 'A 'number!
    unset 'A t! [1] r1
    unset 'A f! [a] r1
    A: 1 t! [1] r1 unset 'A
    A: 2 f! [1] r1 unset 'A

    ;r1: compile-binding-rule 'A [any-type!]
    ;t! [1] r1
    ;f! [aze] r1
]

compile-rest-pattern: func [word][
    compose/deep [
        m1: [to end] m2:
        if (to-paren compose/deep [
                v: copy/part m1 m2
                either value? quote (word) [
                    not equal? get quote (word) v
                ][(to-set-word word) v none]
            ]
        ) break
    ]
]

binding-var: [ahead word! uppercase]

binding-rule: [ change only [
        set b binding-var [set r rule | (r: [any-type!])]
        | set r rule (b: u/gensym)
    ] (compile-binding-rule b r)
]

binding-cons: [
    ahead block!
    insert [into]
    into [
        some binding-rule
        remove '.
        change set restsym binding-var (compile-rest-pattern restsym)
    ]
]

fn-pattern: function [input-rules][

    rules: copy/deep input-rules

    also vars: copy []
    traverse rules func[x][
        if all [parse reduce [x/1] uppercase] [append vars x/1]
        next x]

    valid?: parse rules [some [binding-rule' | binding-cons']]

    either valid? [
        context compose/deep [
            (collect [foreach v unique vars [keep reduce [to-set-word v none]]])
            rules: [(rules)]
            arity: does [length? u/filter rules :block?] 
            clean!: does [unset [(unique vars)]]
            match: function [args] [
                clean!
                also r: parse args rules
                clean!
            ]
            ->: func [args expr] [
                clean!
                also all [parse args rules do bind expr self]
                clean!
            ]
        ]
    ] [return reduce ['args-parser/invalid-rules rules]]
]
[
    probe ap: fn-pattern [A number! A]
    ap/match [1 2]
    ap/match [1 1]
    ap/-> [2 2] [A + A]

    unset [A X As Xs]
    probe ap: fn-pattern [X [X . Xs]]
    ap/match [1 [1 2 3]]
    ap/match [1 [2 2 3]]
]

pfn: function [body][
    
    cases: copy []
    arity: 'unknown

    until [

        body: find body '->
 
        b-rule: u/prevs body ;?? b-rule

        take body ;; skip '->

        expr: u/expr-split body ;?? expr

        pat: fn-pattern b-rule ;?? pat

        either equal? 'unknown arity [
            arity: any [pat/arity break] ?? arity
            spec: collect [loop arity [keep u/gensym]] ;?? spec
        ][
            u/assert [
                equal? arity length? pat/rules
            ] "arity error"
        ]

        append cases compose/deep/only bind [
            match reduce (spec) [-> reduce (spec) (to-block expr)]
        ] pat ;; brings :match :-> and bindings 

        body: copy body ;; reset index

        tail? body
    ]
    ;?? cases
    function copy spec compose/only [case (cases)]
]

[
    pfn1: pfn [
        A A -> 1
        A B -> 0
    ] probe :pfn1
    
    pfn1 0 3
    pfn1 3 3
    
    probe pfn2: pfn [
        A [A B . Xs] -> [print "a"]
        A B -> print "b"
    ]
    
    pfn2 1 [1 2 3 4]
    
    probe fpat1: fn-pattern [A [A B . Xs]]
    fpat1/-> [1 [1 2 3 4]] [reduce [A B Xs]] 
    
    x: none parse [1 2 "a"] [set x  collect [some integer!]] x
]