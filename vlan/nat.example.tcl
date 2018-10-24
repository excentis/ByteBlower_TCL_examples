# This tcl script contains the main script to execute a VLAN back-to-back over a NATed setup.

source [ file join [ file dirname [ info script ]] nat.proc.tcl ]

set setup [ BackToBackSetup ]
# Returns : list of  <serverObject publicByteBlowerPortObject privateByteBlowerPortObject flowList>

puts "Setup done!"
set server [ lindex $setup 0 ]
set publicPort [ lindex $setup 1 ]
set privatePort [ lindex $setup 2 ]
set flowList [ lindex $setup 3]

puts "Running..."
set result [ ::excentis::ByteBlower::FlowLossRate $flowList -return numbers ]

puts "Result: $result"
$server Destructor

