! Copyright (C) 2008 Slava Pestov.
! See http://factorcode.org/license.txt for BSD license.
USING: accessors math namespaces sequences kernel fry
compiler.cfg compiler.cfg.registers compiler.cfg.instructions
compiler.cfg.instructions.syntax ;
IN: compiler.cfg.height

! Combine multiple stack height changes into one at the
! start of the basic block.
!
! Alias analysis and value numbering assume this optimization
! has been performed.

SYMBOL: ds-height
SYMBOL: rs-height

GENERIC: compute-heights ( insn -- )

M: ##inc-d compute-heights n>> ds-height [ + ] change ;
M: ##inc-r compute-heights n>> rs-height [ + ] change ;
M: insn compute-heights drop ;

GENERIC: normalize-height* ( insn -- insn' )

: normalize-inc-d/r ( insn stack -- insn' )
    swap n>> '[ _ - ] change f ; inline

M: ##inc-d normalize-height* ds-height normalize-inc-d/r ;
M: ##inc-r normalize-height* rs-height normalize-inc-d/r ;

GENERIC: loc-stack ( loc -- stack )

M: ds-loc loc-stack drop ds-height ;
M: rs-loc loc-stack drop rs-height ;

GENERIC: <loc> ( n stack -- loc )

M: ds-loc <loc> drop <ds-loc> ;
M: rs-loc <loc> drop <rs-loc> ;

: normalize-peek/replace ( insn -- insn' )
    [ [ [ n>> ] [ loc-stack get ] bi + ] keep <loc> ] change-loc ; inline

M: ##peek normalize-height* normalize-peek/replace ;
M: ##replace normalize-height* normalize-peek/replace ;

M: insn normalize-height* ;

: normalize-height ( insns -- insns' )
    0 ds-height set
    0 rs-height set
    [ [ compute-heights ] each ]
    [ [ [ normalize-height* ] map sift ] with-scope ] bi
    ds-height get dup zero? [ drop ] [ f \ ##inc-d boa prefix ] if
    rs-height get dup zero? [ drop ] [ f \ ##inc-r boa prefix ] if ;
