##
#
# This tcl script contains procedures to setup, execute and clean up a back-to-
# back out of sequence scenario.
#
##

# This script uses the shared procedures of the example scripts, so we include
# that file.
source [ file join [ file dirname [ info script ]] .. general.proc.tcl ]

##
# This procedure creates a everything needed to run a back-2-back out of
# sequence scenario using the higher layer: a ByteBlower server, two ByteBlower
# ports and a flow between them with out of sequence detection enabled. All
# required information to create these objects is pased as parameters. The
# created objects and configurations are returned.
#
# @param serverAddress
#           The IP address or FQDN of the ByteBlower server.
# @param srcPhysicalPort
#           The physical port (interface) on which the source port will be
#           created.
# @param dstPhysicalPort
#           The physical port (interface) on which the destination port will be
#           created.
# @param srcMacAddress
#           The Layer 2 MAC address of the ByteBlower source port.
# @param dstMacAddress
#           The Layer 2 MAC address of the ByteBlower destination port.
# @param srcIpConfig
#           The Layer 3 configuration of the ByteBlower source port. To use an
#           automated address, use the value 'dhcpv4'. To use a fixed address,
#           use a list of three elements: address, gateway address and netmask.
#           @example [ list dhcpv4 ]
#           @example [ list <port-ip> <gateway-ip> <netmask> ]
# @param dstIpConfig
#           The Layer 3 configuration of the ByteBlower destination port. To use
#           an automated address, use the value 'dhcpv4'. To use a fixed 
#           address, use a list of three elements: address, gateway address and
#           netmask.
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
#       The created objects for the out of sequence scenario.
#       @list
#           The return list consists of 4 elements: the ByteBlower server object
#           (1), the ByteBlower source port (2) and destination port (3) and the
#           higher-layer flow configuration (4). The flow configuration consists
#           of a single TX part with outofsequence enabled and a single RX part
#           with an out of sequence detector.
#
proc Outofsequence.Setup { serverAddress srcPhysicalPort dstPhysicalPort srcMacAddress dstMacAddress srcIpConfig dstIpConfig srcUdpPort dstUdpPort ethernetLength flowParam } {
    # Parse flow parameters
    set bidir [lindex $flowParam 0 ]
    set interFrameGap [lindex $flowParam 1 ]
    set numberOfFrames [lindex $flowParam 2 ]

    # Create server and ports
    set bb [ ByteBlower Instance.Get ]
    set server [ $bb Server.Add $serverAddress ]
    set srcByteBlowerPort [ $server Port.Create $srcPhysicalPort ]
    set dstByteBlowerPort [ $server Port.Create $dstPhysicalPort ]

    # Configure layer 2
    [ $srcByteBlowerPort Layer2.EthII.Set ] Mac.Set  $srcMacAddress
    [ $dstByteBlowerPort Layer2.EthII.Set ] Mac.Set  $dstMacAddress

    # Configure layer 3, using the shared support methods of the example scripts
    eval excentis::ByteBlower::Examples::Setup.Port.Layer3 $srcByteBlowerPort $srcIpConfig
    eval excentis::ByteBlower::Examples::Setup.Port.Layer3 $dstByteBlowerPort $dstIpConfig

    # Debug prints
    puts "Source port:"
    puts [$srcByteBlowerPort Description.Get]
    puts "Destination port:"
    puts [$dstByteBlowerPort Description.Get]

    # Create a basic flow with out of sequence detection (two if bidirectional traffic requested), using the shared support methods of the example scripts
    puts "Creating source -> destination flow with out of sequence enabled"
    set latencyEnabled 0
    set outofsequenceEnabled 1
    set flowList [list] 
    lappend flowList [ excentis::ByteBlower::Examples::Setup.Flow.IPv4.UDP $srcByteBlowerPort $dstByteBlowerPort $ethernetLength $srcUdpPort $dstUdpPort \
                                                                                $numberOfFrames $interFrameGap $latencyEnabled $outofsequenceEnabled]
    if { $bidir == 1 } {
	    puts "Creating destination <- source flow with out of sequence enabled (bidir)"
	    lappend flowList [ excentis::ByteBlower::Examples::Setup.Flow.IPv4.UDP $dstByteBlowerPort $srcByteBlowerPort $ethernetLength $dstUdpPort $srcUdpPort \
	                                                                            $numberOfFrames $interFrameGap $latencyEnabled $outofsequenceEnabled ]
    }

    # Return the created objects and the flow configuration
    return [ list $server $srcByteBlowerPort $dstByteBlowerPort $flowList ]
}

##
# This procedure calls the out of sequence tool in the higher layer with
# predefined arguments and the created scenario configuration.
#
# @param flowList
#           The scenario configuration expected by the ByteBlowerHL API. See
#           Outofsequence.Setup and ExecuteScenario for more information.
# @return
#           The return value of the ByteBlowerHL outofsequence method. In this
#           example it has a fixed structured.
#           @list
#               A list of one flow result for the unidirectional case and two
#               flow results for the bidirectional case. Each flow result is
#               itself a list consisting of 4 elements of which one is another
#               list: '-tx <sentFrames> -rx { <receivedFrames>
#               <outofsequenceFrames> }'.
#
proc Outofsequence.Execute { flowList } {
    # Just call the corresponding ByteBlowerHL method.
    return [ ::excentis::ByteBlower::FlowOutofsequence $flowList -return numbers ]
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
proc Outofsequence.Cleanup { server srcPort dstPort } {
    # Call destructor on created objects. Possible errors are ignored.
    catch { $srcPort Destructor } dummy
    catch { $dstPort Destructor } dummy
    catch { $server Destructor } dummy
}
