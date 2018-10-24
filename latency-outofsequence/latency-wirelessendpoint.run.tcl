#-----------------
# Latency tutorial
#-----------------
#
# This script will source all necessary tcl files to run the example.
# Implementation of the necessary procedures is found in the files listed in the
# requirements.
#
# @author ByteBlower development team <byteblower@excentis.com>
# @date 2013/05/28
#
# requirements:
#   - ByteBlower HL
#   - latency.example.tcl (master script running the example)
#   - latency.conf.tcl (test configuration, values should be correct)
#   - latency.proc.tcl (procedures used by this example)
#   - general.proc.tcl (shared support functions)

#------------------------------------------------------------------------------

# Source the configuration
source [ file join [ file dirname [ info script ]] latency-wirelessendpoint.conf.tcl ]

# Run the example using the specified configuration
source [ file join [ file dirname [ info script ]] latency-wirelessendpoint.example.tcl ]
