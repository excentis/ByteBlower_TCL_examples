# This tcl script contains procedures to execute a IGMP Querier test.
# It is intended to be used in conjunction with the following scripts:
#  * igmp.querier.conf.tcl
#  * general.proc.tcl
#  * igmp.querier.proc.tcl
#  * igmp.querier.example.tcl
#  * igmp.querier.run.tcl

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
proc logMessage { messageText { outputFd stdout } } {
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
proc parseNumberResults { direction numberResults } {
    set resultText ""

    if { [ string equal -nocase $direction "ds" ] ||\
        [ string equal -nocase $direction "downstream" ] } {
        set directionFormat "  * NSI -> CPE%u"
    } else {
        set directionFormat "  * CPE%u -> NSI"
    }

    set hostNr 0
    foreach numberResult $numberResults {
        if { $hostNr != 0 } {
            append resultText "\n"
        }
        incr hostNr 1

        append resultText [ format $directionFormat $hostNr ]

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


proc setupQuerier { querierPort } {
    logMessage "Preparing to start IGMP Querier \`${querierPort}'..."
    set querierL2 [ $querierPort Layer2.EthII.Get ]
    set querierL3 [ $querierPort Layer3.IPv4.Get ]
	
    # --- Create the General Membership Query
    set queryFrameContent [ ::excentis::basic::Frame.Igmp.Set [ $querierL2 Mac.Get ] [ $querierL3 Ip.Get ] 3 "0.0.0.0" [ list -IGMP [ list -maxRespTime $::queryResponseInterval ] ] ]

    # --- Create the IGMP Capture
    set igmpCapture [ $querierPort Rx.Capture.Basic.Add ]
    #$igmpCapture Filter.Set "igmp"
    # --- filter out Membership Query messages
    $igmpCapture Filter.Set "igmp and igmp\[0\] != 0x11"
    set ::querier(igmpCapture) $igmpCapture

    # --- Create the General Membership Query Startup Stream
    set useStartupQueries [ expr $::startupQueryCount > 1 ]
    set initialTimeToWait 0
    set ::querier(useStartupQueries) $useStartupQueries
    if { $useStartupQueries } {
        set querierStartupStream [ $querierPort Tx.Stream.Add ]
        $querierStartupStream InitialTimeToWait.Set 0
        $querierStartupStream NumberOfFrames.Set [ expr $::startupQueryCount - 1 ]
        $querierStartupStream InterFrameGap.Set "${::startupQueryInterval}s"

        # --- Configure the General Membership Query Frame
        set querierStartupFrame [ $querierStartupStream Frame.Add ]
        $querierStartupFrame Bytes.Set $queryFrameContent
        set ::querier(startupStream) $querierStartupStream

        incr initialTimeToWait [ expr $::startupQueryCount * $::startupQueryInterval ]
    }

    set querierStream [ $querierPort Tx.Stream.Add ]
    $querierStream InitialTimeToWait.Set "${initialTimeToWait}s"
    # --- Configure an 'infinite' Stream
    $querierStream NumberOfFrames.Set -1
    $querierStream InterFrameGap.Set "${::queryInterval}s"

    # --- Configure the General Membership Query Frame
    set querierFrame [ $querierStream Frame.Add ]
    $querierFrame Bytes.Set $queryFrameContent

    set ::querier(stream) $querierStream

    return
}

proc startQuerier { querierPort } {
    logMessage "Starting IGMP Querier \`${querierPort}'"

    # --- Start the IGMP Capture
    $::querier(igmpCapture) Start

    if { $::querier(useStartupQueries) } {
        # --- Start the IGMP Querier Startup General Membership Queries
        $::querier(startupStream) Start
    }

    # --- Start the IGMP Querier Main General Membership Queries
    $::querier(stream) Start
}

proc runQuerier { querierPort runTime } {
    logMessage "Running IGMP Querier \`${querierPort}' for ${runTime} seconds..."
    set querierL2 [ $querierPort Layer2.EthII.Get ]
    set querierL3 [ $querierPort Layer3.IPv4.Get ]

    set previousNrOfPackets 0
    set startTime [ clock seconds ]

    set igmpCapture $::querier(igmpCapture)
    set igmpCaptureResult [ $igmpCapture Result.Get ]
    
    while { [ clock seconds ] < [ expr $startTime + $runTime ] } {
        # --- Wait for next interval
        set ::querier(waitCondition) 0
        after 500 { set ::querier(waitCondition) 1 }
        vwait ::querier(waitCondition)

        # --- Check the IGMP Capture Status
        set nrOfPackets ""
        
        $igmpCaptureResult Refresh
        logMessage "IGMP capture status:"
        set state [ $igmpCaptureResult State.Name.Get ]


        logMessage [ format "  - %-20s : %s" "state" $state ]
        if { ![ string equal -nocase $state "active" ] } {
            logMessage [ format "  - ERROR : %-12s : %s (should be active!)" "state" $state ] stderr
        }
        
        set elapsedtime [ $igmpCaptureResult CaptureDuration.Get ]
        logMessage [ format "  - %-20s : %s" "elapsedtime" $elapsedtime ]
        
        set nrOfPackets [ $igmpCaptureResult PacketCount.Get ]
        

        # --- Check if we captured new IGMP frame(s)
        if { ![ string equal $nrOfPackets "" ] && $nrOfPackets != $previousNrOfPackets } {
            logMessage "Got [ expr $nrOfPackets - $previousNrOfPackets ] new Frame(s)!"
            set frames [ $igmpCaptureResult Frames.Get ]
            #logMessage "Got Frames: $frames"

            # --- Process the new IGMP frame(s)
            for {} { $previousNrOfPackets < $nrOfPackets } { incr previousNrOfPackets 1 } {
                set newFrame [ lindex $frames $previousNrOfPackets ]
                
                if { [ string equal "$newFrame" "" ] } {
                    continue
                }
                
                logMessage "  - NEW Frame is : $newFrame"

                set ts [ $newFrame Timestamp.Get ]
                set tv_sec [ expr $ts / 1000000000 ]
                set tv_nsec [ expr $ts % 1000000000 ]
                set tv_usec [ expr $tv_nsec / 1000 ]
                #set errorcode [ lindex $newFrame 2 ]
                set length [ $newFrame Length.Get ]
                set bytes [ $newFrame Bytes.Get ]

                # --- Start processing the frame data
                set ipHdrLength [ expr "0x0[ string index $bytes 29 ]" << 2 ] ;# IP Header length = ( ip[14] & 0x0f ) << 2
                logMessage "  - IP Header Length : ${ipHdrLength}"
                set igmpOffset [ expr 14 + ${ipHdrLength} ]
                logMessage "  - IGMP offset : ${igmpOffset}"
                set igmpType "0x[ string range $bytes [ expr 2 * ${igmpOffset} ] [ expr ( 2 * ${igmpOffset} ) + 1 ] ]"
                logMessage "  - IGMP type : ${igmpType}"

                # --- Get the Multicast Group Address (igmp[4:4])
                set hexGroupAddress [ string range $bytes [ expr ( 2 * ${igmpOffset} ) + 8 ] [ expr ( 2 * ${igmpOffset} ) + 15 ] ]
                set groupAddress [ ::excentis::basic::Hex.To.IP $hexGroupAddress ]
                logMessage "  - IGMP Group Address : ${groupAddress}"

                # --- Check if we have a IGMPv2 Leave
                if { $igmpType == 0x17 } {
                    logMessage "Received IGMPv2 Leave Group for \`${groupAddress}'"
                    # --- Setup a Stream for the Group-Specific Membership Query
                    if { [ info exists ::querier(groupSpecificQueryStream,${groupAddress}) ] } {
                        logMessage "Continuing/restarting Group-Specific Queries for \`${groupAddress}'"
                        set groupSpecificQueryStream $::querier(groupSpecificQueryStream,${groupAddress})
                    } else {
                        logMessage "Starting Group-Specific Queries for \`${groupAddress}'"
                        # --- Create the Group-Specific Membership Query
                        set groupSpecificQueryContent [ ::excentis::basic::Frame.Igmp.Set [ $querierL2 Mac.Get ] [ $querierL3 Ip.Get ] 4 ${groupAddress} [ list -IGMP [ list -maxRespTime $::lastMemberQueryInterval ] ] ]

                        # --- Create the Group-Specific Membership Query Stream
                        set groupSpecificQueryStream [ $querierPort Tx.Stream.Add ]

                        # --- Configure the Group-Specific Membership Query Stream
                        $groupSpecificQueryStream InitialTimeToWait.Set 0
                        $groupSpecificQueryStream NumberOfFrames.Set ${::lastMemberQueryCount}
                        $groupSpecificQueryStream InterFrameGap.Set "[ expr 100 * ${::lastMemberQueryInterval} ]ms"

                        # --- Configure the Group-Specific Membership Query Frame
                        set groupSpecificQueryFrame [ $groupSpecificQueryStream Frame.Add ]
                        $groupSpecificQueryFrame Bytes.Set $groupSpecificQueryContent
                    }

                    # --- Start to send Group-Specific Multicast Member Queries
                    $groupSpecificQueryStream Start
                }

                # --- Check if we have an IGMPv2 Join
                if { $igmpType == 0x16 } {
                    logMessage "Received IGMPv2 Membership Report for \`${groupAddress}'"
                    if { [ info exists ::querier(groupSpecificQueryStream,${groupAddress}) ] } {
                        logMessage "Stopping Group-Specific Queries for \`${groupAddress}'"
                        # --- Stop to send Group-Specific Multicast Member Queries
                        $::querier(groupSpecificQueryStream,${groupAddress}) Stop
                    }
                }
            }

            # --- Not really required
            #set previousNrOfPackets $nrOfPackets
        }
    }
    logMessage "Shutting down IGMP Querier \`${querierPort}'"

    # --- Cleanup Group-Specific Membership Query Streams
    foreach item [ array names ::querier groupSpecificQueryStream,* ] {
        logMessage "Stopping Group-Specific Queries for \`${groupAddress}'"
        $::querier($item) Stop
        $::querier($item) Destructor
        unset ::querier($item)
    }

    # --- all done!
    logMessage "Finished running IGMP Querier \`${querierPort}' successfully"
    return
}

proc stopQuerier { querierPort } {
    logMessage "Stopping IGMP Querier \`${querierPort}'"

    # -- Stop and cleanup the IGMP Capture
    set igmpCapture $::querier(igmpCapture)
    $igmpCapture Stop

    # --- Store the captured IGMP packets to a file?
    if { [ info exists ::querierDebugCapture ] && ![ string equal $::querierDebugCapture "" ] } {
        set querierDebugCaptureFile "${::querierDebugCapture}.${querierPort}.pcap"
        logMessage "Storing IGMP Querier \`${querierPort}' captured IGMP frames to \`${querierDebugCaptureFile}'."
        set igmpCaptureResult [ $igmpCapture Result.Get ]
        $igmpCaptureResult Refresh
        if { [ catch { $igmpCaptureResult Pcap.Save ${querierDebugCaptureFile} } errorMessage ] } {
            set errorTrace $::errorInfo
            logMessage "Could not store IGMP Querier \`${querierPort}' captured IGMP frames: \`${errorMessage}'" stderr
            logMessage "Trace:" stderr
            logMessage $errorTrace stderr
        }
    }

    $igmpCapture Destructor
    unset ::querier(igmpCapture)

    if { $::querier(useStartupQueries) } {
        # -- Stop and cleanup the Startup General Membership Query Stream
        set querierStartupStream $::querier(startupStream)
        $querierStartupStream Stop
        $querierStartupStream Destructor
        unset ::querier(startupStream)
    }
    unset ::querier(useStartupQueries)

    # -- Stop and cleanup the Main General Membership Query Stream
    set querierStream $::querier(stream)
    $querierStream Stop
    $querierStream Destructor
    unset ::querier(stream)

    # --- all done!
    logMessage "IGMP Querier \`${querierPort}' stopped sucessfully!"
    return
}

proc hostPrintIgmpStats { hostPort } {
    set hostL3 [ $hostPort Layer3.IPv4.Get ]
    set igmpProtocol [ $hostL3 Protocol.Igmp.Get ]
    set igmpProtocolInfo [ $igmpProtocol Protocol.Info.Get ]
	set igmpSessions [ $igmpProtocol Session.Get ]
    
    set retVal [list ]
    logMessage "IGMP Host \`[ $hostL3 Ip.Get ]' IGMP statistics:"
    
	
	set sessionMethodNameList [ list \
		"TxIgmpFrames"              "Tx.Get" \
		"TxIgmpv1MembershipReports" "Tx.V1.Reports.Get" \
		"TxIgmpv2MembershipReports" "Tx.V2.Reports.Get" \
		"TxIgmpv2LeaveGroups"       "Tx.V2.Leaves.Get" \
		"TxIgmpv3MembershipReports" "Tx.V3.Reports.Get" \
		"RxIgmpFrames"              "Rx.Get" \
		"RxIgmpv1MembershipReports" "Rx.V1.Reports.Get" \
		"RxIgmpv2MembershipReports" "Rx.V2.Reports.Get" \
	]
    
    foreach igmpSession $igmpSessions {
		set igmpSessionInfo [ $igmpSession Session.Info.Get ]
		set groupAddress [ $igmpSession Multicast.Address.Get ]
		
		
        logMessage "  * Statistics for Multicast Group \`${groupAddress}'"
        foreach { name method } $sessionMethodNameList {
        	set value [ $igmpSessionInfo $method ]
            puts [ format "    - %-30s : %s" $name $value ]
			lappend retVal [list $name $value]        	
        }
        		
    }
    

    return $retVal
}

proc printIgmpStatistics { hostPortList } {
    set retVal [list ]
	foreach hostPort $hostPortList {
        lappend retVal [ hostPrintIgmpStats $hostPort ]
    }

    return $retVal
}

proc hostStartListening { hostPort groupAddress igmpVersion } {
    set hostL3 [ $hostPort Layer3.IPv4.Get ]
    set igmpProtocol [ $hostL3 Protocol.Igmp.Get ]
    set igmpSession [ $igmpProtocol Session.V${igmpVersion}.Add $groupAddress ]
    switch -- $igmpVersion {
    	1 - 2 {
    		$igmpSession Join
    	}
    	3 {
    		$igmpSession Multicast.Listen exclude {}
    	}
    }

    # --- all done!
    logMessage "IGMPv${igmpVersion} Host \`[ $hostL3 Ip.Get ]' Joins Multicast Group Address `${groupAddress}'"
    return
}

proc startListening { hostPortList initialTimeToWait joinInterval groupAddress { igmpVersion 2 } } {
    set waitTime $initialTimeToWait
    foreach hostPort $hostPortList {
        logMessage "Next IGMP Host will wait for ${waitTime} seconds to Join \`${groupAddress}'"

        after [ expr 1000 * $waitTime ]
		hostStartListening $hostPort $groupAddress $igmpVersion

        incr waitTime $joinInterval
    }

    # --- all done!
    logMessage "IGMP Hosts successfully scheduled to Join \`${groupAddress}'!"
    return
}

#
# Procedure to search the IGMP session object for the given host port
#
proc hostGetIgmpSession { hostPort groupAddress igmpVersion } {
    set hostL3 [ $hostPort Layer3.IPv4.Get ]
	set igmpProtocol [ $hostL3 Protocol.Igmp.Get ]
	
	# Search in all known IGMP session on the port for an IGMP session object
	# which is of the correct version.
	# If the version is correct, and the IGMP Sessions Multicast Group Address
	# is the same as in the argument of this procedure, we have found the 
	# IGMP session
	foreach igmpSession [ $igmpProtocol Session.Get ] {
		if { [ $igmpSession Info -implements Layer4.Igmpv${igmpVersion}MemberSession ] 
			&& [ $igmpSession Multicast.Address.Get ] == $groupAddress } {
			return $igmpSession
		}
	}

}
proc hostStopListening { hostPort groupAddress igmpVersion } {
    set hostL3 [ $hostPort Layer3.IPv4.Get ]
    set igmpSession [ hostGetIgmpSession $hostPort $groupAddress $igmpVersion ]
    switch -- $igmpVersion {
    	1 - 2 {
    		$igmpSession Leave
    	}
    	3 {
    		$igmpSession Multicast.Listen include {}
    	}
    }

    # --- all done!
    logMessage "IGMPv${igmpVersion} Host \`[ $hostL3 Ip.Get ]' Leaves Multicast Group Address `${groupAddress}'"
    return
}

proc stopListening { hostPortList initialTimeToWait leaveInterval groupAddress { igmpVersion 2 } } {
    set waitTime $initialTimeToWait
    foreach hostPort $hostPortList {
        logMessage "Next IGMP Host will wait for ${waitTime} seconds to Leave \`${groupAddress}'"

        after [ expr 1000 * $waitTime ] 
		hostStopListening $hostPort $groupAddress $igmpVersion

        incr waitTime $leaveInterval
    }

    # --- all done!
    logMessage "IGMP Hosts successfully scheduled to Leave \`${groupAddress}'!"
    return
}

proc startMulticastTraffic { sourcePort hostPortList groupAddress initialTimeToWait testTime multicastTrafficRate ethernetLength multicastDstUdpPort multicastSrcUdpPort } {
    set sourceL2 [ $sourcePort Layer2.EthII.Get ]
    set sourceL3 [ $sourcePort Layer3.IPv4.Get ]

    # --- Create UDP frames (UDP length == EthII length - 42 Bytes)
    set udpDataLength [ expr $ethernetLength - 42 ]

    # --- Create the multicast data (UDP) frame, leaving the IP and ethernet settings to default
    set multicastDmac [ ::excentis::basic::Multicast.IP.To.Mac $groupAddress ]
    set multicastDataFrameContent [ ::excentis::basic::Frame.Udp.Set $multicastDmac [ $sourceL2 Mac.Get ] $groupAddress [ $sourceL3 Ip.Get ] $multicastDstUdpPort $multicastSrcUdpPort [ list -Length $udpDataLength ] ]

    # --- Calculate the multicast Stream settings
    set multicastFrameRate [ expr double($multicastTrafficRate) / $ethernetLength ]
    set multicastNumberOfFrames [ expr int(ceil($multicastFrameRate * $testTime)) ]
    set multicastInterFrameGap [ expr int(floor(1000000000.0 / $multicastFrameRate)) ] ;# [ns]

    # --- Define the multicast Flow
    set multicastStream [ $sourcePort Tx.Stream.Add ]
    $multicastStream NumberOfFrames.Set $multicastNumberOfFrames
    $multicastStream InterFrameGap.Set $multicastInterFrameGap
    set multicastFrame [ $multicastStream Frame.Add ]
    $multicastFrame Bytes.Set $multicastDataFrameContent

    set ::traffic(sourcePort) $sourcePort
    set ::traffic(stream) $multicastStream

    # --- Add the triggers for the multicast traffic at the IGMP Hosts
    set ::traffic(triggers) [ list ]
    foreach hostPort $hostPortList {
        set multicastTrigger [ $hostPort Rx.Trigger.Basic.Add ]
        # --- (1) Using 'display' filters
        #$multicastTrigger Filter.Set [ ::excentis::basic::ParseFilter "(ip.src == [ $sourceL3 Ip.Get ]) and\
        #                              (ip.dst == ${groupAddress}) and\
        #                              (udp.srcport == ${multicastSrcUdpPort}) and\
        #                              (udp.dstport == ${multicastDstUdpPort}) and\
        #                              (eth.len == ${ethernetLength})" ]
        # --- (2) Using 'capture' filters
        $multicastTrigger Filter.Set "ip src [ $sourceL3 Ip.Get ] and\
                                      ip dst ${groupAddress} and\
                                      udp src port ${multicastSrcUdpPort} and\
                                      udp dst port ${multicastDstUdpPort} and\
                                      len == ${ethernetLength}"
        lappend ::traffic(triggers) $hostPort $multicastTrigger
    }

    # --- Start sending the multicast traffic
    $multicastStream Start

    return
}

proc stopMulticastTraffic { } {
# @return list of traffic results, identical to the result list obtained
#         from ::excentis::ByteBlowerHL::FlowLossRate $flowList -return numbers
#
    set sourcePort $::traffic(sourcePort)
    set multicastStream $::traffic(stream)

    $multicastStream Stop

    return
}

proc getMulticastTrafficResults { } {
# @return list of traffic results, identical to the result list obtained
#         from ::excentis::ByteBlowerHL::FlowLossRate $flowList -return numbers
#
    set sourcePort $::traffic(sourcePort)
    set multicastStream $::traffic(stream)

    set results [ list ]

    logMessage "Source Port \`[ [ $sourcePort Layer3.IPv4.Get ] Ip.Get ]' TX Counters:"
    set streamResult [ $multicastStream Result.Get ]
    $streamResult Refresh
    set txFrames [ $streamResult PacketCount.Get ]
    puts [ format "  - %-30s : %s" "NrOfFramesSent" $txFrames ]
    
    

    foreach { hostPort multicastTrigger } $::traffic(triggers) {
        logMessage "IGMP Host Port \`[ [ $hostPort Layer3.IPv4.Get ] Ip.Get ]' RX Counters:"
        set triggerResult [ $multicastTrigger Result.Get ]
        $triggerResult Refresh

        set rxFrames [ $triggerResult PacketCount.Get ]
        puts [ format "  - %-30s : %s" "NrOfFrames" $rxFrames ]
        lappend results [ list -tx $txFrames -rx $rxFrames ]
    }

    return $results
}

proc cleanupMulticastTraffic { } {
    unset ::traffic(sourcePort)
    $::traffic(stream) Destructor
    unset ::traffic(stream)

    foreach { hostPort multicastTrigger } $::traffic(triggers) {
        $multicastTrigger Destructor
    }
    unset ::traffic(triggers)

    return
}

proc IGMP.Querier.Setup {args} {
	#----------------#
	#   Test Setup   #
	#----------------#
	set paramList [list serverAddress querierPhysicalPort hostPhysicalPortList querierMacAddress hostMacAddressBase querierPerformDhcp querierIpAddress querierNetmask querierIpGW hostPerformDhcp hostIpAddressBase hostNetmask hostIpGW multicastGroupAddress robustnessVariable queryInterval queryResponseInterval groupMembershipInterval otherQuerierPresentInterval startupQueryInterval startupQueryCount lastMemberQueryInterval lastMemberQueryCount unsolicitedReportInterval version1RouterPresentTimeout ethernetLength multicastSrcUdpPort multicastDstUdpPort trafficRate testTime hostJoinTime hostJoinInterval hostLeaveTime hostLeaveInterval querierDebugCapture logFile]
	for { set i 0 } { $i < [llength $args] } {incr i} { 
		puts "set [lindex $paramList $i] [lindex $args $i]"
		set [lindex $paramList $i] [lindex $args $i]
	}
	
	# --- Do some sanity checks
	if { [ llength $hostPhysicalPortList ] < 1 } {
		error "There are no hostPhysicalPorts defined!"
	}

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
	set querierPort [ $server Port.Create $querierPhysicalPort ]
	set hostPortList [ list ]
	foreach hostPhysicalPort $hostPhysicalPortList {
		lappend hostPortList [ $server Port.Create $hostPhysicalPort ]
	}

# --- ERROR handling
if { [ catch {
    # --- IGMP Querier Port Layer2 setup
    set querierL2 [ $querierPort Layer2.EthII.Set ]
    $querierL2 Mac.Set $querierMacAddress

    # --- IGMP Querier Port Layer3 setup
    set querierL3 [ $querierPort Layer3.IPv4.Set ]
    if { $querierPerformDhcp == 1 } {
        # --- Using DHCP
        set querierDhcp [ $querierL3 Protocol.Dhcp.Get ]
        $querierDhcp Perform
    } else {
        # --- Using static IP
        $querierL3 Ip.Set $querierIpAddress
        $querierL3 Netmask.Set $querierNetmask
        $querierL3 Gateway.Set $querierIpGW
    }

    # --- Initializing IGMP Host addresses
    set hostMacAddress $hostMacAddressBase
    if { $hostPerformDhcp != 1 } {
        set hostIpAddress $hostIpAddressBase
    }

    foreach hostPort $hostPortList {
        # --- IGMP Host Port Layer2 setup
        set hostL2 [ $hostPort Layer2.EthII.Set ]
        $hostL2 Mac.Set $hostMacAddress

        # --- IGMP Host Port Layer3 setup
        set hostL3 [ $hostPort Layer3.IPv4.Set ]
        if { $hostPerformDhcp == 1 } {
            # --- Using DHCP
            set hostDhcp [ $hostL3 Protocol.Dhcp.Get ]
            $hostDhcp Perform
        } else {
            # --- Using static IP
            $hostL3 Ip.Set $hostIpAddress
            $hostL3 Netmask.Set $hostNetmask
            $hostL3 Gateway.Set $hostIpGW

            # --- Next IGMP Host IP Address
            set hostIpAddress [ ::excentis::basic::IP.Increment $hostIpAddress ]
        }

        # --- Next IGMP Host MAC Address
        set hostMacAddress [ ::excentis::basic::Mac.Increment $hostMacAddress ]
    }
    unset hostL2
    unset hostL3
    catch { unset hostIpAddress }
    unset hostMacAddress

    # --- Initialize the IGMP Querier	
		
    setupQuerier $querierPort

    # --- Show Descriptions
    logMessage "#------------------------------------------------------------------------------#"
    logMessage "#--- Test Setup"
    logMessage "Using [ llength $hostPortList ] IGMP Hosts"
    logMessage "Frame Size (Ethernet without CRC) : ${ethernetLength} Bytes"
    logMessage "Multicast traffic rate            : ${trafficRate} Bytes/s"
    logMessage "Test execution time               : ${testTime} seconds"
    logMessage "Total Multicast data              : [ expr $trafficRate * $testTime ] Bytes"
    if { [ info exists logFile ] && ![ string equal $logFile "" ] } {
        logMessage "Test Log file                     : ${logFile}"
    }
    logMessage "#------------------------------------------------------------------------------#"
    logMessage "#--- ByteBlower Server"
    logMessage [ $server Description.Get ]
    logMessage "#------------------------------------------------------------------------------#"
    logMessage "#--- IGMP Querier Port Configuration"
    logMessage [ $querierPort Description.Get ]
    logMessage "#------------------------------------------------------------------------------#"
    set hostNr 0
    foreach hostPort $hostPortList {
        incr hostNr 1
        logMessage "#--- IGMP Host Port ${hostNr} Configuration"
        logMessage [ $hostPort Description.Get ]
        logMessage "#------------------------------------------------------------------------------#"
    }

    # --- Send out ARPs
    foreach hostPort $hostPortList {
        set hostL3 [ $hostPort Layer3.IPv4.Get ]

        # --- Get the destination MAC addresses to reach the other port
        set dmacNsiPort [ $querierL3 Protocol.Arp [ $hostL3 Ip.Get ] ]
        set dmacCpePort [ $hostL3 Protocol.Arp [ $querierL3 Ip.Get ] ]
    }
    
	# --- ERROR handling
	} errorMessage ] } {
        puts stderr $::errorInfo
		logMessage "Caught Exception: `${errorMessage}'" stderr
		# --- ByteBlower Exception caught?
		catch { logMessage "  * Message   : `[ ${errorMessage} Message.Get ]'" stderr }
		catch { logMessage "  * TimeStamp : `[ ${errorMessage} Timestamp.Get ]'" stderr }
		catch { logMessage "  * Type      :\n[ ${errorMessage} Type.Get ]" stderr }
		catch { logMessage "  * Trace     :\n[ ${errorMessage} Trace.Get ]" stderr }	
	}
	return [ list $server $querierPort $hostPortList ]
}

proc IGMP.Querier.Run { querierPort hostPortList hostJoinTime hostJoinInterval multicastGroupAddress hostLeaveTime hostLeaveInterval trafficRate testTime ethernetLength multicastDstUdpPort multicastSrcUdpPort } {
    #--------------#
    #   Test Run   #
    #--------------#

	if { [ catch {
		# --- Start the IGMP Querier
		startQuerier ${querierPort}

		logMessage "Scheduling [ llength $hostPortList ] IGMP Hosts to Join Multicast Group Address \`${multicastGroupAddress}'"
		startListening $hostPortList $hostJoinTime $hostJoinInterval $multicastGroupAddress

		logMessage "Scheduling [ llength $hostPortList ] IGMP Hosts to Leave Multicast Group Address \`${multicastGroupAddress}' after ${hostLeaveTime}s"
		stopListening $hostPortList $hostLeaveTime $hostLeaveInterval $multicastGroupAddress

		if { $trafficRate > 0 } {
			# --- Downstream test
			logMessage "Sending multicast traffic"
			startMulticastTraffic $querierPort $hostPortList $multicastGroupAddress $hostJoinTime $testTime $trafficRate $ethernetLength $multicastDstUdpPort $multicastSrcUdpPort
		} else {
			logMessage "No multicast traffic will be sent." stderr
		}

		runQuerier $querierPort $testTime

		if { $trafficRate > 0 } {
			logMessage "Stopping multicast traffic"
			stopMulticastTraffic

			logMessage "Waiting 1 second for last packets to arrive at IGMP Host..."
			set ::mainWaitcondition 0
			after 1000 { set ::mainWaitcondition 1 }
			vwait ::mainWaitcondition

			# --- Getting Downstream test results
			logMessage "Getting multicast traffic results"
			set trafficResults [ getMulticastTrafficResults ]
			logMessage "Multicast Traffic Results: {${trafficResults}}"
			logMessage ""
			logMessage [ parseNumberResults "downstream" $trafficResults ]
			logMessage ""

			# --- Cleanup
			cleanupMulticastTraffic
		} else {
			logMessage "No downstream multicast traffic result to be processed."
		}

		# --- Stop and Cleanup IGMP Querier
		stopQuerier $querierPort

		logMessage ""
		puts [set stats [printIgmpStatistics $hostPortList]]
		logMessage ""

	# --- ERROR handling
	} errorMessage ] } {
		logMessage "Caught Exception: `${errorMessage}'" stderr
		# --- ByteBlower Exception caught?
		catch { logMessage "  * Message   : `[ ${errorMessage} Message.Get ]'" stderr }
		catch { logMessage "  * TimeStamp : `[ ${errorMessage} Timestamp.Get ]'" stderr }
		catch { logMessage "  * Type      :\n[ ${errorMessage} Type.Get ]" stderr }
		catch { logMessage "  * Trace     :\n[ ${errorMessage} Trace.Get ]" stderr }
	}
	if { [ info exists ::logFd ] } {
		close $::logFd
		unset ::logFd
	}
	return [list [list $trafficResults ] [list $stats ] ]
}
