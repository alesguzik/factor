! Copyright (C) 2004, 2005 Slava Pestov.
! See http://factor.sf.net/license.txt for BSD license.
IN: math
USING: kernel math math-internals ;

: cos ( x -- y )
    >rect 2dup
    fcosh swap fcos * -rot
    fsinh swap fsin neg * rect> ; inline

: sec ( x -- y ) cos recip ; inline

: cosh ( x -- y )
    >rect 2dup
    fcos swap fcosh * -rot
    fsin swap fsinh * rect> ; inline

: sech ( x -- y ) cosh recip ; inline

: sin ( x -- y )
    >rect 2dup
    fcosh swap fsin * -rot
    fsinh swap fcos * rect> ; inline

: cosec ( x -- y ) sin recip ; inline

: sinh ( x -- y )
    >rect 2dup
    fcos swap fsinh * -rot
    fsin swap fcosh * rect> ; inline

: cosech ( x -- y ) sinh recip ; inline

: tan ( x -- y ) dup sin swap cos / ; inline
: tanh ( x -- y ) dup sinh swap cosh / ; inline
: cot ( x -- y ) dup cos swap sin / ; inline
: coth ( x -- y ) dup cosh swap sinh / ; inline
