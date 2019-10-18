! Copyright (C) 2005 Slava Pestov.
! See http://factor.sf.net/license.txt for BSD license.
IN: generic
USING: words parser kernel namespaces lists strings
kernel-internals math hashtables errors vectors ;

: class ( obj -- class )
    #! The class of an object.
    dup tuple? [ 2 slot ] [ type builtin-type ] ifte ;

: make-tuple ( class -- tuple )
    dup "tuple-size" word-property <tuple>
    [ 0 swap set-array-nth ] keep ;

: (literal-tuple) ( list size -- tuple )
    dup <tuple> swap [
        ( list tuple n -- list tuple n )
        pick car pick pick swap set-array-nth
        >r >r cdr r> r>
    ] repeat nip ;

: literal-tuple ( list -- tuple )
    dup car "tuple-size" word-property over length over = [
        (literal-tuple)
    ] [
        "Incorrect tuple length" throw
    ] ifte ;

: tuple>list ( tuple -- list )
    >tuple array>list ;

: define-tuple-generic ( tuple word def -- )
    over >r [ single-combination ] \ GENERIC: r> define-generic
    define-method ;

: accessor-word ( name tuple -- word )
    [ word-name , "-" , , ] make-string
    create-in ;

: define-accessor ( tuple name n -- accessor )
    #! Generic word with a method specializing on the tuple's
    #! class that reads the right slot.
    >r over accessor-word tuck r> [ slot ] cons
    define-tuple-generic ;

: mutator-word ( name tuple -- word )
    [ "set-" , word-name , "-" , , ] make-string
    create-in ;

: define-mutator ( word name n -- mutator )
    #! Generic word with a method specializing on the tuple's
    #! class that writes to the right slot.
    >r over mutator-word tuck r> [ set-slot ] cons
    define-tuple-generic ;

: define-slot ( word name n -- [ n accessor mutator ] )
    over "delegate" = [
        pick over "delegate-field" set-word-property
    ] when
    3dup define-mutator >r define-accessor r> cons ;

: tuple-predicate ( word -- )
    #! Make a foo? word for testing the tuple class at the top
    #! of the stack.
    dup predicate-word swap [ swap class eq? ] cons
    define-compound ;

: check-shape ( word slots -- )
    #! If the new list of slots is different from the previous,
    #! forget the old definition.
    >r "use" get search dup [
        dup "slots" word-property r> = [
            drop
        ] [
            forget
        ] ifte
    ] [
        r> 2drop
    ] ifte ;

: define-slots ( tuple slots -- words )
    2dup "slots" set-word-property
    2dup length 1 + "tuple-size" set-word-property
    dup length [ 3 + ] project zip
    [ uncons define-slot ] map-with ;

: constructor-word ( word -- word )
    word-name "<" swap ">" cat3 create-in ;

: define-constructor ( word def -- )
    over constructor-word >r
    [ swap literal, \ make-tuple , append, ] make-list
    r> swap define-compound ;

: default-constructor ( tuple -- )
    dup [
        "slot-words" word-property
        reverse [ cdr unit , \ keep , ] each
    ] make-list define-constructor ;

: define-tuple ( tuple slots -- )
    2dup check-shape
    >r
    create-in
    dup save-location
    dup intern-symbol
    dup tuple-predicate
    dup tuple "metaclass" set-word-property
    dup
    dup r> define-slots "slot-words" set-word-property
    default-constructor ;

: tuple-delegate ( tuple -- obj )
    dup tuple? [
        dup class "delegate-field" word-property dup [
            >fixnum slot
        ] [
            2drop f
        ] ifte
    ] [
        drop f
    ] ifte ;

: alist>quot ( default alist -- quot )
    #! Turn an association list that maps values to quotations
    #! into a quotation that executes a quotation depending on
    #! the value on the stack.
    [
        [
            unswons
            \ dup , unswons literal, \ = , \ drop swons ,
            alist>quot , \ ifte ,
        ] make-list
    ] when* ;

: (hash>quot) ( default hash -- quot )
    [
        \ dup , \ hashcode , dup bucket-count , \ rem ,
        buckets>list [ alist>quot ] map-with list>vector ,
        \ dispatch ,
    ] make-list ;

: hash>quot ( default hash -- quot )
    #! Turn a hash  table that maps values to quotations into a
    #! quotation that executes a quotation depending on the
    #! value on the stack.
    dup hash-size 4 <= [
        hash>alist alist>quot
    ] [
        (hash>quot)
    ] ifte ;

: default-tuple-method ( generic -- quot )
    #! If the generic does not define a specific method for a
    #! tuple, execute the return value of this.
    dup "methods" word-property
    tuple over hash dup [
        2nip
    ] [
        drop object over hash dup [
            2nip
        ] [
            2drop [ dup tuple-delegate ] swap
            dup unit swap
            unit [ car ] cons [ undefined-method ] append
            \ ?ifte 3list append
        ] ifte
    ] ifte ;

: tuple-dispatch-quot ( generic -- quot )
    #! Generate a quotation that performs tuple class dispatch
    #! for methods defined on the given generic.
    dup default-tuple-method \ drop swons
    swap "methods" word-property hash>quot
    [ dup class ] swap append ;

: add-tuple-dispatch ( word vtable -- )
    >r tuple-dispatch-quot tuple r> set-vtable ;

: clone-tuple ( tuple -- tuple )
    #! Make a shallow copy of a tuple, without cloning its
    #! delegate.
    dup array-capacity dup <tuple> [ -rot copy-array ] keep ;

: clone-delegate ( tuple -- )
    dup class "delegate-field" word-property dup [
        [ >fixnum slot clone ] 2keep set-slot
    ] [
        2drop
    ] ifte ;

M: tuple clone ( tuple -- tuple )
    #! Clone a tuple and its delegate.
    clone-tuple dup clone-delegate ;

: tuple>list ( tuple -- list )
    >tuple dup array-capacity swap array>list ;

M: tuple = ( obj tuple -- ? )
    over tuple? [
        over class over class = [
            swap tuple>list swap tuple>list =
        ] [
            2drop f
        ] ifte
    ] [
        2drop f
    ] ifte ;

M: tuple hashcode ( vec -- n )
    dup array-capacity 1 number= [
        drop 0
    ] [
        1 swap array-nth hashcode
    ] ifte ;

tuple [
    ( generic vtable definition class -- )
    2drop add-tuple-dispatch
] "add-method" set-word-property

tuple [
    drop tuple "builtin-type" word-property unit
] "builtin-supertypes" set-word-property

tuple 10 "priority" set-word-property

tuple [ 2drop t ] "class<" set-word-property