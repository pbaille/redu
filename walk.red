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
    walk [1 [2 [3]] 4] fn[x][any [all [number? x inc x] x]] :id
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

'aze

print "walk.red loaded"