package require ByteBlower
#- Required ByteBlower HL packages
package require excentis_basic
package require ByteBlowerHL

#- Setup
#set serverAddress 10.4.5.187
#set serverAddress byteblower-1.lab.excentis.com
set serverAddress byteblower-tp-1300.lab.excentis.com
#-- Create physical ports
#set physicalPort1 trunk-1-7
#set physicalPort2 trunk-1-8
#set physicalPort3 trunk-1-9
#set physicalPort4 trunk-1-10
#set physicalPort5 trunk-1-11
set physicalPort1 trunk-1-1
set physicalPort2 trunk-1-2
set physicalPort3 trunk-1-3
set physicalPort4 trunk-1-4
set physicalPort5 trunk-1-5

set macAddress1 "00:FF:12:00:00:01"
set macAddress2 "00:FF:12:00:00:02"
set macAddress3 "00:FF:12:00:00:03"
set macAddress4 "00:FF:12:00:00:04"
set macAddress5 "00:FF:12:00:00:05"
set ipAddress1 "10.10.0.2"
set ipAddress2 "10.10.0.3"
set ipAddress3 "10.10.0.4"
set ipAddress4 "10.10.0.5"
set ipAddress5 "10.10.0.6"
set netmask1 "255.255.255.0"
set netmask2 "255.255.255.0"
set netmask3 "255.255.255.0"
set netmask4 "255.255.255.0"
set netmask5 "255.255.255.0"
set ipGW1 "10.10.0.1"
set ipGW2 "10.10.0.1"
set ipGW3 "10.10.0.1"
set ipGW4 "10.10.0.1"
set ipGW5 "10.10.0.1"
set udpPort1 1024
set udpPort2 1025
set udpPort1b 1028
set udpPort2b 1029
set udpPort3 1026
set udpPort4 1027
set ethernetLength1 128
set udpLength1 [ expr $ethernetLength1 - 46 ]
set ethernetLength2 256
set udpLength2 [ expr $ethernetLength2 - 46 ]
set ethernetLength3 78
set udpLength3 [ expr $ethernetLength3 - 46 ]
set ethernetLength4 78
set udpLength4 [ expr $ethernetLength4 - 46 ]
set numberOfFrames 2000
set interFrameGap 1ms
set multicastGroup "230.1.1.10"

#- Add a Server
set bb [ ByteBlower Instance.Get ]
set server [ $bb Server.Add $serverAddress ]

#- Create 5 ByteBlower Ports
set port1 [ $server Port.Create $physicalPort1 ]
set port2 [ $server Port.Create $physicalPort2 ]
set port3 [ $server Port.Create $physicalPort3 ]
set port4 [ $server Port.Create $physicalPort4 ]
set port5 [ $server Port.Create $physicalPort5 ]
#- Layer2 setup
set port1L2_1 [ $port1 Layer2.EthII.Set ]
set port2L2_1 [ $port2 Layer2.EthII.Set ]
set port3L2_1 [ $port3 Layer2.EthII.Set ]
set port4L2_1 [ $port4 Layer2.EthII.Set ]
set port5L2_1 [ $port5 Layer2.EthII.Set ]
$port1L2_1 Mac.Set $macAddress1
$port2L2_1 Mac.Set $macAddress2
$port3L2_1 Mac.Set $macAddress3
$port4L2_1 Mac.Set $macAddress4
$port5L2_1 Mac.Set $macAddress5
#- Layer3 setup
set port1L3_1 [ $port1 Layer3.IPv4.Set ]
set port2L3_1 [ $port2 Layer3.IPv4.Set ]
set port3L3_1 [ $port3 Layer3.IPv4.Set ]
set port4L3_1 [ $port4 Layer3.IPv4.Set ]
set port5L3_1 [ $port5 Layer3.IPv4.Set ]
#- Using static IP
$port1L3_1 Ip.Set $ipAddress1
$port1L3_1 Netmask.Set $netmask1
$port1L3_1 Gateway.Set $ipGW1
$port2L3_1 Ip.Set $ipAddress2
$port2L3_1 Netmask.Set $netmask2
$port2L3_1 Gateway.Set $ipGW2
$port3L3_1 Ip.Set $ipAddress3
$port3L3_1 Netmask.Set $netmask3
$port3L3_1 Gateway.Set $ipGW3
$port4L3_1 Ip.Set $ipAddress4
$port4L3_1 Netmask.Set $netmask4
$port4L3_1 Gateway.Set $ipGW4
$port5L3_1 Ip.Set $ipAddress5
$port5L3_1 Netmask.Set $netmask5
$port5L3_1 Gateway.Set $ipGW5

# Create the (UDP) scouting frame, leaving the IP and ethernet settings to default
set scoutingFramePayload "BYTEBLOWER SCOUTING FRAME"
if { [ binary scan $scoutingFramePayload H* scoutingFramePayloadHex ] != 1 } {
    error "UDP flow setup error: Unable to generate ByteBlower scouting frame payload."
}
set scoutingFramePayloadData [ ::excentis::basic::String.To.Hex $scoutingFramePayloadHex ]
set scoutingFrame [ ::excentis::basic::Frame.Udp.Set $dmacPort1 [ $port1L2_1 Mac.Get ] [ $port2L3_1 Ip.Get ] [ $port1L3_1 Ip.Get ] $udpPort1 $udpPort1 $scoutingFramePayloadData ]

#- Create UDP frames (UDP length == 82B, EthII length == 128B) for unicast, broadcast, average latency, and latency distribution flows
#Get the destination MAC addresses to reach the other port
#All traffic will be sent from port1 to port2
set dmacPort1 [ $port1L3_1 Protocol.Arp [ $port2L3_1 Ip.Get ] ]

# leave the IP and ethernet settings to default
set frame1 [ ::excentis::basic::Frame.Udp.Set $dmacPort1 [ $port1L2_1 Mac.Get ] [ $port2L3_1 Ip.Get ] [ $port1L3_1 Ip.Get ] $udpPort1 $udpPort1 [ list -Length $udpLength1 ] ]
set frame2 [ ::excentis::basic::Frame.Udp.Set $dmacPort1 [ $port1L2_1 Mac.Get ] [ $port2L3_1 Ip.Get ] [ $port1L3_1 Ip.Get ] $udpPort2 $udpPort2 [ list -Length $udpLength2 ] ]
set frame1b [ ::excentis::basic::Frame.Udp.Set "FF:FF:FF:FF:FF:FF" [ $port1L2_1 Mac.Get ] "255.255.255.255" [ $port1L3_1 Ip.Get ] $udpPort1b $udpPort1b [ list -Length $udpLength1 ] ]
set frame2b [ ::excentis::basic::Frame.Udp.Set "FF:FF:FF:FF:FF:FF" [ $port1L2_1 Mac.Get ] "255.255.255.255" [ $port1L3_1 Ip.Get ] $udpPort2b $udpPort2b [ list -Length $udpLength2 ] ]
set frame3 [ ::excentis::basic::Frame.Udp.Set $dmacPort1 [ $port1L2_1 Mac.Get ] [ $port2L3_1 Ip.Get ] [ $port1L3_1 Ip.Get ] $udpPort3 $udpPort3 [ list -Length $udpLength3 ] ]
set frame4 [ ::excentis::basic::Frame.Udp.Set $dmacPort1 [ $port1L2_1 Mac.Get ] [ $port2L3_1 Ip.Get ] [ $port1L3_1 Ip.Get ] $udpPort4 $udpPort4 [ list -Length $udpLength4 ] ]

#-Create flows
set unicastFlow [ list -tx [ list -port $port1 \
    -scoutingframe [ list -bytes $scoutingFrame ] \
    -frame [ list -bytes $frame1 ] \
    -frame [ list -bytes $frame2 ] \
    -numberofframes $numberOfFrames \
    -interframegap $interFrameGap \
] \
    -rx [ list -port $port2   \
    -trigger [ list -type basic -filter "(ip.src == [ $port1L3_1 Ip.Get ]) and (ip.dst == [ $port2L3_1 Ip.Get ]) and ((udp.srcport == $udpPort1) or (udp.srcport == $udpPort2))" ] \
] \
    -rx [ list -port $port5   \
    -trigger [ list -type basic -filter "(ip.src == [ $port1L3_1 Ip.Get ]) and (ip.dst == [ $port2L3_1 Ip.Get ]) and ((udp.srcport == $udpPort1) or (udp.srcport == $udpPort2))" ] \
] \
]

set broadcastFlow [ list -tx [ list -port $port \
    -frame [ list -bytes $frame1b ]	\
    -frame [ list -bytes $frame2b ]	\
    -numberofframes $numberOfFrames \
    -interframegap $interFrameGap   \
] \
    -rx [ list -port $port1   \
    -trigger [ list -type basic -filter "(ip.src == [ $port1L3_1 Ip.Get ]) and (ip.dst == 255.255.255.255) and ((udp.srcport == $udpPort1b) or (udp.srcport == $udpPort2b))" ] \
] \
    -rx [ list -port $port2   \
    -trigger [ list -type basic -filter "(ip.src == [ $port1L3_1 Ip.Get ]) and (ip.dst == 255.255.255.255) and ((udp.srcport == $udpPort1b) or (udp.srcport == $udpPort2b))" ] \
] \
    -rx [ list -port $port3   \
    -trigger [ list -type basic -filter "(ip.src == [ $port1L3_1 Ip.Get ]) and (ip.dst == 255.255.255.255) and ((udp.srcport == $udpPort1b) or (udp.srcport == $udpPort2b))" ] \
] \
    -rx [ list -port $port4   \
    -trigger [ list -type basic -filter "(ip.src == [ $port1L3_1 Ip.Get ]) and (ip.dst == 255.255.255.255) and ((udp.srcport == $udpPort1b) or (udp.srcport == $udpPort2b))" ] \
] \
    -rx [ list -port $port5   \
    -trigger [ list -type basic -filter "(ip.src == [ $port1L3_1 Ip.Get ]) and (ip.dst == 255.255.255.255) and ((udp.srcport == $udpPort1b) or (udp.srcport == $udpPort2b))" ] \
] \
]

set averageLatencyFlow [ list -tx [ list -port $port1	\
    -scoutingframe [ list -bytes $scoutingFrame ] \
    -frame [ list -bytes $frame3 ]	\
    -numberofframes $numberOfFrames	\
    -interframegap $interFrameGap	\
    -latency 1 \
]	\
    -rx [ list -port $port2	\
    -latency [ list -type basic -filter "(ip.src == [ $port1L3_1 Ip.Get ]) and (ip.dst == [ $port2L3_1 Ip.Get ]) and (udp.srcport == $udpPort3)"	\
] 	\
]	\
]

set latencyDistributionFlow [ list -tx [ list -port $port1	\
    -scoutingframe [ list -bytes $scoutingFrame ] \
    -frame [ list -bytes $frame4 ]	\
    -numberofframes $numberOfFrames	\
    -interframegap $interFrameGap	\
    -latency 1 \
]	\
    -rx [ list -port $port2	\
    -latency [ list -type distribution -filter "(ip.src == [ $port1L3_1 Ip.Get ]) and (ip.dst == [ $port2L3_1 Ip.Get ]) and (udp.srcport == $udpPort4)"	\
] 	\
]	\
]

#-Configure multicast flow
#First compose multicast mac address from multicast ip address
set ipList [ ::excentis::basic::IP.To.Hex $multicastGroup ]
set macByte4 [ format "%02X" [ expr [ lindex $ipList 1 ] & 0x7F ] ]
set macByte5 [ format "%02X" [lindex $ipList 2] ]
set macByte6 [ format "%02X" [lindex $ipList 3] ]
set multicastMac [ string toupper "01:00:5E:$macByte4:$macByte5:$macByte6" ]

set multicastFrame [ ::excentis::basic::Frame.Udp.Set $multicastMac [$port1L2_1 Mac.Get] $multicastGroup [ $port1L3_1 Ip.Get ] 12000 12000 { -Length 256 } ]

set multicastFlow [	list -tx [ list -port $port1	\
    -scoutingframe [ list -bytes $scoutingFrame ] \
    -frame [ list -bytes $multicastFrame ]	\
    -numberofframes $numberOfFrames	\
    -interframegap $interFrameGap	\
]	\
    -rx [ list -port $port2	\
    -trigger [ list	-type basic -filter "(ip.src == [ $port1L3_1 Ip.Get ]) and (ip.dst == $multicastGroup)"]	\
]		\
    -rx [ list -port $port3	\
    -trigger [ list	-type basic -filter "(ip.src == [ $port1L3_1 Ip.Get ]) and (ip.dst == $multicastGroup)"]	\
]		\
    -rx [ list -port $port4	\
    -trigger [ list	-type basic -filter "(ip.src == [ $port1L3_1 Ip.Get ]) and (ip.dst == $multicastGroup)"]	\
]		\
    -rx [ list -port $port5	\
    -trigger [ list	-type basic -filter "(ip.src == [ $port1L3_1 Ip.Get ]) and (ip.dst == $multicastGroup)"]	\
]		\
]

#-join multicast group
set version 1
set port2_igmp [ $port2L3_1 Protocol.Igmp.Get ]
set port2_igmpsession [ $port2_igmp Session.V$version.Add $multicastGroup ]
$port2_igmpsession Join

set port3_igmp [ $port3L3_1 Protocol.Igmp.Get ]
set port3_igmpsession [ $port3_igmp Session.V$version.Add $multicastGroup ]
$port3_igmpsession Join

set port4_igmp [ $port4L3_1 Protocol.Igmp.Get ]
set port4_igmpsession [ $port4_igmp Session.V$version.Add $multicastGroup ]
$port4_igmpsession Join


#- Descriptions
puts [ $server Description.Get ]
puts [ $port1 Description.Get ]
puts [ $port2 Description.Get ]
puts [ $port3 Description.Get ]
puts [ $port4 Description.Get ]
puts [ $port5 Description.Get ]

#-send unicast, broadcast, multicast, and latency flows
set results [ ::excentis::ByteBlower::ExecuteScenario [ list $unicastFlow $broadcastFlow $multicastFlow $averageLatencyFlow $latencyDistributionFlow ] ]
puts ""
puts "results: $results"

#-leave multicast group
$port2_igmpsession Leave
$port3_igmpsession Leave
$port4_igmpsession Leave

