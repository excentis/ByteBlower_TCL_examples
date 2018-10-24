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
# This algorithm will find the frameloss between the 'sender' and the 'receiver'.
# This test will use frames of the 'frameSize', and will start with a test offering the 'maximumFrameRate'
# While still loss,
# the test will continue with a offered load of 'framerate - granualarity * framerate'
# Each test iteration will take 'testTime' seconds.
#
#
# The result will povide an overview of the offered load and the result for that load.
#

proc rfc2544.frameloss { sender receiver frameSize maxFrameRate granularity { testTime 60 } { maxTestIterations -1 } { timetowait 5 } { NAT 0 } { interfaceLimit 999960000 } { dutIP null }  }  {
    # Create a frame of the requested size.
    set udpDataLength [ expr $frameSize - 42 ]
    ## Destination mac.

    set destUdpPort 1024
    set srcUdpPort 1024
    set destIpAddress [ [ $receiver Layer3.IPv4.Get ] Ip.Get ]
    if { $testTime < 60 } {
        puts "WARNING!!!! WARNING!!! Test period too short according to RFC2544. Should be at least 60 seconds."
    }

    set broadcastPart 0.01
    set ultimateFrameRate [ expr floor( $interfaceLimit * (1 - $broadcastPart)/ ( 8 * ($frameSize + 24 )) )]
    if { [ expr $maxFrameRate > $ultimateFrameRate ] } {
        puts "Suggested framerate is higher than the interface limit ($framerate > $ultimateFrameRate)"
        puts "Testing at the limit of the interface."
        set maxFrameRate $ultimateFrameRate
   }


    #- Create the UDP frames, leaving the IP and ethernet settings to default
    set frameRate $maxFrameRate
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
    # Execute scenario.
    # HERE STARTS THE REAL ALGORITHM.
    set flow [ list -tx $tx -rx $rx ]
    set loss [ ::excentis::ByteBlower::FlowLossRate [ list $flow] -finaltimetowait $timetowait ]
    set maxTestIterations [ expr $maxTestIterations - 1 ]
    set resultList [list ]
    set goodResult 0
    if { [expr $loss == 0 ] } {
        incr goodResult
    }
    # Ok, we can continue.
    set iteration 1
    while { [expr $goodResult  < 2 ] && [ expr $maxTestIterations!= 0 ] } {
        lappend resultList [ list $frameRate $loss ]
        incr iteration
        # New frame rate is oldFramerate + factor* oldFrameRate
        set newFrameRate [ expr $frameRate - $granularity * 0.01 * $frameRate ]
        puts "Iteration $iteration: Testing at rate $newFrameRate"
        set frameRate $newFrameRate

        set tx [ rfc2544.update.tx $tx $frameRate $testTime ]
        set flow [ list -tx $tx -rx $rx ]
        set loss [ ::excentis::ByteBlower::FlowLossRate [ list $flow] -finaltimetowait $timetowait ]
        set maxTestIterations [ expr $maxTestIterations - 1 ]
        if { [ expr $loss == 0 ] } {
            incr goodResult
        } else {
            set goodResult 0
        }
    }
    lappend resultList [ list $frameRate $loss ]
    return $resultList
}

# XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX

