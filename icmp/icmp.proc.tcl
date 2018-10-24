# This tcl script contains procedures to execute a Icmp test.
# It is intended to be used in conjunction with the following scripts:
#  * icmp.conf.tcl
#  * general.proc.tcl
#  * icmp.proc.tcl
#  * icmp.example.tcl
#  * icmp.run.tcl

source [ file join [ file dirname [ info script ]] .. general.proc.tcl ]

proc Icmp.Setup { serverAddress physicalPort1 physicalPort2 port1MacAddress port2MacAddress port1PerformDhcp port2PerformDhcp srcIpConfig dstIpConfig icmpIdentifier port1IcmpDataSize port2IcmpDataSize port1IcmpEchoLoopInterval port2IcmpEchoLoopInterval echoLoopRunTime echoReplyTimeout } {
#
# @param echoReplyTimeout Time to wait before receiving ICMP (Echo) statistics [ms]
#


    # --- Connect to the ByteBlower Server
    set bb [ ByteBlower Instance.Get ]
    set server [ $bb Server.Add $serverAddress ]

    # --- Create the ByteBlower Ports
    set port1 [ $server Port.Create $physicalPort1 ]
    set port2 [ $server Port.Create $physicalPort2 ]

    if { [ catch {

            # --- Setup Layer2
            set port1L2 [ $port1 Layer2.EthII.Set ]
            set port2L2 [ $port2 Layer2.EthII.Set ]
            $port1L2 Mac.Set $port1MacAddress
            $port2L2 Mac.Set $port2MacAddress

            # --- Setup Layer3
            #     + Port 1
            set port1L3 [ $port1 Layer3.IPv4.Set ]
            if { $port1PerformDhcp == 1 } {
                # Using Dhcp
                [ $port1L3 Protocol.Dhcp.Get ] Perform
            } else {
                # Using static IP address
                $port1L3 Ip.Set [ lindex $srcIpConfig 0 ] 
                $port1L3 Netmask.Set [ lindex $srcIpConfig 1 ]
                $port1L3 Gateway.Set [ lindex $srcIpConfig 2 ]
            }
            #     + Port 2
            set port2L3 [ $port2 Layer3.IPv4.Set ]
            if { $port2PerformDhcp == 1 } {
                # Using Dhcp
                [ $port2L3 Protocol.Dhcp.Get ] Perform
            } else {
                # Using static IP address
                $port2L3 Ip.Set [ lindex $dstIpConfig 0 ]
                $port2L3 Netmask.Set [ lindex $dstIpConfig 1 ]
                $port2L3 Gateway.Set [ lindex $dstIpConfig 2 ]
            }
            
            # send a Gratuitous ARP, so the network will know about us
            $port2L3 Protocol.GratuitousArp.Reply
            $port2L3 Protocol.GratuitousArp.Reply

            # --- Setup Icmp
            set port1Icmp [ $port1L3 Protocol.Icmp.Get ]
            set port2Icmp [ $port2L3 Protocol.Icmp.Get ]

            # --- Create an Icmp session based on the given identifier
            #     or create a random identifier when icmpIdentifier is empty (== no argument to Session.Add)
            set port1IcmpSession [ eval $port1Icmp Session.Add $icmpIdentifier ]
            set port2IcmpSession [ eval $port2Icmp Session.Add [ expr $icmpIdentifier + 1 ] ]

            # --- The Destination IPv6 address MUST be configured before we can use the session.
            $port1IcmpSession Remote.Address.Set [  $port2L3 Ip.Get ]
            $port2IcmpSession Remote.Address.Set [ $port1L3 Ip.Get ]

            # --- (optional) Configuring the data size.
            if { [ info exists ::port1IcmpDataSize ] &&\
                    ![ string equal $port1IcmpDataSize "" ] } {
                $port1IcmpSession Data.Size.Set $port1IcmpDataSize
            }
            if { [ info exists ::port2IcmpDataSize ]  &&\
                    ![ string equal $port2IcmpDataSize "" ] } {
                $port2IcmpSession Data.Size.Set $port2IcmpDataSize
            }

            # --- Configuring the loop interval.
            $port1IcmpSession Echo.Loop.Interval.Set $port1IcmpEchoLoopInterval
            $port2IcmpSession Echo.Loop.Interval.Set $port2IcmpEchoLoopInterval

    } result ] } {
        puts stderr "Caught Exception    : `${result}'"
        catch { puts "Exception Message   : [ $result Message.Get ]" } dummy
        catch { puts "Exception Timestamp : [ $result Timestamp.Get ]" } dummy
        catch { puts "Exception Trace     : [ $result Trace.Get ]" } dummy
    }
    
    return [ list $server $port1 $port2 $port1IcmpSession $port2IcmpSession $echoLoopRunTime $echoReplyTimeout ]
}

proc PrintIcmpEchoStatistics { icmpSessionName icmpSession } {
# --- When a random Icmp Identifier is chosen, you will propably not see the
            #     received Echo requests from Port1 Icmp Session in the Echo Statistics.
            #     This is because an Icmp Session identification is based on the identifier
            #     field.
    puts "Icmp Echo Statistics for Session `${icmpSessionName}' with Identifier [ $icmpSession Identifier.Get ]"
    set sessionInfo [ $icmpSession Session.Info.Get ]
    $sessionInfo Refresh


    set retVal [list ]
    #foreach {name value} [ $icmpSession Echo.Statistics.Get ] {}
    foreach { name method } [ list \
        RxEchoRequests Rx.Echo.Requests.Get \
        TxEchoReplies Tx.Echo.Replies.Get \
        TxEchoRequests Tx.Echo.Requests.Get \
        RxEchoReplies Rx.Echo.Replies.Get \
    ] {
        set value [ $sessionInfo $method ]
        puts [ format "  - %-15s: %s" $name $value ]
        lappend retVal [ list ${icmpSessionName} [ $icmpSession Identifier.Get ] $name $value ]
    }
    return $retVal
}



proc Icmp.Run { server port1 port2 port1IcmpSession port2IcmpSession echoLoopRunTime echoReplyTimeout } {
    if { [ catch {
            #--------------#
            #   Test Run   #
            #--------------#

            #initialize return value
            set retValue [list ]
            # --- Show configuration
            puts "Port1: [ $port1 Description.Get ]"
            puts "Port2: [ $port2 Description.Get ]"

            puts ""
            puts "*** Before sending Echo Requests ***"
            puts ""

            lappend retValue [ PrintIcmpEchoStatistics "Port1" $port1IcmpSession ]
            lappend retValue [ PrintIcmpEchoStatistics "Port2" $port2IcmpSession ]

            $port1IcmpSession Echo.Request.Send
            $port2IcmpSession Echo.Request.Send

            if { $echoReplyTimeout > 0 } {
                puts ""
                puts "Waiting for ${echoReplyTimeout}\[ms\] for Echo replies"
                puts ""
                set ::waiter 0
                after $echoReplyTimeout "set ::waiter 1"
                vwait ::waiter
            }

            puts ""
            puts "*** After sending single Echo Request ***"
            puts ""

            lappend retValue [ PrintIcmpEchoStatistics "Port1" $port1IcmpSession ]
            lappend retValue [ PrintIcmpEchoStatistics "Port2" $port2IcmpSession ]

            $port1IcmpSession Echo.Loop.Start
            $port2IcmpSession Echo.Loop.Start

            if { $echoLoopRunTime > 0 } {
                set ::waiter 0
                after $echoLoopRunTime "set ::waiter 1"
                vwait ::waiter
            }
            
            $port1IcmpSession Echo.Loop.Stop
            $port2IcmpSession Echo.Loop.Stop

            if { $echoReplyTimeout > 0 } {
                puts ""
                puts "Waiting for ${echoReplyTimeout}\[ms\] for Echo replies after the stop"
                puts ""
                set ::waiter 0
                after $echoReplyTimeout "set ::waiter 1"
                vwait ::waiter
            }


            puts ""
            puts "*** After running Echo Request Loop ***"
            puts ""

            lappend retValue [ PrintIcmpEchoStatistics "Port1" $port1IcmpSession ]
            lappend retValue [ PrintIcmpEchoStatistics "Port2" $port2IcmpSession ]


    } result ] } {

        puts stderr "Caught Exception    : `${result}'"
        catch { puts "Exception Message   : [ $result Message.Get ]" } dummy
        catch { puts "Exception Timestamp : [ $result Timestamp.Get ]" } dummy
        catch { puts "Exception Trace     : [ $result Trace.Get ]" } dummy
    }
    # Destruct the ByteBlower Exception
    catch { 	$result Destructor } dummy


    return [ list $retValue ]
}

