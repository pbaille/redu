Red [
    Description: "a rule for rules"
]

rules: [rule '| rules | rule [end | rules]]

rule: [

    m:
    block! :m into rules
    | paren!

    ;; special words -------------

    ;Matching   
    | 'ahead rule
    | 'end	
    | 'none	
    | 'not rule	
    | 'opt rule	
    | 'quote any-type!	
    | 'skip	
    | 'thru rule	
    | 'to rule	

    ;Control flow
    | 'break	
    | 'if paren!	
    | 'into rule	
    | 'fail	
    | 'then	
    | 'reject	

    ;Iteration
    | 'any rule	
    | 'some rule	
    | 'while rule	

    ;Extraction
    	
    | 'collect 'set word! into rules	
    | 'collect 'into word! into rules
	| 'collect into rules
    | 'copy word! rule	
    | 'keep paren!
    | 'keep rule
    | 'set word! rule

    ;Modification
    | 'insert 'only any-type!	
    | 'remove rule

    ;; litterals -----------------

    | char!
    | string!
    | bitset!
    | set-word!
    | get-word!
    | lit-word!
    | 1 2 number! n: if (not number? n/1) rule
    ;datatype word
    | if (all [
            word? m/1 value? m/1 v: get m/1
            any [datatype? v typeset? v]
        ]) skip
    ;resolvable word
    | if (all [
            word? m/1
            value? m/1
            m/1: get m/1
        ]) into rules  
]

rules?: func [x][parse x rules]
rule?: func [x][parse x rule]


;; tests -----------------------------------------------------

throw: func [b][
    cause-error 'user 'message [reduce b]
]

test: func [s /invalid][
    r: parse s rules
    either invalid [
        if r [throw ['should-be-invalid s]]
    ][if not r [throw ['should-be-valid s]]]
]

tests: func [xs /invalid] [
    foreach x xs [
        either invalid [test/invalid x][test x]]
]

digit: charset "123"

tests [
    [number!]
    [string!]
    [(a b c)]
    [a:]
    [:a]
    [quote 42]
    [#"a"]
    ["foo"]
    ['foo]
    [digit]
    ['a 'b 'c]
    ['a | string! digit]
    [1 string!]
    [3 5 'a]
    [digit ['a :z | 3 string!]]
    [[['a]]]
    [[digit] | string!]
    [ahead 2 3 ['a | digit]]
    [none end]
    ["aze" ["baz" | "ert"] digit]
    [a: integer! (a b c) 2 3 [word! | path!]]
    [(print "a") integer!]
    [string! integer!]
    [1 string!]
    [1 2 string!]
    [if (zub)]
    [if (zub) skip]
    [integer! | string!]
    [string! [integer! | string!]]
]

tests/invalid [
    ;[(print a)]
    [1]
    [1 2 3 string!]
    [pouet integer!]
    [a b c]
]

;; ----------------------------------------------------------
;; a version of parse with ~ ~@

u: context load %utils.red

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

parse+: func [x rules][
    rules: traverse rules func [e][
        case [
            equal? e/1 '! [back change/only remove e do e/1]
            equal? e/1 '..! [insert remove e do take e]
            'else [next e]
        ]
    ]
    ?? rules
    parse x rules
]
[
    string-of-length: func[n][
        compose/deep [ahead string! into [(n) skip]]
    ]
    parse+ ["aze" "ab" "ba"] [
        ..!(string-of-length 3)
        some !(string-of-length 2)
    ]
]

;; ----------------------------------------------------------

upperchar: charset [#"A" - #"Z"]

uppercase: [_: if (parse to-string _ [upperchar to end]) skip]

compile-binding-rule: func [
    "turn a binding rule into native parse rule"
    word
    rule
    ;/callback cb
][
    ;cpar: func [x] [to-paren compose x]
    rule: either block? rule [rule] [compose/only [(rule)]]
    compose/only [
        cbr_:
        if (to-paren compose [not value? quote (word)]
        ) (compose/only [set (word) (rule)  | break])
        | if (to-paren compose [equal? get quote (word) cbr_/1]
        ) (rule)
    ]
]

compile-rest-pattern: func [word][
    ;cpar: func [x] [to-paren compose x]
    compose/deep [
        m1: [to end] m2:
        if (to-paren compose/deep [
                v: copy/part m1 m2
                print "aaa"
                print mold v
                either value? quote (word) [
                    print "branch a"
                    print value? quote (word)
                    not equal? get quote (word) v
                ][print "branch b" print mold v (to-set-word word) v none]
            ]
        ) [(quote (print "break")) break]
        _: (quote (print "end" print mold _))
    ]
]

 compile-rest-pattern 'aze

[
    compile-binding-rule/callback: func [sym val] []
    probe compile-br 'A number!
]

binding-var: [ahead word! uppercase]

binding-rule': [ change only [
        set b binding-var [set r rule | (r: [any-type!])]
        | set r rule (b: u/gensym)
    ] (compile-binding-rule b r)
]

binding-cons': [
    ahead block!
    insert [into]
    into [
        some binding-rule'
        remove '.
        change set restsym binding-var (compile-rest-pattern restsym)
    ]
]

binding-rule: [
    ahead [set b1 binding-var set r1 rule] remove 2 skip
    insert only (compile-binding-rule b1 r1)
    | ahead set b2 binding-var remove skip
    insert only (compile-binding-rule b2 'any-type!)
    | ahead set r3 rule remove skip
    insert only (compile-binding-rule u/gensym r3)
]

binding-cons: [
    ahead block!
    insert [into]
    into [
        some binding-rule
        remove '.
        ahead set restsym binding-var remove skip
        insert only (compile-binding-rule restsym [to end])
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
                ;print ["match args:" mold args mold rules]
                clean!
                also r: parse args rules
                do [print "match?" print r
                    print mold rules
                    if r [print mold reduce [(unique vars)]]
                    clean!]
            ]
            ->: func [args expr] [
                ;print [">>" mold args mold expr]
                clean!
                also all [parse args rules do bind expr self]
                do [print "!>>" print mold reduce [(unique vars)]
                    clean!]
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

u: context load %utils.red

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
