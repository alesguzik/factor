! Copyright (C) 2004, 2006 Slava Pestov.
! See http://factorcode.org/license.txt for BSD license.
USING: arrays generic hashtables help inspector io kernel
kernel-internals math namespaces parser prettyprint sequences
sequences-internals strings styles vectors words ;
IN: errors

PREDICATE: array kernel-error ( obj -- ? )
    dup first \ kernel-error eq? swap second 0 18 between? and ;

GENERIC: error. ( error -- )
GENERIC: error-help ( error -- topic )

M: object error. . ;
M: object error-help drop f ;

M: tuple error. describe ;
M: tuple error-help class ;

M: string error. print ;

SYMBOL: restarts

: :s ( -- )
    error-continuation get continuation-data stack. ;

: :r ( -- )
    error-continuation get continuation-retain stack. ;

: :c ( -- )
    error-continuation get continuation-call callstack. ;

: :get ( variable -- value )
    error-continuation get continuation-name hash-stack ;

: :res ( n -- )
    restarts get nth first3 continue-with ;

: (:help-multi)
    "This error has multiple delegates:" print help-outliner ;

: (:help-none)
    drop "No help for this error. " print ;

: :help ( -- )
    error get delegates [ error-help ] map [ ] subset
    {
        { [ dup empty? ] [ (:help-none) ] }
        { [ dup length 1 = ] [ first help ] }
        { [ t ] [ (:help-multi) ] }
    } cond ;

: (debug-help) ( string quot -- )
    <input> write-object terpri ;

: restart. ( restart n -- )
    [ [ # " :res  " % first % ] "" make ] keep
    [ :res ] curry (debug-help) ;

: restarts. ( -- )
    restarts get dup empty? [
        drop
    ] [
        terpri
        "The following restarts are available:" print
        terpri
        dup length [ restart. ] 2each
    ] if ;

: debug-help ( -- )
    terpri
    "Debugger commands:" print
    terpri
    ":help - documentation for this error" [ :help ] (debug-help)
    ":s    - data stack at exception time" [ :s ] (debug-help)
    ":r    - retain stack at exception time" [ :r ] (debug-help)
    ":c    - call stack at exception time" [ :c ] (debug-help)
    ":get  ( var -- value ) accesses variables at time of the error" print
    flush ;

: print-error ( error -- )
    [
        dup error.
        restarts.
        debug-help
    ] [
        "Error in print-error!" print
    ] recover drop ;

: try ( quot -- ) [ print-error ] recover ;

: save-error ( error continuation -- )
    error-continuation set-global
    dup error set-global
    compute-restarts restarts set-global ;

: error-handler ( error -- )
    dup continuation save-error rethrow ;

: init-error-handler ( -- )
    V{ } clone set-catchstack
    ! kernel calls on error
    [ error-handler ] 5 setenv
    \ kernel-error 12 setenv ;
