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



# XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX

#------------------------#
#   Test procedures      #
#------------------------#

# The real algorithm.
# This algorithm will find the throughput between the 'sender' and the 'receiver'.
# This test will use frames of the 'frameSize', and will start with a test offering the 'initialFrameRate'
# If this first test passes (loss percentage < 'acceptableLoss) ,
# the test will continue with a offered load of 'initialFrameRate + initialFrameRate * factor'
# Each test iteration will take 'testTime' seconds.
#
# The algorithm has some special tricks to deal with 'unstable DUTS', ...
#
# The first element of the result list, will contain the final result, and the precision and quality.
# The second part of the list will povide an overview of the offered load and the result for that load.
#

proc rfc2544.b2b { sender receiver frameSize frameRate initialBurstSize factor acceptableLoss { maxTestIterations -1 } { timetowait 5 } { NAT 0 } { interfaceLimit 999960000 } { dutIP null } } {
    # Create a frame of the requested size.
    set udpDataLength [ expr $frameSize - 42 ]
    ## Destination mac.

    set destUdpPort 1024
    set srcUdpPort 1024
    set destIpAddress [ [ $receiver Layer3.IPv4.Get ] Ip.Get ]

    set broadcastPart 0.01
    set ultimateFrameRate [ expr floor( $interfaceLimit * (1 - $broadcastPart)/ ( 8 * ( $frameSize + 24 )) ) ]
    if { [ expr $frameRate > $ultimateFrameRate ] } {
        puts "Suggested framerate is higher than the interface limit ($frameRate > $ultimateFrameRate)"
        puts "Testing at the limit of the interface."
        set frameRate $ultimateFrameRate
    }


    rfc2544.traffic.Clean $sender $receiver
    # Create the txStructure.
    # We create traffic, with additional broadcast traffic, mgmt traffic and routerupdates
    if { [ string compare $dutIP null ] == 0 } {
        # Only extra broadcast
        # sourcePort destPort frameRate frameSize testTime { NAT 0 } { extraBroadcast 1 } { extraMgmt 1 } { dupIP } { extraRoutingUpdate 1 } { net1  192.168.2.x } { net2 192.168.3.x } { net3 192.168.4.x } { net4 192.168.5.x } { net5 192.168.6.x } { net6 192.168.6.x }
        puts "NO ROUTING AND MGMT"
        set trafficInfo [ rfc2544.traffic.Create $sender $receiver $frameRate $frameSize "($initialBurstSize / $frameRate )" $NAT 1 0 $dutIP 0 ]
        set tx [ lindex $trafficInfo 0 ]
        set rxFilter [ lindex $trafficInfo 1 ]
    } else {
        # Broadcast, mgmt and router updates
        puts "ROUTING AND MGMT"
        set trafficInfo [ rfc2544.traffic.Create $sender $receiver $frameRate $frameSize "($initialBurstSize / $frameRate )" $NAT 1 1 $dutIP 1 ]
        set tx [ lindex $trafficInfo 0 ]
        set rxFilter [ lindex $trafficInfo 1 ]
    }

    set burstSize $initialBurstSize
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
    # This sets the quality score, higher is worse !!!
    set qualityScore 0
    set precision $burstSize
    if { [expr $loss <= $acceptableLoss ] } {
        # Ok, we can continue.
        set iteration 1
        while { [expr $loss <= $acceptableLoss ] && [ expr $maxTestIterations!= 0 ] } {
            lappend resultList [ list $burstSize $loss PASS "" ]
            incr iteration
            # New frame rate is oldFramerate + factor* oldFrameRate
            set newBurstSize [ expr round( $burstSize + $factor * 1.0 * $burstSize ) ]
            puts "Iteration $iteration: Testing at burstSize $newBurstSize"
            set precision [ expr $newBurstSize - $burstSize ]
            set burstSize $newBurstSize

            set tx [ rfc2544.update.tx $tx $frameRate "($burstSize / $frameRate )"]
            set flow [ list -tx $tx -rx $rx ]
            set loss [ ::excentis::ByteBlower::FlowLossRate [ list $flow] -finaltimetowait $timetowait ]
            set maxTestIterations [ expr $maxTestIterations - 1 ]

            if { [ expr  $loss > $acceptableLoss ] } {
                lappend resultList [ list $burstSize $loss FAIL "" ]
                if { [expr $maxTestIterations ==  0] } {
                    break
                }
                # Lucky high shot mode ;)
                # It could be that the device under test had just bad day. Go a little bit higher, and see if that works.
                set newBurstSize [ expr round( $burstSize + $factor * 1.0 * $burstSize ) ]
                puts "Iteration $iteration: Testing at burstSize $newBurstSize, but that is a Luck High Shot"
                set tx [ rfc2544.update.tx $tx $frameRate "($newBurstSize / $frameRate )"]
                set flow [ list -tx $tx -rx $rx ]
                set newLoss [ ::excentis::ByteBlower::FlowLossRate [ list $flow] -finaltimetowait $timetowait ]
                set maxTestIterations [ expr $maxTestIterations - 1 ]
                set precision [ expr $newBurstSize - $burstSize ]
                if { [ expr $newLoss >= $acceptableLoss ] } {
                    # We really overloaded the device.
                    # We just don't use this step...
                    lappend resultList [ list $newBurstSize $newLoss FAIL "Tried a lucky high shot" ]
                } else {
                    # The device had a bad day.
                    set burstSize $newBurstSize
                    set loss $newLoss
                    incr qualityScore
                    lappend resultList [ list $newBurstSize $newLoss PASS "Successfull lucky high shot" ]
                }
            }
        }
        if { [expr $maxTestIterations ==  0] } {
            puts "Maximum number of test iterations reached."
            if { [expr $loss <= $acceptableLoss ] } {
                lappend resultList [ list $burstSize $loss PASS "" ]
            } else {
                lappend resultList [ list $burstSize $loss PASS "" ]
            }
        }
        # First we will do some lineair rough tuning.
        set low [ expr round ( $burstSize / ( 1 + $factor ))]
        set high $burstSize
        # Return to last good result
        set burstSize $low
        while { 1 } {
            # Calculate stepsize
            set lineairStepSize [ expr ( $high - $low ) / 10 ]
            
            # If the stepsize is too small, we can quit.
            if { [ expr ( $lineairStepSize / $low ) < ( $acceptableLoss / 100 )  ] || [ expr $lineairStepSize < 1 ]} {
                puts "VICTORY !!! We have a good result for this device: $burstSize"
                break
            }
            set precision $lineairStepSize
            for { set i 1 } { $i <= 10 } { incr i } {
                set burstSize [ expr $low + $i * $lineairStepSize ]
                set tx [ rfc2544.update.tx $tx $frameRate "($burstSize / $frameRate )" ]
                
                set flow [ list -tx $tx -rx $rx ]
                incr iteration
                puts "Iteration $iteration: Testing at burstsize $burstSize"
                set loss [ ::excentis::ByteBlower::FlowLossRate [ list $flow] -finaltimetowait $timetowait ]
                # Do we have loss ?
                if { [ expr  $loss > $acceptableLoss ] } {
                    lappend resultList [ list $burstSize $loss FAIL "" ]
                    # We have a new high score value, and also a low score...
                    set high $burstSize
                    # Return to last good result
                    set burstSize $low
                    # break out of the for, go into the wild while
                    break
                } else {
                    lappend resultList [ list $burstSize $loss PASS "" ]
                    set low $burstSize
                    # We could recalculate the stepsize here too ;)
                }
                incr maxTestIterations
                if { [expr $maxTestIterations ==  0] } {
                    break
                }
            }
        }
    } else {
        error "No b2b test possible! We have already loss on first test: $loss % of loss."
    }
    return [ list [ list BurstSize $burstSize Quality [ expr ($iteration * 1.0 - $qualityScore ) * 100  / $iteration ] Precision $precision ] $resultList ]
}

# XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX

