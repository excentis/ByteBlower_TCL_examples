# This tcl script contains procedures to execute a MLD test.
# It is intended to be used in conjunction with the following scripts:
#  * mld.conf.tcl
#  * general.proc.tcl
#  * mld.proc.tcl
#  * mld.example.tcl
#  * mld.run.tcl

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

    set ::mld_wait 0
    after [ expr $seconds * 1000 ] "set ::mld_wait 1"
    vwait ::mld_wait

    puts "done"

    return

}

proc MLD.Setup {} {

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

	#- Output some information
	puts "-- Server $::serverIp --"
	puts [ $::server Description.Get ]
	puts "-- ByteBlower port [ $::port1 Interface.Name.Get ]/$::port1 on server $::serverIp --"
	puts "   Stateless IPv6 address : [ $::ip1 Ip.Stateless.Get ]"
	puts "-- ByteBlower port [ $::port2 Interface.Name.Get ]/$::port2 on server $::serverIp --"
	puts "   Stateless IPv6 address : [ $::ip2 Ip.Stateless.Get ]"

	return
}

proc MLD.Run {} {
	
	#************************#
	#**   Multicast test   **#
	#************************#
	
	#- first ByteBlower port listens to 1 multicast address,
	set ip1MldProtocol [ $::ip1 Protocol.Mld.Get ]
	set ip1MldSession1 [ $ip1MldProtocol Session.V2.Add $::multicastAddress1 ]
	$ip1MldSession1 Multicast.Listen  exclude {}



	#- second ByteBlower port listens to 2 multicast addresses
	set ip2MldProtocol [ $::ip2 Protocol.Mld.Get ]
	set ip2MldSession2 [ $ip2MldProtocol Session.V2.Add $::multicastAddress2 ]
	$ip2MldSession2 Multicast.Listen  exclude {}

	set ip2MldSession1 [ $ip2MldProtocol Session.V2.Add $::multicastAddress1 ]
	$ip2MldSession1 Multicast.Listen  exclude {}

	wait 60

	#- Output statistics
	mldstat $::port1 $::serverIp
	mldstat $::port2 $::serverIp

	#- ByteBlower port 1: Change sources - EXCLUDE 4 multicast source addresses
	$ip1MldSession1 Multicast.Listen  exclude [ list $::sourceIp1 $::sourceIp2 $::sourceIp3 $::sourceIp4 ]
	wait 60

	#- ByteBlower port 1: Change sources - EXCLUDE 2 multicast source addresses
	$ip1MldSession1 Multicast.Listen  exclude [ list $::sourceIp1 $::sourceIp4 ]
	wait 30

	#- ByteBlower port 1: Change sources - EXCLUDE 4 multicast source addresses
	$ip1MldSession1 Multicast.Listen  exclude [ list $::sourceIp1 $::sourceIp2 $::sourceIp3 $::sourceIp4 ]
	wait 30

	#- ByteBlower port 1: Change sources - INCLUDE 0 multicast source addresses => don't listen to the multicast address anymore
	$ip1MldSession1 Multicast.Listen  include {}

	wait 30

	#- ByteBlower port 2: Change sources - INCLUDE 0 multicast source addresses => don't listen to the multicast addresses anymore
	$ip2MldSession2 Multicast.Listen  include {}
	$ip2MldSession1 Multicast.Listen  include {}
	

	wait 1

	#- Output statistics
	set retVal [list ]
	lappend retVal [ mldstat $::port1 $::serverIp ]
	lappend retVal [ mldstat $::port2 $::serverIp ]
	
	return [list $retVal]
}

