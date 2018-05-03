
Red [
    Title: "Utils"
	File: %utils.red
	Author: "Pierre Baille"
	Description: "Personal toolbox"
	Date: 26-April-2018
]

;; errors -------------------------------------------

throw: func [s][
    cause-error 'script 'expect-arg [form s]
]

assert: func [b s][if not b [throw s]]

???: func ['m v][print [m "->" v]]

;; deps --------------------------------------------

import: fn [file /as ns /refer ws] [
    m: context load file
    case [
        all [ns ws] [set ns import/refer ws]
        ns [set ns m]
        refer [foreach w ws [set w select m w]]
        'else do body-of m
    ]
]

;; misc --------------------------------------------

gensym: func [/with 'word /reset /local count][
    count: [0]
    count/1: add 1 either reset [0] [count/1]
    to word! rejoin [any [word 'g] count/1]
]

;; aliases -----------------------------------------

fn: :function

;; basics ------------------------------------------

id: fn[x][x]

apply: func [f args][
    do append copy [f] copy args 
]

;; -> ----------------------------------------------

->: function [init code][
    bls: split/on code '.
    ret: copy/deep init
    forall bls [
        ret: do head insert/only next first bls ret
    ]
]

[
    -> [1 2 3][
        next .
        find 3 .
        copy .
        append/only [2 3]
    ]
]

;; numbers -----------------------------------------

inc: func [x][x + 1]
dec: func [x][x - 1]
pos?: func [a][a > 0]
neg?: func [a][a < 0]
zero?: func [a][a = 0]

;; maps --------------------------------------------

assoc: fn [m k v] [also m put m k v]
merge: :extend
merge*: fn [ms][foldl ms :merge]

;; fp b&b ------------------------------------------

foldl: fn [
    "like lisp reduce"
    s [series!]
    f
    /init i "initial value"
][
    if not i [i: first s s: next s]
    forall s [i: f i first s]
]

map: func [s f][
    forall s [s/1: f s/1] s
]

filter: func [s p][
    forall s [unless p s/1 [take s 1]] s
]

[
    x: [1 2 3] 
    foldl x :add ; 6
    foldl/init x :add 1 ; 7

    foldl/init
    partition [a 1 b 2 h 3] 2
    λ[assoc _1 first _2 second _2]
    #()

    x: [1 -1 2 4 -5] 
    map x :inc 
    map/! x :inc
    x

    x: [a] map x :id

    x: [1 -1 2 4 -5] 
    filter x :pos?  
    x
]

;; series ------------------------------------------

prevs: func [
    "prevs next next [1 2 3] ;=> [1 2]"
    s [series!]
][
    copy/part copy head s dec index? s
]

posplit: func [
    "posplit next [1 2 3] ;=> [[1][2 3]]"
    s [series!]
][
    reduce [prevs s copy s]
]

find-where: func [s p][
    s: copy/deep s
    until [
        case [
            tail? s [s]
            p first s [s]
            'else also none s: next s
        ]
    ]
    either tail? s [none][s]
]

split: func [
    "split a series given a separator or a predicate"
    s
    /on sep
    /where pred
    /for n
    /from i
][
    case [
        all [from for] [take/part s dec i s: take/part s n]
        for [s: take/part s n]
        from [take/part s dec i]
    ]
    also ret: copy []
    until [
        found: case [
            where [find-where s :pred]
            on [find s sep]
        ]
        either found [
            empty?: equal? 1 index? found
            unless empty? [
                append/only ret copy/part s dec index? found
            ]
            also none s: copy next found
        ][
            any [tail? s append/only ret s]
        ] 
    ]
]

interleave: fn [x y][
    ;; @gitter red/help
    collect [
        repeat i min length? x length? y [
            keep reduce [x/:i y/:i]
        ]
    ]
]

partition: fn [s size /step step-size][
    s: copy s
    step-size: any [step-size size]
    also ret: clear []
    until [
        append/only ret copy/part s size
        take/part s step-size
        print ((length? s) < step-size)
        any [
            tail? s
            (length? s) < size
        ]
    ]
]

inject: fn [s f /if is-node?][
    is-node?: any [:is-node? :series?]
    also s
    forall s [
        either is-node? s/1 [inject s/1 :f][s/1: f s/1]
    ]
]

[
    find-where [1 2 -1] :neg?
    find-where [1 2 3] :neg?
    find-where [1 -1 9 -3] :neg?

    split/on [1 2 . 3 4 . 5 6] '.
    split/where [1 2 . 4 5 8 . 9] :word? 
    split/where [1 2 . 4 5 8 . 9] :number?
    split/on/from/for [1 2 3 1 3 2 1 2] 1 3 6

    x: [a b c d f g h]
    partition x 2
    partition/step x 3 1

    inject [1 [2 [3]]] :inc
    
]

;; code manipulation -------------------------------

import/refer %arity.red [arity??]

expr-split: function [
    "remove and return the first expression of 'block"
    block [block!]
][
    verb-or-atom: take block

    arity: arity?? verb-or-atom

    either pos? arity [
        wrapped-verb: to-paren reduce [verb-or-atom]
        args: collect [loop arity [keep/only expr-split block]]
        append wrapped-verb args
    ][verb-or-atom]
]

expr-split-all: function [
    "return a new block containing all 'block exprs"
    block
][
    also r: copy []
    until [
        append/only r expr-split block
        tail? block
    ]
]

[
    b: [head next [a] print 'yop 42]
    expr-split-all copy/deep b
    expr-split b
    b
]

;; objects -----------------------------------------

build: fn [
    "create a positional constructor for an object"
    o
][
    ks: copy []
    foreach [k v] body-of o [append ks k]
    args: words-of o
    prot: o
    func args compose/only [
        make (o) interleave (ks) compose (map args :to-paren)]
]

[
    o: object [a: 1 b: 2]
    mk: build o
    mk 7 8
]

print "utils.red loaded"




