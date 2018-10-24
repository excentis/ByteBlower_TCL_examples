# This tcl script contains the main script to execute a multicast test.
# Before we can execute the code, the configuration must be loaded from the config file, or
# from another source.
#
# The test will create one port which will send traffic to the multcast address, and two listeners.
# At the end of the test, the listeners will leave the multicast group.
##
source [ file join [ file dirname [ info script ]] .. general.proc.tcl ]

##
# Step 1: Initialize the three ports:
##

## 1.a Create the server
set bb [ ByteBlower Instance.Get ]
set server [ $bb Server.Add $::serverAddress ]

## 1.b Create the ports
## Source
set srcPort [ $server Port.Create $::portName1 ]
[ $srcPort Layer2.EthII.Set ] Mac.Set $::macAddress1
eval excentis::ByteBlower::Examples::Setup.Port.Layer3 $srcPort $::ipAddress1 $::defaultGw1 $::netmask1

## Destinations

set dstPort1 [ $server Port.Create $::portName2 ]
[ $dstPort1 Layer2.EthII.Set ] Mac.Set $::macAddress2
eval excentis::ByteBlower::Examples::Setup.Port.Layer3 $dstPort1 $::ipAddress2 $::defaultGw2 $::netmask2

set dstPort2 [ $server Port.Create $::portName3 ]
[ $dstPort2 Layer2.EthII.Set ] Mac.Set $::macAddress3
eval excentis::ByteBlower::Examples::Setup.Port.Layer3 $dstPort2 $::ipAddress3 $::defaultGw3 $::netmask3

##
# Step 2: Create the stream
##
set flow [ $srcPort Tx.Stream.Add ]
set frame [ $flow Frame.Add ]

# Create a frame.
# Here, we use the util provided by Excentis which will generate the correct multicast mac based on the multicast IPv4 address.
##
set destinationMac [ ::excentis::basic::Multicast.IP.To.Mac $::multicastAddress ]
set sourceMac [ [ $srcPort Layer2.EthII.Get ] Mac.Get ]
set destinationIP $::multicastAddress
set sourceIP [ [ $srcPort Layer3.IPv4.Get ] Ip.Get ]
$frame Bytes.Set [ ::excentis::basic::Frame.Udp.Set $destinationMac $sourceMac $destinationIP $sourceIP 12000 12000 { -Length 256 } ]
$flow InterFrameGap.Set $::interFrameGap[concat ms]
$flow NumberOfFrames.Set $::numberOfFrames

##
# Step 3. Join the multicast group!
# We can specify which version must be used. By default, be use IGMPv2, but a different version ( 1, 2, 3 ) can be defined.
##
foreach port [ list $dstPort1 $dstPort2 ] {
	set igmpProtocol [ [ $port Layer3.IPv4.Get ] Protocol.Igmp.Get ]
	
	# Create a new IGMPv2 session
	set igmpSession [ $igmpProtocol Session.V2.Add $::multicastAddress ]
	
	# Join to the multicast group specified on the session
	$igmpSession Join
	
	#Create a basic trigger for the multicast group
    [ $port Rx.Trigger.Basic.Add ] Filter.Set "ip dst $::multicastAddress"
}

##
# Start the traffic and wait.
##
$flow Start
set waitTime [ expr ($::interFrameGap*$::numberOfFrames)/1000 ]
puts "Sending multicast traffic for $waitTime seconds"
update
after [ expr $waitTime * 1000 ]
$flow Stop

# Wait an additional second to let the last frames arrive.
after 1000

set rxResult [ list ]
foreach port [ list $dstPort1 $dstPort2 ] {
    # The first elemement of the triggers will be the trigger we create to match the multicast address.
    # Counters.Get will return a list like this:
    # NrOfFrames 1201
    # So, we take the second element as the result.
    ##
	set trig [ lindex [ $port Rx.Trigger.Basic.Get ] 0 ]
	set trigResult [ $trig Result.Get ]
	$trigResult Refresh
    lappend rxResult [ $trigResult PacketCount.Get ]
}

# return the number of frames sent.
set result [ eval list [ lindex [ $flow Counters.Brief.Get ] 1 ] $rxResult ]

