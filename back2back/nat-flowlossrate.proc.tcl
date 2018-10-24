# This tcl script contains procedures to execute NAT flowlossrate test
# It is intended to be used in conjunction with the following scripts:
#  * NAT-flowlossrate.conf.tcl
#  * general.proc.tcl
#  * NAT-flowlossrate.example.tcl
#  * NAT-flowlossrate.run.tcl
source [ file join [ file dirname [ info script ]] .. general.proc.tcl ]

proc NAT-flowlossrate.Setup {} {
	#- Add a Server
    set bb [ ByteBlower Instance.Get ]
    set ::server [ $bb Server.Add $::serverAddress ]

	#- Create 2 ByteBlower Ports
	set ::netPort [ $::server Port.Create $::physicalPort1 ]
	set ::natPort [ $::server Port.Create $::physicalPort2 ]

	#- Layer2 setup
	set ::netL2 [ $::netPort Layer2.EthII.Set ]
	set ::natL2 [ $::natPort Layer2.EthII.Set ]
	$::netL2 Mac.Set $::netMacAddress
	$::natL2 Mac.Set $::natPrivateMacAddress

	
	
	#- Layer3 setup
	set ::netL3 [ $::netPort Layer3.IPv4.Set ]
	set ::natL3 [ $::natPort Layer3.IPv4.Set ]

	#- Setup net port
	if { $::netPerformDhcp } {
		#- Using DHCP
		[ $::netL3 Protocol.Dhcp.Get ] Perform
		set ::netIpAddress [ $::netL3 Ip.Get ]
		set ::netNetmask [ $::netL3 Netmask.Get ]
		set ::netIpGW [ $::netL3 Gateway.Get ]
	} else {
		#- Using static IP
		$::netL3 Ip.Set $::netIpAddress
		$::netL3 Netmask.Set $::netNetmask
		$::netL3 Gateway.Set $::netIpGW
	}
	#- Setup natted port
	if { $::natPerformDhcp } {
		#- Using DHCP
		[ $::natL3 Protocol.Dhcp.Get ] Perform
		set ::natPrivateIpAddress [ $::natL3 Ip.Get ]
		set ::natPrivateNetmask [ $::natL3 Netmask.Get ]
		set ::natPrivateIpGW [ $::natL3 Gateway.Get ]
	} else {
		#- Using static IP
		$::natL3 Ip.Set $::natPrivateIpAddress
		$::natL3 Netmask.Set $::natPrivateNetmask
		$::natL3 Gateway.Set $::natPrivateIpGW
	}

	#- Descriptions
	puts [ $::server Description.Get ]
	puts [ $::netPort Description.Get ]
	puts [ $::natPort Description.Get ]

	#- Get the destination MAC addresses to reach the (public) net port
	set ::dmacNatPort [ $::natL3 Protocol.Arp [ $::netL3 Ip.Get ] ]

	#- Perform the NAT test to get the public IP address and port of the NAT gateway.
	set ::natPublicIpAndPort [ ::excentis::ByteBlower::NatDevice.IP.Get $::netPort $::natPort $::netUdpPort $::natPrivateUdpPort ]
	set ::natPublicIpAddress [ lindex $::natPublicIpAndPort 0 ]
	set ::natPublicUdpPort [ lindex $::natPublicIpAndPort 1 ]
	puts ""
	puts "NAT Device public IP Address is : ${::natPublicIpAddress}"
	puts "NAT Device public UDP Port is   : ${::natPublicUdpPort}"

	#- Get the destination MAC addresses to reach the (private) natted port
	set ::dmacNetPort [ $::netL3 Protocol.Arp $::natPublicIpAddress ]

	# Create the (UDP) scouting frame, leaving the IP and ethernet settings to default
	set scoutingFramePayload "BYTEBLOWER SCOUTING FRAME"
	if { [ binary scan $scoutingFramePayload H* scoutingFramePayloadHex ] != 1 } {
		error "UDP flow setup error: Unable to generate ByteBlower scouting frame payload."
	}
	set scoutingFramePayloadData [ ::excentis::basic::String.To.Hex $scoutingFramePayloadHex ]
	set ::natScoutingFrame [ ::excentis::basic::Frame.Udp.Set $::dmacNatPort [ $::natL2 Mac.Get ] [ $::netL3 Ip.Get ] [ $::natL3 Ip.Get ] $::netUdpPort $::natPrivateUdpPort $scoutingFramePayloadData ]
	set ::netScoutingFrame [ ::excentis::basic::Frame.Udp.Set $::dmacNetPort [ $::netL2 Mac.Get ] $::natPublicIpAddress [ $::netL3 Ip.Get ] $::natPublicUdpPort $::netUdpPort $scoutingFramePayloadData ]

	#- Create UDP frames (UDP length == 82B, EthII length == 128B)
	# leave the IP and ethernet settings to default
	set ::natFrame [ ::excentis::basic::Frame.Udp.Set $::dmacNatPort [ $::natL2 Mac.Get ] [ $::netL3 Ip.Get ] [ $::natL3 Ip.Get ] $::netUdpPort $::natPrivateUdpPort [ list -Length $::udpLength ] ]
	set ::netFrame [ ::excentis::basic::Frame.Udp.Set $::dmacNetPort [ $::netL2 Mac.Get ] $::natPublicIpAddress [ $::netL3 Ip.Get ] $::natPublicUdpPort $::netUdpPort [ list -Length $::udpLength ] ]

	set ::natFlow [ list -tx [ list -port $::natPort\
		-scoutingframe [ list -bytes $::natScoutingFrame ] \
		-frame [ list -bytes $::natFrame ] \
		-numberofframes $::numberOfFrames \
		-interframegap $::interFrameGap \
	] \
		-rx [ list -port $::netPort \
		-trigger [ list -type basic -filter "(ip.src == ${::natPublicIpAddress}) and (ip.dst == [ $::netL3 Ip.Get ]) and (eth.len == $::ethernetLength)" ]\
	] \
	]

	# ---- Back-to-Back test
	#set backToBackResults [ ::excentis::ByteBlower::FlowLossRate [ list $natFlow ] -return numbers ]
	#puts "backToBackResults: $backToBackResults"

	# --- Other Examples:
	# --- Uni-directional
	#set flowlossUnidir [ ::excentis::ByteBlower::FlowLossRate [ list $natFlow ] ]
	#puts "flowlossUnidir: $flowlossUnidir"

	#set flowlossUnidirNumbers [ ::excentis::ByteBlower::FlowLossRate [ list $natFlow ] -return numbers ]
	#puts "flowlossUnidirNumbers: $flowlossUnidirNumbers"

	# --- Bi-directional
	#- define a second flow in the other direction
	set ::netFlow [ list -tx [ list -port $::netPort\
		-scoutingframe [ list -bytes $::netScoutingFrame ] \
		-frame [ list -bytes $::netFrame ] \
		-numberofframes $::numberOfFrames \
		-interframegap $::interFrameGap \
	] \
		-rx [ list -port $::natPort \
		-trigger [ list -type basic -filter "(ip.src == [ $::netL3 Ip.Get ]) and (ip.dst == [ $::natL3 Ip.Get ]) and (eth.len == $::ethernetLength)" ]\
	]\
	]
	return
}
	
proc NAT-flowlossrate.Run {} {
	
	#set flowlossBidir [ ::excentis::ByteBlower::FlowLossRate [ list $natFlow $netFlow ] ]
	#puts "flowlossBidir: $flowlossBidir"
	#
	#set flowlossBidirNumbers [ ::excentis::ByteBlower::FlowLossRate [ list $natFlow $netFlow ] -return numbers ]
	#puts "flowlossBidirNumbers: $flowlossBidirNumbers"

	# --- Using the ::excentis::ByteBlower::ExecuteScenario directly:
	#set result1 [ ::excentis::ByteBlower::ExecuteScenario [ list $netFlow ] ]
	#puts "result1: $result1"
	#set result2 [ ::excentis::ByteBlower::ExecuteScenario [ list $natFlow $netFlow ] ]
	#puts "result2: $result2"

	# --- Run the throughput test --- #
	set currentThroughput $::initialThroughput
	set currentMin $::minimumThroughput
	set currentMax $::maximumThroughput
	set throughput 0

	set i 0
	while {1} {
		incr i 1
		puts "#------------------------#"
		puts [ format "#---   Iteration %2d   ---#" $i ]
		puts "#------------------------#"
		puts ""

		set currentFrameRate [ expr 1.0 * $currentThroughput / 8.0 / $::ethernetLength ] ;# pps
		set currentNumberOfFrames [ expr int( floor( $currentFrameRate * $::iterationTime ) ) ] ;# nr of packets
		set currentInterFrameGap [ expr int( floor( 1000000000.0 / $currentFrameRate ) ) ] ;# ns

		puts "current throughput : ${currentThroughput} bps"
		puts "current minimum    : ${currentMin} bps"
		puts "current maximum    : ${currentMax} bps"
		puts ""
		puts "current Frame Rate       : ${currentFrameRate} pps"
		puts "current Number Of Frames : ${currentNumberOfFrames}"
		puts "current InterFrameGap    : ${currentInterFrameGap} ns"
		puts ""

		set ::natFlow [ list -tx [ list -port $::natPort\
			-scoutingframe [ list -bytes $::natScoutingFrame ] \
			-frame [ list -bytes $::natFrame ]\
			-numberofframes $currentNumberOfFrames \
			-interframegap ${currentInterFrameGap}ns \
		]\
			-rx [ list -port $::netPort\
			-trigger [ list -type basic -filter "(ip.src == ${::natPublicIpAddress}) and (ip.dst == [ $::netL3 Ip.Get ]) and (eth.len == $::ethernetLength)" ]\
		]\
		]

		set flowLossPercent [ ::excentis::ByteBlower::FlowLossRate [ list $::natFlow ] ]
		puts ""
		puts "flowLoss percentage : ${flowLossPercent} %"
		puts ""

		# --- Update current throughput
		if { $flowLossPercent <= $::acceptedLoss } {
			# --- Device throughput is higher
			if { $throughput < $currentThroughput } {
				set throughput $currentThroughput
			}

			set throughputAdjust [ expr $currentMax - $currentThroughput ]
			set currentMin $currentThroughput
		} else {
			# --- Device throughput is lower
			set throughputAdjust [ expr $currentMin - $currentThroughput ]
			set currentMax $currentThroughput
		}
		incr currentThroughput [ expr int( $throughputAdjust * $::backoff / 100.0 ) ]

		puts "highest device throughput : ${throughput} bps"
		puts ""

		# --- Check if we got the required throughputresolution
		if { [ expr $currentMax - $currentMin ] <= $::resolution } {
			#- We got the required resolution
			break
		}

		# --- Wait for 'deviceRecoverTime' seconds to let the device recover
		if { $::deviceRecoverTime > 0 } {
			set ::wait 0
			after $::deviceRecoverTime "set ::wait 1"
			puts "Waiting $::deviceRecoverTime ms..."
			vwait ::wait
			puts "done"
			puts ""
		}

		# --- Send address resolution packets between iterations
		if { $::arpBetweenIterations } {
			set ::dmacNatPort [ $::natL3 Protocol.Arp [ $::netL3 Ip.Get ] ]
			set ::dmacNetPort [ $::netL3 Protocol.Arp $::natPublicIpAddress ]
		}

	}

	puts "#-----------------------------------------------#"
	puts [ format "#---   Device throughput is : %8d bps   ---#" ${throughput} ]
	puts "#-----------------------------------------------#"
	
	return [ list ${throughput}]
}
