#-----------------------------------
# Out of sequence detection tutorial
#-----------------------------------
#
# This script will source all necessary tcl files to run the example.
# Implementation of the necessary procedures is found in the files listed in the
# requirements.
#
# @author ByteBlower development team <byteblower@excentis.com>
# @date 2013/05/25
#
# requirements:
#   - ByteBlower HL
#   - outofsequence.example.tcl (master script running the example)
#   - outofsequence.conf.tcl (test configuration, values should be correct)
#   - outofsequence.proc.tcl (procedures used by this example)
#   - general.proc.tcl (shared support functions)

#------------------------------------------------------------------------------

# Source the configuration
source [ file join [ file dirname [ info script ]] outofsequence.conf.tcl ]

# Run the example using the specified configuration
source [ file join [ file dirname [ info script ]] outofsequence.example.tcl ]
