# --- What would we do without 'the package' :-)
package require ByteBlower

#------------------------#
#   Test Configuration   #
#------------------------#

# --- Server configuration
#set serverAddress "byteblower-demo-1.lab.excentis.com"
set serverAddress byteblower-tp-p860.lab.excentis.com


# --- PhysicalPort configuration
set physicalPort1 "trunk-1-1"
set physicalPort2 "trunk-1-2"

# --- Layer2 configuration
set port1MacAddress "00:ff:12:00:00:01"
set port2MacAddress "00:ff:12:00:00:02"

# --- Layer3 configuration
set port1PerformDhcp 1
set port2PerformDhcp 1
set port1IpAddress "10.10.0.2"
set port2IpAddress "10.10.0.3"
set port1Netmask "255.255.255.0"
set port2Netmask "255.255.255.0"
set port1Gateway "10.10.0.1"
set port2Gateway "10.10.0.1"

# --- ICMP Configuration
#     + An empty IcmpIdentifier will make the server create a random ICMP Identifier.
#     + An non-empty IcmpIdentifier will force the server use the given ICMP Identifier.
#set icmpIdentifier ""
set icmpIdentifier "1234"

#     + Echo Data Size (optional, default is 56Bytes)
set port1IcmpDataSize 0 ;# minimum
set port2IcmpDataSize 1472 ;# maximum for Ethernet MTU of 1500

#     + Echo Loop Interval (default is 10ms, 100pps)
set port1IcmpEchoLoopInterval "50ms" ;# 20pps
set port2IcmpEchoLoopInterval "20ms" ;# 50pps

# --- Test specific configuration
set echoLoopRunTime 5000 ;# ms

#----------------#
#   Test Setup   #
#----------------#

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
                $port1L3 Ip.Set $port1IpAddress
                $port1L3 Netmask.Set $port1Netmask
                $port1L3 Gateway.Set $port1Gateway
            }
            #     + Port 2
            set port2L3 [ $port2 Layer3.IPv4.Set ]
            if { $port2PerformDhcp == 1 } {
                # Using Dhcp
                [ $port2L3 Protocol.Dhcp.Get ] Perform
            } else {
                # Using static IP address
                $port2L3 Ip.Set $port2IpAddress
                $port2L3 Netmask.Set $port2Netmask
                $port2L3 Gateway.Set $port2Gateway
            }

            # --- Setup Icmp
            set port1Icmp [ $port1L3 Protocol.Icmp.Get ]
            set port2Icmp [ $port2L3 Protocol.Icmp.Get ]

            # --- Create an Icmp session based on the given identifier
            #     or create a random identifier when icmpIdentifier is empty (== no argument to Session.Add)
            set port1IcmpSession [ eval $port1Icmp Session.Add $icmpIdentifier ]
            set port2IcmpSession [ eval $port2Icmp Session.Add [ expr $icmpIdentifier + 1 ] ]

            # --- The Destination IPv6 address MUST be configured before we can use the session.
            $port1IcmpSession Remote.Address.Set [ $port2L3 Ip.Get ]
            $port2IcmpSession Remote.Address.Set [ $port1L3 Ip.Get ]

            # --- (optional) Configuring the data size.
            if { [ info exists ::port1IcmpDataSize ] &&\
                    ![ string equal $port1IcmpDataSize "" ] } {
                $port1IcmpSession Data.Size.Set $port1IcmpDataSize
            }
            if { [ info exists ::port2IcmpDataSize ] &&\
                    ![ string equal $port2IcmpDataSize "" ] } {
                $port2IcmpSession Data.Size.Set $port2IcmpDataSize
            }

            # --- Configuring the loop interval.
            $port1IcmpSession Echo.Loop.Interval.Set $port1IcmpEchoLoopInterval
            $port2IcmpSession Echo.Loop.Interval.Set $port2IcmpEchoLoopInterval

            # --- When a random Icmp Identifier is chosen, you will propably not see the
            #     received Echo requests from Port1 Icmp Session in the Echo Statistics.
            #     This is because an Icmp Session identification is based on the identifier
            #     field.l
            proc PrintIcmpEchoStatistics { icmpSessionName icmpSession } {
                puts "Icmp Echo Statistics for Session `${icmpSessionName}' with Identifier [ $icmpSession Identifier.Get ]"
                foreach {name value} [ $icmpSession Echo.Statistics.Get ] {
                    puts [ format "  - %-15s: %s" $name $value ]
                }
            }

            #--------------#
            #   Test Run   #
            #--------------#

            # --- Show configuration
            puts [ $server Description.Get ]
            puts [ $port1 Description.Get ]
            puts [ $port2 Description.Get ]

            puts ""
            puts "*** Before sending Echo Requests ***"
            puts ""

            PrintIcmpEchoStatistics "Port1" $port1IcmpSession
            PrintIcmpEchoStatistics "Port2" $port2IcmpSession

            $port1IcmpSession Echo.Request.Send
            $port2IcmpSession Echo.Request.Send

            puts ""
            puts "*** After sending single Echo Request ***"
            puts ""

            PrintIcmpEchoStatistics "Port1" $port1IcmpSession
            PrintIcmpEchoStatistics "Port2" $port2IcmpSession

            $port1IcmpSession Echo.Loop.Start
            $port2IcmpSession Echo.Loop.Start

            if { $echoLoopRunTime > 0 } {
                set ::waiter 0
                after $echoLoopRunTime "set ::waiter 1"
                vwait ::waiter
            }

            $port1IcmpSession Echo.Loop.Stop
            $port2IcmpSession Echo.Loop.Stop

            puts ""
            puts "*** After running Echo Request Loop ***"
            puts ""

            PrintIcmpEchoStatistics "Port1" $port1IcmpSession
            PrintIcmpEchoStatistics "Port2" $port2IcmpSession

        } result ] } {
    puts stderr "Caught Exception    : `${result}'"
    catch { puts "Exception Message   : [ $result Message.Get ]" } dummy
    catch { puts "Exception Timestamp : [ $result Timestamp.Get ]" } dummy
    catch { puts "Exception Trace     : [ $result Trace.Get ]" } dummy

    # Destruct the ByteBlower Exception
    catch { $result Destructor } dummy
}

#------------------#
#   Test Cleanup   #
#------------------#

$port1 Destructor
$port2 Destructor
$server Destructor

