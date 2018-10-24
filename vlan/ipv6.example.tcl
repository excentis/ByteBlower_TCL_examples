# This tcl script contains the main script to execute a back-to-back IPv6 test.
# You will need to set the correct parameters, as done in the IPv6.conf.tcl file.
#

source [ file join [ file dirname [ info script ]] .. general.proc.tcl ]

# -- Setup
set bb [ ByteBlower Instance.Get ]
set server [ $bb Server.Add $serverAddress ]
set srcPort [ $server Port.Create $physicalPort1 ]
set dstPort [ $server Port.Create $physicalPort2 ]

[ $srcPort Layer2.EthII.Set ] Mac.Set $srcMacAddress
[ $dstPort Layer2.EthII.Set ] Mac.Set $dstMacAddress

if { $srcOnVlan == 1 } {
    set srcVlanConfig [list $srcVlanID]
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
if { $dstOnVlan == 1 } {
    set dstVlanConfig [list $dstVlanID]
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

switch -exact -- $srcAutoConfig  {
    manual    { set srcIpConfig [ list $srcIpAddress $srcIpRouter ] }
    stateless { set srcIpConfig [ list stateless ] }
    dhcp      { set srcIpConfig [ list dhcpv6 ] }
    default   { error "Unknown IP configuration $srcAutoConfig" }
}

switch -exact -- $dstAutoConfig  {
    manual    { set dstIpConfig [ list $dstIpAddress $dstIpRouter ] }
    stateless { set dstIpConfig [ list stateless ] }
    dhcp      { set dstIpConfig [ list dhcpv6 ] }
    default   { error "Unknown IP configuration $dstAutoConfig" }
}

set srcL3 [ eval excentis::ByteBlower::Examples::Setup.Port.Layer3 $srcPort $srcIpConfig ]
set dstL3 [ eval excentis::ByteBlower::Examples::Setup.Port.Layer3 $dstPort $dstIpConfig ]

puts "Source port:"
puts [$srcPort Description.Get]
puts "Destination port:"
puts [$dstPort Description.Get]

# Get address
set srcIpAddress [ eval excentis::ByteBlower::Examples::Setup.Port.Layer3.Get $srcPort $srcIpConfig ]
set dstIpAddress [ eval excentis::ByteBlower::Examples::Setup.Port.Layer3.Get $dstPort $dstIpConfig ]
#- Remove prefix part from IPv6 address
set srcIpAddress [ lindex [ split $srcIpAddress '/' ] 0 ]
set dstIpAddress [ lindex [ split $dstIpAddress '/' ] 0 ]
puts "Resolving addresses."

set flowList [ list  [ excentis::ByteBlower::Examples::Setup.Flow.IPv6.UDP $srcPort $srcIpAddress $dstPort $dstIpAddress $ethernetLength $srcUdpPort $dstUdpPort $numberOfFrames $interFrameGap ] ]
puts "Configured all flows. We will start the test now."

# -- Run test
set result [ ::excentis::ByteBlower::FlowLossRate $flowList -return numbers ]

puts "Result: $result"
$server Destructor
