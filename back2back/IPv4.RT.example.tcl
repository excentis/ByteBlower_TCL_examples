# This tcl script is an example of the use of the ExecuteScenarioRT.
# This allows users to run a test and have intermediate results.
#
# This example demonstrates a callback method which will create a CSV file with intermediate results.
# Such a CSV file will look like this:
#
# timestamp,interval ,,# Frames (TX),# Frames (RX),Rate kbps (RX),Rate Mbps (RX),,# Frames (TX),,# Frames (TX),# Frames (RX),Rate kbps (RX),Rate Mbps (RX),,# Frames (TX)
# 2012-06-15 08:50:33,0 , , 2956 , 2894 , 29255 , 29, , 1, , 9049 , 8420 , 84090 , 84, , 1
# 2012-06-15 08:50:34,1 , , 6012 , 5930 , 29224 , 29, , 1, , 18263 , 16815 , 82462 , 82, , 1
# 2012-06-15 08:50:35,2 , , 9079 , 9059 , 30320 , 30, , 1, , 27511 , 26202 , 91791 , 91, , 1
#
# Such files can then be imported in your favorite spreadsheet program to create graphs, ....
#

source [ file join [ file dirname [ info script ]] .. general.proc.tcl ]

###############
# CallBack method and helper methods.
###############

# This is a global integer we use to detect where we are.
set ::RT.CSV.CallBack.interval 0;
set ::RT.CSV.Std.Header "timestamp,interval"
set ::RT.CSV.TX.Header ",# TX Frames"
set ::RT.CSV.RX.Header ",# RX Frames, Total Average RX Rate (bps), Total Average RX Rate (Mbps)"

set ::RT.CSV.CallBack.channel $outputChannel

proc ::RT.CSV.RX2CSV { rx } {
    # This method will return an RX subresult string, so
    # #NumberOfFrames, Rate (kbps), Rate (Mbps)
    ##
    set NrOfFrames 0
    set NrOfOctets 0
    set bps 0
	set Mbps 0
    foreach { type value }  $rx {
		switch -- $type {
			NrOfFrames -
			NrOfOctets {
			set $type $value
			}
		}
	}
	if { $NrOfFrames != 0 } {
        # This is not always accurate, but in most situations a very adequate
        # way of calculating the realtime speed.
        # Not good in sitations like growing size flows.
        # In the future, ByteBlower will return the TriggerOctetRate, which can be used
        # directly.
        ##
				
		#puts "NrOfFrames = $NrOfFrames"
		#puts "NrOfOctets = $NrOfOctets"
		#puts "Interval  = ${::RT.CSV.CallBack.interval}"
        #set bps [ expr ceil ( $TriggerRate *( $NrOfOctets * 8.0 / $NrOfFrames) ) ]
		set seconds [expr ${::RT.CSV.CallBack.interval} + 1]
		set bps [expr $NrOfFrames * (${::ethernetLength} + 4) * 8.0 / $seconds]
		set Mbps [ expr double( $bps / 1000000.0 ) ]
        puts "**** Average Bitrate : $bps bps"
    }
    return ", $NrOfFrames, $bps, [format "%.2f" $Mbps]"
}

proc ::RT.CSV.TX2CSV { tx } {
    set NrOfFramesSent 0;
    foreach { type value }  $tx {
		switch -- $type {
			NrOfFramesSent
			{
			set $type $value
			}
		}
    }
    return ", $NrOfFramesSent"
}

proc ::RT.CSV.CallBack { result } {
    if { [ catch {
        set headerString ${::RT.CSV.Std.Header}
        set resultString "[clock format [clock seconds] -format {%Y-%m-%d %H:%M:%S}],${::RT.CSV.CallBack.interval}";
        foreach item $result {
	        puts "************* $item"
            append headerString ","
            append resultString ","
            foreach { type value } $item {
                switch -- $type {
                    -rx {
	                    #puts "*********** $value"
                        append resultString [ ::RT.CSV.RX2CSV $value ]
                        append headerString ${::RT.CSV.RX.Header}
                    }
                    -tx {	                   
                        append resultString [ ::RT.CSV.TX2CSV $value ]
                        append headerString ${::RT.CSV.TX.Header}
                    }
                    default {
                        puts stderr "Unknown item in result : $type"
                    }
                }
            }
        }
        if { ${::RT.CSV.CallBack.interval} == 0 } {
            puts ${::RT.CSV.CallBack.channel} "$headerString"
        }
        puts ${::RT.CSV.CallBack.channel} "$resultString"
        flush ${::RT.CSV.CallBack.channel}
        incr ::RT.CSV.CallBack.interval

    } errorString ] } {
        puts stderr "Callback failed : $errorString"
        puts stderr "$::errorInfo"
    }
}

proc ::RT.CSV.ParseFinalResult { result } {
    if { [ catch {
        set resultString "[clock format [clock seconds] -format {%Y-%m-%d %H:%M:%S}],${::RT.CSV.CallBack.interval}";
        foreach item $result {
            foreach { type value } $item {
                switch -- $type {
                    -rx {
                        append resultString [ ::RT.CSV.RX2CSV $value ]
                    }
                    -tx {	                   
                        append resultString [ ::RT.CSV.TX2CSV $value ]
                    }
                    default {
                        puts stderr "Unknown item in result : $type"
                    }
                }
            }
        }
        #puts "$resultString"

    } errorString ] } {
        puts stderr "ParseFinalResult failed : $errorString"
        puts stderr "$::errorInfo"
    }
}


if { $srcPerformDhcp1 == 1 } {
    set srcIpConfig dhcpv4
} else {
    set srcIpConfig [ list $srcIpAddress1 $srcIpGW1 $srcNetmask1 ]
}

if { $dstPerformDhcp1 == 1 } {
    set dstIpConfig dhcpv4
} else {
    set dstIpConfig [ list $dstIpAddress1 $dstIpGW1 $dstNetmask1 ]
}

set bb [ ByteBlower Instance.Get ]
set server [ $bb Server.Add $serverAddress ]
set srcPort [ $server Port.Create $physicalPort1 ]
set dstPort [ $server Port.Create $physicalPort2 ]

[ $srcPort Layer2.EthII.Set ] Mac.Set  $srcMacAddress1
[ $dstPort Layer2.EthII.Set ] Mac.Set  $dstMacAddress1

eval excentis::ByteBlower::Examples::Setup.Port.Layer3 $srcPort $srcIpConfig
eval excentis::ByteBlower::Examples::Setup.Port.Layer3 $dstPort $dstIpConfig

puts "Source port:"
puts [$srcPort Description.Get]
puts "Destination port:"
puts [$dstPort Description.Get]

puts "Resolving addresses."
set interFrameGap "$interFrameGapInNs"
append interFrameGap "ns"
set flows [list [ excentis::ByteBlower::Examples::Setup.Flow.IPv4.UDP $srcPort $dstPort $ethernetLength $srcUdpPort1 $dstUdpPort1 $numberOfFrames $interFrameGap] ]
if { $bidir == 1 } {
    lappend flows [ excentis::ByteBlower::Examples::Setup.Flow.IPv4.UDP $dstPort $srcPort $ethernetLength $srcUdpPort1 $dstUdpPort1 $numberOfFrames $interFrameGap ]
}

puts "Configured all flows. We will start the test now."
set ::RT.CSV.CallBack.interval 0
set result [ ::excentis::ByteBlower::ExecuteScenarioRT $flows -extended -callback ::RT.CSV.CallBack ]

puts " ***** FINAL RESULT : "
#puts $result
# set the interval to the time when the last packets were expected to be received :
set nsPerSecond 1000000000;
set endInterval [expr ($numberOfFrames * $interFrameGapInNs / $nsPerSecond) - 1]
#puts "LAST INTERVAL = $endInterval"
set ::RT.CSV.CallBack.interval $endInterval
::RT.CSV.ParseFinalResult $result

# Cleanup :
$server Destructor
close ${::RT.CSV.CallBack.channel}
puts "Test Finished"
