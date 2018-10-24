# This tcl script contains procedures to execute a Tcp Ack Suppression test.
# It is intended to be used in conjunction with the following scripts:
#  * tcp-ack-suppression.conf.tcl
#  * general.proc.tcl
#  * tcp-ack-suppression.proc.tcl
#  * tcp-ack-suppression.example.tcl
#  * tcp-ack-suppression.run.tcl

source [ file join [ file dirname [ info script ]] .. general.proc.tcl ]

proc TAS.Setup { } {
	 
	#- Connect to ByteBlower Server
    set bb [ ByteBlower Instance.Get ]
	set server [ $bb Server.Add $::serverIp ]

	#- Use ByteBlower ports
	set port1 [ $server Port.Create $::portName1 ]
	set port2 [ $server Port.Create $::portName2 ]
	set port3 [ $server Port.Create $::portName3 ]

	#- Layer2 setup
	set ethernet1 [ $port1 Layer2.EthII.Set ]
	set ethernet2 [ $port2 Layer2.EthII.Set ]
	set ethernet3 [ $port3 Layer2.EthII.Set ]
	$ethernet1 Mac.Set $::mac1
	$ethernet2 Mac.Set $::mac2
	$ethernet3 Mac.Set $::mac3

	#- Layer3 setup
	set ip1 [ $port1 Layer3.IPv4.Set ]
	set ip2 [ $port2 Layer3.IPv4.Set ]
	set ip3 [ $port3 Layer3.IPv4.Set ]
	
	#- Using DHCP
	if { $::performDhcpPort1 == 1 } {
		[ $ip1 Protocol.Dhcp.Get ] Perform
	} else {
		$ip1 Ip.Set $::ipAddress1
		$ip1 Gateway.Set $::ipGW1
		$ip1 Netmask.Set $::ipNetmask1
	}
	
	if { $::performDhcpPort2 == 1 } {
		[ $ip2 Protocol.Dhcp.Get ] Perform
	} else {
		$ip2 Ip.Set $::ipAddress2
		$ip2 Gateway.Set $::ipGW2
		$ip2 Netmask.Set $::ipNetmask2
	}
	
	if { $::performDhcpPort3 == 1 } {
		[ $ip3 Protocol.Dhcp.Get ] Perform
	} else {
		$ip3 Ip.Set $::ipAddress3
		$ip3 Gateway.Set $::ipGW3
		$ip3 Netmask.Set $::ipNetmask3
	}

	#- Descriptions
	puts [ $server Description.Get ]
	puts [ $port1 Description.Get ]
	puts [ $port2 Description.Get ]
	puts [ $port3 Description.Get ]

	puts [ set ip1GwMac "0x[ join [ split [ $ip1 Protocol.Arp [ $ip1 Gateway.Get ] ] ":" ] " 0x" ]" ]
	puts [ set ip2GwMac "0x[ join [ split [ $ip2 Protocol.Arp [ $ip2 Gateway.Get ] ] ":" ] " 0x" ]" ]
	puts [ set ip3GwMac "0x[ join [ split [ $ip3 Protocol.Arp [ $ip3 Gateway.Get ] ] ":" ] " 0x" ]" ]

	return [ list $server $port1 $port2 $port3 ]
}	
	
proc TAS.Run { port1 port2 port3 } {
	set resultInfoList [list ]

	puts "Test from port1 to port2 :"
	lappend resultInfoList [ ::excentis::ByteBlower::TcpAckSuppression -tx [ list -port $port1 -portNumber 3134 ] -rx [ list -port $port2 -portNumber 3246 -requestSize 10000000 ] ]
        #puts stderr $resultInfoList

	#puts "Test from port1 to port3 :"
	#lappend resultInfoList [ ::excentis::ByteBlower::TcpAckSuppression -tx [ list -port $port1 -portNumber 3134 ] -rx [ list -port $port3 -portNumber 4823 -requestSize 10000000 ] ]
        #puts stderr $resultInfoList

	puts "Test from port1 to port2 and port3 :"
	lappend resultInfoList [ ::excentis::ByteBlower::TcpAckSuppression -tx [ list -port $port1 -portNumber 4864 ] -rx [ list -port $port2 -portNumber 1864 -requestSize 10000000 ] -rx [ list -port $port3 -portNumber 1238 -requestSize 10000000 ] ]
        #puts stderr $resultInfoList

	puts "Test from port1 to port2 (2 clients) and port3 :"
	lappend resultInfoList [ ::excentis::ByteBlower::TcpAckSuppression -tx [ list -port $port1 -portNumber 4413 ] -rx [ list -port $port2 -portNumber 1438 -requestSize 10000000 ] -rx [ list -port $port2 -portNumber 1484 -requestSize 10000000 ] -rx [ list -port $port3 -portNumber 4546 -requestSize 10000000 ] ]
        #puts stderr $resultInfoList
		
	return [ list $resultInfoList ]
}
