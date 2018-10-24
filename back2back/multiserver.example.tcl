source [ file join [ file dirname [ info script ]] .. general.proc.tcl ]

#----------------#
#   Test Setup   #
#----------------#

#- Add a Server
set bb [ ByteBlower Instance.Get ]
set server1 [ $bb Server.Add $server1Address ]
set server2 [ $bb Server.Add $server2Address ]

#- Create 2 ByteBlower Ports
set backToBackSource1 [ $server1 Port.Create $physicalPort1 ]
set backToBackDestination1 [ $server2 Port.Create $physicalPort2 ]

#- Layer2 setup
set srcL2_1 [ $backToBackSource1 Layer2.EthII.Set ]
$srcL2_1 Mac.Set $srcMacAddress1

set destL2_1 [ $backToBackDestination1 Layer2.EthII.Set ]
$destL2_1 Mac.Set $destMacAddress1



#- Layer3 setup
#-  Back-To-Back Source Layer3 setup
if { $srcPerformDhcp1 == 1 } {
    #- Using DHCP
    set srcIpConfig "dhcpv4"
} else {
    #- Using static IP
    set srcIpConfig [ list $srcIpAddress1 $srcIpGW1 $srcNetmask1 ]
}

#- Back-To-Back Destination Layer3 setup
if { $destPerformDhcp1 == 1 } {
    #- Using DHCP
    set dstIpConfig "dhcpv4"
} else {
    #- Using static IP
    set dstIpConfig [ list $destIpAddress1 $destIpGW1  $destNetmask1 ]
}

eval excentis::ByteBlower::Examples::Setup.Port.Layer3 $backToBackSource1 $srcIpConfig
eval excentis::ByteBlower::Examples::Setup.Port.Layer3 $backToBackDestination1 $dstIpConfig

#- Descriptions
puts [ $server1 Description.Get ]
puts [ $server2 Description.Get ]
puts [ $backToBackSource1 Description.Get ]
puts [ $backToBackDestination1 Description.Get ]

set srcFlow1 [ excentis::ByteBlower::Examples::Setup.Flow.IPv4.UDP $backToBackSource1 $backToBackDestination1 $ethernetLength $srcUdpPort1 $destUdpPort1 $numberOfFrames $interFrameGap]
set destFlow1 [ excentis::ByteBlower::Examples::Setup.Flow.IPv4.UDP $backToBackDestination1 $backToBackSource1 $ethernetLength $destUdpPort1 $srcUdpPort1 $numberOfFrames $interFrameGap]

#----------------#
#   Tests        #
#----------------#


#- Back-to-Back test
set backToBackResults [ ::excentis::ByteBlower::FlowLossRate [ list $srcFlow1 ] -return numbers ]
puts "backToBackResults: $backToBackResults"

#- Other Examples:
#- Uni-directional
set flowlossUnidir [ ::excentis::ByteBlower::FlowLossRate [ list $srcFlow1 ] ]
puts "flowlossUnidir: $flowlossUnidir"

set flowlossUnidirNumbers [ ::excentis::ByteBlower::FlowLossRate [ list $srcFlow1 ] -return numbers ]
puts "flowlossUnidirNumbers: $flowlossUnidirNumbers"

set flowlossBidir [ ::excentis::ByteBlower::FlowLossRate [ list $srcFlow1 $destFlow1 ] ]
puts "flowlossBidir: $flowlossBidir"

set flowlossBidirNumbers [ ::excentis::ByteBlower::FlowLossRate [ list $srcFlow1 $destFlow1 ] -return numbers ]
puts "flowlossBidirNumbers: $flowlossBidirNumbers"

#- Using the ::excentis::ByteBlower::ExecuteScenario directly:
set result1 [ ::excentis::ByteBlower::ExecuteScenario [ list $srcFlow1 ] ]
puts "result1: $result1"
set result2 [ ::excentis::ByteBlower::ExecuteScenario [ list $srcFlow1 $destFlow1 ] ]
puts "result2: $result2"

$server1 Destructor
$server2 Destructor

