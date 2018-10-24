# This tcl script contains the main script to execute a flowlossrate test on a NATed setup.
# Before you can use this script, you need to configure different parameters,
# as shown and provided by the nat-flowlossrate.conf.tcl file.
##
source [ file join [ file dirname [ info script ]]  nat-flowlossrate.proc.tcl ]

# Test Setup 
set setup [ NAT-flowlossrate.Setup ]

# Test Run
set result [ NAT-flowlossrate.Run ]

# Test Cleanup Server and Port List
$::server Destructor

            
