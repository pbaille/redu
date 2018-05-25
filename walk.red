Red [
    Description: "Red port of clojure.walk"
]

u: context load %utils.red

fn: :function

walk: fn [x inner outer][
    if series? x [u/map x :inner]
    outer x
]

postwalk: fn [x f][
    walk x fn[y][postwalk y :f] :f
]

prewalk: fn [x f][
    walk f x fn[y][prewalk y :f] fn[z][z]
]

postwalk-demo: fn [x][
    postwalk x fn[y][print ["walked: " mold y] y]
]

prewalk-demo: fn [x][
    prewalk x fn[y][print ["walked: " mold y] y]
]

prewalk-replace: fn [x smap][
    prewalk x fn[y][any [select smap y y]]
]

postwalk-replace: fn [x smap][
    postwalk x fn[y][any [select smap y y]]
]

[
    id: fn[x][x]
    walk [1 [2 [3]] 4] fn[x]Red []

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

[any [all [number? x inc x] x]] :id
    prewalk-demo [1 2 [3 4 [5 6] 7] 8 [9]]
    postwalk-demo [1 2 [3 4 [5 6] 7] 8 [9]]
    prewalk-replace [_1 + _3 - 34  [_2 + _3] 12] #(_1 one _2 two _3 three)
    postwalk-replace [1 2 [-1 2 [-3] -8] -5] #(2 "two" -1 "minone")
]

mywalk: func [
    x "the thing you walk"
    leaf? 
    leaf! 
    node? 
    node! 
][
    case [
        ;(x = :_) [print "gotit"]
        node? x [u/map node! x fn[x][mywalk x :leaf? :leaf! :node? :node!]]
        leaf? x [leaf! x]
        true [x]
    ]
]

[
    mywalk
    [_  [_ + [_] _2] 2]
    :word?
    fn[x][either x = '_  ['op] [x]]
    :series?

    :id
    'ze
]
