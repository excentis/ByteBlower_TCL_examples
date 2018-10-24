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

proc rfc2544.throughput { sender receiver frameSize initialFrameRate factor acceptableLoss { testTime 60 } { maxTestIterations -1 } { timetowait 5000 } { NAT 0 } { interfaceLimit 999960000 } { dutIP null }  }  {
    # Create a frame of the requested size.
    set udpDataLength [ expr $frameSize - 42 ]
    ## Destination mac.

    set destUdpPort 1024
    set srcUdpPort 1024
    #- Create the UDP frames, leaving the IP and ethernet settings to default
    set frameRate $initialFrameRate
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
        set interfaceLimit [expr floor( $interfaceLimit * 0.99) ]
    } else {
        # Broadcast, mgmt and router updates
        puts "ROUTING AND MGMT"
        set trafficInfo [ rfc2544.traffic.Create $sender $receiver $frameRate $frameSize $testTime $NAT 1 1 $dutIP 1 ]
        set tx [ lindex $trafficInfo 0 ]
        set rxFilter [ lindex $trafficInfo 1 ]
        # Assuming for the extra router update to be within the rounding error.
        set interfaceLimit [expr floor( $interfaceLimit * 0.99) ] 

    }

    # Create the rxStructure.
    set rx [ list -port $receiver \
        -trigger [ list -type basic -filter $rxFilter ] \
    ]

    # HERE STARTS THE REAL ALGORITHM.

    set errorCode ""
    set iteration 0
    set loss 0
    # Initialization
    set resultList [ list ]
    set qualityScore 0 ; # This sets the quality score, higher is worse
    set precision $frameRate

    set ultimateFrameRate [ expr floor( $interfaceLimit / (8 * ($frameSize + 24))) ]

    #
    # PHASE 1: Exponential phase
    #
    while { [ string equal $errorCode "" ] && [expr $loss <= $acceptableLoss ] && [ expr $maxTestIterations != 0 ] } {
        lappend resultList [ list $frameRate $loss PASS "" ]

        # Update parameters
        incr iteration
        set newFrameRate [ expr min($ultimateFrameRate, $frameRate + $factor * 1.0 * $frameRate ) ] ;
        set precision [ expr $newFrameRate - $frameRate ]
        set frameRate $newFrameRate

        # Run scenario
        puts "Iteration $iteration/$maxTestIterations: Testing at rate $frameRate/$ultimateFrameRate"
        set tx [ rfc2544.update.tx $tx $frameRate $testTime ]
        set flow [ list -tx $tx -rx $rx ]
        set loss [ ::excentis::ByteBlower::FlowLossRate [ list $flow ] -finaltimetowait $timetowait ]
        set maxTestIterations [ expr $maxTestIterations - 1 ]
        if { [lsearch $loss "-error"] != -1} {
            set errorCode [ lindex $loss [ expr [lsearch $loss "-error"] + 1 ] ]
            set loss [ lindex $loss 0 ]
        }

        # Process failed scenario
        if { [ expr  $loss > $acceptableLoss ] || ! [ string equal $errorCode "" ] } {
            if { ! [ string equal $errorCode "" ] } {
                lappend resultList [ list $frameRate $loss FAIL "Failure due to flow error: $errorCode" ]
            } else {
                lappend resultList [ list $frameRate $loss FAIL "" ]
            }

            # Stop the test when we ran out of iterations
            if { [expr $maxTestIterations ==  0] } {
                break
            }

            # Lucky high shot mode (Device under test might have a bad day. Go a little bit higher, and see if that works.)
            # Update parameters

            set newFrameRate [ expr min($ultimateFrameRate, $frameRate + $factor * 0.5 * $frameRate ) ]
            set precision [ expr $newFrameRate - $frameRate ]

            # Run scenario
            puts "Iteration $iteration: Testing at rate ${newFrameRate}, but this is a Lucky High Shot"
            set tx [ rfc2544.update.tx $tx $newFrameRate $testTime ]
            set flow [ list -tx $tx -rx $rx ]
            set newLoss [ ::excentis::ByteBlower::FlowLossRate [ list $flow ] -finaltimetowait $timetowait ]
            set maxTestIterations [ expr $maxTestIterations - 1 ]
            if { [lsearch $newLoss "-error"] != -1} {
                set errorCode [ lindex $newLoss [ expr [lsearch $newLoss "-error"] + 1 ] ]
                set newLoss [ lindex $newLoss 0 ]
            }

            # Process lucky high show result
            if { ! [ string equal $errorCode "" ] } {
                # We really have a flow error.
                # We log this result, but ingore it for phase 2.
                lappend resultList [ list $newFrameRate $newLoss FAIL "Tried a lucky high shot, but flow error: $errorCode" ]
            } elseif { [ expr $newLoss >= $acceptableLoss ] } {
                # We really overloaded the device or network under test.
                # We log this result, but ignore it for phase 2.
                lappend resultList [ list $newFrameRate $newLoss FAIL "Tried a lucky high shot" ]
            } else {
                # The device had a bad day. We continue phase 1 with the new values and reset the error code.
                set frameRate $newFrameRate
                set loss $newLoss
                incr qualityScore
                set errorCode ""
                lappend resultList [ list $newFrameRate $newLoss PASS "Successfull lucky high shot" ]
            }
        } elseif { [ expr $frameRate == $ultimateFrameRate ] } {
            ## We had not sufficient loss and are already testing at the interface limit.
            ## End this part of the test.
            puts "At interface limit ending the test"
            break
        }

    }

    if { [expr $maxTestIterations ==  0] } {
        puts "Maximum number of test iterations reached."
        if { [expr $loss <= $acceptableLoss ] } {
            lappend resultList [ list $frameRate $loss PASS "" ]
        } else {
            lappend resultList [ list $frameRate $loss FAIL "" ]
        }
    }

    # PHASE 2: Finetuning
    #puts "Some finetuning is needed: we had a loss of $loss percent at a rate of $frameRate"

    # Initialization of finetuning boundaries 
    set low [ expr round ( $frameRate / ( 1 + $factor ))]
    set high $frameRate

    while { 1 } {
        # Stepsize for linear interpolation: 1/10th of interval
        set frameRate $low; # go back to last succesful iteration
        set lineairStepSize [ expr ( $high - $low ) * 1.0 / 10 ]
        set errorCode ""
        puts "new framerate $low, $lineairStepSize"

        # If the stepsize is too small, we can quit.
        if { [ expr ( $lineairStepSize / $low ) < ( $acceptableLoss / 100 )  ] || [ expr $lineairStepSize < ( 1.0 / 1000000000 ) ] } {
            puts "VICTORY !!! We have a good result for this device."
            break
        } elseif { [expr $maxTestIterations  == 0] } {
            puts "No iterations left ."
            break
        }

        set precision $lineairStepSize
        for { set i 1 } { $i <= 10 } { incr i } {
            # See if we still need something to do.
            if { [expr $maxTestIterations ==  0] } {
                break
            }

            # Update parameters
            incr iteration
            set frameRate [ expr min($frameRate + $lineairStepSize, $high) ]

            # Run scenario
            puts "Iteration $iteration: Testing at rate $frameRate"
            set tx [ rfc2544.update.tx $tx $frameRate $testTime ]
            set flow [ list -tx $tx -rx $rx ]
            set loss [ ::excentis::ByteBlower::FlowLossRate [ list $flow ] -finaltimetowait $timetowait ]
            set maxTestIterations [ expr $maxTestIterations - 1 ]
            if { [lsearch $loss "-error"] != -1} {
                set errorCode [ lindex $loss [ expr [lsearch $loss "-error"] + 1 ] ]
                set loss [ lindex $loss 0 ]
            }

            # If we have loss (or a flow error), we create a new (smaller) interval
            if { ! [ string equal $errorCode "" ] } {
                lappend resultList [ list $frameRate $loss FAIL "Failure due to flow error: $errorCode" ]
                # New upper boundary for next interval.
                set high $frameRate
                # Restart lineair finetuning with smaller interval (out of for, into the while loop)
                break
            } elseif { [ expr  $loss > $acceptableLoss ] } {
                lappend resultList [ list $frameRate $loss FAIL "" ]
                # New upper boundary for next interval.
                set high $frameRate
                # Restart lineair finetuning with smaller interval (out of for, into the while loop)
                break
            } else {
                lappend resultList [ list $frameRate $loss PASS "" ]
                # New lower boundary for next interval (but try higher lower boundary for now).
                set low $frameRate
            }
        }
    }
    return [ list FrameRate $frameRate Quality [ expr ($iteration * 1.0 - $qualityScore ) * 100  / $iteration ] Precision $precision ] 
}

# XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
