! Copyright (C) 2008, 2009 Doug Coleman, Daniel Ehrenberg.
! See http://factorcode.org/license.txt for BSD license.
USING: accessors kernel make prettyprint.backend
prettyprint.custom regexp regexp.parser splitting ;
in: regexp.prettyprint

M: regexp pprint*
    [
        [
            [ raw>> "R[[ " % % "]]" % ]
            [ options>> options>string % ] bi
        ] "" make
    ] keep present-text ;