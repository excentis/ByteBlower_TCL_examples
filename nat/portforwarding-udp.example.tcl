# This tcl script contains the main script to execute a back-to-back over a NATed setup.

source [ file join [ file dirname [ info script ]] portforwarding-udp.proc.tcl ]

if { $publicPerformDhcp1 == 1 } {
    set publicIpConfig dhcpv4
} else {
    set publicIpConfig [ list $publicIpAddress1 $publicIpGW1 $publicNetmask1 ]
}
if { $privatePerformDhcp1 == 1 } {
    set privateIpConfig dhcpv4
} else {
    set privateIpConfig [ list $privateIpAddress1 $privateIpGW1 $privateNetmask1 ]
}

# setup for test
# serverAddress publicPhysicalPort privatePhysicalPort publicMacAddress privateMacAddress publicIpConfig privateIpConfig publicUdpPort privateUdpPort natPublicUdpPort ethernetLength flowParam
set setup [ BackToBackSetup $serverAddress $publicPort1 $privatePort1 $publicMacAddress1 $privateMacAddress1 $publicIpConfig $privateIpConfig  $publicUdpPort1 $privateUdpPort1 $natPublicUdpPort1 $ethernetLength [list $interFrameGap $numberOfFrames ] ]
puts "Setup done!"
set server [ lindex $setup 0 ]
set publicPort [ lindex $setup 1 ]
set privatePort [ lindex $setup 2 ]

set flowList [ lindex $setup 3]
puts "Running..."
set result [ ::excentis::ByteBlower::FlowLossRate $flowList -return numbers ]

puts "Result: $result"
$server Destructor

