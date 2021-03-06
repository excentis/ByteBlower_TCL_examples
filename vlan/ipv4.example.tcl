# This tcl script contains the main script to execute a back-to-back test.
# You will need to set the correct parameters, as shown in the IPv4.conf.tcl file.
#

# Group configuration parameters in parameter lists for setup

source [ file join [ file dirname [ info script ]] .. general.proc.tcl ]

set bb [ ByteBlower Instance.Get ]
set server [ $bb Server.Add $serverAddress ]
set srcPort [ $server Port.Create $physicalPort1 ]
set dstPort [ $server Port.Create $physicalPort2 ]

[ $srcPort Layer2.EthII.Set ] Mac.Set  $srcMacAddress1
[ $dstPort Layer2.EthII.Set ] Mac.Set  $dstMacAddress1

if { $srcOnVlan == 1 } {
    foreach vlanId $srcVlanID {
        set srcVlanConfig [list $vlanId ]
        if { [info exists srcVlanPriority] } {
            lappend srcVlanConfig $srcVlanPriority
        } else {
            lappend srcVlanConfig ""
        }
        if { [info exists srcVlanDropEligible] } {
            lappend srcVlanConfig $srcVlanDropEligible
        }
        eval excentis::ByteBlower::Examples::Setup.Port.Layer2_5.Vlan $srcPort $srcVlanConfig
    }
}
if { $dstOnVlan == 1 } {
    foreach vlanId $dstVlanID {
        set dstVlanConfig [list $vlanId]
        if { [info exists dstVlanPriority] } {
            lappend dstVlanConfig $dstVlanPriority
        } else {
            lappend dstVlanConfig ""
        }
        if { [info exists dstVlanDropEligible] } {
            lappend dstVlanConfig $dstVlanDropEligible
        }
        eval excentis::ByteBlower::Examples::Setup.Port.Layer2_5.Vlan $dstPort $dstVlanConfig
    }
}

if { $srcPerformDhcp1 == 1 } {
    set srcIpConfig dhcpv4
} else {
    set srcIpConfig [ list $srcIpAddress1 $srcIpGW1 $srcNetmask1 ]
}
if { $dstPerformDhcp1 == 1 } {
    set dstIpConfig dhcpv4
} else {
    set dstIpConfig [ list $dstIpAddress1 $dstIpGW1 $dstNetmask1 ]
}
eval excentis::ByteBlower::Examples::Setup.Port.Layer3 $srcPort $srcIpConfig
eval excentis::ByteBlower::Examples::Setup.Port.Layer3 $dstPort $dstIpConfig

puts "Source port:"
puts [$srcPort Description.Get]
puts "Destination port:"
puts [$dstPort Description.Get]

if { $ethernetLength > [ $srcPort MDL.Get ] } {
    puts "SourcePort: Setting MTU to $ethernetLength"
    $srcPort MDL.Set $ethernetLength
}
if { $ethernetLength > [ $dstPort MDL.Get ] } {
    puts "DestinationPort: Setting MTU to $ethernetLength"
    $dstPort MDL.Set $ethernetLength
}

puts "Resolving addresses."
set flows [list [ excentis::ByteBlower::Examples::Setup.Flow.IPv4.UDP $srcPort $dstPort $ethernetLength $srcUdpPort1 $dstUdpPort1 $numberOfFrames $interFrameGap] ]
if { $bidir == 1 } {
    lappend flows [ excentis::ByteBlower::Examples::Setup.Flow.IPv4.UDP $dstPort $srcPort $ethernetLength $srcUdpPort1 $dstUdpPort1 $numberOfFrames $interFrameGap ]
}
puts "Configured all flows. We will start the test now."

set result [ ::excentis::ByteBlower::FlowLossRate $flows -return percentagePerFlow ]
puts "Frame Loss: ${result}"


$server Destructor

