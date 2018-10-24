# This tcl script contains the main script to execute a back-to-back test.
# You will need to set the correct parameters, as shown in the IPv4.conf.tcl file.
#

# Group configuration parameters in parameter lists for setup

source [ file join [ file dirname [ info script ]] .. general.proc.tcl ]

if { $srcPerformDhcp == 1 } {
    set srcIpConfig dhcpv4
} else {
    set srcIpConfig [ list $srcIpAddress $srcIpGW $srcNetmask ]
}



# --- Convert a human readable duration to a duration in nanoseconds
set ifg_ns [ excentis::ByteBlower::Examples::Setup.ConvertDurationToNanoseconds $interFrameGap ]

# --- calculate the duration.  Will need it to set it on the trigger.
#     We convert it to ms because of the troubles with 32-bit TCL
set duration_ms [ expr int((double($ifg_ns) * $numberOfFrames) / 1000000) ]


set bb [ ByteBlower Instance.Get ]

# --- Connect to the ByteBlower Server
set server [ $bb Server.Add $serverAddress ]

# --- Create the ByteBlower Port
set srcPort [ $server Port.Create $physicalPort ]
[ $srcPort Layer2.EthII.Set ] Mac.Set  $srcMacAddress
eval excentis::ByteBlower::Examples::Setup.Port.Layer3 $srcPort $srcIpConfig

puts "ByteBlower port:"
puts [$srcPort Description.Get]


# --- Connect to the MeetingPoint Server
set meetingpoint [ $bb MeetingPoint.Add $meetingPointAddress ]

# --- Get the specified device
set wirelessEndpoint [ $meetingpoint Device.Get $wirelessEndpointUUID ]

puts "Wireless Endpoint:"
puts [$wirelessEndpoint Description.Get]


if { $ethernetLength > [ $srcPort MDL.Get ] } {
    puts "SourcePort: Setting MTU to $ethernetLength"
    $srcPort MDL.Set $ethernetLength
}

puts "Configuring flows..."

set portL3 [ $srcPort Layer3.IPv4.Get ]
set portIP [ $portL3 Ip.Get ]
set deviceInfo [ $wirelessEndpoint Device.Info.Get ]
set networkInfo [ $deviceInfo Network.Info.Get ]
set ipv4List [ $networkInfo IPv4.Get ]
if { [ llength $ipv4List ] < 1 } {
    error "The Wireless Endpoint with UUID '${wirelessEndpointUUID}' has no active IPv4 addresses."
}
# Selecting "first available" IPv4 address:
set wirelessEndpointIP [ lindex $ipv4List 0 ]

set dstMac [ $portL3 Resolve $wirelessEndpointIP ]
set frameDownstream [ ::excentis::basic::Frame.Udp.Set $dstMac [ [ $srcPort Layer2.EthII.Get ] Mac.Get ] \
     $wirelessEndpointIP $portIP \
    $dstUdpPort $srcUdpPort [ list -Length $ethernetLength ] \
]
set flowDownstream [ list \
    -tx [ list -port $srcPort \
        -frame [ list \
            -bytes $frameDownstream \
        ] \
        -numberofframes $numberOfFrames \
        -interframegap $interFrameGap  \
    ] \
    -rx [ list -port $wirelessEndpoint \
        -trigger [ list -type basic \
            -filterFormat "tuple" \
            -filter [ list \
                -sourceAddress $portIP \
                -udpSourcePort $srcUdpPort \
                -udpDestinationPort $dstUdpPort \
            ] \
            -duration "[ expr $duration_ms + 5000 ]ms"
        ] \
    ] \
]


set flows [list $flowDownstream ]
if { $bidir == 1 } {
    set payload [ list ]
    for { set i 0 } { $i < [ expr $ethernetLength - 42 ] } { incr i } {
        lappend payload 0xaa
    }
    set flowUpstream [ list \
        -tx [ list -port $wirelessEndpoint \
            -frame [ list \
                -payload $payload \
                -sourcePort $srcUdpPort \
                -destinationPort $dstUdpPort \
                -destinationAddress $portIP \
            ] \
            -numberofframes $numberOfFrames \
            -interframegap $interFrameGap \
        ] \
        -rx [ list -port $srcPort \
            -trigger [ list -type basic \
                -filterFormat bpf \
                -filter "(ip dst $portIP) and (udp dst port $dstUdpPort)" \
        ] ] ]
    lappend flows $flowUpstream
}
puts "Configured all flows. We will start the test now."
puts "Flow configuration: {${flows}}"

if { [ catch {
    set result [ ::excentis::ByteBlower::FlowLossRate $flows -return percentagePerFlow]
} result ] } {
    puts stderr "Caught Exception : ${result}"
    catch { puts "Message   : [ $result Message.Get ]" } dummy
    catch { puts "Timestamp : [ $result Timestamp.Get ]" } dummy
    catch { puts "Trace :\n[ $result Trace.Get ]" } dummy

    # --- Destruct the ByteBlower Exception
    catch { $result Destructor } dummy
    set result "error"
}

puts "Frame Loss: ${result}"

catch { $wirelessEndpoint Lock 0}
$wirelessEndpoint Destructor
$server Destructor
$meetingpoint Destructor

