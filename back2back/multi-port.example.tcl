source [ file join [ file dirname [ info script ]] .. general.proc.tcl ]



#-----------------------#
#   Helper procedures   #
#-----------------------#

#----------------------
# Write a message to the standard output <outputFd>.
# The message will also be written to the log file '::logFd' (if one has been defined).
#
# @param messageText Text to write to the default output channel AND to the log file (if it is used).
# @param outputFd Output channel to (always) write to (Default: stdout)
#----------------------
proc ::logMessage { messageText { outputFd stdout } } {
    puts $outputFd $messageText
    if { [ info exists ::logFd ] } {
        puts $::logFd $messageText
        flush $::logFd
    }
}

#----------------------
# Parse the returned list of the ::excentis::ByteBlower::FlowLossRate function
# when the option '-return numbers' was given.
#
# NOTE: only the part for the given <direction> should be given!
#
# @param direction Direction of the Flow results ('downstream', 'ds', 'upstream' or 'us')
# @param numberResults The list of Flow results for the given direction.
#
# For Example:
#   set bidirNumbersResults [ ::excentis::ByteBlower::FlowLossRate [ eval list $downstreamFlowList $upstreamFlowList ] -return numbers ]
#   set downstreamFlowListLength [ llength $downstreamFlowList ]
#   puts [ ::parseNumberResults downstream [ lrange $downstreamUnidirNumbers 0 [ expr $downstreamFlowListLength - 1 ] ] ]
#   puts [ ::parseNumberResults upstream [ lrange $downstreamUnidirNumbers $downstreamFlowListLength end ] ]
#----------------------
proc ::parseNumberResults { direction numberResults } {
    set resultText ""

    if { [ string equal -nocase $direction "ds" ] ||\
        [ string equal -nocase $direction "downstream" ] } {
        set directionFormat "  * NSI -> CPE%u"
    } else {
        set directionFormat "  * CPE%u -> NSI"
    }

    set cpeNr 0
    foreach numberResult $numberResults {
        if { $cpeNr != 0 } {
            append resultText "\n"
        }
        incr cpeNr 1

        append resultText [ format $directionFormat $cpeNr ]

        set tx 0
        set rx 0
        foreach {name value} $numberResult {
            switch -- $name {
                -tx {
                    append resultText "\n    - Transmitted ${value} packets"
                    set tx ${value}
                }
                -rx {
                    append resultText "\n    - Received ${value} packets"
                    set rx ${value}
                }
            }
        }
        set loss [ expr $tx - $rx ]
        set lossPercent 0
        if { $tx != 0 } {
            set lossPercent [ expr double($loss) / $tx ]
        }
        append resultText [ format "\n    - Traffic loss: %d packets / %0.2f %%" $loss $lossPercent ]
    }

    return $resultText
}

#----------------#
#   Test Setup   #
#----------------#



# --- Open log file
if { [ info exists ::logFd ] } {
    unset ::logFd
}
if { [ info exists logFile ] && ![ string equal $logFile "" ] } {
    if { [ file exists $logFile ] } {
        error "Log file `${logFile}' already exists, please (re)move it before running this test!"
    }
    puts "Extra logging will be done to `${logFile}'"
    set ::logFd [ open $logFile "w" ]
}

# --- Add a Server
set bb [ ByteBlower Instance.Get ]
set server [ $bb Server.Add $serverAddress ]

# --- Create 2 ByteBlower Ports
set nsiPort [ $server Port.Create $nsiPhysicalPort1 ]
set cpePortList [ list ]

for { set cpeNumber 1 } { $cpeNumber <= $numberOfCpePorts } { incr cpeNumber } {
    lappend cpePortList [ $server Port.Create $cpe(PhysicalPort$cpeNumber) ]
}

# --- ERROR handling
if { [ catch {

            # --- NSI Port Layer2 setup
            set nsiL2 [ $nsiPort Layer2.EthII.Set ]
            $nsiL2 Mac.Set $nsiMacAddress1

            # --- NSI Port Layer3 setup
            set nsiL3 [ $nsiPort Layer3.IPv4.Set ]
            if { $nsiPerformDhcp1 == 1 } {
                # --- Using DHCP
                [ $nsiL3 Protocol.Dhcp.Get ] Perform
            } else {
                # --- Using static IP
                $nsiL3 Ip.Set $nsiIpAddress1
                $nsiL3 Netmask.Set $nsiNetmask1
                $nsiL3 Gateway.Set $nsiIpGW1
            }


            for { set cpeNumber 1 } { $cpeNumber <= $numberOfCpePorts } { incr cpeNumber } { 
                set cpePort [ lindex $cpePortList [ expr $cpeNumber - 1 ] ]
                # --- CPE Port Layer2 setup
                set cpeL2 [ $cpePort Layer2.EthII.Set ]
                $cpeL2 Mac.Set $cpe(MacAddress${cpeNumber})

                # --- CPE Port Layer3 setup
                set cpeL3 [ $cpePort Layer3.IPv4.Set ]
                if { $cpe(PerformDhcp$cpeNumber) == 1 } {
                    # --- Using DHCP
                    [ $cpeL3 Protocol.Dhcp.Get ] Perform
                } else {
                    # --- Using static IP
                    $cpeL3 Ip.Set $cpe(IpAddress${cpeNumber})
                    $cpeL3 Netmask.Set $cpe(Netmask${cpeNumber})
                    $cpeL3 Gateway.Set $cpe(IpGW${cpeNumber})
                }

            }
            unset cpeL2
            unset cpeL3

            # --- Show Descriptions
            logMessage "#------------------------------------------------------------------------------#"
            logMessage "#--- Test Setup"
            logMessage "Using [ llength $cpePortList ] CPEs"
            logMessage "Frame Size (Ethernet without CRC) : ${ethernetLength} Bytes"
            logMessage "Downstream traffic rate           : ${downstreamRate} Bytes/s"
            logMessage "Upstream traffic rate             : ${upstreamRate} Bytes/s"
            logMessage "Test execution time               : ${testTime} seconds"
            logMessage "Total Downstream data             : [ expr $downstreamRate * $testTime ] Bytes"
            logMessage "Total Upstream data               : [ expr $upstreamRate * $testTime ] Bytes"
            if { [ info exists logFile ] && ![ string equal $logFile "" ] } {
                logMessage "Test Log file                     : ${logFile}"
            }
            logMessage "#------------------------------------------------------------------------------#"
            logMessage "#--- ByteBlower Server"
            logMessage [ $server Description.Get ]
            logMessage "#------------------------------------------------------------------------------#"
            logMessage "#--- NSI Port Configuration"
            logMessage [ $nsiPort Description.Get ]
            logMessage "#------------------------------------------------------------------------------#"
            set cpeNr 0
            foreach cpePort $cpePortList {
                incr cpeNr 1
                logMessage "#--- CPE Port ${cpeNr} Configuration"
                logMessage [ $cpePort Description.Get ]
                logMessage "#------------------------------------------------------------------------------#"
            }

            # --- Create UDP frames (UDP length == EthII length - 42 Bytes)

            set udpDataLength [ expr $ethernetLength - 42 ]

            set downstreamFlowList [ list ]
            set upstreamFlowList [ list ]

            foreach cpePort $cpePortList {
                set cpeL2 [ $cpePort Layer2.EthII.Get ]
                set cpeL3 [ $cpePort Layer3.IPv4.Get ]

                # --- Get the destination MAC addresses to reach the other port
                set dmacNsiPort [ $nsiL3 Protocol.Arp [ $cpeL3 Ip.Get ] ]
                set dmacCpePort [ $cpeL3 Protocol.Arp [ $nsiL3 Ip.Get ] ]

                # --- Scouting frame payload
                set scoutingFramePayload "BYTEBLOWER SCOUTING FRAME"
                if { [ binary scan $scoutingFramePayload H* scoutingFramePayloadHex ] != 1 } {
                    error "UDP flow setup error: Unable to generate ByteBlower scouting frame payload."
                }
                set scoutingFramePayloadData [ ::excentis::basic::String.To.Hex $scoutingFramePayloadHex ]

                if { $downstreamRate > 0 } {
                    # Create the downstream (UDP) scouting frame, leaving the IP and ethernet settings to default
                    set downstreamScoutingFrame [ ::excentis::basic::Frame.Udp.Set $dmacNsiPort [ $nsiL2 Mac.Get ] [ $cpeL3 Ip.Get ] [ $nsiL3 Ip.Get ] $cpeUdpPort $nsiUdpPort $scoutingFramePayloadData ]
                    
                    # --- Create the downstream UDP frame, leaving the IP and ethernet settings to default
                    set downstreamFrame [ ::excentis::basic::Frame.Udp.Set $dmacNsiPort [ $nsiL2 Mac.Get ] [ $cpeL3 Ip.Get ] [ $nsiL3 Ip.Get ] $cpeUdpPort $nsiUdpPort [ list -Length $udpDataLength ] ]

                    # --- Calculate the downstream Stream settings
                    set downstreamFrameRate [ expr double($downstreamRate) / $ethernetLength ]
                    set downstreamNumberOfFrames [ expr int(ceil($downstreamFrameRate * $testTime)) ]
                    set downstreamInterFrameGap [ expr int(floor(1000000000.0 / $downstreamFrameRate)) ] ;# [ns]

                    # --- Define the downstream Flow
                    set downstreamFlow [ list -tx [ list -port $nsiPort \
                        -scoutingframe [ list -bytes $downstreamScoutingFrame ] \
                        -frame [ list -bytes $downstreamFrame ] \
                        -numberofframes $downstreamNumberOfFrames \
                        -interframegap $downstreamInterFrameGap \
                    ] \
                        -rx [ list -port $cpePort \
                        -trigger [ list -type basic \
                        -filter "(ip.src == [ $nsiL3 Ip.Get ]) and\
                                                                      (ip.dst == [ $cpeL3 Ip.Get ]) and\
                                                                      (udp.srcport == ${nsiUdpPort}) and\
                                                                      (udp.dstport == ${cpeUdpPort}) and\
                                                                      (eth.len == ${ethernetLength})" ] \
                    ] \
                    ]

                    # --- Store the downstream Flow
                    lappend downstreamFlowList $downstreamFlow
                }

                if { $upstreamRate > 0 } {
                    # Create the upstream (UDP) scouting frame, leaving the IP and ethernet settings to default
                    set upstreamScoutingFrame [ ::excentis::basic::Frame.Udp.Set $dmacCpePort [ $cpeL2 Mac.Get ] [ $nsiL3 Ip.Get ] [ $cpeL3 Ip.Get ] $nsiUdpPort $cpeUdpPort $scoutingFramePayloadData ]
                    
                    # --- Create the upstream UDP frame, leaving the IP and ethernet settings to default
                    set upstreamFrame [ ::excentis::basic::Frame.Udp.Set $dmacCpePort [ $cpeL2 Mac.Get ] [ $nsiL3 Ip.Get ] [ $cpeL3 Ip.Get ] $nsiUdpPort $cpeUdpPort [ list -Length $udpDataLength ] ]

                    # --- Calculate the downstream Stream settings
                    set upstreamFrameRate [ expr double($upstreamRate) / $ethernetLength ]
                    set upstreamNumberOfFrames [ expr int(ceil($upstreamFrameRate * $testTime)) ]
                    set upstreamInterFrameGap [ expr int(floor(1000000000.0 / $upstreamFrameRate)) ] ;# [ns]

                    # --- Define the upstream Flow
                    set upstreamFlow [ list -tx [ list -port $cpePort \
                        -scoutingframe [ list -bytes $upstreamScoutingFrame ] \
                        -frame [ list -bytes $upstreamFrame ] \
                        -numberofframes $upstreamNumberOfFrames \
                        -interframegap $upstreamInterFrameGap \
                    ] \
                        -rx [ list -port $nsiPort \
                        -trigger [ list -type basic \
                        -filter "(ip.src == [ $cpeL3 Ip.Get ]) and\
                                                                    (ip.dst == [ $nsiL3 Ip.Get ]) and\
                                                                    (udp.srcport == ${cpeUdpPort}) and\
                                                                    (udp.dstport == ${nsiUdpPort}) and\
                                                                    (eth.len == $ethernetLength)" ] \
                    ] \
                    ]

                    # --- Store the upstream Flow
                    lappend upstreamFlowList $upstreamFlow
                }
            }

            #--------------#
            #   Test Run   #
            #--------------#

            if { $downstreamRate > 0 && $upstreamRate > 0 } {
                # --- Bi-Directional test
                logMessage "Performing Bi-directional Downstream / Upstream Test"
                # --- Return RX/TX Frame count per Flow
                set results [ ::excentis::ByteBlower::FlowLossRate [ eval list $downstreamFlowList $upstreamFlowList ] -return numbers ]
                logMessage "Bi-directional Downstream / Upstream Results: ${results}"
                set downstreamFlowListLength [ llength $downstreamFlowList ]
                # --- First part of the results is for the downstreamFlowList
                logMessage [ ::parseNumberResults downstream [ lrange $results 0 [ expr $downstreamFlowListLength - 1 ] ] ]
                # --- Second part of the results is for the upstreamFlowList
                logMessage [ ::parseNumberResults upstream [ lrange $results $downstreamFlowListLength end ] ]
                logMessage ""
            } elseif { $downstreamRate > 0 } {
                # --- Downstream test
                logMessage "Performing Downstream Test"
                # --- Return RX/TX Frame count per Flow
                set results [ ::excentis::ByteBlower::FlowLossRate $downstreamFlowList -return numbers ]
                logMessage "Uni-directional Downstream Results: {${results}}"
                logMessage [ ::parseNumberResults downstream $results ]
                logMessage ""
            } elseif { $upstreamRate > 0 } {
                # --- Upstream test
                logMessage "Performing Upstream Test"
                # --- Return RX/TX Frame count per Flow
                set results [ ::excentis::ByteBlower::FlowLossRate $upstreamFlowList -return numbers ]
                logMessage "Uni-directional Upstream Results: {${results}}"
                logMessage [ ::parseNumberResults upstream $results ]
                logMessage ""
            } else {
                logMessage "Nothing to test." stderr
            }

            #-------------------------#
            #   Other Test Examples   #
            #-------------------------#

            ##   + Uni-directional Downstream
            #if { $downstreamRate > 0 } {
            #    # --- Return Total (ALL Flows!) percentage loss
            #    set downstreamUnidir [ ::excentis::ByteBlower::FlowLossRate $downstreamFlowList ]
            #    logMessage "Downstream Unidir Results: ${downstreamUnidir}%\n"
            #
            #    # --- Return RX/TX Frame count per Flow
            #    set downstreamUnidirNumbers [ ::excentis::ByteBlower::FlowLossRate $downstreamFlowList -return numbers ]
            #    logMessage "Downstream Unidir Results returning Numbers: ${downstreamUnidirNumbers}"
            #    logMessage [ ::parseNumberResults downstream $downstreamUnidirNumbers ]
            #    logMessage ""
            #}
            #
            ##   + Uni-directional Upstream
            #if { $upstreamRate > 0 } {
            #    # --- Return Total (ALL Flows!) percentage loss
            #    set upstreamUnidir [ ::excentis::ByteBlower::FlowLossRate $upstreamFlowList ]
            #    logMessage "Upstream Unidir Results: ${upstreamUnidir}%\n"
            #
            #    # --- Return RX/TX Frame count per Flow
            #    set upstreamUnidirNumbers [ ::excentis::ByteBlower::FlowLossRate $upstreamFlowList -return numbers ]
            #    logMessage "Upstream Unidir Results returning Numbers: ${upstreamUnidirNumbers}"
            #    logMessage [ ::parseNumberResults upstream $upstreamUnidirNumbers ]
            #    logMessage ""
            #}
            #
            ##   + Bi-directional
            #if { $downstreamRate > 0 && $upstreamRate > 0 } {
            #    # --- Return Total (ALL upstream AND downstream Flows!) percentage loss
            #    set bidirResults [ ::excentis::ByteBlower::FlowLossRate [ eval list $downstreamFlowList $upstreamFlowList ] ]
            #    logMessage "Downstream / Upstream Bidir Results: ${bidirResults}%\n"
            #
            #    set bidirNumbersResults [ ::excentis::ByteBlower::FlowLossRate [ eval list $downstreamFlowList $upstreamFlowList ] -return numbers ]
            #    logMessage "Downstream / Upstream Bidir Results returning Numbers: ${bidirNumbersResults}"
            #    set downstreamFlowListLength [ llength $downstreamFlowList ]
            #    # --- First part of the results is for the downstreamFlowList
            #    logMessage [ ::parseNumberResults downstream [ lrange $bidirNumbersResults 0 [ expr $downstreamFlowListLength - 1 ] ] ]
            #    # --- Second part of the results is for the upstreamFlowList
            #    logMessage [ ::parseNumberResults upstream [ lrange $bidirNumbersResults $downstreamFlowListLength end ] ]
            #    logMessage ""
            #}
            #
            ## --- Run the test using the ::excentis::ByteBlower::ExecuteScenario directly (results are not processed immediately):
            ##   + Uni-directional Downstream
            #if { $downstreamRate > 0 } {
            #    # --- Return unparsed Stream and Trigger values
            #    set unidirResults [ ::excentis::ByteBlower::ExecuteScenario $downstreamFlowList ]
            #    logMessage "::excentis::ByteBlower::ExecuteScenario Downstream Unidir Results: ${unidirResults}\n"
            #}
            #
            ##   + Uni-directional Upstream
            #if { $upstreamRate > 0 } {
            #    # --- Return unparsed Stream and Trigger values
            #    set unidirResults [ ::excentis::ByteBlower::ExecuteScenario $upstreamFlowList ]
            #    logMessage "::excentis::ByteBlower::ExecuteScenario Upstream Unidir Results: ${unidirResults}\n"
            #}
            #
            ##   + Bi-directional
            #if { $downstreamRate > 0 && $upstreamRate > 0 } {
            #    # --- Return unparsed Stream and Trigger values
            #    set bidirResults [ ::excentis::ByteBlower::ExecuteScenario [ eval list $downstreamFlowList $upstreamFlowList ] ]
            #    logMessage "::excentis::ByteBlower::ExecuteScenario Downstream / Upstream Bidir Results: ${bidirResults}\n"
            #}

            # --- ERROR handling
        } errorMessage ] } {
    ::logMessage "Caught Exception: `${errorMessage}'" stderr
    # --- ByteBlower Exception caught?
    catch { ::logMessage "  * Message   : `[ ${errorMessage} Message.Get ]'" stderr }
    catch { ::logMessage "  * TimeStamp : `[ ${errorMessage} Timestamp.Get ]'" stderr }
    catch { ::logMessage "  * Type      :\n[ ${errorMessage} Type.Get ]" stderr }
    catch { ::logMessage "  * Trace     :\n[ ${errorMessage} Trace.Get ]" stderr }
}

#------------------#
#   Test Cleanup   #
#------------------#

foreach cpePort $cpePortList {
    $cpePort Destructor
}
$nsiPort Destructor
$server Destructor

if { [ info exists ::logFd ] } {
    close $::logFd
    unset ::logFd
}
