! Copyright (C) 2004 Chris Double.
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
!
! Start an httpd server and some words to re-load the continuation
! server files.
USE: kernel
USE: httpd-responder
USE: httpd
USE: threads
USE: prettyprint
USE: errors
USE: stdio

USE: parser

: l1 
  "cont-examples.factor" run-file 
  "cont-numbers-game.factor" run-file ;
: l2 "todo.factor" run-file ;
: l3 "todo-example.factor" run-file ;
: l4 "live-updater.factor" run-file ;
: l5 "eval-responder.factor" run-file ;
: l6 "live-updater-responder.factor" run-file ;
: l7 "cont-testing.factor" run-file ;
: l8 
  #! Use for reloading and testing changes to browser responder
  #! in factor core.
  "../../library/httpd/browser-responder.factor" run-file ;
: l9
  #! Use for reloading and testing changes to cont responder
  #! in factor core.
  "../../library/httpd/cont-responder.factor" run-file ;
DEFER: la
: la [ 8888 httpd ] [ dup . flush [ la ] when* ] catch ;
: lb [ la "httpd thread exited.\n" write flush ] in-thread  ;