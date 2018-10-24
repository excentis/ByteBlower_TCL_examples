# This tcl script contains the main script to execute a TcpAckTest test.
# Before you can use this script, you need to source following tcl scripts:
#  * ack-test.conf.tcl

source [ file join [ file dirname [ info script ]] ack-test.proc.tcl ]

# Test Setup 
set setup [ TcpAckTest.Setup ]


set port1 [ lindex $setup 1 ]
set port2 [ lindex $setup 2 ]
set portEth1 [ lindex $setup 3 ]
set portEth2 [ lindex $setup 4 ]
set portIp1 [ lindex $setup 5 ]
set portIp2 [ lindex $setup 6 ]

# Test Run
set result [ TcpAckTest.Run $port1 $port2 $portEth1 $portEth2 $portIp1 $portIp2 $::initialAckValue $::ackIncrement $::numberOfAcks $::numberOfFrames ]

# Test Cleanup Server and Port List
#Cleanup [lindex $setup 0] [ lrange $setup 1 2 ]
