! :folding=indent:collapseFolds=1:

! $Id$
!
! Copyright (C) 2004, 2005 Slava Pestov.
! 
! Redistribution and use in source and binary forms, with or without
! modification, are permitted provided that the following conditions are met:
! 
! 1. Redistributions of source code must retain the above copyright notice,
!    this list of conditions and the following disclaimer.
! 
! 2. Redistributions in binary form must reproduce the above copyright notice,
!    this list of conditions and the following disclaimer in the documentation
!    and/or other materials provided with the distribution.
! 
! THIS SOFTWARE IS PROVIDED ``AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES,
! INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND
! FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE
! DEVELOPERS AND CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
! SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
! PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS;
! OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
! WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR
! OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF
! ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

IN: inference
USE: errors
USE: interpreter
USE: kernel
USE: lists
USE: math
USE: namespaces
USE: strings
USE: vectors
USE: words
USE: hashtables
USE: generic
USE: prettyprint

: max-recursion 0 ;

! This variable takes a value from 0 up to max-recursion.
SYMBOL: inferring-base-case

: branches-can-fail? ( -- ? )
    inferring-base-case get max-recursion > ;

! Word properties that affect inference:
! - infer-effect -- must be set. controls number of inputs
! expected, and number of outputs produced.
! - infer - quotation with custom inference behavior; ifte uses
! this. Word is passed on the stack.

! Vector of results we had to add to the datastack. Ie, the
! inputs.
SYMBOL: d-in

! Recursive state. An alist, mapping words to labels.
SYMBOL: recursive-state

GENERIC: value= ( literal value -- ? )
GENERIC: value-class-and ( class value -- )

TUPLE: value class type-prop recursion ;

C: value ( recursion -- value )
    [ set-value-recursion ] keep ;

TUPLE: computed delegate ;

C: computed ( class -- value )
    swap recursive-state get <value> [ set-value-class ] keep
    over set-computed-delegate ;

M: computed value= ( literal value -- ? )
    2drop f ;

M: computed value-class-and ( class value -- )
    [ value-class class-and ] keep set-value-class ;

TUPLE: literal value delegate ;

C: literal ( obj rstate -- value )
    [
        >r <value> [ >r dup class r> set-value-class ] keep
        r> set-literal-delegate
    ] keep
    [ set-literal-value ] keep ;

M: literal value= ( literal value -- ? )
    literal-value = ;

M: literal value-class-and ( class value -- )
    value-class class-and drop ;

M: literal set-value-class ( class value -- )
    2drop ;

: (ensure-types) ( typelist n stack -- )
    pick [
        3dup >r >r car r> r> vector-nth value-class-and
        >r >r cdr r> 1 + r> (ensure-types)
    ] [
        3drop
    ] ifte ;

: ensure-types ( typelist stack -- )
    dup vector-length pick length - dup 0 < [
        swap >r neg tail 0 r>
    ] [
        swap
    ] ifte (ensure-types) ;

: required-inputs ( typelist stack -- values )
    >r dup length r> vector-length - dup 0 > [
        head [ <computed> ] map
    ] [
        2drop f
    ] ifte ;

: vector-prepend ( values stack -- stack )
    >r list>vector r> vector-append ;

: ensure-d ( typelist -- )
    dup meta-d get ensure-types
    meta-d get required-inputs dup
    meta-d [ vector-prepend ] change
    d-in [ vector-prepend ] change ;

: (present-effect) ( vector -- list )
    [ value-class ] vector-map vector>list ;

: present-effect ( [[ d-in meta-d ]] -- [ in-types out-types ] )
    #! After inference is finished, collect information.
    uncons >r (present-effect) r> (present-effect) 2list ;

: simple-effect ( [[ d-in meta-d ]] -- [[ in# out# ]] )
    #! After inference is finished, collect information.
    uncons vector-length >r vector-length r> cons ;

: effect ( -- [[ d-in meta-d ]] )
    d-in get meta-d get cons ;

: init-inference ( recursive-state -- )
    init-interpreter
    0 <vector> d-in set
    recursive-state set
    dataflow-graph off
    0 inferring-base-case set ;

DEFER: apply-word

: apply-literal ( obj -- )
    #! Literals are annotated with the current recursive
    #! state.
    dup recursive-state get <literal> push-d
    #push dataflow, [ 1 0 node-outputs ] bind ;

: apply-object ( obj -- )
    #! Apply the object's stack effect to the inferencer state.
    dup word? [ apply-word ] [ apply-literal ] ifte ;

: active? ( -- ? )
    #! Is this branch not terminated?
    d-in get meta-d get and ;

: terminate ( -- )
    #! Ignore this branch's stack effect.
    meta-d off meta-r off d-in off ;

: terminator? ( obj -- ? )
    #! Does it throw an error?
    dup word? [ "terminator" word-property ] [ drop f ] ifte ;

: handle-terminator ( quot -- )
    #! If the quotation throws an error, do not count its stack
    #! effect.
    [ terminator? ] some? [ terminate ] when ;

: infer-quot ( quot -- )
    #! Recursive calls to this word are made for nested
    #! quotations.
    active? [
        [ unswons apply-object infer-quot ] when*
    ] [
        drop
    ] ifte ;

: check-return ( -- )
    #! Raise an error if word leaves values on return stack.
    meta-r get vector-length 0 = [
        "Word leaves elements on return stack" throw
    ] unless ;

: values-node ( op -- )
    #! Add a #values or #return node to the graph.
    f swap dataflow, [
        meta-d get vector>list node-consume-d set
    ] bind ;

: (infer) ( quot -- )
    f init-inference
    infer-quot
    #return values-node check-return ;

: infer ( quot -- [[ in out ]] )
    #! Stack effect of a quotation.
    [ (infer) effect present-effect ] with-scope ;

: dataflow ( quot -- dataflow )
    #! Data flow of a quotation.
    [ (infer) get-dataflow ] with-scope ;