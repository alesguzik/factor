! Copyright (C) 2004, 2005 Slava Pestov.
! See http://factor.sf.net/license.txt for BSD license.
IN: inference
USING: errors generic interpreter kernel kernel-internals
lists math namespaces strings vectors words stdio prettyprint ;

: fast-slot? ( -- ? )
    #! If the slot number is literal and the object's type is
    #! known, we can compile a slot access into a single
    #! instruction (x86).
    peek-d literal?
    peek-next-d value-class builtin-supertypes length 1 = and ;

: fast-slot ( -- )
    dataflow-drop, pop-d literal-value
    peek-d value-class builtin-supertypes cons
    \ slot [ [ object ] [ object ] ] (consume/produce) ;

: computed-slot ( -- )
    \ slot dup "infer-effect" word-property consume/produce ;

\ slot [
    [ object fixnum ] ensure-d
    fast-slot? [ fast-slot ] [ computed-slot ] ifte
] "infer" set-word-property

: type-value-map ( value -- )
    num-types
    [ tuck builtin-type <class-tie> cons ] project-with
    [ cdr class-tie-class ] subset ;

\ type [
    [ object ] ensure-d
    \ type #call dataflow, [
        peek-d type-value-map >r
        1 0 node-inputs
        [ object ] consume-d
        [ fixnum ] produce-d
        r> peek-d set-value-literal-ties
        1 0 node-outputs
    ] bind
] "infer" set-word-property
