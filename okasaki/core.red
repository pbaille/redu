Red []

cd %..
u: context load %utils.red
cd %okasaki

Cons: ['Cons any-type! [into Cons | 'Nil]]

parse [Cons 2 Nil] Cons
parse [Cons 1 [Cons 2 Nil]] Cons


