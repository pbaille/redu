Red [
    Title: "Arity related functions"
    File: %arity.red
    Authors: [Greggirwin Hiiamboris Rebolek]
]

;; -------------------------------------------------------------------
;; https://gist.github.com/greggirwin/53ce7d1228422076e142fa5a061e7649

; We have other reflective functions (words-of, body-of, etc.), but
; this is a little higher level, sounded fun to do, and may prove
; useful as we write more Red tools. It also shows how to make your
; own typesets and use them when parsing.

arity-of: function [
	"Returns the fixed-part arity of a function spec"
	spec [any-function! block!]
	/with refs [refinement! block!] "Count one or more refinements, and add their arity"
][
	if any-function? :spec [spec: spec-of :spec]		; extract func specs to block
	t-w: make typeset! [word! get-word! lit-word!]		; typeset for words to count
	t-x: make typeset! [refinement! set-word!]			; typeset for breakpoint, set-word is for return:
	n: 0
	; Match our word typeset until we hit a breakpoint that indicates
	; the end of the fixed arity part of the spec. 'Skip ignores the
	; type and doc string parts of the spec.
	parse spec rule: [any [t-w (n: n + 1) | t-x break | skip]]
	; Do the same thing for each refinement they want to count the
	; args for. First match thru the refinement, then start counting.
	if with [foreach ref to block! refs [parse spec [thru ref rule]]]
	n
]

[
    arity-of :append
    arity-of/with :append /only
    arity-of/with :append /dup
    arity-of :load
    arity-of/with :load /as

    test-fn: func [a b /c d /e f g /h i j k /local x y z return: [integer!]][]

    arity-of :test-fn
    arity-of/with :test-fn /c
    arity-of/with :test-fn /e
    arity-of/with :test-fn /h
    arity-of/with :test-fn [/c /e /h]
    arity-of :arity-of
    arity-of/with :arity-of /with]

;; -------------------------------------------------------------------
;; https://gist.github.com/hiiamboris/5f85edba139fc88a5eb0ee9b7b30bc6b

arity?: function [p [word! path!]] [
	either word? p [
		preprocessor/func-arity? spec-of get :p
	][
		; path format: obj1/obj2.../func/ref1/ref2...
		; have to find a point where in that path a function starts
		; i.e. p2: obj1/obj2.../func
		; and the call itself is: func/ref1/ref2...
		p2: as path! clear head []		; reuse the same block over and over again
		until [
			append  p2  pick p 1 + length? p2
			; stupid get won't accept paths of single length like [change], have to work around
			any-function? get either 1 = length? p2 [p2/1][p2]
		]
		preprocessor/func-arity?/with  (spec-of get either 1 = length? p2 [p2/1][p2])  (at p length? p2)
	]
]

;; me :)
arity??: function [x][
    print "arity??:" ?? x
    valid: all [value? x find [word! path!] type?/word x]
    either valid [arity? x][0]
]

;; ---------------------------------------------------------------
;; https://github.com/rebolek/red-tools/blob/master/func-tools.red

arity-spec: func [
    "Return function's arity" ; TODO: support for lit-word! and get-word! ?
    fn [any-function!]  "Function to examine"
    /local result count name count-rule refinement-rule append-name
][
    result: copy []
    count: 0
    name: none
    append-name: quote (repend result either name [[name count]][[count]]) 
    count-rule: [
        some [
            word! (count: count + 1)
        |   ahead refinement! refinement-rule
        |   skip
        ]
    ] 
    refinement-rule: [
        append-name
        set name refinement!
        (count: 0)
        count-rule
    ]
    parse spec-of :fn count-rule
    do append-name
    either find result /local [
        head remove/part find result /local 2
    ][result]
]

print "arity.red loaded"