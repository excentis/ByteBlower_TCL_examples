#------------------------------------------------------------------------------
# IPv6 Back-to Back tutorial
#------------------------------------------------------------------------------
#
# This tutorial demonstrates how easy you can set up a Back-to-Back test,
# similar to the one described in the ByteBlower GUI manual, but using IPv6
# addresses.
# It will show you how to setup the test, using the ByteBlower LowerLayer
# API. Only frame creation will be done using the HigherLayer TCL API procedures.
#
# This script will source all necessary tcl files to run the example.
# Implementation of the necessary procedures is found in the files listed in the
# requirements.
#
# @author ByteBlower development team <byteblower@excentis.com>
# @date 2008/06/25
#
# requirements:
#   - basic.utils.tcl from the TCL-HL package
#   - basic.framev4v6.tcl from the TCL-HL package
#   - general.proc.tcl from the TCL-HL examples
#   - back-to-back.IPv6.conf.tcl from the TCL-HL examples
#   - back-to-back.IPv6.proc.tcl from the TCL-HL examples
#   - back-to-back.IPv6.example.tcl from the TCL-HL examples
#------------------------------------------------------------------------------
source [ file join [ file dirname [ info script ]] IPv6.conf.tcl ]
source [ file join [ file dirname [ info script ]] IPv6.example.tcl ]