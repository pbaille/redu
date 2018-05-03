Red [
    Title: "lambda syntax"
]

u: context load %utils.red
w: context load %walk.red

fn: :function

λarg?: fn [x][
    word? x
    digit: charset "123456789"
    parse to-string x [#"_" 0 1 digit]
]

λ: fn [
    "λ[_1 + _2]"
    code
][
    ;; will hold all λarg? occurences
    ;; eg: _ | _1 | _2 ...
    args: head clear []

    ;;populate args
    u/inject copy/deep code fn[x][
        case [
            λarg? x [append args x]
            (x = 'λ) [u/throw "no nested λ"]
            'else [x]
        ] 
    ]

    ;; the sorting is optional
    ;; (better for readability)
    args: sort unique args

    ;; create a substitution map with fresh gensyms
    arg-smap: u/foldl/init args fn[m a][
        u/assoc m a u/gensym
    ] copy #()

    ;; do the sym replace in spec and code
    ;; should be done in place (mutation)
    code: w/prewalk-replace copy/deep code arg-smap
    spec: u/map args fn[x][select arg-smap x]

    func spec code
]

λ!: fn [
    "like λ but immediately applied"
    code
    args 
][
    l: λ code
    u/apply :l args
]

[
    u/map [1 2 3] λ[add _ _]
    λ[add _ _]
    u/apply λ[add _ _] [3]
    λ![_ + _] [3]
]