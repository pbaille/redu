Red [
    Description: "a rule for rules"
]

rule: [
    m:
    block! :m into rules
    | paren!

    ;; special words ---------------------------------------

    ;;Matching
    
    | 'ahead rule
    | 'end	
    | 'none	
    | 'not rule	
    | 'opt rule	
    | 'quote any-type?	
    | 'skip	
    | 'thru rule	
    | 'to rule	

    ;;Control flow

    | 'break	
    | 'if paren!	
    | 'into rule	
    | 'fail	
    | 'then	
    | 'reject	

    ;;Iteration

    | 'any rule	
    | 'some rule	
    | 'while rule	

    ;;Extraction

    | 'collect into rules	
    | 'collect 'set word! into rules	
    | 'collect 'into word! into rules	
    | 'copy word! rule	
    | 'keep rule	
    | 'keep paren!	
    | 'set word! rule

    ;;Modification

    | 'insert 'only any-type!	
    | 'remove rule

    ;; litterals -------------------------------------------------

    | char!
    | string!
    | bitset!
    | set-word!
    | get-word!
    | lit-word!
    | 1 2 number! n: if (not number? n/1) rule
    ;; datatype word
    | if (all [
            word? m/1
            value? m/1
            datatype? get m/1
        ]) skip
    ;; resolvable word
    | if (all [
            word? m/1
            value? m/1
            m/1: get m/1
        ]) into rule
    
]

rules: [rule '| rules | rule [end | rules]]

;; tests -----------------------------------------------------

throw: func [b][
    cause-error 'user 'message [reduce b]
]

test: func [s /invalid][
    r: parse s rules
    either invalid[
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

parse [1 1 1 1] [1 2 3 4 integer!]
parse [2 2 "a" "a"] [2 [1 3 [string! | integer!]]]