##
#
# This tcl script contains the main script to create and execute a back-to-back
# out of sequence scenario. Sourcing this script causes the scenario to be
# executed. It assumes the configuration file (outofsequence.conf.tcl) is
# sourced!
#
##

# The file containing the actual setup and execute procedures.
source [ file join [ file dirname [ info script ]] outofsequence.proc.tcl ]

# Map the configuration to layer3 configurations. This allows easy configuration
# of the ByteBlower ports
if { $srcPerformDhcp == 1 } {
    set srcIpConfig dhcpv4
} else {
    set srcIpConfig [ list $srcIpAddress $srcIpGW $srcNetmask ]
}
if { $dstPerformDhcp == 1 } {
    set dstIpConfig dhcpv4
} else {
    set dstIpConfig [ list $dstIpAddress $dstIpGW $dstNetmask ]
}

puts "Setting up out of sequence scenario..."
set setup [ Outofsequence.Setup $serverAddress $srcPort $dstPort $srcMacAddress $dstMacAddress \
                            $srcIpConfig $dstIpConfig $srcUdpPort $dstUdpPort $ethernetLength \
                            [ list $bidir $interFrameGap $numberOfFrames ] ]
puts "Setup done!"

# The setup procedure returns 4 elements it created. The flowList is the
# scenario configuration used by the ByteBlowerHL. It is all we need in this
# example.
set server [ lindex $setup 0 ]
set srcPort [ lindex $setup 1 ]
set dstPort [ lindex $setup 2 ]
set flowList [ lindex $setup 3]

puts "Running out of sequence scenario..."
set result [ Outofsequence.Execute $flowList ]
puts "Out of sequence scenario finished!"

puts "Cleanup up out of sequence scenario..."
Outofsequence.Cleanup $srcPort $dstPort $flowList
puts "Cleanup done!"

puts "Result:"
puts $result
