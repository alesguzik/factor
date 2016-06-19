USING: descriptive kernel math tools.test continuations prettyprint io.streams.string see
math.ratios ;
in: descriptive.tests

DESCRIPTIVE: divide ( num denom -- fraction ) / ;

{ 3 } [ 9 3 divide ] unit-test

{
    T{ descriptive-error f
        { { "num" 3 } { "denom" 0 } }
        T{ division-by-zero f 3 }
        divide
    }
} [
    [ 3 0 divide ] [ ] recover
] unit-test

{ "USING: descriptive math ;\nin: descriptive.tests\nDESCRIPTIVE: divide ( num denom -- fraction ) / ;\n" }
[ \ divide [ see ] with-string-writer ] unit-test

DESCRIPTIVE:: divide* ( num denom -- fraction ) num denom / ;

{ 3 } [ 9 3 divide* ] unit-test

{
    T{ descriptive-error f
        { { "num" 3 } { "denom" 0 } }
        T{ division-by-zero f 3 }
        divide*
    }
} [ [ 3 0 divide* ] [ ] recover ] unit-test

{ "USING: descriptive math ;\nin: descriptive.tests\nDESCRIPTIVE:: divide* ( num denom -- fraction ) num denom / ;\n" } [ \ divide* [ see ] with-string-writer ] unit-test