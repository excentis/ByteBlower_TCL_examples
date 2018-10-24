# This file contains procedures to create traffic according to RFC2544, appendix C
#
#

# This is a helper method to retrieve an IPv6 address from a port.
proc rfc2544.ipv6.get { port } {
    set L3v6 [ $port Layer3.IPv6.Get ]
    set addresses [ list ]
    eval lappend addresses [ $L3v6 Ip.Stateless.Get ] [ $L3v6 Ip.Dhcp.Get ] [ $L3v6 Ip.Manual.Get ]
    foreach address $addresses {
        set result [ lindex [ split $address / ] 0 ]
        if { [ string equal $result "" ] == 0 } {
            return $result
        }
    }
    return "null"
}

proc rfc2544.traffic.UDP { sourcePort destIp length {destUdpPort 7 } } {
    set frame ""
    set payload [ list ]
    # This will create a UDP frame from source to dest, with the requested length.
    if { [ llength [ $sourcePort Layer3.IPv4.Get ] ] > 0 } {
        # IPv4 case
        set destMac [ [ $sourcePort Layer3.IPv4.Get ] Protocol.Arp $destIp ]
        set udpDataLength [ expr $length - 42 ]
        for { set i 0 } { $i < $udpDataLength } { incr i } {
            lappend payload 0x[format %02X [expr $i % 256 ] ]
        }
        set frame [ ::excentis::basic::Frame.Udp.Set $destMac [ [ $sourcePort Layer2.EthII.Get ] Mac.Get ] $destIp [ [ $sourcePort Layer3.IPv4.Get ] Ip.Get ] $destUdpPort 49184 $payload ]
    } else {
        # IPv6 support
        set destMac [ [ $sourcePort Layer3.IPv6.Get ] Protocol.NeighborDiscovery $destIp ]
        set udpDataLength [ expr $length - 62 ]; # ethernetHeaderLength 14 - ip6HeaderLength 40 - udpHeaderLength 8
        for { set i 0 } { $i < $udpDataLength } { incr i } {
            lappend payload 0x[format %02X [expr $i % 256 ] ]
        }
        set frame [ ::excentis::basic::Frame.Udpv6.Set $destMac [ [ $sourcePort Layer2.EthII.Get ] Mac.Get ] $destIp [ rfc2544.ipv6.get $sourcePort ] $destUdpPort 49184 $payload ]
    }
    return $frame
}

proc rfc2544.traffic.UDP.broadcast { sourcePort length } {
    set frame ""
    # This will create a broadcast UDP frame from source with the requested length.
    # This only applies to IPv4, because IPv6 doesn't know any broadcast.
    #
    set udpDataLength [ expr $length - 42 ]
    for { set i 0 } { $i < $udpDataLength } { incr i } {
        lappend payload 0x[format %02X [expr $i % 256 ] ]
    }
    set frame [ ::excentis::basic::Frame.Udp.Set FF-FF-FF-FF-FF-FF [ [ $sourcePort Layer2.EthII.Get ] Mac.Get ] 255.255.255.255 [ [ $sourcePort Layer3.IPv4.Get ] Ip.Get ] 7 49184 $payload ]
    return $frame
}

proc rfc2544.traffic.Management { sourcePort destIp } {

    set frame ""
    # This is the SNMP Get for the sysUpTime
    set payload { 0x04 0x06 0x70 0x75 0x62 0x6c 0x69 0x63 0xa0 0x1c 0x02 0x04 0x24 0x46 0x27 0xc2 0x02 0x01 0x00 0x02 0x01 0x00 0x30 0x0e 0x30 0x0c 0x06 0x08 0x2b 0x06 0x01 0x02 0x01 0x01 0x03 0x00 0x05 0x00 };
    # This will create a UDP frame from source to dest, with the requested length.
    if { [ llength [ $sourcePort Layer3.IPv4.Get ] ] > 0 } {
        # IPv4 case
        set destMac [ [ $sourcePort Layer3.IPv4.Get ] Protocol.Arp $destIp ]
        set frame [ ::excentis::basic::Frame.Udp.Set $destMac [ [ $sourcePort Layer2.EthII.Get ] Mac.Get ] $destIp [ [ $sourcePort Layer3.IPv4.Get ] Ip.Get ] 161 49184 $payload ]
    } else {
        # IPv6 support
        set destMac [ [ $sourcePort Layer3.IPv6.Get ] Protocol.NeighborDiscovery $destIp ]
        set frame [ ::excentis::basic::Frame.Udpv6.Set $destMac [ [ $sourcePort Layer2.EthII.Get ] Mac.Get ] $destIp [ rfc2544.ipv6.get $sourcePort ] 161 49184 $payload ]
    }
    return $frame
}

proc rfc2544.traffic.RouterUpdate { sourcePort destIp { net1  192.168.2.x } { net2 192.168.3.x } { net3 192.168.4.x } { net4 192.168.5.x } { net5 192.168.6.x } { net6 192.168.6.x } } {
    # Sends a router update...
    # Rip header
    set frame ""
    set payload [ list 0x02 0x01 0x00 0x00 ]
    # Net1
    eval lappend payload 0x00 0x02 0x00 0x00 [convert.SubNetToBytes $net1 ] 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x07
    eval lappend payload 0x00 0x02 0x00 0x00 [convert.SubNetToBytes $net2 ] 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x07
    eval lappend payload 0x00 0x02 0x00 0x00 [convert.SubNetToBytes $net3 ] 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x07
    eval lappend payload 0x00 0x02 0x00 0x00 [convert.SubNetToBytes $net4 ] 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x07
    eval lappend payload 0x00 0x02 0x00 0x00 [convert.SubNetToBytes $net5 ] 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x07
    eval lappend payload 0x00 0x02 0x00 0x00 [convert.SubNetToBytes $net6 ] 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x07
    if { [ llength [ split $destIp . ] ] == 4 } {
        # IPv4 case
        set ipParts [ split $destIp '.' ]
        set destIp "[lindex $ipParts 0].[lindex $ipParts 1].[lindex $ipParts 2].255"
        set frame [ ::excentis::basic::Frame.Udp.Set ff-ff-ff-ff-ff-ff [ [ $sourcePort Layer2.EthII.Get ] Mac.Get ] $destIp [ [ $sourcePort Layer3.IPv4.Get ] Ip.Get ] 208 208 $payload ]
    }
    return $frame
}

proc convert.SubNetToBytes { subnet } {
    set intList [ split $subnet '.' ]
    set byteList [ list ]
    for { set i 0 } { $i < 3 }  { incr i } {
        lappend byteList 0x[ format %02X [ lindex $intList $i ] ]
    }
    return $byteList
}

proc rfc2544.traffic.Clean { sourcePort destPort } {
    # This will remove all the streams and triggers on the two ports.
    foreach port [ list $sourcePort $destPort ] {
        # Clear all triggers
        foreach rx [ $port Rx.Trigger.Basic.Get ] {
            $rx Desctructor
        }
        foreach rx [ $port Rx.Trigger.SizeDistribution.Get ] {
            $rx Desctructor
        }
        foreach rx [ $port Rx.OutOfSequence.Basic.Get ] {
            $rx Desctructor
        }
        foreach rx [ $port Rx.Latency.Basic.Get ] {
            $rx Desctructor
        }
        foreach rx [ $port Rx.Latency.Distribution.Get ] {
            $rx Desctructor
        }
        # Clear all streams
        foreach stream [ $port Tx.Stream.Get ] {
            $stream Destructor
        }
    }
}

# @return list of
#         - destination IP address for the frame
#         - destination UDP port for the frame
#         - source IP address for the trigger
#         - source UDP port for the trigger
#         - public IP address of the NAT gateway
#         - public UDP port of the NAT gateway
#
proc rfc2544.traffic.TranslateNATInformation { sourcePort destPort NAT srcUdpPort destUdpPort } {
    switch -- $NAT {
        0 {
            # --- nothing to resolve
            # But, we need to check if it is IPv4 or IPv6 traffic
            if { [ llength [ $sourcePort Layer3.IPv6.Get ] ] > 0 } {
                set txDestIp [  rfc2544.ipv6.get  $destPort ]
                set rxSrcIp [  rfc2544.ipv6.get  $sourcePort ]
            } else {
                set txDestIp [ [ $destPort Layer3.IPv4.Get ] Ip.Get ]
                set rxSrcIp [ [ $sourcePort Layer3.IPv4.Get ] Ip.Get ]
            }
            # (destination UDP port does not change)
            set txDestUdpPort $destUdpPort
            set rxSrcUdpPort $srcUdpPort
            set publicIp $txDestIp
            set publicUdpPort $destUdpPort
        }
        1 {
            if { [ llength [ $sourcePort Layer3.IPv6.Get ] ] > 0 } {
                error "NAT not supported for IPv6"
            }
            # --- Destination Port is behind a NAT gateway
            set natPublicIpAndPort [ ::excentis::ByteBlower::NatDevice.IP.Get $sourcePort $destPort $srcUdpPort $destUdpPort ]
            set publicIp [ lindex $natPublicIpAndPort 0 ]
            set publicUdpPort [ lindex $natPublicIpAndPort 1 ]
            # puts "NAT: public Ip Address is $publicIp, public UDP port is $publicUdpPort"
            set txDestIp $publicIp
            set txDestUdpPort $publicUdpPort
            set rxSrcIp [ [ $sourcePort Layer3.IPv4.Get ] Ip.Get ]
            set rxSrcUdpPort $srcUdpPort
        }
        2 {
            if { [ llength [ $sourcePort Layer3.IPv6.Get ] ] > 0 } {
                error "NAT not supported for IPv6"
            }
            # --- Source Port is behind a NAT gateway
            set natPublicIpAndPort [ ::excentis::ByteBlower::NatDevice.IP.Get $destPort $sourcePort $destUdpPort $srcUdpPort ]
            set publicIp [ lindex $natPublicIpAndPort 0 ]
            set publicUdpPort [ lindex $natPublicIpAndPort 1 ]
            # puts "NAT: public Ip Address is $publicIp, public UDP port is $publicUdpPort"
            set txDestIp [ [ $destPort Layer3.IPv4.Get ] Ip.Get ]
            set txDestUdpPort $destUdpPort
            set rxSrcIp $publicIp
            set rxSrcUdpPort $publicUdpPort
            # (destination UDP port does not change)
        }
        default {
            error "Invalid value for NAT type (`${NAT}'), should be 0 (NAT disabled), 1 (destination NAT) or 2 (source NAT)"
        }
    }
    return [ list $txDestIp $txDestUdpPort $rxSrcIp $rxSrcUdpPort $publicIp $publicUdpPort ]
}

proc rfc2544.traffic.Create { sourcePort destPort frameRate frameSize testTime { NAT 0 } { extraBroadcast 1 } { extraMgmt 1 } { dupIP } { extraRoutingUpdate 1 } { net1  192.168.2.x } { net2 192.168.3.x } { net3 192.168.4.x } { net4 192.168.5.x } { net5 192.168.6.x } { net6 192.168.6.x } } {
    # Will create the tx part and rx trigger filter for the test, and setup the additional traffic on
    # the ports ( broadcast, mgmt traffic and routing updates )
    #
    # SourcePort is the ByteBlower port which will send the traffic.
    # DestPort is the ByteBlowe port which should receive the traffic.
    # frameRate is the frameRate for the test traffic.
    # frameSize the size of the test frames.
    #
    # Optional:
    #  - NAT  : 0 : no nating
    #           1 : destination is behind a NAT
    #           2 : source is behind a NAT
    #
    # - extraBroadcast : Add 1% of broadcast traffic to the test traffic.
    # - extraMbmt : Add 1 snmp message per second.
    # - extraRoutingpdate : Add 1 routing update message per 30 seconds ( RIP )
    # - net{1-6} : networks for the RIP update.
    #

    # --- Step 1: Discover addresses and ports
    set natInformation [ rfc2544.traffic.TranslateNATInformation $sourcePort $destPort $NAT 49184 7 ]

    set destIp [ lindex $natInformation 0 ]
    set destUdpPort [ lindex $natInformation 1 ]

    # --- Step 2: Create the txStructure.
    set frame [ rfc2544.traffic.UDP $sourcePort $destIp $frameSize $destUdpPort ]
    set tx [ list -port $sourcePort -frame [ list -bytes $frame ] -numberofframes [expr round( $testTime * $frameRate) ] -interframegap [ expr round (1000000000 / $frameRate ) ] ]

    # --- Step 3: Create additional traffic.
    if { [expr $extraBroadcast == 1 ] } {
        if { [ llength [ $sourcePort Layer3.IPv6.Get ] ] > 0 } {
            puts "Broadcast is not supported for IPv6, skipping broadcast traffic."
        } else {
            # 1% of broadcast traffic.
            set broadcastStream [ $sourcePort Tx.Stream.Add ]
            [ $broadcastStream Frame.Add ] Bytes.Set [ rfc2544.traffic.UDP.broadcast $sourcePort $frameSize ]
            # 1% of original traffic
            $broadcastStream InterFrameGap.Set [ expr round (100000000000 / $frameRate ) ]
            $broadcastStream NumberOfFrames.Set [ expr round ( $testTime * $frameRate * 1.0 / 100 ) ]
        }
    }
    if { [ expr $extraMgmt == 1 ] } {
        set mgmtStream [ $sourcePort Tx.Stream.Add ]
        [ $mgmtStream Frame.Add ] Bytes.Set [ rfc2544.traffic.Management $sourcePort $dutIP ]
        $mgmtStream InterFrameGap.Set 1s
        $mgmtStream NumberOfFrames.Set [ expr round ( $testTime ) ]
    }
    if { [expr $extraRoutingUpdate == 1 ]} {
        if { [ llength [ $sourcePort Layer3.IPv6.Get ] ] > 0 } {
            puts "Routing update is not supported for IPv6, skipping routing update traffic."
        } else {
            set routingStream [ $sourcePort Tx.Stream.Add ]
            [ $routingStream Frame.Add ] Bytes.Set [ rfc2544.traffic.RouterUpdate $sourcePort $dutIp $net1 $net2 $net3 $net4 $net5 $net6 ]
            $mgmtStream InterFrameGap.Set 30s
            $mgmtStream NumberOfFrames.Set [ expr round ( $testTime / 30 ) ]
        }
    }

    # --- Step 4: Create the RX trigger
    proc max {x y} {expr {$x>$y? $x: $y}}
    set length [ max $frameSize 60 ]
    if { [ llength [ $sourcePort Layer3.IPv4.Get ] ] > 0 } {
        set rxFilter "(ip.src == [ lindex $natInformation 2 ]) and (ip.dst == [ [$destPort Layer3.IPv4.Get ] Ip.Get ]) and (eth.len == $length)"
    } else {
        set rxFilter "(ipv6.src == [ lindex $natInformation 2 ]) and (ipv6.dst == [ rfc2544.ipv6.get $destPort ]) and (eth.len == $length)"
    }

    return [ list $tx $rxFilter ]
}

proc rfc2544.update.tx { tx frameRate testTime} {
    regsub -all {\-numberofframes [0-9]+} $tx "-numberofframes [expr round ($testTime * $frameRate ) ]" tx
    regsub -all {\-interframegap [0-9]+} $tx "-interframegap [ expr round ( 1000000000 / $frameRate ) ]" tx
    return $tx
}

proc rfc2544.traffic.rate2speed { frameSize frameRate } {
    set result [list L2-speed [ expr ( $frameRate * ($frameSize + 4 )  / 1000.0 ) * 8 ]Kbps]
    lappend result "L1-speed" [ expr ( $frameRate * ($frameSize + 24 ) / 1000.0 ) * 8 ]Kbps
    return $result
}

