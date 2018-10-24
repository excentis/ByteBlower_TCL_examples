# This tcl script contains procedures to execute a TcpAckTest test.
# It is intended to be used in conjunction with the following scripts:
#  * TcpAckTest.conf.tcl
#  * general.proc.tcl
#  * TcpAckTest.proc.tcl
#  * TcpAckTest.example.tcl
#  * TcpAckTest.run.tcl

source [ file join [ file dirname [ info script ]] .. general.proc.tcl ]

proc TcpAckTest.Setup { } {

	
	# Initializing the ByteBlower
	#-------------------------------
	# o change IP to your ByteBlower IP
	set bb [ ByteBlower Instance.Get ]
	set server [ $bb Server.Add $::serverAddress ]

	# Setting up  port1
	#-------------------------------------
	# o change port
	# o change MAC
	set port1 [ $server Port.Create $::physicalPort1 ]

	set portEth1 [ $port1 Layer2.EthII.Set ]
	$portEth1 Mac.Set $::macAddressPort1
	$portEth1 Type.Set DIX
	

	set portIp1 [ $port1 Layer3.IPv4.Set]
	[ $portIp1 Protocol.Dhcp.Get ] Perform
	# Setting up  port2
	#-------------------------------------
	# o change port
	# o change MAC
	set port2 [ $server Port.Create $::physicalPort2 ]

	set portEth2 [ $port2 Layer2.EthII.Set ]
	$portEth2 Mac.Set $::macAddressPort2
	$portEth2 Type.Set DIX

	set portIp2 [ $port2 Layer3.IPv4.Set ]
	[ $portIp2 Protocol.Dhcp.Get ] Perform

	return [ list $server $port1 $port2 $portEth1 $portEth2 $portIp1 $portIp2 ]
}

proc TcpAckTest.Run { port1 port2 portEth1 portEth2 portIp1 portIp2 initialAckValue ackIncrement numberOfAcks numberOfFrames } {

	set txflowparameters "-port $port1"

	# Create the (UDP) scouting frame, leaving the IP and ethernet settings to default
	set scoutingFramePayload "BYTEBLOWER SCOUTING FRAME"
	if { [ binary scan $scoutingFramePayload H* scoutingFramePayloadHex ] != 1 } {
		error "UDP flow setup error: Unable to generate ByteBlower scouting frame payload."
	}
	set scoutingFramePayloadData [ ::excentis::basic::String.To.Hex $scoutingFramePayloadHex ]
	set scoutingFrame [ ::excentis::basic::Frame.Udp.Set [$portEth2 Mac.Get] [$portEth1 Mac.Get] [$portIp2 Ip.Get] [$portIp1 Ip.Get] \
		8000 8000 $scoutingFramePayloadData ]
	lappend txflowparameters -scoutingframe [ list -bytes $scoutingFrame ]

	for {set i 0} {$i < $numberOfAcks} {incr i} {
		set a [expr $initialAckValue + $i * $ackIncrement]
		set ack "0x[format %02x [expr ($a/0x1000000)]] 0x[format %02x [expr ($a & 0x00ff0000)/0x10000]]\
				 0x[format %02x [expr ($a & 0x0000ff00)/0x100]] 0x[format %02x [expr $a & 0x000000ff]]"
		#puts "iteration $i: ack value $ack"
		set frame$i [::excentis::basic::Frame.Tcp.Set [$portEth2 Mac.Get] [$portEth1 Mac.Get] [$portIp2 Ip.Get] [$portIp1 Ip.Get] \
			8000 8000 "0x00 0x00" [list -TCP [list -TCPAck $ack]]]
		lappend txflowparameters -frame [ list -bytes [set frame$i] ]
	}
	lappend txflowparameters -numberofframes $numberOfFrames -interframegap 10ms

	set flow [ list -tx $txflowparameters	\
		        -rx [ list -port $port2 -trigger [list -type basic -filter "(ip.src == [$portIp1 Ip.Get]) and (ip.dst == [$portIp2 Ip.Get])"] ]		\
	         ]

	return [::excentis::ByteBlower::ExecuteScenario [list $flow]]
}
