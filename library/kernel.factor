! :folding=indent:collapseFolds=1:

! $Id$
!
! Copyright (C) 2004 Slava Pestov.
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

IN: kernel
USE: generic
USE: lists
USE: math
USE: math-internals
USE: strings
USE: vectors
USE: words
USE: vectors

: cpu ( -- arch )
    #! Returns one of "x86" or "unknown".
    7 getenv ;

: os ( -- arch )
    #! Returns one of "unix" or "win32".
    11 getenv ;

: dispatch ( n vtable -- )
    vector-nth call ;

: 2generic ( n n vtable -- )
    >r arithmetic-type r> dispatch ; inline

GENERIC: hashcode
M: object hashcode drop 0 ;

GENERIC: =
M: object = eq? ;

: set-boot ( quot -- )
    #! Set the boot quotation.
    8 setenv ;

: num-types ( -- n )
    #! One more than the maximum value from type primitive.
    17 ;

IN: syntax
BUILTIN: f 6 FORGET: f?
BUILTIN: t 7 FORGET: t?
