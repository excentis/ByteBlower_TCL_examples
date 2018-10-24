# This tcl script contains procedures to execute a MLD with Traffic test.
# It is intended to be used in conjunction with the following scripts:
#  * mld_with_traffic.conf.tcl
#  * general.proc.tcl
#  * mld_with_traffic.proc.tcl
#  * mld_with_traffic.example.tcl
#  * mld_with_traffic.run.tcl

source [ file join [ file dirname [ info script ]] .. general.proc.tcl ]

#*****************#
#**   helpers   **#
#*****************#

##
#  Procedure which outputs the MLD statistics for ByteBlower port $bbPort,
#  located on server with IP address $serverIp.
#
#  @param bbPort ByteBlower port which is configured for layer 2 and IPv6
#
#  @param serverIp IP address of the server on which the ByteBlower port is located (only used for information output)
#
#  @return none
##
proc mldstat { bbPort { serverIp 0.0.0.0 } } {

    set bbIpv6 [ $bbPort Layer3.IPv6.Get ]
    set mldProtocol [ $bbIpv6 Protocol.Mld.Get ]


	set retVal [list ]
    foreach mldSession [ $mldProtocol Session.Get ] {
    	set sessionInfo [ $mldSession Session.Info.Get ]
    	set mAddress [ $mldSession Multicast.Address.Get ]
    	

        puts "-- Statistics for multicast address $mAddress on port $bbPort on server $serverIp --"

        foreach {name value} [ list \
        	"TxMldFrames" [ $sessionInfo Tx.Get ] \
        	"TxMldv1MulticastListenerReports" [ $sessionInfo Tx.V1.Reports.Get ] \
        	"TxMldv1MulticastListenerDones" [ $sessionInfo Tx.V1.Dones.Get ] \
        	"TxMldv2MulticastListenerReports" [ $sessionInfo Tx.V2.Reports.Get ] \
			"RxMldFrames" [ $sessionInfo Rx.Get ] \
        	"RxMldv1MulticastListenerReports" [ $sessionInfo Rx.V1.Reports.Get ] \
        ] {
            puts "  $name\t: $value"
			lappend retVal [ list $name $value ]
        }
    }

    return $retVal

}

##
#  Procedure which waits for $seconds seconds
#
#  @param seconds Number of seconds to wait
#
#  @return none
##
proc wait { seconds } {

    puts -nonewline "waiting $seconds seconds... "
    update

    set ::mld_wait 0
    after [ expr $seconds * 1000 ] "set ::mld_wait 1"
    vwait ::mld_wait

    puts "done"

    return

}

proc MLD_with_traffic.Setup {} {

	#***************#
	#**   Setup   **#
	#***************#

	#- Connect to ByteBlower server
    set ::bb [ ByteBlower Instance.Get ]
	set ::server [ $::bb Server.Add $::serverIp ]

	#- Create first ByteBlower port
	set ::port1 [ $::server Port.Create $::portName1 ]

	#- Layer2 setup (ethII)
	set ::ethernet1 [ $::port1 Layer2.EthII.Set ]
	$::ethernet1 Mac.Set $::macAddress1

	#- Layer3 setup (IPv6)
	set ::ip1 [ $::port1 Layer3.IPv6.Set ]

	#- Using StatelessAutoConfiguration
	$::ip1 StatelessAutoconfiguration

	#- OR Using DHCPv6
	#[ $ip1 Protocol.Dhcp.Get ] Perform

	#- OR Using static IP
	#$ip1 Gateway.Set $ipRouter1
	#$ip1 Ip.Add $ipAddress1

	#- Create second ByteBlower port
	set ::port2 [ $::server Port.Create $::portName2 ]

	#- Layer2 setup (ethII)
	set ::ethernet2 [ $::port2 Layer2.EthII.Set ]
	$::ethernet2 Mac.Set $::macAddress2

	#- Layer3 setup (IPv6)
	set ::ip2 [ $::port2 Layer3.IPv6.Set ]

	#- Using StatelessAutoConfiguration
	$::ip2 StatelessAutoconfiguration

	#- OR Using DHCPv6
	#[ $ip2 Protocol.Dhcp.Get ] Perform

	#- OR Using static IP
	#$ip2 Ip.Add $ipAddress2
	#$ip2 Gateway.Set $ipRouter2

	#- Create third ByteBlower port (sending port)
	set ::sourcePort [ $::server Port.Create $::sourcePortName ]

	#- Layer2 setup (ethII)
	set ::sourceL2 [ $::sourcePort Layer2.EthII.Set ]
	$::sourceL2 Mac.Set $::sourceMacAddress

	#- Layer3 setup (IPv6)
	set ::sourceL3 [ $::sourcePort Layer3.IPv6.Set ]

	#- Using StatelessAutoConfiguration
	$::sourceL3 StatelessAutoconfiguration
	set ::sourcePortIpAddress [ $::sourceL3 Ip.Stateless.Get ]

	#- OR Using DHCPv6
	#[ $sourceL3 Protocol.Dhcp.Get ] Perform
	#set sourcePortIpAddress [ $sourceL3 Ip.Dhcp.Get ]

	#- OR Using static IP
	#$sourceL3 Ip.Manual.Add $sourceIpAddress
	#$sourceL3 Gateway.Set $sourceIpRouter
	#set sourcePortIpAddress [ $sourceL3 Ip.Manual.Get ]

	#- Output some information
	puts "-- Server $::serverIp --"
	puts [ $::server Description.Get ]
	puts "-- ByteBlower port [ $::port1 Interface.Name.Get ]/$::port1 on server $::serverIp --"
	puts "   Stateless IPv6 address : [ $::ip1 Ip.Stateless.Get ]"
	puts "-- ByteBlower port [ $::port2 Interface.Name.Get ]/$::port2 on server $::serverIp --"
	puts "   Stateless IPv6 address : [ $::ip2 Ip.Stateless.Get ]"
	puts "-- ByteBlower port [ $::sourcePort Interface.Name.Get ] on server $::serverIp --"
	puts "   Stateless IPv6 address : [ $::sourceL3 Ip.Stateless.Get ]"
	
	return
}

proc MLD_with_traffic.Run {} {

	#************************#
	#**   Multicast test   **#
	#************************#

	#- Setup Multicast traffic + triggers

	#- First multicast Address
	set ::sourceStream1 [ $::sourcePort Tx.Stream.Add ]
	set ::sourceFrame1 [ $::sourceStream1 Frame.Add ]
	$::sourceFrame1 Bytes.Set [ \
		::excentis::basic::Frame.Udpv6.Set \
			[ ::excentis::basic::Multicast.IPv6.To.Mac $::multicastAddress1 ] \
			[ $::sourceL2 Mac.Get ] \
			$::multicastAddress1 \
			[ lindex [ split [ $::sourceL3 Ip.Stateless.Get ] '/' ] 0 ] \
			12000 \
			12000 \
			{ -Length 256 } \
		]
	#- Sending 100 frames per second
	$::sourceStream1 InterFrameGap.Set 10ms
	#- Send traffic for 5 minutes
	$::sourceStream1 NumberOfFrames.Set 30000

	#- port 1 trigger
	set ::trigger1_1 [ $::port1 Rx.Trigger.Basic.Add ]
	$::trigger1_1 Filter.Set "ip6 dst $::multicastAddress1 and udp"

	#- port 2 trigger
	set ::trigger2_1 [ $::port2 Rx.Trigger.Basic.Add ]
	$::trigger2_1 Filter.Set "ip6 dst $::multicastAddress1 and udp"

	#- Second multicast Address
	set ::sourceStream2 [ $::sourcePort Tx.Stream.Add ]
	set ::sourceFrame2 [ $::sourceStream2 Frame.Add ]
	$::sourceFrame2 Bytes.Set [ ::excentis::basic::Frame.Udpv6.Set [ ::excentis::basic::Multicast.IPv6.To.Mac $::multicastAddress2 ]\
		[ $::sourceL2 Mac.Get ]\
		$::multicastAddress2\
		[ lindex [ split [ $::sourceL3 Ip.Stateless.Get ] '/' ] 0 ]\
		13000\
		13000\
		{ -Length 512 }\
	]
	#- Sending 50 frames per second
	$::sourceStream2 InterFrameGap.Set 20ms
	#- Send traffic for 5 minutes
	$::sourceStream2 NumberOfFrames.Set 15000

	#- port 1 trigger
	set ::trigger1_2 [ $::port1 Rx.Trigger.Basic.Add ]
	$::trigger1_2 Filter.Set "ip6 dst $::multicastAddress2 and udp"

	#- port 2 trigger
	set ::trigger2_2 [ $::port2 Rx.Trigger.Basic.Add ]
	$::trigger2_2 Filter.Set "ip6 dst $::multicastAddress2 and udp"

	#- First, we clear the trigger counters and start the multicast traffic from the source port
	$::sourceStream1 Result.Clear
	$::sourceStream2 Result.Clear
	$::trigger1_1 Result.Clear
	$::trigger1_2 Result.Clear
	$::trigger2_1 Result.Clear
	$::trigger2_2 Result.Clear

	$::sourceStream1 Start
	puts "Started sending multicast traffic for $::multicastAddress1"
	$::sourceStream2 Start
	puts "Started sending multicast traffic for $::multicastAddress2"

	#- first ByteBlower port listens to 1 multicast address,
	set ip1MldProtocol [ $::ip1 Protocol.Mld.Get ]
	set ip1MldSession1 [ $ip1MldProtocol Session.V2.Add $::multicastAddress1 ]
	$ip1MldSession1 Multicast.Listen exclude {}

	#- second ByteBlower port listens to 2 multicast addresses
	set ip2MldProtocol [ $::ip2 Protocol.Mld.Get ]
	set ip2MldSession1 [ $ip2MldProtocol Session.V2.Add $::multicastAddress2 ]
	$ip2MldSession1 Multicast.Listen exclude {}
	
	set ip2MldSession2 [ $ip2MldProtocol Session.V2.Add $::multicastAddress1 ]
	$ip2MldSession2 Multicast.Listen exclude {}

	wait 60

	#- Output statistics
	mldstat $::port1 $::serverIp
	mldstat $::port2 $::serverIp

	#- ByteBlower port 1: Change sources - EXCLUDE 4 multicast source addresses
	$ip1MldSession1 Multicast.Listen exclude [ list $::sourceIp1 $::sourceIp2 $::sourceIp3 $::sourceIp4 ]
	wait 60

	#- ByteBlower port 1: Change sources - EXCLUDE 2 multicast source addresses
	$ip1MldSession1 Multicast.Listen exclude [ list $::sourceIp1 $::sourceIp4 [ lindex [ split $::sourcePortIpAddress '/' ] 0 ] ]
	#wait 30

	#- ByteBlower port 1: Change sources - EXCLUDE 4 multicast source addresses
	$ip1MldSession1 Multicast.Listen exclude [ list $::sourceIp1 $::sourceIp2 $::sourceIp3 $::sourceIp4 ]
	#wait 30

	#- ByteBlower port 1: Change sources - INCLUDE 0 multicast source addresses => don't listen to the multicast address anymore
	$ip1MldSession1 Multicast.Listen include [ list ]
	wait 30

	#- ByteBlower port 2: Change sources - INCLUDE 0 multicast source addresses => don't listen to the multicast addresses anymore
	$ip2MldSession1 Multicast.Listen include {}
	$ip2MldSession2 Multicast.Listen include {}

	wait 1

	$::sourceStream1 Stop
	puts "Stopped sending multicast traffic to $::multicastAddress1"
	$::sourceStream2 Stop
	puts "Stopped sending multicast traffic to $::multicastAddress2"

	#- Output statistics
	mldstat $::port1 $::serverIp
	mldstat $::port2 $::serverIp

	#- Output loss counters...
	set ::sourceCounters1 [ $::sourceStream1 Result.Get ]
	set ::sourceCounters2 [ $::sourceStream2 Result.Get ]
	set ::triggerCounters1_1 [ $::trigger1_1 Result.Get ]
	set ::triggerCounters1_2 [ $::trigger1_2 Result.Get ]
	set ::triggerCounters2_1 [ $::trigger2_1 Result.Get ]
	set ::triggerCounters2_2 [ $::trigger2_2 Result.Get ]

	set ::sourceSent1 [ $::sourceCounters1 PacketCount.Get ]
	set ::sourceSent2 [ $::sourceCounters2 PacketCount.Get ]
	set ::triggerRcv1_1 [ $::triggerCounters1_1 PacketCount.Get ]
	set ::triggerRcv1_2 [ $::triggerCounters1_2 PacketCount.Get ]
	set ::triggerRcv2_1 [ $::triggerCounters2_1 PacketCount.Get ]
	set ::triggerRcv2_2 [ $::triggerCounters2_2 PacketCount.Get ]

	set retVal [ list ]
	puts "Port1 Multicast Address $::multicastAddress1 sent/received/loss : ${::sourceSent1}/${::triggerRcv1_1}/[ expr $::sourceSent1 - $::triggerRcv1_1 ]"
	lappend retVal [ list -tx $::sourceSent1 -rx $::triggerRcv1_1 ]
	
	puts "Port1 Multicast Address $::multicastAddress2 sent/received/loss : ${::sourceSent2}/${::triggerRcv1_2}/[ expr $::sourceSent2 - $::triggerRcv1_2 ]"
	lappend retVal [ list -tx $::sourceSent2 -rx $::triggerRcv1_2 ]
	
	puts "Port2 Multicast Address $::multicastAddress1 sent/received/loss : ${::sourceSent1}/${::triggerRcv2_1}/[ expr $::sourceSent1 - $::triggerRcv2_1 ]"
	lappend retVal [ list -tx $::sourceSent1 -rx $::triggerRcv2_1]
	
	puts "Port2 Multicast Address $::multicastAddress2 sent/received/loss : ${::sourceSent2}/${::triggerRcv2_2}/[ expr $::sourceSent2 - $::triggerRcv2_2 ]"
	lappend retVal [ list -tx $::sourceSent2 -rx $::triggerRcv2_2]	

	return [ list $retVal ]
}
