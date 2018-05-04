Red [
    Description: "a rule for rules"
]

rule: [

    ;; rule can be a block
    m: if (block? m/1) into rules

    ;; red expression are skipped 
    | paren! skip

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

    | 'collect into rule	
    | 'collect 'set word! into rule	
    | 'collect 'into word! into rule	
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
            parse append copy [] get m/1 rules
        ]) skip
    
]

rules: [rule '| rules | some rule]

;; tests -----------------------------------------------------

test: func [s /invalid][
    r: parse s rules
    either invalid[
        if r [throw append copy "should be invalid: " mold s]
    ][if not r [throw append copy "should be valid: " mold s]]
]

tests: func [xs /invalid] [
    foreach x xs [
        either invalid [
            test/invalid x
        ][test x]
    ]
]

digit: charset "123"

tests [
    [string!]
    [a:]
    [:a]
    [#"a"]
    [digit]
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
    [(print a)]
    [1]
    [1 2 3 string!]
    [pouet integer!]
    [a b c]
]

