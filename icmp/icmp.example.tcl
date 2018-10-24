# This tcl script contains the main script to execute a icmp test.
# Before you can use this script, you need to source following tcl scripts:
#  * icmp.conf.tcl
#  * general.proc.tcl
#  * icmp.proc.tcl

# Test Setup 
source [ file join [ file dirname [ info script ]] icmp.proc.tcl ]

set srcIpConfig [ list $port1IpAddress $port1Gateway $port1Netmask ]
set dstIpConfig [ list $port2IpAddress $port2Gateway $port2Netmask ]

set setup [ Icmp.Setup	$serverAddress $physicalPort1	$physicalPort2	$port1MacAddress $port2MacAddress $port1PerformDhcp $port2PerformDhcp $srcIpConfig $dstIpConfig $icmpIdentifier $port1IcmpDataSize $port2IcmpDataSize $port1IcmpEchoLoopInterval $port2IcmpEchoLoopInterval $echoLoopRunTime $echoReplyTimeout ]




# Test Run
set result [ eval "Icmp.Run ${setup}" ]

[ lindex $setup 0 ] Destructor

set result $result

# Test Cleanup
#Cleanup [lindex $setup 0] [ lrange $setup 1 2 ]
