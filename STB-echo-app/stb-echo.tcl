####
#
# STB ECHO APPLICATION
# --------------------
#
# This application tests the STB Internal EuroDOCSIS IP Access
# as defined in spec SP-STB-v1.1-I02-061025 including the new 
# specs SP-STB-v3.0-I02-120525
#
# *************************************************************
# Change the Test Configuration to meet your setup to test the
# DUT ( SETUPBOX )
#
# *************************************************************
# - Version 2.0
###

#- What would we do without the package ;-)
package require ByteBlower
#- Required ByteBlower HL packages
package require excentis_basic
package require ByteBlowerHL

#------------------------#
#   Test Configuration   #
#------------------------#

# --- ByteBlower Server address
set serverAddress byteblower-dev-1-1.lab.excentis.com

# --- Physical Ports to connect the logical ByteBlowerPort
set physicalPort trunk-1-1

# --- Layer2 Configuration
set srcMacAddress "00:FF:1C:00:00:01"

# --- Layer3 Configuration
#     - Set to 1 if you want to use DHCP
set srcPerfomDhcp 1
#     - else use static IPv4 Configuration
set srcIpAddress "10.10.0.2"
set srcNetmask "255.255.255.0"
set srcIpGw "10.10.0.1"

# --- Destination
set dstIpAddress "10.150.2.144"

# --- EchoCount
set echoCount 1

# --- EchoLength
set echoLength 50 

### -- ADVANCED SETTINGS -- ##

# --- NumberOfFrames
set numberOfFrames 10
set frameRate 1 

###                                           ### 
### - DON'T change anything below this line - ###
###                                           ###

#----------------#
#   Test Setup   #
#----------------#

# --- Frame configuration
set srcUdpPort 2001
set dstUdpPort 10001

set ethernetLength 64

#- Add a Server
set bb [ ByteBlower Instance.Get ]
set server [ $bb Server.Add $serverAddress ]

#- Create Port
set sourcePort [ $server Port.Create $physicalPort ]

#- Layer2 setup
set srcL2 [ $sourcePort Layer2.EthII.Set ]
$srcL2 Mac.Set $srcMacAddress

#- Layer3 setup
set srcL3 [ $sourcePort Layer3.IPv4.Set ]
if { $srcPerfomDhcp == 1 } {
    #- Using DHCP
    [ $srcL3 Protocol.Dhcp.Get ] Perform
} else {
    #- Using static IP
    $srcL3 Ip.Set $srcIpAddress
    $srcL3 Netmask.Set $srcNetmask
    $srcL3 Gateway.Set $srcIpGw
}

#- Get the destination MAC address to reach the STB
#set destMacAddress [ $srcL3 Protocol.Arp $dstIpAddress ]
set destMacAddress [ $srcL3 Protocol.Arp [ $srcL3 Gateway.Get ] ]


# Preparing the udpframe content
set udppayload { 0x45 0x75 }
set echolengthHEX [ format "%04x" $echoLength ]
set temp "0x"
append temp [ string range $echolengthHEX 2 3 ]
lappend udppayload $temp
set temp "0x"
append temp [ string range $echolengthHEX 0 1 ]
lappend udppayload $temp
set echocountHEX [ format "%04x" $echoCount ]
set temp "0x"
append temp [ string range $echocountHEX 2 3 ]
lappend udppayload $temp
set temp "0x"
append temp [ string range $echocountHEX 0 1 ]
lappend udppayload $temp

set padding $echoLength
lappend udppayload 0x3f 0x26
for {set x 0} {$x<$padding} {incr x} {
    lappend udppayload 0xa0
}
#- Create UDP frame
set srcFrame [ ::excentis::basic::Frame.Udp.Set $destMacAddress [ $srcL2 Mac.Get ] $dstIpAddress [ $srcL3 Ip.Get ] $dstUdpPort $srcUdpPort $udppayload ]

# Calculate interFrameGap
set interFrameGap [ expr 1000000000 / $frameRate ]

# Calculate udplength of reply
set udplen [ format "0x%04x" [ expr $echoLength + 14 ] ]
#fout !!! verwijderen
#set udplen [ format "0x%04x" [ expr $echoLength + 16 ] ]
#- udpfilter ( magicNumber:EchoLength:EchoCount:2BytesPayload )
set srcFlow [ list -tx [ list -port $sourcePort \
    -frame [ list -bytes $srcFrame ] \
    -numberofframes $numberOfFrames \
    -interframegap $interFrameGap \
] \
    -rx [ list -port $sourcePort \
    -trigger [ list -type sizedistribution -filterFormat bpf -filter "( ip src $dstIpAddress ) and ( ip dst [ $srcL3 Ip.Get ] ) and ( udp src port $dstUdpPort ) and ( udp dst port $srcUdpPort ) and ( udp\[8:2\] = 0x4575 and udp\[14:2\] = 0xc0d9)" ] \
] \
]


puts "========================================"
puts "= SET-TOP BOX ECHO APPLICATION TESTING ="
puts "=              (Excentis)         v2.0 ="
puts "========================================"

puts " Settings "
puts "----------"
puts ""
puts "IpAddress device under test: $dstIpAddress"
puts "EchoCount: $echoCount"
puts "EchoLength: $echoLength"
puts "Number of frames to send: $numberOfFrames"
puts "Framerate: $frameRate /second"
puts ""


# Sending the packet
set result [ ::excentis::ByteBlower::ExecuteScenario [ list $srcFlow ] ]
set result [ lindex $result 0 ]
set sent [ lindex [ lindex $result 1 ] 1 ]
set received [ lindex $result 3]
set totalReceived [ lindex $received 1 ]
set listReceived [ lindex $received 11 ]

# - The correct expected size according to spec SP-STB-v3.0-I02
set expectedSizeV30I02 [ expr $echoLength + 48 ]
# - The correct expected size according to spec antes SP-STB-v3.0-I02
set expectedSizePreV30I02 [ expr $echoLength + 42 ]
set totalCorrectSizeV30I02 0
set totalCorrectSizePreV30I02 0
set totalWrongSize [ list ]

foreach {size number} $listReceived {
    if { $number > 0 } {
        # Got packets of this size
        # Check if it was the correct size
        if { $size == $expectedSizeV30I02 } {
            # According to spec SP-STB-v3.0-I02
            set totalCorrectSizeV30I02 $number
        } elseif { $size == $expectedSizePreV30I02 } {
            # According to specs previously then SP-STB-v3.0-I02
            set totalCorrectSizePreV30I02 $number
        } else {
            # Wrong size !!!
            lappend totalWrongSize $size
            lappend totalWrongSize $number
        }
    }
}

puts " Results "
puts "---------"

puts ""
puts "Number of packets sent: $sent"
puts "Number of correct (*) received packets:"
puts "   - conform to SP-STB-v3.0-I02 (size=$expectedSizeV30I02): $totalCorrectSizeV30I02"
puts "   - conform to specs predating SP-STB-v3.0-I02 (size=$expectedSizePreV30I02): $totalCorrectSizePreV30I02"
puts "Number of packets received with incorrect size"
puts "  packetSize -- Amount received "
puts "................................"
foreach { size number } $totalWrongSize {
    puts "    $size     --      $number "
}
puts " "
puts " (*) for certification, the size of the "
puts "     received packets are not taken into"
puts "     account"
puts "     "
puts "========================================"
puts "                        www.excentis.com"
puts "========================================"
