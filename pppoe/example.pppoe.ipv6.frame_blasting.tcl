#!/usr/bin/tclsh
package require ByteBlower
package require ByteBlowerHL

#-------------------#
#   Configuration   #
#-------------------#

# --- ByteBlower Server address
set bbServerName "byteblower-dev-2100-2.lab.byteblower.excentis.com."

# --- Source and Destination Physical Port
set srcPhysicalPort trunk-1-1
set destPhysicalPort trunk-1-2

# --- Layer 2 Configuration
# --- Source and Destination ByteBlower Port MAC address
set srcPortMacAddress "00:ff:12:00:00:01"
set destPortMacAddress "00:ff:12:00:00:02"

# --- Layer 2.5 Configuration
# --- PPPoE Configuration
set srcPerformPppoe 1
set srcPppoeServiceName "PPPoE-source-port"
set srcPapPeerID "bb-pppoe"
set srcPapPassword "bb-pppoe"

set destPerformPppoe 1
set destPppoeServiceName "PPPoE-destination-port"
set destPapPeerID "bb-pppoe"
set destPapPassword "bb-pppoe"

# --- Layer 3 Configuration
#- Define source port Layer3 IPv6 settings
#- will we use Stateless Auto Configuration?
set srcIpv6UseStatelessAutoConfiguration 1
set destIpv6UseStatelessAutoConfiguration 1

#- will we use DHCP instead?
set srcIpv6UseDhcp 0
set destIpv6UseDhcp 0

#- Fixed IPv6 settings (used when Stateless Auto Configuration, nor DHCP is used)
set srcIpv6UseManual 0
set srcManualIpv6Address "2001:0db8:0001:0020:0000:0000:0000:0002"
set srcManualIpv6AddressPrefix "64"
set destManualIpv6UseManual 0
set destManualIpv6Address "2001:0db8:0001:0020:0000:0000:0000:0003"
set destManualIpv6AddressPrefix "64"

#- If there is a router between the source and destination ByteBlower ports, you can uncomment this line
#set srcManualIpv6Router "2001:0db8:0001:0020:0000:0000:0000:0001"
#set destManualIpv6Router "2001:0db8:0001:0020:0000:0000:0000:0001"

# --- Traffic settings

#   + Time to wait before start to send traffic (ms)
#set waitBeforeTrafficStart 0
set waitBeforeTrafficStart 250

# frame size (Bytes) (IMIX) (WITHOUT CRC)
set ethernetLength 124 ;# ByteBlower requires to set ethernet frames without CRC bytes!
# Traffic rate (pps)
set packetRate 100
# Time to run the test (seconds)
set executionTime 10

# Bi-directional traffic?
set bidirPacketRate 20

#-----------#
#   Setup   #
#-----------#

# --- Does your system support console coloring?
set systemSupportsColoring [ string equal $::tcl_platform(platform) unix ]

# --- Get Frame creation functions
package require excentis_basic

# --- Connect to the ByteBlower Server
set server [ ByteBlower Server.Add $bbServerName ]

# --- Create Source and Destination ByteBlower Port
set backToBackSource [ $server Port.Create $srcPhysicalPort ]
set backToBackDestination [ $server Port.Create $destPhysicalPort ]

if { [ catch {

# --- Source port Layer2 setup
# - Create the Layer2 Configuration Object
set srcL2 [ $backToBackSource Layer2.EthII.Set ]
# - Set the MAC address on the Layer2 Object
$srcL2 Mac.Set $srcPortMacAddress

# - idem for Destination port Layer2 setup
set destL2 [ $backToBackDestination Layer2.EthII.Set ]
$destL2 Mac.Set $destPortMacAddress

# --- Configure the Source Port Layer2.5 settings
if { $srcPerformPppoe == 1 } {
    # --- Prepare the PPPoE configuration
    set srcPppoeResult [ ::excentis::ByteBlower::PPPoE.Setup \
                            $backToBackSource $srcPppoeServiceName \
                            "pap" [ list ${srcPapPeerID} ${srcPapPassword} ] \
                            "ipv6cp" \
                       ]

    # --- Start the PPPoE Session
    set srcPppoeSessionId [ ::excentis::ByteBlower::PPPoE.Start $srcPppoeResult ]

    # --- Extract Network Control Protocol (IPCP) results
    set srcIpv6cpResults [ ::excentis::ByteBlower::PPPoE.NCP.Results.Get $srcPppoeResult ]
    set srcIpv6Address [ lindex $srcIpv6cpResults 0 ]
    set srcIpv6GW [ lindex $srcIpv6cpResults 1 ]


    # --- Show the results
    if { $systemSupportsColoring } {
        puts [ format "Interface PPPoE got Session ID \`\033\[0;33m0x%04X\033\[0m'" ${srcPppoeSessionId} ]
    } else {
        puts [ format "Interface PPPoE got Session ID \`0x%04X'" ${srcPppoeSessionId} ]
    }
    puts "Source Ipv6cp : Got Server IPv6 Address        : ${srcIpv6Address}"
    puts "Source Ipv6cp : Got Server Remote IPv6 Address : ${srcIpv6GW}"
}

# --- Configure the Destination Port Layer2.5 settings
if { $destPerformPppoe == 1 } {
    # --- Prepare the PPPoE configuration
    set destPppoeResult [ ::excentis::ByteBlower::PPPoE.Setup \
                            $backToBackDestination $destPppoeServiceName \
                            "pap" [ list ${destPapPeerID} ${destPapPassword} ] \
                            "ipv6cp" \
                        ]

    # --- Start the PPPoE Session
    set destPppoeSessionId [ ::excentis::ByteBlower::PPPoE.Start $destPppoeResult ]

    # --- Extract Network Control Protocol (IPCP) results
    set destIpv6cpResults [ ::excentis::ByteBlower::PPPoE.NCP.Results.Get $destPppoeResult ]
    set destIpv6Address [ lindex $destIpv6cpResults 0 ]
    set destIpv6GW [ lindex $destIpv6cpResults 1 ]

    # --- Show the results
    if { $systemSupportsColoring } {
        puts [ format "Destination PPPoE got Session ID \`\033\[0;33m0x%04X\033\[0m'" ${destPppoeSessionId} ]
    } else {
        puts [ format "Destination PPPoE got Session ID \`0x%04X'" ${destPppoeSessionId} ]
    }
    puts "Destination Ipv6cp : Got Client IPv6 Address        : $destIpv6Address"
    puts "Destination Ipv6cp : Got Client Remote IPv6 Address : $destIpv6GW"
}

# --- Source port Layer3 setup
# - Create the Layer3 Configuration Object
if { $srcPerformPppoe == 1 } {
    set srcL3 [ $backToBackSource Layer3.IPv6.Get ]
} else {
    set srcL3 [ $backToBackSource Layer3.IPv6.Set ]
}
if { $srcIpv6UseStatelessAutoConfiguration == 1 } {
    #- Using StatelessAutoConfiguration
    $srcL3 StatelessAutoconfiguration
    #set ::waiter 0
    #after 10000 "set ::waiter 1"
    #vwait ::waiter
    #set ipv6Address [ $srcL3 Ip.Stateless.Get ]
    puts "Waiting for valid Server Stateless auto-configuration address"
    while { [ llength [ set ipv6Address [ $srcL3 Ip.Stateless.Get ] ] ] < 1 } {
        set ::waiter 0
        after 500 "set ::waiter 1"
        vwait ::waiter
        puts -nonewline "*"; flush stdout
    }
    puts ""
    puts "Got Stateless IPv6 address {${ipv6Address}}"
} elseif { $srcIpv6UseDhcp == 1 } {
    #- Using DHCP
    #- Perform DHCPv6 on the dhcp Object
    [ $srcL3 Protocol.Dhcp.Get ] Perform
    set ipv6Address [ $srcL3 Ip.Dhcp.Get ]
} elseif { $srcIpv6UseManual } {
    #- Using static IP
    #- Set IPv6 address, Netmask and gateway on the Layer3 Object
    #$srcL3 StatelessAutoconfiguration ;# Failed fixed IPv6 address workaround
    $srcL3 Ip.Add "${srcManualIpv6Address}/${srcManualIpv6AddressPrefix}"
    if { [ info exists srcManualIpv6Router ] &&\
         ![ string equal $srcManualIpv6Router "" ] } {
        puts "tcp_scalabilty: Setting source router address: ${srcManualIpv6Router}"
        $srcL3 Gateway.Set $srcManualIpv6Router
    }
    set ipv6Address [ $srcL3 Ip.Manual.Get ]
} else { ;#$srcPerformPppoe == 1
    set ipv6Address [ $srcL3 Ip.LinkLocal.Get ]
}
#- Remove prefix part from IPv6 address
set frameSrcIpv6Address [ lindex [ split $ipv6Address '/' ] 0 ]
#set frameSrcIpv6AddressPrefix [ lindex [ split $ipv6Address '/' ] 1 ]

#- idem for Destination port Layer3 setup
if { $destPerformPppoe == 1 } {
    set destL3 [ $backToBackDestination Layer3.IPv6.Get ]
} else {
    set destL3 [ $backToBackDestination Layer3.IPv6.Set ]
}
if { $destIpv6UseStatelessAutoConfiguration == 1 } {
    #- Using StatelessAutoConfiguration
    $destL3 StatelessAutoconfiguration
    #set ::waiter 0
    #after 10000 "set ::waiter 1"
    #vwait ::waiter
    #set ipv6Address [ $destL3 Ip.Stateless.Get ]
    puts "Waiting for valid Client Stateless auto-configuration address"
    while { [ llength [ set ipv6Address [ $destL3 Ip.Stateless.Get ] ] ] < 1 } {
        set ::waiter 0
        after 500 "set ::waiter 1"
        vwait ::waiter
        puts -nonewline "*"; flush stdout
    }
    puts ""
    puts "Got Stateless IPv6 address {${ipv6Address}}"
} elseif { $destIpv6UseDhcp == 1 } {
    #- Using DHCP
    #- Perform DHCPv6 on the dhcp Object
    [ $destL3 Protocol.Dhcp.Get ] Perform
    set ipv6Address [ $destL3 Ip.Dhcp.Get ]
} elseif { $destIpv6UseManual } {
    #- Using static IP
    #- Set IPv6 address, Netmask and gateway on the Layer3 Object
    #$destL3 StatelessAutoconfiguration ;# Failed fixed IPv6 address workaround
    $destL3 Ip.Add "${destManualIpv6Address}/${destManualIpv6AddressPrefix}"
    if { [ info exists destManualIpv6Router ] &&\
         ![ string equal $destManualIpv6Router "" ] } {
        puts "tcp_scalabilty: Setting source router address: ${destManualIpv6Router}"
        $destL3 Gateway.Set $destManualIpv6Router
    }
    set ipv6Address [ $destL3 Ip.Manual.Get ]
} else { ;#$destPerformPppoe == 1
    set ipv6Address [ $destL3 Ip.LinkLocal.Get ]
}
#- Remove prefix part from IPv6 address
set frameDestIpv6Address [ lindex [ split $ipv6Address '/' ] 0 ]
#set frameDestIpv6AddressPrefix [ lindex [ split $ipv6Address '/' ] 1 ]

puts "Done creating 2 Ports on ByteBlower Server '${bbServerName}'"

# --- Setup Traffic

set srcUdpPort [ expr int(0xFFFF * rand()) & 0xFFFF ]
set destUdpPort [ expr int(0xFFFF * rand()) & 0xFFFF ]

proc createPppoeFrame { srcBBPort destBBPort frameSrcIpv6Address frameDestIpv6Address ethernetLength srcUdpPort destUdpPort } {
    #set srcL3 [ $srcBBPort Layer3.IPv6.Get ]
    #set destL3 [ $destBBPort Layer3.IPv6.Get ]
    #
    # --- Get the destination MAC addresses for our UDP frame to reach the other port ---
    #
    #- Sending a NeighborSolicitation for the destination IP of our UDP frame.
    #set dmacBackToBackSource [ $srcL3 Protocol.NeighborDiscovery $frameDestIpv6Address ]
    #puts "pppoe.ipv6.frame_blasting: using destination MAC address: ${dmacBackToBackSource}"

    #
    # --- Create UDP frames (UDP length == 82B, EthII length == 128B)
    #
    set udpDataLength [ expr $ethernetLength - 14 - 40 - 8 ] ;# - Ethernet header - IPv6 Header - UDP Header
    #- We leave the IP and ethernet settings to default.
    #set srcFrameContent [ ::excentis::basic::Frame.Udpv6.Set $dmacBackToBackSource [ $srcL2 Mac.Get ] \
    #                                      $frameDestIpv6Address $frameSrcIpv6Address \
    #                                      $destUdpPort $srcUdpPort \
    #                                      [ list -Length $udpDataLength ] \
    #                    ]
    set srcFrameContent [ ::excentis::basic::Frame.Udpv6.Set "00:00:00:00:00:00" "00:00:00:00:00:00" \
                                                             $frameDestIpv6Address $frameSrcIpv6Address \
                                                             $destUdpPort $srcUdpPort \
                                                             [ list -length $udpDataLength ] \
                        ]
    puts "pppoe.ipv6.frame_blasting: Frame length: [ llength ${srcFrameContent} ]"

    # --- Update the Layer2 and/or Layer 2.5 Header of the Frame
    return [ ::excentis::ByteBlower::LinkLayer.AutoComplete $srcFrameContent $srcBBPort ]
}

proc createStream { srcBBPort pppoeFrameContentString executionTime packetRate srcUdpPort destUdpPort } {
    # --- Calculate rate per flow
    set interFrameGap [ expr int(floor(1e6 / double($packetRate))) ] ;# us

    set frameCount [ expr int(ceil($executionTime * $packetRate)) ]

    #
    # --- Stream setup on the Back-to-Back source port
    #
    #- Create the source Stream Object
    set stream [ $srcBBPort Tx.Stream.Add ]
    #- Create a Frame Object on the Source Stream
    set srcFrame [ $stream Frame.Add ]
    #- Set the Frame Contents
    $srcFrame Bytes.Set $pppoeFrameContentString
    #- Set the frame timing on the Stream object
    $stream InterFrameGap.Set ${interFrameGap}us
    $stream NumberOfFrames.Set $frameCount

    return $stream
}

proc createTriggerFilter { srcBBPort destBBPort pppoeFrameContentString nonPppoeFrameSize srcPerformPppoe destPerformPppoe destPppoeSessionId frameSrcIpv6Address frameDestIpv6Address srcUdpPort destUdpPort } {
    set srcL3 [ $srcBBPort Layer3.IPv6.Get ]
    set destL3 [ $destBBPort Layer3.IPv6.Get ]

    # --- Update the Frame Size for the trigger!
    #set nonPppoeFrameSize [ expr [ string length $pppoeFrameContentString ] / 2 ]

    #
    # --- Trigger setup on the Back-to-Back destination port
    #
    #- Set BPF filter for the frame we will receive from the source port:
    #  filter is set on source and destination IPv6 address, source and
    #  destination UDP port and ethernet length.
    if { $destPerformPppoe == 1 } {
        # --- We use Ethernet + PPPoE header instead of Ethernet Header
        #     BPF filtering does not support PPPoE extentions on Ethernet,
        #     therefore we have to create a filter manually
        if { $srcPerformPppoe == 1 } {
            set pppoeProtocol "0x[ string range $pppoeFrameContentString 24 27 ]"
            set pppoeVersionType "0x[ string range $pppoeFrameContentString 28 29 ]"
            set pppoeCode "0x[ string range $pppoeFrameContentString 30 31 ]"
            #set srcPppoeSessionId "0x[ string range $pppoeFrameContentString 32 35 ]"
            set pppProtocol "0x[ string range $pppoeFrameContentString 40 43 ]"
            set hexSrcIpAddress1 "0x[ string range $pppoeFrameContentString 60 67 ]"
            set hexDestIpAddress1 "0x[ string range $pppoeFrameContentString 92 99 ]"
            set hexSrcIpAddress2 "0x[ string range $pppoeFrameContentString 68 75 ]"
            set hexDestIpAddress2 "0x[ string range $pppoeFrameContentString 100 107 ]"
            set hexSrcIpAddress3 "0x[ string range $pppoeFrameContentString 76 83 ]"
            set hexDestIpAddress3 "0x[ string range $pppoeFrameContentString 108 115 ]"
            set hexSrcIpAddress4 "0x[ string range $pppoeFrameContentString 84 91 ]"
            set hexDestIpAddress4 "0x[ string range $pppoeFrameContentString 116 123 ]"
        } else {
            set pppoeProtocol "0x8864"
            set pppoeVersionType "0x11"
            set pppoeCode "0x00"
            set pppProtocol "0x0057"
            set hexFrameSrcIpAddress [ ::excentis::basic::IPv6.To.Hex $frameSrcIpv6Address ]
            set hexFrameDestIpAddress [ ::excentis::basic::IPv6.To.Hex $frameDestIpv6Address ]
            set hexSrcIpAddress1 [ eval format {"0x%02x%02x%02x%02x"} [ lrange $hexFrameSrcIpAddress 0 3 ] ]
            set hexDestIpAddress1 [ eval format {"0x%02x%02x%02x%02x"} [ lrange $hexFrameDestIpAddress 0 3 ] ]
            set hexSrcIpAddress2 [ eval format {"0x%02x%02x%02x%02x"} [ lrange $hexFrameSrcIpAddress 4 7 ] ]
            set hexDestIpAddress2 [ eval format {"0x%02x%02x%02x%02x"} [ lrange $hexFrameDestIpAddress 4 7 ] ]
            set hexSrcIpAddress3 [ eval format {"0x%02x%02x%02x%02x"} [ lrange $hexFrameSrcIpAddress 8 11 ] ]
            set hexDestIpAddress3 [ eval format {"0x%02x%02x%02x%02x"} [ lrange $hexFrameDestIpAddress 8 11 ] ]
            set hexSrcIpAddress4 [ eval format {"0x%02x%02x%02x%02x"} [ lrange $hexFrameSrcIpAddress 12 15 ] ]
            set hexDestIpAddress4 [ eval format {"0x%02x%02x%02x%02x"} [ lrange $hexFrameDestIpAddress 12 15 ] ]
        }
        # Captured size is Ethernet + PPPoE Header + PPP Header (without Ethernet CRC!)
        # --- Not explicitly required that the received frame size is the same as the source frame size ( llength $pppoeFrameContentString )
        #     => Use the "untagged" source frame size + add the PPPoE header size at the destination side
        #set triggerFilter "len = [ expr ${nonPppoeFrameSize} + 6 + 2 ] \
        #                       and ether\[12:2\] = ${pppoeProtocol} and ether\[14:1\] = ${pppoeVersionType} and ether\[15:1\] = ${pppoeCode} and ether\[16:2\] = [ format "0x%04x" ${destPppoeSessionId} ] \
        #                       and ether\[20:2\] = ${pppProtocol} and ether\[34:4\] = ${hexSrcIpAddress} and ether\[38:4\] = ${hexDestIpAddress} \
        #                       and ether\[42:2\] = ${srcUdpPort} and ether\[44:2\] = ${destUdpPort}"
        set triggerFilter "len = [ expr ${nonPppoeFrameSize} + 6 + 2 ] \
                               and ether\[12:2\] = ${pppoeProtocol} and ether\[14:1\] = ${pppoeVersionType} and ether\[15:1\] = ${pppoeCode} and ether\[16:2\] = [ format "0x%04x" ${destPppoeSessionId} ] \
                               and ether\[20:2\] = ${pppProtocol} \
                               and ether\[30:4\] = ${hexSrcIpAddress1} and ether\[34:4\] = ${hexSrcIpAddress2} \
                               and ether\[38:4\] = ${hexSrcIpAddress3} and ether\[42:4\] = ${hexSrcIpAddress4} \
                               and ether\[46:4\] = ${hexDestIpAddress1} and ether\[50:4\] = ${hexDestIpAddress2} \
                               and ether\[54:4\] = ${hexDestIpAddress3} and ether\[58:4\] = ${hexDestIpAddress4} \
                               and ether\[62:2\] = ${srcUdpPort} and ether\[64:2\] = ${destUdpPort}"
    } else {
        set triggerFilter "(ip6 src $frameSrcIpv6Address) and (ip6 dst $frameDestIpv6Address) and (udp dst port ${destUdpPort}) and (udp src port ${srcUdpPort}) and (len = ${nonPppoeFrameSize})"
    }

    return $triggerFilter
}

set srcPppoeFrameContentString [ createPppoeFrame $backToBackSource $backToBackDestination $frameSrcIpv6Address $frameDestIpv6Address $ethernetLength $srcUdpPort $destUdpPort ]
set srcStream [ createStream $backToBackSource $srcPppoeFrameContentString $executionTime $packetRate $srcUdpPort $destUdpPort ]

# --- Add the source Stream
puts "Stream on '${bbServerName}' - [ $backToBackSource Interface.Name.Get ]: UDP ${srcUdpPort} -> ${destUdpPort}, ${ethernetLength} Bytes, [ $srcStream InterFrameGap.Get ] ns, [ $srcStream NumberOfFrames.Get ] packets sent."

if { [ info exists bidirPacketRate ] } {
    set destPppoeFrameContentString [ createPppoeFrame $backToBackDestination $backToBackSource $frameDestIpv6Address $frameSrcIpv6Address $ethernetLength $destUdpPort $srcUdpPort ]
    set destStream [ createStream $backToBackDestination $destPppoeFrameContentString $executionTime $bidirPacketRate $destUdpPort $srcUdpPort ]

    # --- Add the destination Stream
    puts "Stream on '${bbServerName}' - [ $backToBackDestination Interface.Name.Get ]: UDP ${destUdpPort} -> ${srcUdpPort}, ${ethernetLength} Bytes, [ $destStream InterFrameGap.Get ] ns, [ $destStream NumberOfFrames.Get ] packets sent."
}

if { $destPerformPppoe == 1 } {
    set destTriggerFilter [ createTriggerFilter $backToBackSource $backToBackDestination $srcPppoeFrameContentString $ethernetLength $srcPerformPppoe $destPerformPppoe $destPppoeSessionId $frameSrcIpv6Address $frameDestIpv6Address $srcUdpPort $destUdpPort ]
} else {
    set destTriggerFilter [ createTriggerFilter $backToBackSource $backToBackDestination $srcPppoeFrameContentString $ethernetLength $srcPerformPppoe $destPerformPppoe null $frameSrcIpv6Address $frameDestIpv6Address $srcUdpPort $destUdpPort ]
}

#- Create a basic trigger
set destTrigger [ $backToBackDestination Rx.Trigger.Basic.Add ]
$destTrigger Filter.Set ${destTriggerFilter}

if { [ info exists bidirPacketRate ] } {
    if { $srcPerformPppoe == 1 } {
        set srcTriggerFilter [ createTriggerFilter $backToBackDestination $backToBackSource $destPppoeFrameContentString $ethernetLength $destPerformPppoe $srcPerformPppoe $srcPppoeSessionId $frameDestIpv6Address $frameSrcIpv6Address $destUdpPort $srcUdpPort ]
    } else {
        set srcTriggerFilter [ createTriggerFilter $backToBackDestination $backToBackSource $destPppoeFrameContentString $ethernetLength $destPerformPppoe $srcPerformPppoe null $frameDestIpv6Address $frameSrcIpv6Address $destUdpPort $srcUdpPort ]
    }

    #- Create a basic trigger
    set srcTrigger [ $backToBackSource Rx.Trigger.Basic.Add ]
    $srcTrigger Filter.Set ${srcTriggerFilter}
}

#
# --- Get the Description of the current Setup ---
#
# (includes description of all configured streams and flows)
if { 0 } {
puts ""
puts "*** ByteBlower Server Information ***"
puts ""
puts [ $server Description.Get ]
}
puts ""
puts "*** Back-to-Back source port Setup ***"
puts ""
puts [ $backToBackSource Description.Get ]
puts ""
puts "*** Back-to-Back destination port Setup ***"
puts ""
puts [ $backToBackDestination Description.Get ]

#------------------#
#   Run the test   #
#------------------#

puts ""
puts "#-------------------#"
puts "|   Starting Test   |"
puts "#-------------------#"
puts ""

# --- Wait until the test is finished
if { $waitBeforeTrafficStart > 0 } {
    puts "Waiting ${waitBeforeTrafficStart} ms..."
    set ::waiter 0
    after $waitBeforeTrafficStart { set ::waiter 1 }
    vwait ::waiter
    puts "done"
}

# --- Clear the counters
$srcStream Result.Clear
$destTrigger Result.Clear
if { [ info exists bidirPacketRate ] } {
    $destStream Result.Clear
    $srcTrigger Result.Clear
}

# --- Start the traffic
#puts "Starting ByteBlower Port"
## --- We don't want Schedules to start
##$backToBackSource Start
##puts "Starting ByteBlower Port Stream"
#$srcStream Start
if { [ info exists bidirPacketRate ] } {
    ByteBlower Ports.Start $backToBackSource $backToBackDestination
} else {
    ByteBlower Ports.Start $backToBackSource
}
set startTime [ clock seconds ]

# --- Wait until the test is finished
set waitTime [ expr ( 1000 * $executionTime ) + 100 ] ; # Wait 100 ms extra for getting the results.
puts "Starting test at [ clock format [ clock seconds ] ] (finish in ${executionTime} seconds)"
set waiter 0
after $waitTime "set waiter 1"
vwait waiter
puts "Test finished at [ clock format [ clock seconds ] ]"

#---------------------#
#   Getting results   #
#---------------------#

# --- Stop traffic
puts "Stopping source ByteBlower Port '[ $backToBackSource Interface.Name.Get ]'"
set stopTime1 [ clock seconds ]
#$srcStream Stop
##$backToBackSource Stop
if { [ info exists bidirPacketRate ] } {
    ByteBlower Ports.Stop $backToBackSource $backToBackDestination
} else {
    ByteBlower Ports.Stop $backToBackSource
}
set stopTime2 [ clock seconds ]

set testRunTime [ expr $stopTime1 - $startTime ]
puts "Test took $testRunTime seconds"
puts "Stopping took [ expr $stopTime2 - $stopTime1 ] seconds"

# --- Getting results
puts "* Destination\t: ${bbServerName} - [ $backToBackDestination Interface.Name.Get ]"
if { $destPerformPppoe == 1 } {
    set destPppoeStatus [ ::excentis::ByteBlower::PPPoE.Status.Get ${destPppoeResult} ]
    if { $systemSupportsColoring } {
        puts "  - PPPoE Status : \033\[0;35m${destPppoeStatus}\033\[0;m"
    } else {
        puts "  - PPPoE Status : ${destPppoeStatus}"
    }
}
puts "* Source Port\t: ${bbServerName} - [ $backToBackSource Interface.Name.Get ]"
if { $srcPerformPppoe == 1 } {
    set srcPppoeStatus [ ::excentis::ByteBlower::PPPoE.Status.Get $srcPppoeResult ]
    if { $systemSupportsColoring } {
        puts "  - PPPoE Status : \033\[0;35m${srcPppoeStatus}\033\[0;m"
    } else {
        puts "  - PPPoE Status : ${srcPppoeStatus}"
    }
}

proc printResults { stream trigger ethernetLength } {
    upvar systemSupportsColoring systemSupportsColoring

    puts "  - Source Stream:"
    if { [ catch { $stream Status.Get } errorStatus ] } {
        # --- Getting Flow Error Status is not supported in this ByteBlower Server version
        set errorStatus "<UNSUPPORTED>"
    }
    puts "    + Error Status\t: ${errorStatus}"
    set confNrOfFrames [ $stream NumberOfFrames.Get ]
    puts "    + Configured NumberOfFrames\t: ${confNrOfFrames}"
    set streamResult [ $stream Result.Get ]

    # --- DEBUG
    #puts [ $streamResult Description.Get ]

    $streamResult Refresh
    set txNrOfFrames [ $streamResult PacketCount.Get ]
    if { $txNrOfFrames == $confNrOfFrames } {
        if { $systemSupportsColoring } {
            set result "\033\[0;32mpass\033\[0;m"
        } else {
            set result "pass"
        }
    } else {
        if { $systemSupportsColoring } {
            set result "\033\[0;31mFAIL\033\[0;m"
        } else {
            set result "FAIL"
        }
    }
    puts "    + PacketCount\t: ${txNrOfFrames}\t\t${result}"
    puts "  - Destination Trigger: [ $trigger Filter.Get ]"
    if { 0 } {
    foreach {name value} [ $trigger Counters.Get ] {
        if { ![ string equal -nocase $name "NrOfFrames" ] } {
            puts "    + ${name}\t: ${value}"
            if { [ string equal -nocase $name "NrOfOctets" ] } {
                set rxNrOfOctets [ expr $value / $ethernetLength * ( $ethernetLength + 4 ) ]
                set rxRate [ expr double( ${rxNrOfOctets} * 8 / ${testRunTime} ) / 1000 ]
                puts "    + Receive rate\t: ${rxNrOfOctets} Bytes in ${testRunTime} seconds ~ ${rxRate} kbps"
            }
            continue
        }
        if { $value == $txNrOfFrames } {
            if { $systemSupportsColoring } {
                set result "\033\[0;32mpass\033\[0m"
            } else {
                set result "pass"
            }
        } else {
            if { $systemSupportsColoring } {
                set result "\033\[0;31mFAIL\033\[0m"
            } else {
                set result "FAIL"
            }
        }
        puts "    + ${name}\t: ${value}\t\t${result}"
    }
    } else {
    set triggerResult [ $trigger Result.Get ]

    # --- DEBUG
    #puts [ $triggerResult Description.Get ]

    $triggerResult Refresh
    foreach name { PacketCount ByteCount Timestamp.First Timestamp.Last } {
        set "rx${name}" [ $triggerResult ${name}.Get ]
    }

    # --- Calculate some results
    set rxRunTime [ expr ( double(${rxTimestamp.Last}) - double(${rxTimestamp.First}) ) / 1e9 ] ;# [seconds]
    set rxL2ByteCount [ expr $rxByteCount / $ethernetLength * ( $ethernetLength + 4 ) ]
    set rxL2Rate [ expr double( ${rxL2ByteCount} * 8 / ${rxRunTime} ) / 1000 ]
    set rxRate [ expr double( ${rxByteCount} * 8 / ${rxRunTime} ) / 1000 ]

    # --- Process the results
    if { $rxPacketCount == $txNrOfFrames } {
        if { $systemSupportsColoring } {
            set result "\033\[0;32mpass\033\[0;m"
        } else {
            set result "pass"
        }
    } else {
        if { $systemSupportsColoring } {
            set result "\033\[0;31mFAIL\033\[0;m"
        } else {
            set result "FAIL"
        }
    }

    # --- Output the results
    puts "    + PacketCount\t: ${rxPacketCount}\t\t${result}"
    foreach name { ByteCount Timestamp.First Timestamp.Last } {
        puts "    + ${name}\t: [ set "rx${name}" ]"
    }
    #   + Rate without PPPoE header
    puts "    + Receive L2 rate\t: ${rxL2ByteCount} Bytes in ${rxRunTime} seconds ~ ${rxL2Rate} kbps"
    puts "    + Receive rate\t: ${rxByteCount} Bytes in ${rxRunTime} seconds ~ ${rxRate} kbps"
    }
}

printResults $srcStream $destTrigger $ethernetLength

if { [ info exists bidirPacketRate ] } {
    printResults $destStream $srcTrigger $ethernetLength
}

if { $systemSupportsColoring } {
    puts "* Test Started @ \033\[0;33m[ clock format $startTime ]\033\[0m"
    puts "* Test Stopped @ \033\[0;33m[ clock format $stopTime2 ]\033\[0m"
} else {
    puts "* Test Started @ [ clock format $startTime ]"
    puts "* Test Stopped @ [ clock format $stopTime2 ]"
}

# --- Clean up
# --- Termintate PPPoE
if { $srcPerformPppoe == 1 } {
    ::excentis::ByteBlower::PPPoE.Terminate $srcPppoeResult
}
if { $destPerformPppoe == 1 } {
    ::excentis::ByteBlower::PPPoE.Terminate $destPppoeResult
}

} catched ] } {
    puts stderr "\033\[0;31m$::errorInfo\033\[0;m"
    catch { puts stderr "\033\[0;31m[ $catched Message.Get ]\033\[0;m" } dummy
    catch { puts stderr "\033\[0;31m[ $catched Timestamp.Get ]\033\[0;m" } dummy
    catch { puts stderr "\033\[0;31m[ $catched Trace.Get ]\033\[0;m" } dummy

    # --- Delete the ByteBlower Ports
    $backToBackDestination Destructor
    $backToBackSource Destructor

    $server Destructor

    error $catched

} else {
    # --- Delete the ByteBlower Ports
    $backToBackDestination Destructor
    $backToBackSource Destructor

    $server Destructor

}

# --- all done
#exit 0
