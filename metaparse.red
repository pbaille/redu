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
            word? m/1
            value? m/1
            datatype? get m/1
        ]) skip
    ;resolvable word
    | if (all [
            word? m/1
            value? m/1
            m/1: get m/1
        ]) into rule  
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
    
    parse+ [1 "aze" "ererer"] [
        ..!(reduce [integer! string-of-length 3])
        string!
    ]
]

;; ----------------------------------------------------------

compile-binding-rule: func [
    "turn a binding rule into native parse rule"
    word
    rule
][
    compose/only [
        cbr_:
        if (to-paren compose [not value? quote (word)]
        ) (compose/only [set (word) (rule) | break])
        | if (to-paren compose [equal? get quote (word) cbr_/1]
        ) (rule)]]

upperchar: charset [#"A" - #"Z"]

uppercase: [_: if (parse to-string _ [upperchar to end]) skip]

binding-var: [ahead word! uppercase]

binding-rule: [
    ahead [set b1 binding-var set r1 rule] remove 2 skip
      insert only (compile-binding-rule b1 r1)
    | ahead set b2 binding-var remove skip
      insert only (compile-binding-rule b2 'any-type!)
    | ahead set r3 rule remove skip
      insert only (compile-binding-rule u/gensym r3)]

binding-cons: [
    ahead block!
    _:(insert _ 'into) skip
    into [
        some binding-rule
        remove '.
        ahead set restsym binding-var remove skip
        insert only (compile-binding-rule restsym [to end])]]

args-parser: function[input-rules][

    rules: copy/deep input-rules

    also vars: copy []
    traverse rules func[x][
        if all [parse reduce [x/1] uppercase] [append vars x/1]
        next x]

    valid?: parse rules [some [b-rule | b-cons]]

    if valid? [
        func [args] compose/only [
            unset (unique copy vars)
            also parse args (rules)
            unset (unique copy vars)]]
]

[
    ap: args-parser [A integer! A]
    ap [1 'aze]
    ap [1 1]
    
    ap: args-parser [A [A . As]]
    ap [1 [1 2 3]]
    ap [1 [2 2 3]]
]
