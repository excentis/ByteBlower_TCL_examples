# This tcl script contains the main script to execute a icmpv6 test.
# Before you can use this script, you need to source following tcl scripts:
#  * icmpv6.conf.tcl
#  * general.proc.tcl
#  * icmpv6.proc.tcl

source [ file join [ file dirname [ info script ]] icmpv6.proc.tcl ]

set srcIpConfig [ list $port1IpAddress $port1Router  ]
set dstIpConfig [ list $port2IpAddress $port2Router  ]


# Test Setup 
set setup [ Icmpv6.Setup $serverAddress $physicalPort1 $physicalPort2 $port1MacAddress $port2MacAddress $port1AutoConfig $port2AutoConfig $srcIpConfig $dstIpConfig $icmpIdentifier $port1IcmpDataSize $port2IcmpDataSize $port1IcmpEchoLoopInterval $port2IcmpEchoLoopInterval $echoLoopRunTime $echoReplyTimeout ]

# Test Run
set result [ eval "Icmpv6.Run ${setup}" ]

[ lindex $setup 0 ] Destructor

set result $result

# Test Cleanup
#Cleanup [lindex $setup 0] [ lrange $setup 1 2 ]

