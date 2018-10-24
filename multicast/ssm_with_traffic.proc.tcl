# This tcl script contains procedures to execute a source specific multicast test with traffic.
# It is intended to be used in conjunction with the following scripts:
#  * ssm_with_traffic.conf.tcl
#  * general.proc.tcl
#  * ssm_with_traffic.proc.tcl
#  * ssm_with_traffic.example.tcl
#  * ssm_with_traffic.run.tcl

source [ file join [ file dirname [ info script ]] .. general.proc.tcl ]

#*****************#
#**   helpers   **#
#*****************#

##
#  Procedure which outputs the IGMP statistics for ByteBlower port $bbPort,
#  located on server with IP address $serverIp.
#
#  @param bbPort ByteBlower port which is configured for layer 2 and IPv4
#
#  @param serverIp IP address of the server on which the ByteBlower port is located (only used for information output)
#
#  @return none
##
proc ssmstat { bbPort { serverIp 0.0.0.0 } } {

    set bbIpv4 [ $bbPort Layer3.IPv4.Get ]
    set igmpProtocol [ $bbIpv4 Protocol.Igmp.Get ]
    set igmpProtocolInfo [ $igmpProtocol Protocol.Info.Get ]
    
    puts "-- Statistics for IGMP protocol --"
    puts [ $igmpProtocolInfo Description.Get ]
    
    set retlist  [ list ]
    
	foreach igmpSession [ $igmpProtocol Session.Get ] {
		set mAddress [ $igmpSession Multicast.Address.Get ]
		set igmpSessionInfo [ $igmpSession Session.Info.Get ]
        puts "-- Statistics for multicast address $mAddress  --"
        puts [$igmpSessionInfo Description.Get ]
        

        set ret [ list \
        	"TxIgmpFrames" [ $igmpProtocolInfo Tx.Get ] \
        	"RxIgmpFrames" [ $igmpProtocolInfo Rx.Get ] \
        ]
        
        lappend retlist $mAddress $ret

    }
	
    return $retlist
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

    set ::igmp_wait 0
    after [ expr $seconds * 1000 ] "set ::igmp_wait 1"
    vwait ::igmp_wait

    puts "done"

    return

}

proc ssm_with_traffic.Setup {args} {
	foreach {param value} $args {			
			switch -- $param {
				"-serverIp" 				{set serverIp $value}
				"-sourcePortName" 			{set sourcePortName $value}
				"-portName1" 				{set portName1 $value}				
				"-portName2" 				{set portName2 $value}				
				"-performDhcp_sourcePort" 	{set performDhcp_sourcePort $value}				
				"-performDhcp_port1" 		{set performDhcp_port1 $value}
				"-performDhcp_port2" 		{set performDhcp_port2 $value}				
				"-sourceMacAddress" 		{set sourceMacAddress $value}
				"-sourceIpAddress"			{set sourceIpAddress $value}
				"-sourceIpGateway" 			{set sourceIpGateway $value}
				"-sourceIpNetmask" 			{set sourceIpNetmask $value}
				"-macAddress1" 				{set macAddress1 $value}
				"-ipAddress1" 				{set ipAddress1 $value}				
				"-ipGateway1" 				{set ipGateway1 $value}
				"-ipNetmask1" 				{set ipNetmask1 $value}
				"-macAddress2" 				{set macAddress2 $value}
				"-ipAddress2" 				{set ipAddress2 $value}
				"-ipGateway2" 				{set ipGateway2 $value}
				"-ipNetmask2" 				{set ipNetmask2 $value}
				"-multicastAddress1"		{set multicastAddress1 $value}
				"-multicastAddress2" 		{set multicastAddress2 $value}
				"-sourceIp1" 				{set sourceIp1 $value}
				"-sourceIp2" 				{set sourceIp2 $value}
				"-sourceIp3" 				{set sourceIp3 $value}
				"-sourceIp4" 				{set sourceIp4 $value}
			}
	}

	#- Connect to ByteBlower server
	set bb [ ByteBlower Instance.Get ]
	set server [ $bb Server.Add $serverIp ]

	#- Create first ByteBlower port
	set port1 [ $server Port.Create $portName1 ]

	#- Layer2 setup (ethII)
	set ethernet1 [ $port1 Layer2.EthII.Set ]
	$ethernet1 Mac.Set $macAddress1

	#- Layer3 setup (IPv4)
	set ip1 [ $port1 Layer3.IPv4.Set ]

	if { $performDhcp_port1 == 1 } {
		#- Using DHCP	
		[ $ip1 Protocol.Dhcp.Get ] Perform
	} else {
		#- OR Using static IP
		$ip1 Ip.Set $ipAddress1
		$ip1 Gateway.Set $ipGateway1
		$ip1 Netmask.Set $ipNetmask1
	}

	#- Create second ByteBlower port
	set port2 [ $server Port.Create $portName2 ]

	#- Layer2 setup (ethII)
	set ethernet2 [ $port2 Layer2.EthII.Set ]
	$ethernet2 Mac.Set $macAddress2

	#- Layer3 setup (IPv4)
	set ip2 [ $port2 Layer3.IPv4.Set ]

	if { $performDhcp_port2 == 1 } {
		#- Using DHCP	
		[ $ip2 Protocol.Dhcp.Get ] Perform
	} else {
		#- OR Using static IP
		$ip2 Ip.Set $ipAddress2
		$ip2 Gateway.Set $ipGateway2
		$ip2 Netmask.Set $ipNetmask2
	}

	#- Create third ByteBlower port (sending port)
	set sourcePort [ $server Port.Create $sourcePortName ]

	#- Layer2 setup (ethII)
	set sourceL2 [ $sourcePort Layer2.EthII.Set ]
	$sourceL2 Mac.Set $sourceMacAddress

	#- Layer3 setup (IPv4)
	set sourceL3 [ $sourcePort Layer3.IPv4.Set ]

	if { $performDhcp_sourcePort == 1 } {
		#- Using DHCP
		[ $sourceL3 Protocol.Dhcp.Get ] Perform
	} else {
		#- OR Using static IP
		$sourceL3 Ip.Set $sourceIpAddress
		$sourceL3 Gateway.Set $sourceIpGateway
		$sourceL3 Netmask.Set $sourceIpNetmask
	}

	set sourcePortIpAddress [ $sourceL3 Ip.Get ]

	#- Output some information
	puts "-- Server $serverIp --"
	puts [ $server Description.Get ]
	puts "-- ByteBlower port $portName1 on server $serverIp --"
	puts "   IPv4 address : [ $ip1 Ip.Get ]"
	puts "-- ByteBlower port $portName2 on server $serverIp --"
	puts "   IPv4 address : [ $ip2 Ip.Get ]"
	puts "-- ByteBlower port $sourcePortName on server $serverIp --"
	puts "   IPv4 address : [ $sourceL3 Ip.Get ]"

	#************************#
	#**   Multicast test   **#
	#************************#

	#- Setup Multicast traffic + triggers

	#- First multicast Address
	set sourceStream1 [ $sourcePort Tx.Stream.Add ]
	set sourceFrame1 [ $sourceStream1 Frame.Add ]
	$sourceFrame1 Bytes.Set [ ::excentis::basic::Frame.Udp.Set [ ::excentis::basic::Multicast.IP.To.Mac $multicastAddress1 ]\
		[ $sourceL2 Mac.Get ]\
		$multicastAddress1\
		[ lindex [ split [ $sourceL3 Ip.Get ] '/' ] 0 ]\
		12000\
		12000\
		{ -Length 256 }\
	]
	#- Sending 100 frames per second
	$sourceStream1 InterFrameGap.Set 10ms
	#- Send traffic for 5 minutes
	$sourceStream1 NumberOfFrames.Set 30000

	#- port 1 trigger
	set trigger1_1 [ $port1 Rx.Trigger.Basic.Add ]
	$trigger1_1 Filter.Set "ip dst $multicastAddress1 and udp"

	#- port 2 trigger
	set trigger2_1 [ $port2 Rx.Trigger.Basic.Add ]
	$trigger2_1 Filter.Set "ip dst $multicastAddress1 and udp"

	#- Second multicast Address
	set sourceStream2 [ $sourcePort Tx.Stream.Add ]
	set sourceFrame2 [ $sourceStream2 Frame.Add ]
	$sourceFrame2 Bytes.Set [ ::excentis::basic::Frame.Udp.Set [ ::excentis::basic::Multicast.IP.To.Mac $multicastAddress2 ]\
		[ $sourceL2 Mac.Get ]\
		$multicastAddress2\
		[ lindex [ split [ $sourceL3 Ip.Get ] '/' ] 0 ]\
		13000\
		13000\
		{ -Length 512 }\
	]
	#- Sending 50 frames per second
	$sourceStream2 InterFrameGap.Set 20ms
	#- Send traffic for 5 minutes
	$sourceStream2 NumberOfFrames.Set 15000

	#- port 1 trigger
	set trigger1_2 [ $port1 Rx.Trigger.Basic.Add ]
	$trigger1_2 Filter.Set "ip dst $multicastAddress2 and udp"

	#- port 2 trigger
	set trigger2_2 [ $port2 Rx.Trigger.Basic.Add ]
	$trigger2_2 Filter.Set "ip dst $multicastAddress2 and udp"

	#- First, we clear the trigger counters and start the multicast traffic from the source port
	$sourceStream1 Result.Clear
	$sourceStream2 Result.Clear
	$trigger1_1 Result.Clear
	$trigger1_2 Result.Clear
	$trigger2_1 Result.Clear
	$trigger2_2 Result.Clear

	return [ list $server $port1 $port2 $sourcePort $sourceStream1 $sourceStream2 $ip1 $ip2 $trigger1_1 $trigger1_2 $trigger2_1 $trigger2_2]
}

	
	
proc ssm_with_traffic.Run {args} {
	foreach {param value} $args {			
			switch -- $param {
				"-port1" 				{set port1 $value}				
				"-port2" 				{set port2 $value}				
				"-serverIp" 			{set serverIp $value}								
				"-sourceStream1" 		{set sourceStream1 $value}				
				"-sourceStream2" 		{set sourceStream2 $value}								
				"-ip1" 					{set ip1 $value}
				"-ip2" 					{set ip2 $value}				
				"-multicastAddress1"	{set multicastAddress1 $value}
				"-multicastAddress2"	{set multicastAddress2 $value}				
				"-sourceIp1" 			{set sourceIp1 $value}
				"-sourceIp2" 			{set sourceIp2 $value}
				"-sourceIp3" 			{set sourceIp3 $value}
				"-sourceIp4" 			{set sourceIp4 $value}				
				"-trigger1_1"			{set trigger1_1 $value}
				"-trigger1_2"			{set trigger1_2 $value}
				"-trigger2_1"			{set trigger2_1 $value}
				"-trigger2_2"			{set trigger2_2 $value}
			}
	}	
		
	$sourceStream1 Start
	puts "Started sending multicast traffic for $multicastAddress1"
	$sourceStream2 Start
	puts "Started sending multicast traffic for $multicastAddress2"

	#- first ByteBlower port listens to 1 multicast address,
	set ip1IgmpProtocol [ $ip1 Protocol.Igmp.Get ]
	set ip1Igmpv3Session1 [ $ip1IgmpProtocol Session.V3.Add $multicastAddress1 ]
	$ip1Igmpv3Session1 Multicast.Listen exclude {}


	#- second ByteBlower port listens to 2 multicast addresses
	set ip2IgmpProtocol [ $ip2 Protocol.Igmp.Get ]
	set ip2Igmpv3Session2 [ $ip2IgmpProtocol Session.V3.Add $multicastAddress2 ]
	$ip2Igmpv3Session2 Multicast.Listen exclude {}
	
	set ip2Igmpv3Session1 [ $ip2IgmpProtocol Session.V3.Add $multicastAddress1 ]
	$ip2Igmpv3Session1 Multicast.Listen exclude {}
	
	wait 60

	#- Output statistics
	ssmstat $port1 $serverIp
	ssmstat $port2 $serverIp

	#- ByteBlower port 1: Change sources - EXCLUDE 4 multicast source addresses
	$ip1Igmpv3Session1 Multicast.Listen exclude [ list $sourceIp1 $sourceIp2 $sourceIp3 $sourceIp4 ]

	wait 60

	#- ByteBlower port 1: Change sources - EXCLUDE 2 multicast source addresses
	#$ip1 Protocol.Igmp.Multicast.Listen -address $multicastAddress1 -version 3 -multicastSourceList [ list $sourceIp1 $sourceIp4 [ lindex [ split $sourcePortIpAddress '/' ] 0 ] ] -multicastSourceFilter "exclude"

	#wait 30

	#- ByteBlower port 1: Change sources - EXCLUDE 4 multicast source addresses
	#$ip1 Protocol.Igmp.Multicast.Listen -address $multicastAddress1 -version 3 -multicastSourceList [ list $sourceIp1 $sourceIp2 $sourceIp3 $sourceIp4 ] -multicastSourceFilter "exclude"

	#wait 30

	#- ByteBlower port 1: Change sources - INCLUDE 0 multicast source addresses => don't listen to the multicast address anymore
	$ip1Igmpv3Session1 Multicast.Listen include {}
	

	wait 30

	#- ByteBlower port 2: Change sources - INCLUDE 0 multicast source addresses => don't listen to the multicast addresses anymore
	$ip2Igmpv3Session2 Multicast.Listen include {}
	$ip2Igmpv3Session1 Multicast.Listen include {}


	wait 1

	$sourceStream1 Stop
	puts "Stopped sending multicast traffic to $multicastAddress1"
	$sourceStream2 Stop
	puts "Stopped sending multicast traffic to $multicastAddress2"

	#- Output statistics
	set retVal_stats [list ]
	lappend retVal_stats [ ssmstat $port1 $serverIp ]
	lappend retVal_stats [ ssmstat $port2 $serverIp ]

	#- Output loss counters...
	set retVal_counters [list ]
	set sourceResult1 [ $sourceStream1 Result.Get ]
	$sourceResult1 Refresh
	
	set sourceResult2 [ $sourceStream2 Result.Get ]
	$sourceResult2 Refresh
	
	set triggerCounters1_1 [ $trigger1_1 Result.Get ]
	set triggerCounters1_2 [ $trigger1_2 Result.Get ]
	set triggerCounters2_1 [ $trigger2_1 Result.Get ]
	set triggerCounters2_2 [ $trigger2_2 Result.Get ]

	set sourceSent1 [ $sourceResult1 PacketCount.Get ]
	set sourceSent2 [ $sourceResult2 PacketCount.Get ]
	set triggerRcv1_1 [ $triggerCounters1_1 PacketCount.Get ]
	set triggerRcv1_2 [ $triggerCounters1_2 PacketCount.Get ]
	set triggerRcv2_1 [ $triggerCounters2_1 PacketCount.Get ]
	set triggerRcv2_2 [ $triggerCounters2_2 PacketCount.Get ]

	puts "Port1 Multicast Address $multicastAddress1 sent/received/loss : ${sourceSent1}/${triggerRcv1_1}/[ expr $sourceSent1 - $triggerRcv1_1 ]"
	puts "Port1 Multicast Address $multicastAddress2 sent/received/loss : ${sourceSent2}/${triggerRcv1_2}/[ expr $sourceSent2 - $triggerRcv1_2 ]"
	puts "Port2 Multicast Address $multicastAddress1 sent/received/loss : ${sourceSent1}/${triggerRcv2_1}/[ expr $sourceSent1 - $triggerRcv2_1 ]"
	puts "Port2 Multicast Address $multicastAddress2 sent/received/loss : ${sourceSent2}/${triggerRcv2_2}/[ expr $sourceSent2 - $triggerRcv2_2 ]"
	
	lappend retVal_counters [ list -Tx $sourceSent1 -Rx $triggerRcv1_1 ]
	lappend retVal_counters [ list -Tx $sourceSent2 -Rx $triggerRcv1_2 ]
	lappend retVal_counters [ list -Tx $sourceSent1 -Rx $triggerRcv2_1 ]
	lappend retVal_counters [ list -Tx $sourceSent2 -Rx $triggerRcv2_2 ]
	
	return 	[ list [list $retVal_stats ] [ list $retVal_counters ] ]
}
