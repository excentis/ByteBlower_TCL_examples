#!/usr/bin/tclsh
package require ByteBlower
package require ByteBlowerHL

#------------------------#
#   Test Configuration   #
#------------------------#

# --- ByteBlower Server Address
set serverAddress "byteblower-dev-2100-2.lab.byteblower.excentis.com."

# --- Source and Destination Physical Port
set serverPhysicalPort trunk-1-1
set clientPhysicalPort trunk-1-2

# --- Layer 2 Configuration
# --- Source and Destination ByteBlower Port MAC address
set serverMacAddress "00:ff:12:ff:ee:dd"
set clientMacAddress "00:ff:12:ff:ee:ee"

# --- Layer 2.5 Configuration
# --- PPPoE Configuration
set serverPerformPppoe 1
set serverPppoeServiceName "PPPoE-http-server"
set serverPapPeerID "bb-pppoe"
set serverPapPassword "bb-pppoe"

set clientPerformPppoe 1
set clientPppoeServiceName "PPPoE-http-client"
set clientPapPeerID "bb-pppoe"
set clientPapPassword "bb-pppoe"

# --- Layer 3 Configuration
set serverIpv4Address "10.8.3.61"
set serverNetmask "255.255.255.0"
set serverIpv4GW "10.8.3.2"

set clientIpv4Address "10.8.3.62"
set clientNetmask "255.255.255.0"
set clientIpv4GW "10.8.3.2"

# --- Layer 4 Configuration
set serverTcpPort 80
#   + Uncomment to onverride the Slow Start Threshold
set slowStartThreshold 2147483647 ;# infinite
#   + Uncomment to configure window scaling
#     with the given the Receiver's Window Scale
set rcvWindowScale 4

# --- Layer 5 Configuration
#   + Uncomment to override the HTTP Method
set httpRequestMethod "GET"
#   + Used for bi-directional traffic
set httpRequestMethod2 "PUT"

# --- Traffic Settings

#   + Time to wait before start to send traffic (ms)
#set waitBeforeTrafficStart 0
set waitBeforeTrafficStart 250

#   + Number of HTTP Clients per interface
set numberOfClients 4

#   + Uncomment to configure TCP duration
set requestDuration "30s"
#   + Uncomment to configure TCP data size
#set requestSize 100e6 ;# 100 MB

# Bi-directional traffic ?
# @note
#     Make sure you configure @ref httpRequestMethod2
#     as the opposite of @ref httpRequestMethod
set performBidirTest 1

# --- DEBUGGING - Stop the test if the TCP session did not finish after 10 minutes
set localTimeout 600 ;# seconds

#----------------#
#   Test Setup   #
#----------------#

# --- Does your system support console coloring?
set systemSupportsColoring [ string equal $::tcl_platform(platform) unix ]

#- Add a Server
set server [ ByteBlower Server.Add $serverAddress ]

#- Create 2 ByteBlower Ports
set httpServerPort [ $server Port.Create $serverPhysicalPort ]
set httpClientPort [ $server Port.Create $clientPhysicalPort ]

if { [ catch {

#- Layer2 setup
set serverL2 [ $httpServerPort Layer2.EthII.Set ]
set clientL2 [ $httpClientPort Layer2.EthII.Set ]
$serverL2 Mac.Set $serverMacAddress
$clientL2 Mac.Set $clientMacAddress

# --- Configure the Port Layer2.5 settings
if { $serverPerformPppoe == 1 } {
    # --- Prepare the PPPoE configuration
    set serverPppoeResult [ ::excentis::ByteBlower::PPPoE.Setup \
                                $httpServerPort $serverPppoeServiceName \
                                "pap" [ list ${serverPapPeerID} ${serverPapPassword} ] \
                                "ipcp" \
                          ]

    # --- Start the PPPoE Session
    puts "Starting PPPoE Session"
    set serverSessionId [ ::excentis::ByteBlower::PPPoE.Start $serverPppoeResult ]
    puts "PPPoE Session Started"

    # --- Extract Network Control Protocol (IPCP) results
    set serverIpcpResults [ ::excentis::ByteBlower::PPPoE.NCP.Results.Get $serverPppoeResult ]
    set serverIpv4Address [ lindex $serverIpcpResults 0 ]
    set serverIpv4GW [ lindex $serverIpcpResults 1 ]

    # --- Show the results
    if { $systemSupportsColoring } {
        puts "    PPPoE Status : \033\[0;35m[ ::excentis::ByteBlower::PPPoE.Status.Get ${serverPppoeResult} ]\033\[0;m"
        puts [ format "Interface %s got Session ID \`\033\[0;33m0x%04X\033\[0;m'" [ $httpServerPort Interface.Name.Get ] ${serverSessionId} ]
    } else {
        puts "    PPPoE Status : [ ::excentis::ByteBlower::PPPoE.Status.Get ${serverPppoeResult} ]"
        puts [ format "Interface %s got Session ID \`0x%04X'" [ $httpServerPort Interface.Name.Get ] ${serverSessionId} ]
    }
    puts "Got Server IPv4 Address        : $serverIpv4Address"
    puts "Got Server Remote IPv4 Address : $serverIpv4GW"

} else {
    set serverL3 [ $httpServerPort Layer3.IPv4.Set ]
    $serverL3 Ip.Set $serverIpv4Address
    $serverL3 Netmask.Set $serverNetmask
    $serverL3 Gateway.Set $serverIpv4GW

    unset serverL3
}

# --- HTTP Client PPPoE
if { $clientPerformPppoe == 1 } {
    # --- Prepare the PPPoE configuration
    set clientPppoeResult [ ::excentis::ByteBlower::PPPoE.Setup \
                                $httpClientPort $clientPppoeServiceName \
                                "pap" [ list ${clientPapPeerID} ${clientPapPassword} ] \
                                "ipcp" \
                          ]

    # --- Start the PPPoE Session
    set clientSessionId [ ::excentis::ByteBlower::PPPoE.Start $clientPppoeResult ]

    # --- Extract Network Control Protocol (IPCP) results
    set clientIpcpResults [ ::excentis::ByteBlower::PPPoE.NCP.Results.Get $clientPppoeResult ]
    set clientIpv4Address [ lindex $clientIpcpResults 0 ]
    set clientIpv4GW [ lindex $clientIpcpResults 1 ]

    # --- Show the results
    if { $systemSupportsColoring } {
        puts "    PPPoE Status : \033\[0;35m[ ::excentis::ByteBlower::PPPoE.Status.Get ${clientPppoeResult} ]\033\[0;m"
        puts [ format "Interface %s got Session ID \`\033\[0;33m0x%04X\033\[0;m'" [ $httpClientPort Interface.Name.Get ] ${clientSessionId} ]
    } else {
        puts "    PPPoE Status : [ ::excentis::ByteBlower::PPPoE.Status.Get ${clientPppoeResult} ]"
        puts [ format "Interface %s got Session ID \`0x%04X'" [ $httpClientPort Interface.Name.Get ] ${clientSessionId} ]
    }
    puts "Got Client IPv4 Address        : $clientIpv4Address"
    puts "Got Client Remote IPv4 Address : $clientIpv4GW"

} else {
    set clientL3 [ $httpClientPort Layer3.IPv4.Set ]
    $clientL3 Ip.Set $clientIpv4Address
    $clientL3 Netmask.Set $clientNetmask
    $clientL3 Gateway.Set $clientIpv4GW

    unset clientL3
}

#- Layer3 setup
set serverL3 [ $httpServerPort Layer3.IPv4.Get ]
puts "Server L3 Configuration:"
if { [ llength $serverL3 ] > 0 } {
    puts " - IPv4 Address    : [ $serverL3 Ip.Get ]"
    puts " - Netmask         : [ $serverL3 Netmask.Get ]"
    puts " - Default Gateway : [ $serverL3 Gateway.Get ]"
} else {
    puts " <EMPTY>"
}

set clientL3 [ $httpClientPort Layer3.IPv4.Get ]
puts "Client L3 Configuration:"
if { [ llength $clientL3 ] > 0 } {
    puts " - IPv4 Address    : [ $clientL3 Ip.Get ]"
    puts " - Netmask         : [ $clientL3 Netmask.Get ]"
    puts " - Default Gateway : [ $clientL3 Gateway.Get ]"
} else {
    puts " <EMPTY>"
}

#- Get the obtained server IP address
set serverIpAddress [ $serverL3 Ip.Get ]

#- Create a HTTP Server
puts "Adding HTTP server"
set httpServer [ $httpServerPort Protocol.Http.Server.Add ]

puts "- Setting HTTP server port ${serverTcpPort}"
$httpServer Port.Set $serverTcpPort

if { [ info exists rcvWindowScale ] } {
    puts "- Apply Receivers Window scale ${rcvWindowScale}"
    $httpServer ReceiveWindow.Scaling.Value.Set $rcvWindowScale
    $httpServer ReceiveWindow.Scaling.Enable 1
}

if { [ info exists slowStartThreshold ] } {
    puts "- Apply Slow Start Threshold ${slowStartThreshold}"
    $httpServer SlowStartThreshold.Set $slowStartThreshold
}

#- Create HTTP Clients
proc createHTTPClient { httpClientPort serverIpAddress serverTcpPort httpRequestMethodName } {
    set httpClient [ $httpClientPort Protocol.Http.Client.Add ]
    puts "${httpClient} ([ $httpClient ServerClientId.Get ]):"
    puts "- Requesting on server: '$serverIpAddress'"; flush stdout
    $httpClient Remote.Address.Set $serverIpAddress
    puts "- Requesting on server port: '$serverTcpPort'"; flush stdout
    $httpClient Remote.Port.Set $serverTcpPort

    # --- Allow us to start all HTTP clients simultaneously
    $httpClient Request.Start.Type.Set "scheduled"

    if { [ uplevel 1 { info exists requestDuration } ] } {
        $httpClient Request.Duration.Set "[ uplevel 1 set requestDuration ]"
    } elseif { [ uplevel 1 { info exists requestSize } ] } {
        $httpClient Request.Size.Set [ expr int([ uplevel 1 set requestSize ]) ]
    }

    if { [ uplevel 1 "info exists ${httpRequestMethodName}" ] } {
        $httpClient Http.Method.Set [ uplevel 1 set $httpRequestMethodName ]
    }

    if { [ uplevel 1 { info exists rcvWindowScale } ] } {
        puts "- Apply Receivers Window scale [ uplevel 1 set rcvWindowScale ]"
        $httpClient ReceiveWindow.Scaling.Value.Set [ uplevel 1 set rcvWindowScale ]
        $httpClient ReceiveWindow.Scaling.Enable 1
    }

    if { [ uplevel 1 { info exists slowStartThreshold } ] } {
        puts "- Apply Slow Start Threshold [ uplevel 1 set slowStartThreshold ]"
        $httpClient SlowStartThreshold.Set [ uplevel 1 set slowStartThreshold ]
    }

    return $httpClient
}

set httpClients [ list ]
if { $performBidirTest } {
    set httpClients2 [ list ]
}

for { set i 0 } { $i < $numberOfClients } { incr i 1 } {
    puts "Adding HTTP Client ${i}"; update
    lappend httpClients [ createHTTPClient $httpClientPort $serverIpAddress $serverTcpPort httpRequestMethod ]

    if { $performBidirTest } {
        puts "Adding bi-dir HTTP Client ${i}"; update
        lappend httpClients2 [ createHTTPClient $httpClientPort $serverIpAddress $serverTcpPort httpRequestMethod2 ]
    }
}


#- Descriptions
#puts [ $server Description.Get ]
puts "Getting HTTP server port description"
puts [ $httpServerPort Description.Get ]
puts "Getting HTTP client port description"
puts [ $httpClientPort Description.Get ]; flush stdout

#-------------------#
#   Starting Test   #
#-------------------#

# --- Wait until the test is finished
if { $waitBeforeTrafficStart > 0 } {
    puts "Waiting ${waitBeforeTrafficStart} ms..."
    set ::waiter 0
    after $waitBeforeTrafficStart { set ::waiter 1 }
    vwait ::waiter
    puts "done"
}

#- Start the HTTP Server
$httpServer Start

#- Start the HTTP Client (request a page)
set startTime1 [ clock seconds ]
#$httpClient Request.Start
# + Start HTTP Client schedules
ByteBlower Ports.Start $httpClientPort

set startTime2 [ clock seconds ]

#- Server Client Info
proc sci { httpServer httpClient } {
    set httpClientSessionInfo [ $httpClient Http.Session.Info.Get ]

    # --- Refresh the local HTTP Session Info to get the final status "snapshot"
    $httpClientSessionInfo Refresh

    # Request the HTTP Server Session Info from the HTTP Server.
    set scId [ $httpClient ServerClientId.Get ]
    #puts [ $httpServer Client.Identifiers.Get ]
    set httpServerSessionInfo [ $httpServer Http.Session.Info.Get $scId ]
    # --- Refresh the local HTTP Session Info to get the current status "snapshot"
    #
    # --- REMARK: Please note that the HTTP Server only keeps one HTTP Session Info for each client!
    #             This means that once you obtained the Session Info for the Client, you MUST use Refresh
    #             on that object to synchronize the status with the ByteBlower Server!
    $httpServerSessionInfo Refresh

    # --- Text based
    puts [ $httpServerSessionInfo Description.Get ]
    # --- Value based
    #foreach httpSessionInfoMethod [ list "AverageDataSpeed.Get"\
    #                                     "Request.Content.Size.Get"\
    #                                     "Request.Header.Size.Get"\
    #                                     "Request.Method.Get"\
    #                                     "Request.Size.Get"\
    #                                     "Request.Uri.Get"\
    #                                     "Role.Get"\
    #                                     "Rx.Bytes.Get"\
    #                                     "T1.Get"\
    #                                     "T2.Get"\
    #                                     "T3.Get"\
    #                                     "Tcp.CongestionWindow.Downgrades.Get"\
    #                                     "Tcp.CongestionWindow.Size.Current.Get"\
    #                                     "Tcp.CongestionWindow.Size.Maximum.Get"\
    #                                     "Tcp.Status.Get"\
    #                                     "Tcp.Tx.Bytes.Get"\
    #                                     "Tcp.ReceiveWindow.Size.Maximum.Get"\
    #                                     "Tcp.ReceiveWindow.Size.Minimum.Get"\
    #                                     "Time.Data.Packet.First.Get"\
    #                                     "Time.Data.Packet.Last.Get"\
    #                                     "Time.Request.Packet.First.Get"\
    #                                     "Time.Request.Packet.Last.Get"\
    #                                     "Time.Request.Start.Get"\
    #                                     "Time.Response.Packet.First.Get"\
    #                                     "Time.Response.Packet.Last.Get"\
    #                                     "Time.Response.Start.Get"\
    #                              ] {
    #    puts -nonewline "    - [ string range $httpSessionInfoMethod 0 [ expr [ string length $httpSessionInfoMethod ] - 5 ] ] : "
    #    if { [ catch { eval "$httpServerSessionInfo" "$httpSessionInfoMethod" } result ] } {
    #        puts ""
    #        puts stderr "\tCaught Exception: ${result}"
    #        catch { puts stderr "\t[ $result Message.Get ]" } dummy
    #    } else {
    #        puts $result
    #    }
    #}
}

#- Wait for the client to complete the request
foreach httpClient $httpClients {
    puts "Waiting for HTTP Client ${httpClient}"
    if { [ catch {
        $httpClient WaitUntilFinished "${localTimeout}s"
    } waitError ] } {
        catch { puts stderr "\033\[0;31m[ $waitError Message.Get ]\033\[0;m" } dummy
        catch { puts stderr "\033\[0;31m[ $waitError Timestamp.Get ]\033\[0;m" } dummy
        catch { puts stderr "\033\[0;31m[ $waitError Trace.Get ]\033\[0;m" } dummy
        catch { $waitError Destructor } dummy
    }
    puts ""
}
if { $performBidirTest } {
    foreach httpClient $httpClients2 {
        puts "Waiting for HTTP Client ${httpClient}"
        if { [ catch {
            $httpClient WaitUntilFinished "${localTimeout}s"
        } waitError ] } {
            catch { puts stderr "\033\[0;31m[ $waitError Message.Get ]\033\[0;m" } dummy
            catch { puts stderr "\033\[0;31m[ $waitError Timestamp.Get ]\033\[0;m" } dummy
            catch { puts stderr "\033\[0;31m[ $waitError Trace.Get ]\033\[0;m" } dummy
            catch { $waitError Destructor } dummy
        }
        puts ""
    }
}
unset httpClient

#- Stop the HTTP client
set stopTime1 [ clock seconds ]
#ByteBlower Ports.Stop $httpClientPort
foreach httpClient $httpClients {
    $httpClient Request.Stop
}
if { $performBidirTest } {
    foreach httpClient $httpClients2 {
        $httpClient Request.Stop
    }
}
unset httpClient
set stopTime2 [ clock seconds ]

#- Stop the HTTP stop
$httpServer Stop

#- Get the list of status information
if { $systemSupportsColoring } {
    puts "\033\[0;32mHTTP Server Port status\033\[0;m (\033\[0;33m${httpServerPort}\033\[0;m):"
    if { $serverPerformPppoe == 1 } {
        puts "    PPPoE Status : \033\[0;35m[ ::excentis::ByteBlower::PPPoE.Status.Get ${serverPppoeResult} ]\033\[0;m"
    }
} else {
    puts "HTTP Server Port status (${httpServerPort}):"
    if { $serverPerformPppoe == 1 } {
        puts "    PPPoE Status : [ ::excentis::ByteBlower::PPPoE.Status.Get ${serverPppoeResult} ]"
    }
}

#- Get the list of status information
if { $systemSupportsColoring } {
    puts "\033\[0;32mClient Port status\033\[0;m (\033\[0;33m${httpClientPort}\033\[0;m):"
    if { $clientPerformPppoe == 1 } {
        puts "    PPPoE Status : \033\[0;35m[ ::excentis::ByteBlower::PPPoE.Status.Get ${clientPppoeResult} ]\033\[0;m"
    }
} else {
    puts "Client Port status (${httpClientPort}):"
    if { $clientPerformPppoe == 1 } {
        puts "    PPPoE Status : [ ::excentis::ByteBlower::PPPoE.Status.Get ${clientPppoeResult} ]"
    }
}

proc getHttpClientStatus { httpClient httpServer } {
    upvar systemSupportsColoring systemSupportsColoring

    puts ""

if { [ catch {
    set httpClientSessionInfo [ $httpClient Http.Session.Info.Get ]

    # --- Refresh the local HTTP Session Info to get the final status "snapshot"
    $httpClientSessionInfo Refresh

    if { $systemSupportsColoring } {
        puts "\033\[0;32mClient status\033\[0;m (\033\[0;33m${httpClient}\033\[0;m):"
    } else {
        puts "Client status (${httpClient}):"
    }
    puts [ $httpClientSessionInfo Description.Get ]

    if { $systemSupportsColoring } {
        puts "\033\[0;32mServer's Client status\033\[0;m (\033\[0;33m${httpClient}\033\[0;m):"
    } else {
        puts "Server's Client status (${httpClient}):"
    }
    sci $httpServer $httpClient

    set clientTcpSessionInfo [ $httpClientSessionInfo Tcp.Session.Info.Get ]

    #- The final status value of the HTTP client, we expect it to be "finished"
    set statusValue [ $clientTcpSessionInfo ConnectionState.Get ]

    switch -- [ $httpClientSessionInfo Request.Method.Get ] {
        "GET" {
            # --- Data is flowing from HTTP Server to HTTP Client
            #     => Getting transmitter results from the HTTP Server Session Info
            set httpServerSessionInfo [ $httpServer Http.Session.Info.Get [ $httpClient ServerClientId.Get ] ]
            $httpServerSessionInfo Refresh
            #     => Getting receiver results from the HTTP Client Session Info
            set clientHttpSessionResult [ $httpClientSessionInfo Result.Get ]
            set clientTcpSessionResult [ $clientTcpSessionInfo Result.Get ]

            set serverHttpSessionResult [ $httpServerSessionInfo Result.Get ]
            set serverTcpSessionInfo [ $httpServerSessionInfo Tcp.Session.Info.Get ]
            set serverTcpSessionResult [ $serverTcpSessionInfo Result.Get ]

            #set txBytes [ $serverTcpSessionResult Tx.ByteCount.Total.Get ]
            set txBytes [ $serverHttpSessionResult Tx.ByteCount.Total.Get ]

            #- Received number of bits
            #set rxBytes [ $clientTcpSessionResult Rx.ByteCount.Total.Get ]
            set rxBytes [ $clientHttpSessionResult Rx.ByteCount.Total.Get ]
            set avgThroughput [ $clientHttpSessionResult AverageDataSpeed.Get ]
            set minCongestion [ $clientTcpSessionResult ReceiverWindow.Minimum.Get ]
            set maxCongestion [ $clientTcpSessionResult ReceiverWindow.Maximum.Get ]
        }
        "PUT" {
            # --- Data is flowing from HTTP Client to HTTP Server
            #     => Getting transmitter results from the HTTP Client Session Info
            set clientHttpSessionResult [ $httpClientSessionInfo Result.Get ]
            set clientTcpSessionResult [ $clientTcpSessionInfo Result.Get ]
            #     => Getting receiver results from the HTTP Server Session Info
            set httpServerSessionInfo [ $httpServer Http.Session.Info.Get [ $httpClient ServerClientId.Get ] ]
            $httpServerSessionInfo Refresh

            set serverHttpSessionResult [ $httpServerSessionInfo Result.Get ]
            set serverTcpSessionInfo [ $httpServerSessionInfo Tcp.Session.Info.Get ]
            set serverTcpSessionResult [ $serverTcpSessionInfo Result.Get ]

            #set txBytes [ $clientTcpSessionResult Tx.ByteCount.Total.Get ]
            set txBytes [ $clientHttpSessionResult Tx.ByteCount.Total.Get ]

            #- Received number of bytes
            #set rxBytes [ $serverTcpSessionResult Rx.ByteCount.Total.Get ]
            set rxBytes [ $serverHttpSessionResult Rx.ByteCount.Total.Get ]
            set avgThroughput [ $serverHttpSessionResult AverageDataSpeed.Get ]
            set minCongestion [ $serverTcpSessionResult ReceiverWindow.Minimum.Get ]
            set maxCongestion [ $serverTcpSessionResult ReceiverWindow.Maximum.Get ]
        }
        default {
            puts sterr "Unsupported HTTP Client HTTP Request Method : '[ $httpClientSessionInfo Request.Method.Get ]'"
            set txBytes "?"
            set rxBytes "?"
            set avgThroughput "?"
            set minCongestion "?"
            set maxCongestion "?"
        }
    }

    if { $systemSupportsColoring } {
        puts "\033\[0;32mSession status\033\[0;m (\033\[0;33m${httpClient}\033\[0;m):"
    } else {
        puts "Session status (${httpClient}):"
    }
    if { [ info exists requestDuration ] } {
        puts "    Request duration      : ${requestDuration}"
    } elseif { [ info exists requestSize ] } {
        puts "    Request size          : ${requestSize} bytes"
    }
    puts "    TX Payload            : $txBytes bytes"
    puts "    RX Payload            : $rxBytes bytes"
    if { $systemSupportsColoring } {
        puts "    Average Throughput    : \033\[1;m${avgThroughput} bytes/s\033\[0;m"
    } else {
        puts "    Average Throughput    : $avgThroughput bytes/s"
    }
    puts "    Min Congestion Window : $minCongestion bytes"
    puts "    Max Congestion Window : $maxCongestion bytes"
    puts "    Status                : $statusValue"
} waitError ] } {
    catch { puts stderr "\033\[0;31m[ $waitError Message.Get ]\033\[0;m" } dummy
    catch { puts stderr "\033\[0;31m[ $waitError Timestamp.Get ]\033\[0;m" } dummy
    catch { puts stderr "\033\[0;31m[ $waitError Trace.Get ]\033\[0;m" } dummy
    catch { $waitError Destructor } dummy

    set avgThroughput 0
    set rxBytes 0
}

    return [ list $avgThroughput $rxBytes ]
}

set totalAvgThroughput 0
set totalRxBytes 0

foreach httpClient $httpClients {
    foreach { avgThroughput rxBytes } [ getHttpClientStatus $httpClient $httpServer ] {
        # --- XXX - Q&D calculation of total average throughput (assuming "time first", "time last" and duration are close enough)
        set totalAvgThroughput [ expr $totalAvgThroughput + $avgThroughput ]
        set totalRxBytes [ expr $totalRxBytes + $rxBytes ]
    }
}
if { $performBidirTest } {
    set totalBidirAvgThroughput 0
    set totalBidirRxBytes 0

    foreach httpClient $httpClients2 {
        foreach { avgThroughput rxBytes } [ getHttpClientStatus $httpClient $httpServer ] {
            # --- XXX - Q&D calculation of total average throughput (assuming "time first", "time last" and duration are close enough)
            set totalBidirAvgThroughput [ expr $totalAvgThroughput + $avgThroughput ]
            set totalBidirRxBytes [ expr $totalRxBytes + $rxBytes ]
        }
    }
}
unset httpClient

set startInterval [ expr $startTime2 - $startTime1 ]
set stopInterval [ expr $stopTime2 - $stopTime1 ]
set runInterval [ expr $stopTime2 - $startTime2 ]

puts ""
puts "Starting took ${startInterval} seconds"
puts "Stopping took ${stopInterval} seconds"
if { $systemSupportsColoring } {
    puts "Test ran for \033\[0;33m${runInterval} seconds\033\[0;m"
    puts "Total payload: \033\[0;33m${totalRxBytes} Bytes\033\[0;m"
    puts "Total Average Throughput : \033\[0;33m${totalAvgThroughput} bytes/s\033\[0;m"
    if { $performBidirTest } {
        puts "Total (bidir) payload: \033\[0;33m${totalBidirRxBytes} Bytes\033\[0;m"
        puts "Total (bidir) Average Throughput : \033\[0;33m${totalBidirAvgThroughput} bytes/s\033\[0;m"
    }
} else {
    puts "Test ran for ${runInterval} seconds"
    puts "Total payload: ${totalRxBytes} Bytes"
    puts "Total Average Throughput : ${totalAvgThroughput} bytes/s"
    if { $performBidirTest } {
        puts "Total (bidir) payload: ${totalBidirRxBytes} Bytes"
        puts "Total (bidir) Average Throughput : ${totalBidirAvgThroughput} bytes/s"
    }
}

# --- Clean up
if { $serverPerformPppoe == 1 } {
    ::excentis::ByteBlower::PPPoE.Terminate $serverPppoeResult
}
if { $clientPerformPppoe == 1 } {
    ::excentis::ByteBlower::PPPoE.Terminate $clientPppoeResult
}

} catched ] == 1 } {
    puts stderr "\033\[0;31m$::errorInfo\033\[0;m"
    catch { puts stderr "\033\[0;31m[ $catched Message.Get ]\033\[0;m" } dummy
    catch { puts stderr "\033\[0;31m[ $catched Timestamp.Get ]\033\[0;m" } dummy
    catch { puts stderr "\033\[0;31m[ $catched Trace.Get ]\033\[0;m" } dummy

    # --- Cleanup
    catch { unset ::httpServerSessionInfo } dummy

    # --- Delete the ByteBlower Ports
    $httpClientPort Destructor
    $httpServerPort Destructor

    $server Destructor

    error $catched

} else {
    # --- Cleanup
    catch { unset ::httpServerSessionInfo } dummy

    # --- Delete the ByteBlower Ports
    $httpClientPort Destructor
    $httpServerPort Destructor

    $server Destructor

}

# --- all done
#exit 0
