
source [ file join [ file dirname [ info script ]] .. general.proc.tcl ]

#----------------#
#   Test Setup   #
#----------------#

#- Add a Server
set bb [ ByteBlower Instance.Get ]
set server [ $bb Server.Add $serverAddress ]

#- Create 2 ByteBlower Ports
set backToBackSource1 [ $server Port.Create $physicalPort1 ]
set backToBackDestination1 [ $server Port.Create $physicalPort2 ]

#- Layer2 setup
set srcL2_1 [ $backToBackSource1 Layer2.EthII.Set ]
$srcL2_1 Mac.Set $srcMacAddress1

set destL2_1 [ $backToBackDestination1 Layer2.EthII.Set ]
$destL2_1 Mac.Set $destMacAddress1

#- Layer3 setup
#-  Back-To-Back Source Layer3 setup
set srcL3_1 [ $backToBackSource1 Layer3.IPv4.Set ]
if { $srcPerformDhcp1 == 1 } {
    #- Using DHCP
    [ $srcL3_1 Protocol.Dhcp.Get ] Perform
} else {
    #- Using static IP
    $srcL3_1 Ip.Set $srcIpAddress1
    $srcL3_1 Netmask.Set $srcNetmask1
    $srcL3_1 Gateway.Set $srcIpGW1
}

#- Back-To-Back Destination Layer3 setup
set destL3_1 [ $backToBackDestination1 Layer3.IPv4.Set ]
if { $destPerformDhcp1 == 1 } {
    #- Using DHCP
    [ $destL3_1 Protocol.Dhcp.Get ] Perform
} else {
    #- Using static IP
    $destL3_1 Ip.Set $destIpAddress1
    $destL3_1 Netmask.Set $destNetmask1
    $destL3_1 Gateway.Set $destIpGW1
}

#- Descriptions
puts [ $server Description.Get ]
puts [ $backToBackSource1 Description.Get ]
puts [ $backToBackDestination1 Description.Get ]

#- Get the destination MAC addresses to reach the other port
set dmacBackToBackSource1 [ $srcL3_1 Protocol.Arp [ $destL3_1 Ip.Get ] ]
set dmacBackToBackDestination1 [ $destL3_1 Protocol.Arp [ $srcL3_1 Ip.Get ] ]

#- Create ICMP frames (ICMP data length == 86B, EthII length == 124B (without CRC))
set ipDataLength [ expr $ethernetLength - 34 ]
set icmpDataLength [ expr $ethernetLength - 38 ]
set icmpEchoDataLength [ expr $ethernetLength - 42 ]

# ---
# --- Below, you can find several examples for creating ICMP frames
# ---

#- Manually creating ICMP frame on top of an IP Frame (all ICMP layer bytes are 0xDD)
#set icmpProtocol 0x01
#set srcFrame1 [ ::excentis::basic::Frame.Ipv4.Set $dmacBackToBackSource1 [ $srcL2_1 Mac.Get ] [ $destL3_1 Ip.Get ] [ $srcL3_1 Ip.Get ] $icmpProtocol [ list -Length $ipDataLength ] ]
#set destFrame2 [ ::excentis::basic::Frame.Ipv4.Set $dmacBackToBackDestination1 [ $destL2_1 Mac.Get ] [ $srcL3_1 Ip.Get ] [ $destL3_1 Ip.Get ] $icmpProtocol [ list -Length $ipDataLength ] ]
#- Create an ICMP Frame with 0xDD data of the required ICMP length
#set srcFrame1 [ ::excentis::basic::Frame.Icmp.Set $dmacBackToBackSource1 [ $srcL2_1 Mac.Get ] [ $destL3_1 Ip.Get ] [ $srcL3_1 Ip.Get ] 0x08 0x00 [ list -Length $icmpDataLength ] ]
#set destFrame2 [ ::excentis::basic::Frame.Icmp.Set $dmacBackToBackDestination1 [ $destL2_1 Mac.Get ] [ $srcL3_1 Ip.Get ] [ $destL3_1 Ip.Get ] 0x08 0x00 [ list -Length $icmpDataLength ] ]

#- Create an ICMP Echo Request Frame Frame with valid ID and sequence number and filling with 0xDD data to the required ICMP length
#set srcFrame1 [ ::excentis::basic::Frame.Icmp.Echo.Set $dmacBackToBackSource1 [ $srcL2_1 Mac.Get ] [ $destL3_1 Ip.Get ] [ $srcL3_1 Ip.Get ] $icmpEchoIdentifier $icmpEchoSequenceNumber [ list -Length $icmpEchoDataLength ] ]
#set destFrame2 [ ::excentis::basic::Frame.Icmp.Echo.Set $dmacBackToBackDestination1 [ $destL2_1 Mac.Get ] [ $srcL3_1 Ip.Get ] [ $destL3_1 Ip.Get ] $icmpEchoIdentifier $icmpEchoSequenceNumber [ list -Length $icmpEchoDataLength ] ]

#- Create an ICMP Echo Reply Frame Frame with valid ID and sequence number and filling with 0xDD data to the required ICMP length
set srcFrame1 [ ::excentis::basic::Frame.Icmp.Echo.Set $dmacBackToBackSource1 [ $srcL2_1 Mac.Get ] [ $destL3_1 Ip.Get ] [ $srcL3_1 Ip.Get ] $icmpEchoIdentifier $icmpEchoSequenceNumber [ list -Length $icmpEchoDataLength ] [ list -ICMP [ list -type 0 ] ] ]
set destFrame2 [ ::excentis::basic::Frame.Icmp.Echo.Set $dmacBackToBackDestination1 [ $destL2_1 Mac.Get ] [ $srcL3_1 Ip.Get ] [ $destL3_1 Ip.Get ] $icmpEchoIdentifier $icmpEchoSequenceNumber [ list -Length $icmpEchoDataLength ] [ list -ICMP [ list -type 0 ] ] ]

# --- Define the Flow
set srcFlow1 [ list -tx [ list -port $backToBackSource1        \
    -frame [ list -bytes $srcFrame1 ]                  \
    -numberofframes $numberOfFrames \
    -interframegap $interFrameGap   \
] \
    -rx [ list -port $backToBackDestination1   \
    -trigger [ list -type basic -filter "(ip.src == [ $srcL3_1 Ip.Get ]) and (ip.dst == [ $destL3_1 Ip.Get ]) and (eth.len == $ethernetLength)" ] \
] \
]

#------------------#
#   Run the Test   #
#------------------#

if { $bidir == 0 } {
    #- Back-to-Back test
    set result [ ::excentis::ByteBlower::FlowLossRate [ list $srcFlow1 ] -return numbers ]
    puts "result: $result"
} else {
    ##- Bi-directional
    ##- define a second flow in the other direction
    set destFlow1 [ list -tx [ list -port $backToBackDestination1   \
                                    -frame [ list -bytes $destFrame2 ] \
                                    -numberofframes $numberOfFrames \
                                    -interframegap $interFrameGap   \
                             ] \
                         -rx [ list -port $backToBackSource1        \
                                    -trigger [ list -type basic -filter "(ip.src == [ $destL3_1 Ip.Get ]) and (ip.dst == [ $srcL3_1 Ip.Get ]) and (eth.len == $ethernetLength)" ] \
                             ] \
                  ]

    set result [ ::excentis::ByteBlower::FlowLossRate [ list $srcFlow1 $destFlow1 ] -return numbers ]
    puts "result: $result"

}


##- Other Examples:
##- Uni-directional
#set flowlossUnidir [ ::excentis::ByteBlower::FlowLossRate [ list $srcFlow1 ] ]
#puts "flowlossUnidir: $flowlossUnidir"
#
#set flowlossUnidirNumbers [ ::excentis::ByteBlower::FlowLossRate [ list $srcFlow1 ] -return numbers ]
#puts "flowlossUnidirNumbers: $flowlossUnidirNumbers"
#
##- Bi-directional
##- define a second flow in the other direction
#set destFlow1 [ list -tx [ list -port $backToBackDestination1   \
#                                -frame [ list -bytes $destFrame2 ] \
#                                -numberofframes $numberOfFrames \
#                                -interframegap $interFrameGap   \
#                         ] \
#                     -rx [ list -port $backToBackSource1        \
#                                -trigger [ list -type basic -filter "(ip.src == [ $destL3_1 Ip.Get ]) and (ip.dst == [ $srcL3_1 Ip.Get ]) and (eth.len == $ethernetLength)" ] \
#                         ] \
#              ]
#
#set flowlossBidir [ ::excentis::ByteBlower::FlowLossRate [ list $srcFlow1 $destFlow1 ] ]
#puts "flowlossBidir: $flowlossBidir"
#
#set flowlossBidirNumbers [ ::excentis::ByteBlower::FlowLossRate [ list $srcFlow1 $destFlow1 ] -return numbers ]
#puts "flowlossBidirNumbers: $flowlossBidirNumbers"
#
##- Using the ::excentis::ByteBlower::ExecuteScenario directly:
#set result1 [ ::excentis::ByteBlower::ExecuteScenario [ list $srcFlow1 ] ]
#puts "result1: $result1"
#set result2 [ ::excentis::ByteBlower::ExecuteScenario [ list $srcFlow1 $destFlow1 ] ]
##puts "result2: $result2"

