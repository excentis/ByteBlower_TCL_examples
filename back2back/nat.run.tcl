#------------------------------------------------------------------------------
# IPv1 Back-to-Back.NAT tutorial
#------------------------------------------------------------------------------
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
#   - back-to-back.NAT.conf.tcl from the TCL-HL examples
#   - back-to-back.NAT.proc.tcl from the TCL-HL examples
#   - back-to-back.NAT.example.tcl from the TCL-HL examples
#------------------------------------------------------------------------------


# This script will run the back-to-back example, by sourcing all necessary files.
source [ file join [ file dirname [ info script ]] nat.conf.tcl ]
source [ file join [ file dirname [ info script ]] nat.example.tcl ]
