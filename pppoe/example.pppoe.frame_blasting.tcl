#!/usr/bin/tclsh
package require ByteBlower
package require excentis_basic
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
set srcInitialTimeToWait 500 ;# ms
#set srcPppoeServiceName "ByteBlower-testing"
set srcPppoeServiceName "PPPoE-source-port"
set srcPapPeerID "bb-pppoe"
set srcPapPassword "bb-pppoe"

set destPerformPppoe 1
#set destPppoeServiceName "ByteBlower-testing"
set destInitialTimeToWait 2000 ;# ms
set destPppoeServiceName "PPPoE-destination-port"
set destPapPeerID "bb-pppoe"
set destPapPassword "bb-pppoe"

# --- Layer 3 Configuration
set srcPortIpv4Address 10.147.10.61
set srcPortNetmask 255.255.255.0
set srcPortIpv4GW 10.147.10.1

set destPortIpv4Address 10.147.10.62
set destPortNetmask 255.255.255.0
set destPortIpv4GW 10.147.10.1

# --- Traffic settings

# --- Configure timing

#  + Time to wait before start to send traffic (ms)
#set waitBeforeTrafficStart 0
set waitBeforeTrafficStart 250

# frame size (Bytes) (IMIX) (WITHOUT CRC)
set frameSize 60
# Traffic rate (pps)
set packetRate 100
# Time to run the test (seconds)
set executionTime 10

# Bi-directional traffic?
set bidirPacketRate 20

# --- Testing
# frame size (Bytes) (IMIX) (WITHOUT CRC)
#set frameSize 1500
# Traffic rate (pps)
#set packetRate 100
# Time to run the test (seconds)
#set executionTime 160


#-----------#
#   Setup   #
#-----------#

# --- Does your system support console coloring?
set systemSupportsColoring [ string equal $::tcl_platform(platform) unix ]

# --- Connect to the ByteBlower Server
set bbServer [ ByteBlower Server.Add $bbServerName ]

# --- Create Source and Destination ByteBlower Port
set srcBBPort [ $bbServer Port.Create $srcPhysicalPort ]
set destBBPort [ $bbServer Port.Create $destPhysicalPort ]

if { [ catch {

# --- Configure the Port Layer2 settings
set srcL2 [ $srcBBPort Layer2.EthII.Set ]
$srcL2 Mac.Set $srcPortMacAddress
set destL2 [ $destBBPort Layer2.EthII.Set ]
$destL2 Mac.Set $destPortMacAddress

# --- Configure the Port Layer2.5 settings
if { $srcPerformPppoe == 1 } {
    # --- Prepare the PPPoE configuration
    set srcPppoeResult [ ::excentis::ByteBlower::PPPoE.Setup $srcBBPort $srcPppoeServiceName \
                                                "pap" [ list ${srcPapPeerID} ${srcPapPassword} ] \
                                                "ipcp" \
                       ]

    # --- Start the PPPoE Session
    set srcPppoeSessionId [ ::excentis::ByteBlower::PPPoE.Start $srcPppoeResult ]

    # --- Extract Network Control Protocol (IPCP) results
    set srcIpcpResults [ ::excentis::ByteBlower::PPPoE.NCP.Results.Get $srcPppoeResult ]
    set srcPortIpv4Address [ lindex $srcIpcpResults 0 ]
    set srcPortIpv4GW [ lindex $srcIpcpResults 1 ]

    # --- Show the results
    if { $systemSupportsColoring } {
        puts [ format "Interface PPPoE got Session ID \`\033\[0;33m0x%04X\033\[0;m'" ${srcPppoeSessionId} ]
    } else {
        puts [ format "Interface PPPoE got Session ID \`0x%04X'" ${srcPppoeSessionId} ]
    }
    puts "Source Ipcp : Got IPv4 Address        : ${srcPortIpv4Address}"
    puts "Source Ipcp : Got Remote IPv4 Address : ${srcPortIpv4GW}"
} else {
    set srcL3 [ $srcBBPort Layer3.IPv4.Set ]
    $srcL3 Ip.Set $srcPortIpv4Address
    $srcL3 Netmask.Set $srcPortNetmask
    $srcL3 Gateway.Set $srcPortIpv4GW
    unset srcL3
}

if { $destPerformPppoe == 1 } {
    # --- Prepare the PPPoE configuration
    set destPppoeResult [ ::excentis::ByteBlower::PPPoE.Setup $destBBPort $destPppoeServiceName \
                                                "pap" [ list ${destPapPeerID} ${destPapPassword} ] \
                                                "ipcp" \
                        ]

    # --- Start the PPPoE Session
    set destPppoeSessionId [ ::excentis::ByteBlower::PPPoE.Start $destPppoeResult ]

    # --- Extract Network Control Protocol (IPCP) results
    set destIpcpResults [ ::excentis::ByteBlower::PPPoE.NCP.Results.Get $destPppoeResult ]
    set destPortIpv4Address [ lindex $destIpcpResults 0 ]
    set destPortIpv4GW [ lindex $destIpcpResults 1 ]

    # --- Show the results
    if { $systemSupportsColoring } {
        puts [ format "Destination PPPoE got Session ID \`\033\[0;33m0x%04X\033\[0;m'" ${destPppoeSessionId} ]
    } else {
        puts [ format "Destination PPPoE got Session ID \`0x%04X'" ${destPppoeSessionId} ]
    }
    puts "Destination Ipcp : Got IPv4 Address        : ${destPortIpv4Address}"
    puts "Destination Ipcp : Got Remote IPv4 Address : ${destPortIpv4GW}"
} else {
    set destL3 [ $destBBPort Layer3.IPv4.Set ]
    $destL3 Ip.Set $destPortIpv4Address
    $destL3 Netmask.Set $destPortNetmask
    $destL3 Gateway.Set $destPortIpv4GW
    unset destL3
}

# --- Configure the Port Layer3 settings
set srcL3 [ $srcBBPort Layer3.IPv4.Get ]
puts "Source Port L3 Configuration:"
if { [ llength $srcL3 ] > 0 } {
    puts " - IPv4 Address    : [ $srcL3 Ip.Get ]"
    puts " - Netmask         : [ $srcL3 Netmask.Get ]"
    puts " - Default Gateway : [ $srcL3 Gateway.Get ]"
} else {
    puts " <EMPTY>"
}

set destL3 [ $destBBPort Layer3.IPv4.Get ]
puts "Destination Port L3 Configuration:"
if { [ llength $destL3 ] > 0 } {
    puts " - IPv4 Address    : [ $destL3 Ip.Get ]"
    puts " - Netmask         : [ $destL3 Netmask.Get ]"
    puts " - Default Gateway : [ $destL3 Gateway.Get ]"
} else {
    puts " <EMPTY>"
}

puts "Done creating 2 Ports on ByteBlower Server '${bbServerName}'"

# --- Setup Traffic

set srcUdpPort [ expr int(0xFFFF * rand()) & 0xFFFF ]
set destUdpPort [ expr int(0xFFFF * rand()) & 0xFFFF ]

proc createPppoeFrame { srcBBPort destBBPort ethernetLength srcUdpPort destUdpPort } {
    set srcL3 [ $srcBBPort Layer3.IPv4.Get ]
    set destL3 [ $destBBPort Layer3.IPv4.Get ]

    # --- Create the frame
    set frameContent [ ::excentis::basic::Frame.Udp.Set "00:00:00:00:00:00" "00:00:00:00:00:00" \
                                     [ $destL3 Ip.Get ] [ $srcL3 Ip.Get ] \
                                     $destUdpPort $srcUdpPort \
                                     [ list -length [ expr $ethernetLength - 42 ] ]
                     ]


    # --- Update the Layer2 and/or Layer 2.5 Header of the Frame
    return [ ::excentis::ByteBlower::LinkLayer.AutoComplete $frameContent $srcBBPort ]
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

proc createTriggerFilter { srcBBPort destBBPort pppoeFrameContentString nonPppoeFrameSize srcPerformPppoe destPerformPppoe destPppoeSessionId srcUdpPort destUdpPort } {
    set srcL3 [ $srcBBPort Layer3.IPv4.Get ]
    set destL3 [ $destBBPort Layer3.IPv4.Get ]

    # --- Update the Frame Size for the trigger!
    #set nonPppoeFrameSize [ expr [ string length $pppoeFrameContentString ] / 2 ]
    ##set nonPppoeFrameSize [ llength $pppoeFrameContent ]

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
            set hexSrcIpAddress "0x[ string range $pppoeFrameContentString 68 75 ]"
            set hexDestIpAddress "0x[ string range $pppoeFrameContentString 76 83 ]"
        } else {
            set pppoeProtocol "0x8864"
            set pppoeVersionType "0x11"
            set pppoeCode "0x00"
            set pppProtocol "0x0021"
            set hexSrcIpAddress [ eval format {"0x%02x%02x%02x%02x"} [ ::excentis::basic::IP.To.Hex [ $srcL3 Ip.Get ] ] ]
            set hexDestIpAddress [ eval format {"0x%02x%02x%02x%02x"} [ ::excentis::basic::IP.To.Hex [ $destL3 Ip.Get ] ] ]
        }
        # --- Not explicitly required that the received frame size is the same as the source frame size ( llength $pppoeFrameContent )
        #     => Use the "untagged" source frame size + add the PPPoE header size at the destination side
        set triggerFilter "len = [ expr ${nonPppoeFrameSize} + 8 ] \
                           and ether\[12:2\] = ${pppoeProtocol} and ether\[14:1\] = ${pppoeVersionType} and ether\[15:1\] = ${pppoeCode} and ether\[16:2\] = [ format "0x%04x" ${destPppoeSessionId} ] \
                           and ether\[20:2\] = ${pppProtocol} and ether\[34:4\] = ${hexSrcIpAddress} and ether\[38:4\] = ${hexDestIpAddress} \
                           and ether\[42:2\] = ${srcUdpPort} and ether\[44:2\] = ${destUdpPort}"
        #set triggerFilter "len = [ expr ${nonPppoeFrameSize} + 8 ] \
        #                   and ether\[12:2\] = ${pppoeProtocol} and ether\[14:1\] = ${pppoeVersionType} and ether\[15:1\] = ${pppoeCode} \
        #                   and ether\[20:2\] = ${pppProtocol} and ether\[34:4\] = ${hexSrcIpAddress} and ether\[38:4\] = ${hexDestIpAddress} \
        #                   and ether\[42:2\] = ${srcUdpPort} and ether\[44:2\] = ${destUdpPort}"
    } else {
        set triggerFilter "ip src [ $srcL3 Ip.Get ] and ip dst [ $destL3 Ip.Get ] and udp dst port ${destUdpPort} and udp src port ${srcUdpPort} and len = ${nonPppoeFrameSize}"
    }

    return $triggerFilter
}

set srcPppoeFrameContentString [ createPppoeFrame $srcBBPort $destBBPort $frameSize $srcUdpPort $destUdpPort ]
set srcStream [ createStream $srcBBPort $srcPppoeFrameContentString $executionTime $packetRate $srcUdpPort $destUdpPort ]

# --- Add the source Stream
puts "Stream on '${bbServerName}' - [ $srcBBPort Interface.Name.Get ]: UDP ${srcUdpPort} -> ${destUdpPort}, ${frameSize} Bytes, [ $srcStream InterFrameGap.Get ] ns, [ $srcStream NumberOfFrames.Get ] packets sent."

if { [ info exists bidirPacketRate ] } {
    set destPppoeFrameContentString [ createPppoeFrame $destBBPort $srcBBPort $frameSize $destUdpPort $srcUdpPort ]
    set destStream [ createStream $destBBPort $destPppoeFrameContentString $executionTime $bidirPacketRate $destUdpPort $srcUdpPort ]

    # --- Add the destination Stream
    puts "Stream on '${bbServerName}' - [ $destBBPort Interface.Name.Get ]: UDP ${destUdpPort} -> ${srcUdpPort}, ${frameSize} Bytes, [ $destStream InterFrameGap.Get ] ns, [ $destStream NumberOfFrames.Get ] packets sent."
}

set triggerFilter [ createTriggerFilter $srcBBPort $destBBPort $srcPppoeFrameContentString $frameSize $srcPerformPppoe $destPerformPppoe $destPppoeSessionId $srcUdpPort $destUdpPort ]

set destTrigger [ $destBBPort Rx.Trigger.Basic.Add ]
$destTrigger Filter.Set ${triggerFilter}

if { [ info exists bidirPacketRate ] } {
    set triggerFilter [ createTriggerFilter $destBBPort $srcBBPort $destPppoeFrameContentString $frameSize $destPerformPppoe $srcPerformPppoe $srcPppoeSessionId $destUdpPort $srcUdpPort ]

    set srcTrigger [ $srcBBPort Rx.Trigger.Basic.Add ]
    $srcTrigger Filter.Set ${triggerFilter}
}

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
puts "Starting ByteBlower Port"
if { [ info exists bidirPacketRate ] } {
    ByteBlower Ports.Start $srcBBPort $destBBPort
} else {
    ByteBlower Ports.Start $srcBBPort
}
set startTime [ clock seconds ]

# --- Wait until the test is finished
set waitTime [ expr ( 1000 * $executionTime ) + 100 ] ; # Wait 100 ms extra for getting the results.
puts "Waiting ${waitTime} ms..."
set waiter 0
after $waitTime "set waiter 1"
vwait waiter
puts "done"

#---------------------#
#   Getting results   #
#---------------------#

# --- Stop traffic
puts "Stopping source ByteBlower Port '[ $srcBBPort Interface.Name.Get ]'"
set stopTime1 [ clock seconds ]
if { [ info exists bidirPacketRate ] } {
    ByteBlower Ports.Stop $srcBBPort $destBBPort
} else {
    ByteBlower Ports.Stop $srcBBPort
}
set stopTime2 [ clock seconds ]

set testRunTime [ expr $stopTime1 - $startTime ]
puts "Test took $testRunTime seconds"
puts "Stopping took [ expr $stopTime2 - $stopTime1 ] seconds"

# --- Getting results
puts "* Destination\t: ${bbServerName} - [ $destBBPort Interface.Name.Get ]"
if { $destPerformPppoe == 1 } {
    set destPppoeStatus [ ::excentis::ByteBlower::PPPoE.Status.Get ${destPppoeResult} ]
    if { $systemSupportsColoring } {
        puts "  - PPPoE Status : \033\[0;35m${destPppoeStatus}\033\[0;m"
    } else {
        puts "  - PPPoE Status : ${destPppoeStatus}"
    }
}
puts "* Source Port\t: ${bbServerName} - [ $srcBBPort Interface.Name.Get ]"
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

printResults $srcStream $destTrigger $frameSize

if { [ info exists bidirPacketRate ] } {
    printResults $destStream $srcTrigger $frameSize
}

if { $systemSupportsColoring } {
    puts "* Test Started @ \033\[0;33m[ clock format $startTime ]\033\[0;m"
    puts "* Test Stopped @ \033\[0;33m[ clock format $stopTime2 ]\033\[0;m"
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
    $destBBPort Destructor
    $srcBBPort Destructor

    $bbServer Destructor

    error $catched

} else {
    # --- Delete the ByteBlower Ports
    $destBBPort Destructor
    $srcBBPort Destructor

    $bbServer Destructor

}

# --- all done
#exit 0

