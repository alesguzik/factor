IN: scratchpad
USE: kernel
USE: math
USE: test
USE: stdio
USE: prettyprint

[ slip ] unit-test-fails
[ 1 slip ] unit-test-fails
[ 1 2 slip ] unit-test-fails
[ 1 2 3 slip ] unit-test-fails

[ 5 ] [ [ 2 2 + ] 1 slip + ] unit-test
[ 6 ] [ [ 2 2 + ] 1 1 2slip + + ] unit-test
[ 6 ] [ [ 2 1 + ] 1 1 1 3slip + + + ] unit-test

[ [ ] keep ] unit-test-fails

[ 6 ] [ 2 [ sq ] keep + ] unit-test

[ [ ] 2keep ] unit-test-fails
[ 1 [ ] 2keep ] unit-test-fails
[ 3 1 2 ] [ 1 2 [ 2drop 3 ] 2keep ] unit-test

[ 0 ] [ f [ sq ] [ 0 ] ifte* ] unit-test
[ 4 ] [ 2 [ sq ] [ 0 ] ifte* ] unit-test

[ 0 ] [ f [ 0 ] unless* ] unit-test
[ t ] [ t [ "Hello" ] unless* ] unit-test

[ "2\n" ] [ [ 1 2 [ . ] [ sq . ] ?ifte ] with-string ] unit-test
[ "9\n" ] [ [ 3 f [ . ] [ sq . ] ?ifte ] with-string ] unit-test
[ "4\n" ] [ [ 3 4 [ . ] ?when ] with-string ] unit-test
[ 3 ] [ 3 f [ . ] ?when ] unit-test
[ t ] [ 3 t [ . ] ?unless ] unit-test