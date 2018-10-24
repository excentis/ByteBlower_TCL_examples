# This tcl script contains the main script to execute a back-to-back over a NATed setup.

source [ file join [ file dirname [ info script ]] nat-WirelessEndpoint.proc.tcl ]

if { $publicPerformDhcp1 == 1 } {
    set publicIpConfig dhcpv4
} else {
    set publicIpConfig [ list $publicIpAddress1 $publicIpGW1 $publicNetmask1 ]
}

# setup for test
set setup [ BackToBackSetup $serverAddress $meetingPointAddress $publicPort1 $wirelessEndpointUUID \
                            $publicMacAddress1 $publicIpConfig $publicUdpPort1 $privateUdpPort1 \
                            $ethernetLength [ list $bidir $interFrameGap $numberOfFrames ] ]
puts "Setup done!"
set server [ lindex $setup 0 ]
set meetingpoint [ lindex $setup 1 ]
set publicPort [ lindex $setup 2 ]
set privatePort [ lindex $setup 3 ]

set flowList [ lindex $setup 4]
puts "Running..."
set result [ list ]
if { [ catch { 
    set result [ ::excentis::ByteBlower::FlowLossRate $flowList -return numbers ]
} err ] } { 
    puts stderr "Caught Exception : ${err}"
    catch { puts "Message   : [ $err Message.Get ]" } dummy
    catch { puts "Timestamp : [ $err Timestamp.Get ]" } dummy
    catch { puts "Trace :\n[ $err Trace.Get ]" } dummy

    # --- Destruct the ByteBlower Exception
    catch { $err Destructor } dummy
}
puts "Result: $result"

catch { $privatePort Lock 0 }
$server Destructor

$meetingpoint Destructor

