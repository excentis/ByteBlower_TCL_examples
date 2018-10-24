##
#
# This tcl script contains the main script to create and execute a back-to-back
# latency scenario. Sourcing this script causes the scenario to be executed. It
# assumes the configuration file (latency.conf.tcl) is sourced!
#
##

# The file containing the actual setup and execute procedures.
source [ file join [ file dirname [ info script ]] latency-wirelessendpoint.proc.tcl ]

# Map the configuration to layer3 configurations. This allows easy configuration
# of the ByteBlower ports
if { $srcPerformDhcp == 1 } {
    set srcIpConfig dhcpv4
} else {
    set srcIpConfig [ list $srcIpAddress $srcIpGW $srcNetmask ]
}

puts "Setting up latency scenario..."
set setup [ Latency.Setup $meetingpointAddress $wirelessEndpointUUID \
                            $serverAddress $srcPort $srcMacAddress \
                            $srcIpConfig $srcUdpPort $dstUdpPort $ethernetLength \
                            [ list $bidir $interFrameGap $numberOfFrames ] ]
puts "Setup done!"

# The setup procedure returns 4 elements it created. The flowList is the
# scenario configuration used by the ByteBlowerHL. It is all we need in this
# example.
set server [ lindex $setup 0 ]
set srcPort [ lindex $setup 1 ]
set meetingpoint [ lindex $setup 2 ]
set dstPort [ lindex $setup 3 ]
set flowList [ lindex $setup 4 ]

puts "Running latency scenario..."
set result [ Latency.Execute $flowList ]
puts "Latency scenario finished!"

puts "Cleanup up latency scenario..."
Latency.Cleanup $setup
puts "Cleanup done!"

puts "Result:"
puts $result
