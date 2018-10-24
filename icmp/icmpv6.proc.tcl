# This tcl script contains procedures to execute a Icmpv6 test.
# It is intended to be used in conjunction with the following scripts:
#  * icmpv6.conf.tcl
#  * general.proc.tcl
#  * icmpv6.proc.tcl
#  * icmpv6.example.tcl
#  * icmpv6.run.tcl

source [ file join [ file dirname [ info script ]] .. general.proc.tcl ]

proc Icmpv6.Setup { serverAddress physicalPort1 physicalPort2 port1MacAddress port2MacAddress port1AutoConfig port2AutoConfig srcIpConfig dstIpConfig  icmpIdentifier port1IcmpDataSize port2IcmpDataSize port1IcmpEchoLoopInterval port2IcmpEchoLoopInterval echoLoopRunTime echoReplyTimeout } {
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
            set port1L3 [ $port1 Layer3.IPv6.Set ]
            if { [ string equal -nocase $port1AutoConfig "statelessautoconfig" ] } {
                # Using StatelessAutoConfiguration
                $port1L3 StatelessAutoconfiguration
                set port1IpAddress [ $port1L3 Ip.Stateless.Get ]
            } elseif { [ string equal -nocase $port1AutoConfig "dhcp" ] } {
                # Using DHCPv6
                [ $port1L3 Protocol.Dhcp.Get ] Perform
                set port1IpAddress [ $port1L3 Ip.Dhcp.Get ]
            } else {
                # Using static IP address
                $port1L3 Gateway.Manual.Set $port1Router
                $port1L3 Ip.Manual.Add $port1IpAddress
            }
            #     + Port 2
            set port2L3 [ $port2 Layer3.IPv6.Set ]
            if { [ string equal -nocase $port2AutoConfig "statelessautoconfig" ] } {
                # Using StatelessAutoConfiguration
                $port2L3 StatelessAutoconfiguration
                set port2IpAddress [ $port2L3 Ip.Stateless.Get ]
            } elseif { [ string equal -nocase $port2AutoConfig "dhcp" ] } {
                # Using DHCPv6
                [ $port2L3 Protocol.Dhcp.Get ] Perform
                set port2IpAddress [ $port2L3 Ip.Dhcp.Get ]
            } else {
                # Using static IP address
                $port2L3 Gateway.Manual.Set $port2Router
                $port2L3 Ip.Manual.Add $port2IpAddress
            }
            
            # send a gratuitous arp, not really gratuitous, but will do the trick
            $port1L3 Resolve [ $port1L3 Gateway.Advertised.Get ]
            $port2L3 Resolve [ $port2L3 Gateway.Advertised.Get ]

            # --- Setup Icmp
            set port1Icmpv6 [ $port1L3 Protocol.Icmp.Get ]
            set port2Icmpv6 [ $port2L3 Protocol.Icmp.Get ]

            # --- Create an Icmp session based on the given identifier
            #     or create a random identifier when icmpIdentifier is empty (== no argument to Session.Add)
            set port1Icmpv6Session [ eval $port1Icmpv6 Session.Add $icmpIdentifier ]
            set port2Icmpv6Session [ eval $port2Icmpv6 Session.Add [ expr $icmpIdentifier + 1 ] ]

            # --- The Destination IPv4 address MUST be configured before we can use the session.
            $port1Icmpv6Session Remote.Address.Set [ lindex [ split $port2IpAddress "/" ] 0 ]
            $port2Icmpv6Session Remote.Address.Set [ lindex [ split $port1IpAddress "/" ] 0 ]

            # --- (optional) Configuring the data size.
            if { [ info exists ::port1IcmpDataSize ] &&\
                    ![ string equal $port1IcmpDataSize "" ] } {
                $port1Icmpv6Session Data.Size.Set $port1IcmpDataSize
            }
            if { [ info exists ::port2IcmpDataSize ] &&\
                    ![ string equal $port2IcmpDataSize "" ] } {
                $port2Icmpv6Session Data.Size.Set $port2IcmpDataSize
            }

            # --- Configuring the loop interval.
            $port1Icmpv6Session Echo.Loop.Interval.Set $port1IcmpEchoLoopInterval
            $port2Icmpv6Session Echo.Loop.Interval.Set $port2IcmpEchoLoopInterval
    } result ] } {
        puts stderr "Caught Exception    : `${result}'"
        catch { puts "Exception Message   : [ $result Message.Get ]" } dummy
        catch { puts "Exception Timestamp : [ $result Timestamp.Get ]" } dummy
        catch { puts "Exception Trace     : [ $result Trace.Get ]" } dummy

        # Destruct the ByteBlower Exception
        catch { $result Destructor } dummy
    }
    return [ list $server $port1 $port2 $port1Icmpv6Session $port2Icmpv6Session $echoLoopRunTime $echoReplyTimeout ]
}

# --- When a random Icmp Identifier is chosen, you will propably not see the
#     received Echo requests from Port1 Icmp Session in the Echo Statistics.
#     This is because an Icmp Session identification is based on the identifier
#     field.
proc PrintIcmpv6EchoStatistics { icmpv6SessionName icmpv6Session } {
    puts "Icmpv6 Echo Statistics for Session `${icmpv6SessionName}' with Identifier [ $icmpv6Session Identifier.Get ]"
    set sessionInfo [ $icmpv6Session Session.Info.Get ]
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
        lappend retVal [ list ${icmpv6SessionName} [ $icmpv6Session Identifier.Get ] $name $value ]
    }
    return $retVal
}


proc Icmpv6.Run { server port1 port2 port1Icmpv6Session port2Icmpv6Session echoLoopRunTime echoReplyTimeout } {
    if { [ catch {
            # --- Show configuration
            puts [ $server Description.Get ]
            puts [ $port1 Description.Get ]
            puts [ $port2 Description.Get ]

            #initialize return value
            set retValue [list ]

            puts ""
            puts "*** Before sending Echo Requests ***"
            puts ""

            lappend retValue [ PrintIcmpv6EchoStatistics "Port1" $port1Icmpv6Session ]
            lappend retValue [ PrintIcmpv6EchoStatistics "Port2" $port2Icmpv6Session ]

            $port1Icmpv6Session Echo.Request.Send
            $port2Icmpv6Session Echo.Request.Send

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

            lappend retValue [ PrintIcmpv6EchoStatistics "Port1" $port1Icmpv6Session ]
            lappend retValue [ PrintIcmpv6EchoStatistics "Port2" $port2Icmpv6Session ]

            $port1Icmpv6Session Echo.Loop.Start
            $port2Icmpv6Session Echo.Loop.Start

            if { $echoLoopRunTime > 0 } {
                set ::waiter 0
                after $echoLoopRunTime "set ::waiter 1"
                vwait ::waiter
            }
            
            $port1Icmpv6Session Echo.Loop.Stop
            $port2Icmpv6Session Echo.Loop.Stop

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

            lappend retValue [ PrintIcmpv6EchoStatistics "Port1" $port1Icmpv6Session ]
            lappend retValue [ PrintIcmpv6EchoStatistics "Port2" $port2Icmpv6Session ]

    } result ] } {
        puts stderr "Caught Exception    : `${result}'"
        catch { puts "Exception Message   : [ $result Message.Get ]" } dummy
        catch { puts "Exception Timestamp : [ $result Timestamp.Get ]" } dummy
        catch { puts "Exception Trace     : [ $result Trace.Get ]" } dummy
    }
        # Destruct the ByteBlower Exception
        catch { $result Destructor } dummy
        return [ list $retValue ]
}
