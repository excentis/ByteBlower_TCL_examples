##
#
# This tcl script contains procedures to setup, execute and clean up a back-to-
# back latency scenario.
#
##

# This script uses the shared procedures of the example scripts, so we include
# that file.
source [ file join [ file dirname [ info script ]] .. general.proc.tcl ]

##
# This procedure creates a everything needed to run a back-2-back latency
# scenario using the higher layer: a ByteBlower server, two ByteBlower ports and
# a flow between them with latency enabled. All required information to create
# these objects is pased as parameters. The created objects and configurations
# are returned.
#
# @param meetingpointAddress
#           Address of the ByteBlower MeetingPoint server.
# @param wirelessEndpointUUID
#           UUID of the ByteBlower Wireless Endpoint
# @param serverAddress
#           The IP address or FQDN of the ByteBlower server.
# @param srcPhysicalPort
#           The physical port (interface) on which the source port will be
#           created.
# @param srcMacAddress
#           The Layer 2 MAC address of the ByteBlower source port.
# @param srcIpConfig
#           The Layer 3 configuration of the ByteBlower source port. To use an
#           automated address, use the value 'dhcpv4'. To use a fixed address,
#           use a list of three elements: address, gateway address and netmask.
#           @example [ list dhcpv4 ]
#           @example [ list <port-ip> <gateway-ip> <netmask> ]
# @param srcUdpPort
#           The Layer 4 UDP source port for the traffic between the two
#           ByteBlower ports.
# @param dstUdpPort
#           The Layer 4 UDP destination port for the traffic between the two
#           ByteBlower ports.
# @param ethernetLength
#           The length of the ethernet frames sent between the two ByteBlower
#           ports.
# @param flowParam
#           The flow settings.
#           @list
#               A list of three elements: a boolean flag indicating whether the
#               traffic should be unidirectional (value 0) or bidirectional 
#               (value 1), the interframegap in nanoseconds and the number of 
#               frames that have to be sent.
# @return
#       The created objects for the latency scenario.
#       @list
#           The return list consists of 4 elements: the ByteBlower server object
#           (1), the ByteBlower source port (2) and destination port (3) and the
#           higher-layer flow configuration (4). The flow configuration consists
#           of a single TX part with enabled latency and a single RX part with
#           a latency detector.
#
proc Latency.Setup { meetingpointAddress wirelessEndpointUUID serverAddress srcPhysicalPort srcMacAddress srcIpConfig srcUdpPort dstUdpPort ethernetLength flowParam } {
    # Parse flow parameters
    set bidir [lindex $flowParam 0 ]
    set interFrameGap [lindex $flowParam 1 ]
    set numberOfFrames [lindex $flowParam 2 ]

    # Create server and ports
    set bb [ ByteBlower Instance.Get ]
    
    set server [ $bb Server.Add $serverAddress ]
    set srcByteBlowerPort [ $server Port.Create $srcPhysicalPort ]

    # Configure layer 2
    [ $srcByteBlowerPort Layer2.EthII.Set ] Mac.Set  $srcMacAddress

    # Configure layer 3, using the shared support methods of the example scripts
    eval excentis::ByteBlower::Examples::Setup.Port.Layer3 $srcByteBlowerPort $srcIpConfig
   
    # Debug prints
    puts "Source port:"
    puts [$srcByteBlowerPort Description.Get]
    
    # --- Connect to the MeetingPoint Server
    set meetingpoint [ $bb MeetingPoint.Add $meetingpointAddress ]

    # --- Get the specified device
    set wirelessEndpoint [ $meetingpoint Device.Get $wirelessEndpointUUID ]
    
    puts "Wireless Endpoint:"
    puts [$wirelessEndpoint Description.Get]
    
    # Create a basic flow with latency (two if bidirectional traffic requested), using the shared support methods of the example scripts
    puts "Creating source -> destination flow with latency enabled"
    set latencyEnabled 1
    set outofsequenceEnabled 0
    set flowList [list] 
    lappend flowList [ excentis::ByteBlower::Examples::Setup.Flow.IPv4.UDP $srcByteBlowerPort $wirelessEndpoint $ethernetLength $srcUdpPort $dstUdpPort \
                                                                                $numberOfFrames $interFrameGap $latencyEnabled $outofsequenceEnabled ]
    if { $bidir == 1 } {
	    puts "Creating destination <- source flow with latency enabled (bidir)"
	    lappend flowList [ excentis::ByteBlower::Examples::Setup.Flow.IPv4.UDP $wirelessEndpoint $srcByteBlowerPort $ethernetLength $srcUdpPort $dstUdpPort \
	                                                                            $numberOfFrames $interFrameGap $latencyEnabled $outofsequenceEnabled ]
    }
    
    # Return the created objects and the flow configuration
    return [ list $server $srcByteBlowerPort $meetingpoint $wirelessEndpoint $flowList ]
}

##
# This procedure calls the latency tool in the higher layer with predefined 
# arguments and the created scenario configuration.
#
# @param flowList
#           The scenario configuration expected by the ByteBlowerHL API. See
#           Latency.Setup and ExecuteScenario for more information.
# @return
#           The return value of the ByteBlowerHL latency method. In this example
#           it has a fixed structured.
#           @list
#               A list of one flow result for the unidirectional case and two
#               flow results for the bidirectional case. Each flow result is
#               itself a list consisting of 4 elements of which one is another
#               list: '-tx <sentFrames> -rx { <receivedFrames> <minLatency> 
#               <avgLatency> <maxLatency> <jitter> }'. 
#
proc Latency.Execute { flowList } {
    if { [ catch {
        # Just call the corresponding ByteBlowerHL method.
        set result [ ::excentis::ByteBlower::FlowLatency $flowList -return numbers ]
    } result ] } {
        puts stderr "Caught Exception : ${result}"
        catch { puts "Message   : [ $result Message.Get ]" } dummy
        catch { puts "Timestamp : [ $result Timestamp.Get ]" } dummy
        catch { puts "Trace :\n[ $result Trace.Get ]" } dummy

        # --- Destruct the ByteBlower Exception
        catch { $result Destructor } dummy
        set result "error"
    }
    return $result
}

##
# This procedure cleans up the created objects. Note any other objects were
# cleaned by the ByteBlowerHL, which leaves ByteBlower ports in the same state
# as at the start of a scenario.
#
# @param server
#           The ByteBlower server object.
# @param srcPort
#           The ByteBlower port object that was the source.
# @param dstPort
#           The ByteBlower port object that was the destination.
#
proc Latency.Cleanup { setup } {
    # Call destructor on created objects. Possible errors are ignored.
    set server [ lindex $setup 0 ]
    set srcPort [ lindex $setup 1 ]
    set meetingpoint [ lindex $setup 2 ]
    set dstPort [ lindex $setup 3 ]
    
    catch { $srcPort Destructor } dummy
    catch { $server Destructor } dummy
    catch { $dstPort Lock 0 } dummy    
    catch { $dstPort Destructor } dummy
    catch { $meetingpoint Destructor } dummy

}
