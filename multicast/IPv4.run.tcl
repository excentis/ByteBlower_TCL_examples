# In this example, we perform a simple multicast test. This will load the configuration from 
# the IPv4.conf.tcl file and use this to perform the test, described in the IPv4.example file.
##

source [ file join [ file dirname [ info script ]] IPv4.conf.tcl ]
source [ file join [ file dirname [ info script ]] IPv4.example.tcl ]


