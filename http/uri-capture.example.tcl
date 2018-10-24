# This tcl script contains the main script to execute a http uri capture test.
# Before you can use this script, you need to source following tcl scripts:
#  * http_uri_capture.conf.tcl
#  * general.proc.tcl
#  * http_uri_capture.proc.tcl
source [ file join [ file dirname [ info script ]]  uri-capture.proc.tcl ]

# Test Setup 
set setup [ http_uri_capture.Setup ]

# Test Run
set result [ http_uri_capture.Run ]

# Test Cleanup
# -- Clean up
#Cleanup $::server $::port
