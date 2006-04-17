! Copyright (C) 2005, 2006 Slava Pestov.
! See http://factorcode.org/license.txt for BSD license.
IN: compiler
USING: arrays assembler generic hashtables
inference kernel kernel-internals lists math math-internals
namespaces sequences words ;

\ slot [
    drop
    { { 0 "obj" } { 1 "n" } } { "obj" } [
        "obj" %get %untag ,
        "n" %get "obj" %get %slot ,
    ] with-template
] "intrinsic" set-word-prop

\ set-slot [
    drop
    { { 0 "val" } { 1 "obj" } { 2 "slot" } } { } [
        "obj" %get %untag ,
        "val" %get "obj" %get "slot" %get %set-slot ,
    ] with-template
    end-basic-block
    T{ vreg f 1 } %write-barrier ,
] "intrinsic" set-word-prop

\ char-slot [
    drop
    { { 0 "n" } { 1 "str" } } { "str" } [
        "n" %get "str" %get %char-slot ,
    ] with-template
] "intrinsic" set-word-prop

\ set-char-slot [
    drop
    { { 0 "ch" } { 1 "n" } { 2 "str" } } { } [
        "ch" %get "str" %get "n" %get %set-char-slot ,
    ] with-template
] "intrinsic" set-word-prop

\ type [
    drop
    { { any-reg "in" } } { "in" }
    [ end-basic-block "in" %get %type , ] with-template
] "intrinsic" set-word-prop

\ tag [
    drop
    { { any-reg "in" } } { "in" } [ "in" %get %tag , ] with-template
] "intrinsic" set-word-prop

: binary-op ( op -- )
    { { 0 "x" } { 1 "y" } } { "x" } [
        end-basic-block >r "y" %get "x" %get dup r> execute ,
    ] with-template ; inline

{
    { fixnum+       %fixnum+       }
    { fixnum-       %fixnum-       }
    { fixnum-bitand %fixnum-bitand }
    { fixnum-bitor  %fixnum-bitor  }
    { fixnum-bitxor %fixnum-bitxor }
    { fixnum/i      %fixnum/i      }
    { fixnum*       %fixnum*       }
} [
    first2 [ binary-op drop ] curry
    "intrinsic" set-word-prop
] each

: binary-jump ( label op -- )
    { { any-reg "x" } { any-reg "y" } } { } [
        end-basic-block >r >r "y" %get "x" %get r> r> execute ,
    ] with-template ; inline

{
    { fixnum<= %jump-fixnum<= }
    { fixnum<  %jump-fixnum<  }
    { fixnum>= %jump-fixnum>= }
    { fixnum>  %jump-fixnum>  }
    { eq?      %jump-eq?      }
} [
    first2 [ binary-jump drop ] curry
    "if-intrinsic" set-word-prop
] each

\ fixnum-mod [
    drop
    ! This is not clever. Because of x86, %fixnum-mod is
    ! hard-coded to put its output in vreg 2, which happends to
    ! be EDX there.
    { { 0 "x" } { 1 "y" } } { "out" } [
        end-basic-block
        T{ vreg f 2 } "out" set
        "y" %get "x" %get "out" %get %fixnum-mod ,
    ] with-template
] "intrinsic" set-word-prop

\ fixnum/mod [
    drop
    ! See the remark on fixnum-mod for vreg usage
    { { 0 "x" } { 1 "y" } } { "quo" "rem" } [
        end-basic-block
        T{ vreg f 0 } "quo" set
        T{ vreg f 2 } "rem" set
        "y" %get "x" %get 2array
        "rem" %get "quo" %get 2array %fixnum/mod ,
    ] with-template
] "intrinsic" set-word-prop

\ fixnum-bitnot [
    drop
    { { 0 "x" } } { "x" } [
        "x" %get dup %fixnum-bitnot ,
    ] with-template
] "intrinsic" set-word-prop
