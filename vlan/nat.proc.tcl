# This tcl script contains procedures to execute a VLAN back-to-back test.
# It is intended to be used in conjunction with the following scripts:
#  * general.proc.tcl

source [ file join [ file dirname [ info script ]] .. general.proc.tcl ]

proc  BackToBackSetup { } {
    # This procedure will create a server and 2 ByteBlower ports. It also configures the mac and IPv4 addresses for these ports.
    # Next, one or two UDP flows are created (depending on flowParam values) between the source and destination port.
    # Returns : list of  <serverObject publicByteBlowerPortObject privateByteBlowerPortObject flowList>

    set bb [ ByteBlower Instance.Get ]
    set server [ $bb Server.Add $::serverAddress ]
    set publicByteBlowerPort [ $server Port.Create $::publicInterface ]
    set privateByteBlowerPort [ $server Port.Create $::privateInterface ]

    [ $publicByteBlowerPort Layer2.EthII.Set ] Mac.Set  $::publicMacAddress
    [ $privateByteBlowerPort Layer2.EthII.Set ] Mac.Set  $::privateMacAddress

    if { $::publicOnVlan == 1 } {
	set publicVlanConfig [list $::publicVlanID]
	if { [info exists ::publicVlanPriority] } {
	    lappend publicVlanConfig $::publicVlanPriority
	} else {
	    lappend publicVlanConfig ""
	}
	if { [info exists ::publicVlanDropEligible] } {
	    lappend publicVlanConfig $::publicVlanDropEligible
	}
	eval excentis::ByteBlower::Examples::Setup.Port.Layer2_5.Vlan $publicByteBlowerPort $publicVlanConfig
    }
    if { $::privateOnVlan == 1 } {
	set privateVlanConfig [list $::privateVlanID]
	if { [info exists ::privateVlanPriority] } {
	    lappend privateVlanConfig $::privateVlanPriority
	} else {
	    lappend privateVlanConfig ""
	}
	if { [info exists ::privateVlanDropEligible] } {
	    lappend privateVlanConfig $::privateVlanDropEligible
	}
	eval excentis::ByteBlower::Examples::Setup.Port.Layer2_5.Vlan $privateByteBlowerPort $privateVlanConfig
    }


    if { $::publicPerformDhcp == 1 } {
	set publicIpConfig dhcpv4
    } else {
	set publicIpConfig [ list $::publicIpAddress $::publicIpGW $::publicNetmask ]
    }
    if { $::privatePerformDhcp == 1 } {
	set privateIpConfig dhcpv4
    } else {
	set privateIpConfig [ list $::privateIpAddress $::privateIpGW $::privateNetmask ]
    }

    eval excentis::ByteBlower::Examples::Setup.Port.Layer3 $publicByteBlowerPort $publicIpConfig
    eval excentis::ByteBlower::Examples::Setup.Port.Layer3 $privateByteBlowerPort $privateIpConfig

    puts "Source port:"
    puts [$publicByteBlowerPort Description.Get]
    puts "Destination port:"
    puts [$privateByteBlowerPort Description.Get]
    #- Resolve NAT device public IP address and UDP ports
    #  Note that when the destination ports are behind the SAME NAT device,
    # the publicIpAddress will be the same for both resolved NAT information!
    set natPublicInfo [ ::excentis::ByteBlower::NatDevice.IP.Get $publicByteBlowerPort $privateByteBlowerPort $::publicUdpPort $::privateUdpPort ]
    set natPublicIpAddress [ lindex $natPublicInfo 0 ]
    set natPublicUdpPort [ lindex $natPublicInfo 1 ]
    puts "Natted Port private UDP port `$::privateUdpPort' is mapped to NAT device public UDP port `$natPublicUdpPort'"
    puts "Creating flow Public -> NAT -> Private"
    set flows [list [ excentis::ByteBlower::Examples::Setup.Flow.IPv4.UDP.NAT $publicByteBlowerPort $privateByteBlowerPort $::ethernetLength  [ [ $publicByteBlowerPort Layer3.IPv4.Get ] Ip.Get ] $natPublicIpAddress $::publicUdpPort $natPublicUdpPort $::publicUdpPort $::privateUdpPort $::numberOfFrames $::interFrameGap] ]
    if { $::bidir == 1 } {
		puts "Creating flow Public <- NAT <- Private"
		lappend flows [ excentis::ByteBlower::Examples::Setup.Flow.IPv4.UDP.NAT $privateByteBlowerPort $publicByteBlowerPort $::ethernetLength  $natPublicIpAddress [ [ $publicByteBlowerPort Layer3.IPv4.Get ] Ip.Get ] $natPublicUdpPort $::publicUdpPort $::privateUdpPort $::publicUdpPort $::numberOfFrames $::interFrameGap]
    }
    return [ list $server $publicByteBlowerPort $privateByteBlowerPort $flows ]
}

