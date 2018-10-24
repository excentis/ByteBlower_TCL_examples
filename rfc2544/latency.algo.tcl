#------------------------#
#   Test Initialisation  #
#------------------------#

#- What would we do without the package ;-)
package require ByteBlower
#- Required ByteBlower HL packages
package require excentis_basic
package require ByteBlowerHL

source traffic.tcl

# This script uses the shared procedures of the example scripts, so we include
# that file.
source [ file join [ file dirname [ info script ]] .. general.proc.tcl ]

#------------------------#
#   Test procedures      #
#------------------------#

# The real algorithm.
# This algorithm will find the latency between the 'sender' and the 'receiver'.
# This test will use frames of the 'frameSize', and will start with a test offering the 'initialFrameRate'
#
# After 60 seconds, another frame is send, including a timestamp. We will measure the latency for this frame, and repeat this test 20 times.
#

proc rfc2544.latency { sender receiver frameSize frameRate { testTime 120 } { iterations 20 } { timetowait 5 } { NAT 0 } { interfaceLimit 999960000 } { dutIP null }  }  {
    # Create a frame of the requested size.
    set udpDataLength [ expr $frameSize - 42 ]
    ## Destination mac.

    set destIpAddress [ [ $receiver Layer3.IPv4.Get ] Ip.Get ]
    if { $testTime < 60 } {
        puts "WARNING!!!! WARNING!!! Test period too short according to RFC2544. Should be at least 60 seconds."
    }

    set broadcastPart 0.01
    set ultimateFrameRate [ expr floor( $interfaceLimit * (1 - $broadcastPart) / ( 8 * ($frameSize + 24 )) ) ]
    if { [ expr $frameRate > $ultimateFrameRate ] } {
        puts "Suggested framerate is higher than the interface limit ($frameRate > $ultimateFrameRate)"
        puts "Testing at the limit of the interface."
        set frameRate $ultimateFrameRate
    }


    #- Create the UDP frames, leaving the IP and ethernet settings to default
    rfc2544.traffic.Clean $sender $receiver
    # Create the txStructure.
    # We create traffic, with additional broadcast traffic, mgmt traffic and routerupdates
    if { [ string compare $dutIP null ] == 0 } {
        # Only extra broadcast
        # sourcePort destPort frameRate frameSize testTime { NAT 0 } { extraBroadcast 1 } { extraMgmt 1 } { dupIP } { extraRoutingUpdate 1 } { net1  192.168.2.x } { net2 192.168.3.x } { net3 192.168.4.x } { net4 192.168.5.x } { net5 192.168.6.x } { net6 192.168.6.x }
        puts "NO ROUTING AND MGMT"
        set trafficInfo [ rfc2544.traffic.Create $sender $receiver $frameRate $frameSize $testTime $NAT 1 0 $dutIP 0 ]
        set tx [ lindex $trafficInfo 0 ]
        set rxFilter [ lindex $trafficInfo 1 ]
    } else {
        # Broadcast, mgmt and router updates
        puts "ROUTING AND MGMT"
        set trafficInfo [ rfc2544.traffic.Create $sender $receiver $frameRate $frameSize $testTime $NAT 1 1 $dutIP 1 ]
        set tx [ lindex $trafficInfo 0 ]
        set rxFilter [ lindex $trafficInfo 1 ]
    }

    # Create the rxStructure.
    set rx [ list -port $receiver \
        -trigger [ list -type basic -filter $rxFilter ] \
    ]

    # Create the flow with timestamping, and the appropriate trigger on the receivers side.
    set timedFlow [ $sender Tx.Stream.Add ]
    # Create the frame.
    set natInformation [ rfc2544.traffic.TranslateNATInformation $sender $receiver $NAT 49184 1025 ]
    # Create the frame content, with a different length
    # rfc2544.traffic.UDP { sourcePort destIp length {destUdpPort 7 } }
    if { [ expr $frameSize > 60 ] } {
        set frameContent [ rfc2544.traffic.UDP $sender [ lindex $natInformation 0 ] 60 [ lindex $natInformation 1 ] ]
    } else {
        set frameContent [ rfc2544.traffic.UDP $sender [ lindex $natInformation 0 ] 64 [ lindex $natInformation 1 ] ]
    }
    set timedFrame [ $timedFlow Frame.Add ]
    $timedFrame Bytes.Set $frameContent
    [$timedFrame FrameTag.Time.Get] Enable 1
    $timedFlow InitialTimeToWait.Set [ expr $testTime / 2 ]s
    $timedFlow NumberOfFrames.Set 1
    # We still need to receive the frame.
    set timedRx [ $receiver Rx.Latency.Basic.Add ]
    $timedRx Filter.Set [ ::excentis::basic::ParseFilter "(ip.src == [ lindex $natInformation 2 ]) and (ip.dst == [ [$receiver Layer3.IPv4.Get ] Ip.Get ]) and (udp.dstport == 1025) " ]
    $timedRx Result.Clear

    # Execute scenario.
    # HERE STARTS THE REAL ALGORITHM.
    set flow [ list -tx $tx -rx $rx ]
    for { set i 0 } { $i < $iterations } { incr i } {
        set loss [ ::excentis::ByteBlower::FlowLossRate [ list $flow] -finaltimetowait $timetowait ]
    }
    return [ [ $timedRx Result.Get ] Latency.Average.Get]
}

# XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX

