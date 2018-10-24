# This tcl script contains the main script to execute a back-to-back IPv6 test.
# You will need to set the correct parameters, as done in the IPv6.conf.tcl file.
#

source [ file join [ file dirname [ info script ]] .. general.proc.tcl ]

##
# We just need to verify the current config for the IP addrresses.
##
switch -exact -- $srcAutoConfig  {
    manual {
	set srcIpConfig [ list $srcIpAddress $srcIpRouter ]
    }
    stateless {
	set srcIpConfig [ list stateless ]
    }
    dhcp {
	set srcIpConfig [ list dhcpv6 ]
    }
    default {
	error "Unknown IP configuration $srcAutoConfig"
    }
}

# -- Setup
set bb [ ByteBlower Instance.Get ]
set server [ $bb Server.Add $serverAddress ]
set srcPort [ $server Port.Create $physicalPort1 ]

set meetingpoint [ $bb MeetingPoint.Add $meetingPointAddress ]
set wirelessEndpoint [ $meetingpoint Device.Get $wirelessEndpointUUID ]

[ $srcPort Layer2.EthII.Set ] Mac.Set $srcMacAddress

set srcL3 [ eval excentis::ByteBlower::Examples::Setup.Port.Layer3 $srcPort $srcIpConfig ]

puts "ByteBlower port:"
puts [$srcPort Description.Get]
puts "Wireless Endpoint:"
puts [$wirelessEndpoint Description.Get]

# Get address
set srcIpAddress [ eval excentis::ByteBlower::Examples::Setup.Port.Layer3.Get $srcPort $srcIpConfig ]
set dstIpAddress [ eval excentis::ByteBlower::Examples::Setup.WirelessEndpoint.Layer3.Get $wirelessEndpoint "dhcpv6" ]

#- Remove prefix part from IPv6 address
set srcIpAddress [ lindex [ split $srcIpAddress '/' ] 0 ]
set dstIpAddress [ lindex [ split $dstIpAddress '/' ] 0 ]
puts "Resolving addresses."

set flowList [ list  [ excentis::ByteBlower::Examples::Setup.Flow.IPv6.UDP $srcPort $srcIpAddress $wirelessEndpoint $dstIpAddress $ethernetLength $srcUdpPort $dstUdpPort $numberOfFrames $interFrameGap ] ]
puts "Configured all flows. We will start the test now."

if { $bidir } {
    lappend flowList [ excentis::ByteBlower::Examples::Setup.Flow.IPv6.UDP $wirelessEndpoint $dstIpAddress $srcPort $srcIpAddress $ethernetLength $srcUdpPort $dstUdpPort $numberOfFrames $interFrameGap ]
}

# -- Run test
if { [ catch {
    set result [ ::excentis::ByteBlower::FlowLossRate $flowList -return numbers ]
} result ] } {
    puts stderr "Caught Exception : ${result}"
    catch { puts "Message   : [ $result Message.Get ]" } dummy
    catch { puts "Timestamp : [ $result Timestamp.Get ]" } dummy
    catch { puts "Trace :\n[ $result Trace.Get ]" } dummy

    # --- Destruct the ByteBlower Exception
    catch { $result Destructor } dummy
    set result [ list ]
}

puts "Result: $result"
$server Destructor
