! Copyright (C) 2004, 2006 Slava Pestov.
! See http://factorcode.org/license.txt for BSD license.
USING: arrays generic hashtables inference
kernel math namespaces sequences words ;
IN: compiler

GENERIC: stack-reserve*

M: object stack-reserve* drop 0 ;

: stack-reserve ( node -- )
    0 swap [ stack-reserve* max ] each-node ;

DEFER: #terminal?

PREDICATE: #merge #terminal-merge node-successor #terminal? ;

UNION: #terminal POSTPONE: f #return #values #terminal-merge ;

: tail-call? ( -- ? )
    node-stack get [ node-successor ] map [ #terminal? ] all? ;

GENERIC: linearize* ( node -- next )

: linearize-child ( node -- )
    [ node@ linearize* ] iterate-nodes end-basic-block ;

! A map from words to linear IR.
SYMBOL: linearized

! Renamed labels. To avoid problems with labels with the same
! name in different scopes.
SYMBOL: renamed-labels

: make-linear ( word quot -- )
    [
        init-templates
        swap >r { } make r> linearized get set-hash
    ] with-node-iterator ; inline

: linearize-1 ( word node -- )
    swap [
        dup stack-reserve %prologue , linearize-child
    ] make-linear ;

: init-linearizer ( -- )
    H{ } clone linearized set
    H{ } clone renamed-labels set ;

: linearize ( word dataflow -- linearized )
    #! Outputs a hashtable mapping from labels to their
    #! respective linear IR.
    init-linearizer linearize-1 linearized get ;

M: node linearize* ( node -- next ) drop iterate-next ;

: linearize-call ( label -- next )
    end-basic-block
    tail-call? [ %jump , f ] [ %call , iterate-next ] if ;

: rename-label ( label -- label )
    <label> dup rot renamed-labels get set-hash ;

: renamed-label ( label -- label )
    renamed-labels get hash ;

: linearize-call-label ( label -- next )
    rename-label linearize-call ;

M: #label linearize* ( node -- next )
    #! We remap the IR node's label to a new label object here,
    #! to avoid problems with two IR #label nodes having the
    #! same label in different lexical scopes.
    dup node-param dup linearize-call-label >r
    renamed-label swap node-child linearize-1 r> ;

: intrinsic ( #call -- quot ) node-param "intrinsic" word-prop ;

: if-intrinsic ( #call -- quot )
    dup node-successor #if?
    [ node-param "if-intrinsic" word-prop ] [ drop f ] if ;

: linearize-if ( node label -- next )
    <label> [
        >r >r node-children first2 linearize-child
        r> r> %jump-label , %label , linearize-child
    ] keep %label , iterate-next ;

M: #call linearize* ( node -- next )
    dup if-intrinsic [
        >r <label> 2dup r> call
        >r node-successor r> linearize-if node-successor
    ] [
        dup intrinsic
        [ call iterate-next ] [ node-param linearize-call ] if*
    ] if* ;

M: #call-label linearize* ( node -- next )
    node-param renamed-label linearize-call ;

SYMBOL: live-d
SYMBOL: live-r

: value-dropped? ( value -- ? )
    dup live-d get member? not
    swap live-r get member? not and ;

: shuffle-in-template ( values -- template )
    [
        dup value-dropped? [ drop f ] when any-reg swap 2array
    ] map ;

: shuffle-out-template ( instack outstack -- stack )
    #! Avoid storing a value into its former position.
    dup length [
        pick ?nth dupd ( eq? ) 2drop f [ <clean> ] when
    ] 2map nip ;

: linearize-shuffle ( node -- )
    compute-free-vregs node-shuffle
    dup shuffle-in-d over shuffle-out-d
    shuffle-out-template live-d set
    dup shuffle-in-r over shuffle-out-r
    shuffle-out-template live-r set
    dup shuffle-in-d shuffle-in-template
    swap shuffle-in-r shuffle-in-template template-inputs
    live-d get live-r get template-outputs ;

M: #shuffle linearize* ( #shuffle -- )
    linearize-shuffle iterate-next ;

: linearize-push ( node -- )
    compute-free-vregs
    >#push< dup length alloc-reg# [ <vreg> ] map
    [ [ load-literal ] 2each ] keep
    phantom-d get phantom-append ;

M: #push linearize* ( #push -- )
    linearize-push iterate-next ;

M: #if linearize* ( node -- next )
    { { 0 "flag" } } { } [
        end-basic-block
        <label> dup "flag" %get %jump-t ,
    ] with-template linearize-if ;

: dispatch-head ( node -- label/node )
    #! Output the jump table insn and return a list of
    #! label/branch pairs.
    { { 0 "n" } } { }
    [ end-basic-block "n" %get %dispatch , ] with-template
    node-children [ <label> dup %target-label ,  2array ] map ;

: dispatch-body ( label/node -- )
    <label> swap [
        first2 %label , linearize-child end-basic-block
        dup %jump-label ,
    ] each %label , ;

M: #dispatch linearize* ( node -- next )
    #! The parameter is a list of nodes, each one is a branch to
    #! take in case the top of stack has that type.
    dispatch-head dispatch-body iterate-next ;

M: #return linearize* drop end-basic-block %return , f ;
