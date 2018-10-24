# This tcl script contains procedures to execute a TCP with MTU test.
# It is intended to be used in conjunction with the following scripts:
#  * tcp-with-mtu.conf.tcl
#  * general.proc.tcl
#  * tcp-with-mtu.proc.tcl
#  * tcp-with-mtu.example.tcl
#  * tcp-with-mtu.run.tcl

source [ file join [ file dirname [ info script ]] .. general.proc.tcl ]

proc TCP_with_MTU.Setup { } {

    #- Add a Server
    set bb [ ByteBlower Instance.Get ]
    set server [ $bb Server.Add $::serverAddress ]

    #- Create 2 ByteBlower Ports
    set httpServerPort [ $server Port.Create $::physicalPort1 ]
    set httpClientPort [ $server Port.Create $::physicalPort2 ]

    if { [ catch {
            # MTU
            $httpServerPort MDL.Set $::mtu
            $httpClientPort MDL.Set $::mtu

            #- Layer2 setup
            set serverL2 [ $httpServerPort Layer2.EthII.Set ]
            $serverL2 Mac.Set $::serverMacAddress

            set clientL2 [ $httpClientPort Layer2.EthII.Set ]
            $clientL2 Mac.Set $::clientMacAddress

            #- Layer3 setup
            #-  HTTP Server Layer3 setup
            set serverL3 [ $httpServerPort Layer3.IPv4.Set ]
            if { $::serverPerformDhcp == 1 } {
                #- Using DHCP
                [ $serverL3 Protocol.Dhcp.Get ] Perform
            } else {
                #- Using static IP
                $serverL3 Ip.Set $::serverIpAddress
                $serverL3 Netmask.Set $::serverNetmask
                $serverL3 Gateway.Set $::serverIpGW
            }
            #-  HTTP Client Layer3 setup
            set clientL3 [ $httpClientPort Layer3.IPv4.Set ]
            if { $::clientPerformDhcp == 1 } {
                #- Using DHCP
                [ $clientL3 Protocol.Dhcp.Get ] Perform
            } else {
                #- Using static IP
                $clientL3 Ip.Set $::clientIpAddress
                $clientL3 Netmask.Set $::clientNetmask
                $clientL3 Gateway.Set $::clientIpGW
            }

            #- Get the obtained server IP address
            set serverIpAddress [ $serverL3 Ip.Get ]

            #- Create a HTTP Server
            set httpServer [ $httpServerPort Protocol.Http.Server.Add ]
            if { [ info exists ::serverTcpPort ] } {
                $httpServer Port.Set $::serverTcpPort
            } else {
                set serverTcpPort [ $httpServer Port.Get ]
            }

            #- Create a HTTP Client
            set httpClient [ $httpClientPort Protocol.Http.Client.Add ]
            $httpClient Remote.Address.Set $serverIpAddress
            $httpClient Remote.Port.Set $serverTcpPort
            if { [ info exists ::clientTcpPort ] } {
                $httpClient Local.Port.Set $::clientTcpPort
            }
            if { [ info exists ::httpMethod ] } {
                $httpClient Http.Method.Set $::httpMethod
            }

            #- Descriptions
            puts [ $server Description.Get ]
            puts [ $httpServerPort Description.Get ]
            puts [ $httpClientPort Description.Get ]

    } result ] } {
            puts stderr "Caught Exception : ${result}"
            catch { puts "Message   : [ $result Message.Get ]" } dummy
            catch { puts "Timestamp : [ $result Timestamp.Get ]" } dummy
            catch { puts "Trace :\n[ $result Trace.Get ]" } dummy
            # --- Destruct the ByteBlower Exception
            catch { $result Destructor } dummy
    }
    return [ list $httpServerPort $httpClientPort $httpServer $httpClient $server]
}

proc sci { httpServer httpClient } {
    #--------------------------------------#
    #   Show Server Client Info procedure  #
    #--------------------------------------#
    puts "HTTP Server's Client Information : "
    if { [ info exists ::httpClientSessionInfo ] } {
        # --- ByteBlower API > 1.4.4 (Supports configuring HTTP Method / using HTTP Session Info object)

        # If we have the HTTP Server Session Info already, we just refresh it,
        # otherwise, we will request it from the HTTP Server.
        if { [ info exists ::httpServerSessionInfo ] } {
            # --- Refresh the local HTTP Session Info to get the current status "snapshot"
            $::httpServerSessionInfo Refresh
        } else {
            set scId [ $httpClient ServerClientId.Get ]
            set ::httpServerSessionInfo [ $httpServer Http.Session.Info.Get $scId ]
        }

        # --- If your test has multiple HTTP Clients, it is better to get the HTTP Session information
        #     for that client and refresh it.
        # --- REMARK: Please note that the HTTP Server only keeps one HTTP Session Info for each client!
        #             This means that once you obtained the Session Info for the Client, you MUST use Refresh
        #             on that object to synchronize the status with the ByteBlower Server!
        #set scId [ $::httpClient ServerClientId.Get ]
        #set httpServerSessionInfo [ $::httpServer Http.Session.Info.Get $scId ]
        #$httpServerSessionInfo Refresh

        # --- Text based
        puts [ $::httpServerSessionInfo Description.Get ]
        # --- Value based
        #foreach httpSessionInfoMethod [ list "Speed.Mbps.Get"\
        #                                     "Request.Content.Size.Get"\
        #                                     "Request.Header.Size.Get"\
        #                                     "Request.Method.Get"\
        #                                     "Request.Size.Get"\
        #                                     "Request.Uri.Get"\
        #                                     "Role.Get"\
        #                                     "Rx.ByteCount.Total.Get"\
        #                                     "T1.Get"\
        #                                     "T2.Get"\
        #                                     "T3.Get"\
        #                                     "Tcp.CongestionWindow.Downgrades.Get"\
        #                                     "Tcp.CongestionWindow.Size.Current.Get"\
        #                                     "Tcp.CongestionWindow.Size.Maximum.Get"\
        #                                     "Tcp.Status.Get"\
        #                                     "Tx.ByteCount.Total.Get"\
        #                                     "CongestionWindow.Maximum.Get"\
        #                                     "CongestionWindow.Minimum.Get"\
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
        #    if { [ catch { eval "$::httpServerSessionInfo" "$httpSessionInfoMethod" } result ] } {
        #        puts ""
        #        puts stderr "\tCaught Exception: ${result}"
        #        catch { puts stderr "\t[ $result Message.Get ]" } dummy
        #    } else {
        #        puts $result
        #    }
        #}
    } else {
        # --- ByteBlower API <= 1.4.4 (Does not support configuring HTTP Method / using HTTP Session Info object)

        set scId [ $httpClient ServerClientId.Get ]
        set serverClientInfo [ $httpServer Http.Session.Info.Get $scId ]

        foreach { name value } $serverClientInfo {
            puts "$name\t: $value"
        }
    }
}

proc TCP_with_MTU.Run { httpServer httpClient requestSize} {

    #--------------#
    #   Test Run   #
    #--------------#
    if { [ catch {
        #- Start the HTTP Server
        $httpServer Start

        #- Set the requested size :
        $httpClient Request.Size.Set $requestSize

        #- Start the HTTP Client
        $httpClient Request.Start
        
        # --- Wait a second
        set wait 0
        after 2000 "set wait 1"
        vwait wait
            
        # Wait for the client to complete the request
        set httpClientSessionInfo [ $httpClient Http.Session.Info.Get ]

        set httpClientStatus "<UNKNOWN>"
        while { ![ $httpClient Finished.Get ] } {
            # --- Wait a second
            set wait 0
            after 1000 "set wait 1"
            vwait wait

            puts -nonewline "*"
            unset wait

            # --- Synchronize the local HTTP Client status information with the remote status to get the current status "snapshot"
            $httpClientSessionInfo Refresh
        }
        puts ""


        #- Stop the HTTP client
        #- Stopping HTTP client may reset (possible) error status
        #puts [ $httpClient Request.Stop ]

        #- Stop the HTTP stop
        $httpServer Stop

        #- Get the HTTP Client status information
        if { [ info exists httpClientSessionInfo ] } {
            # --- ByteBlower API > 1.4.4 (Supports configuring HTTP Method / using HTTP Session Info object)

            # --- Refresh the local HTTP Session Info to get the final status "snapshot"
            $httpClientSessionInfo Refresh

            #- The final status value of the HTTP client, we expect it to be "finished"
            set statusValue [ $httpClient Request.Status.Get ]

            switch -- [ $httpClientSessionInfo Request.Method.Get ] {
                "GET" {
                    # --- Data is flowing from HTTP Server to HTTP Client
                    #     => Getting receiver results from the HTTP Client Session Info

                    set httpResultSnapshot [ $httpClientSessionInfo Result.Get ]
                    $httpResultSnapshot Refresh

                    set rxBytes [ $httpResultSnapshot Rx.ByteCount.Total.Get ]
                    set avgThroughput [ $httpResultSnapshot AverageDataSpeed.Get ]
                    if { $avgThroughput > 0 } {
                        set avgThroughtput [ expr [ expr $avgThroughput / 1000000 ] * 8 ]
                    }

                    set tcpResultSnapshot [ [ $httpClientSessionInfo Tcp.Session.Info.Get ] Result.Get ]
                    $tcpResultSnapshot Refresh

                    set minCongestion [ $tcpResultSnapshot CongestionWindow.Minimum.Get ]
                    set maxCongestion [ $tcpResultSnapshot CongestionWindow.Maximum.Get ]
                }
                "PUT" {
                    # --- Data is flowing from HTTP Client to HTTP Server
                    #     => Getting receiver results from the HTTP Server Session Info
                    set httpServerSessionInfo [ $httpServer Http.Session.Info.Get [ $httpClient ServerClientId.Get ] ]
                    set httpResultSnapshot [ $httpServerSessionInfo Result.Get ]
                    $httpResultSnapshot Refresh

                    #- Received number of bits
                    set rxBytes [ $httpResultSnapshot Rx.ByteCount.Total.Get ]
                    set avgThroughput [ $httpResultSnapshot AverageDataSpeed.Get ]
                    if { $avgThroughput > 0 } {
                        set avgThroughtput [ expr [ expr $avgThroughput / 1000000 ] * 8 ]
                    }
                    
                    set tcpResultSnapshot [ [ $httpServerSessionInfo Tcp.Session.Info.Get ] Result.Get ]
                    $tcpResultSnapshot Refresh

                    set minCongestion [ $tcpResultSnapshot CongestionWindow.Minimum.Get ]
                    set maxCongestion [ $tcpResultSnapshot CongestionWindow.Maximum.Get ]
                }
                default {
                    puts sterr "Unsupported HTTP Client HTTP Request Method : '[ $httpClientSessionInfo Request.Method.Get ]'"
                    set rxBytes "?"
                    set avgThroughput "?"
                    set minCongestion "?"
                    set maxCongestion "?"
                }
            }
        } else {
            # --- ByteBlower API <= 1.4.4 (Does not support configuring HTTP Method / using HTTP Session Info object)

            set httpClientStatus [ $httpClient Status.Get ]
            puts "Client status list is:"
            puts "    $httpClientStatus"

            #- The final status value of the HTTP client, we expect it to be "finished"
            #set statusValue [ lindex $httpClientStatus 2 ]
            set statusValue [ $httpClient StatusValue.Get ]

            #- Received number of bits
            set rxBytes [ $httpClient ReceivedSize.Get ]
            set avgThroughput [ $httpClient AverageThroughput.Get ]
            set minCongestion [ $httpClient MinimumWindowSize.Get ]
            set maxCongestion [ $httpClient MaximumWindowSize.Get ]

        }

        set retVal [ list ]
        puts "TX Payload            : $requestSize bytes";	lappend retVal [ list TxBytes $requestSize ]
        puts "RX Payload            : $rxBytes bytes";		lappend retVal [ list RxBytes $rxBytes ]
        puts "Average Throughput    : $avgThroughput Mbit/s"; 	lappend retVal [ list AvgThroughput $avgThroughput ]
        puts "Min Congestion Window : $minCongestion bytes"; 	lappend retVal [ list MinCongestionWindow $minCongestion ]
        puts "Max Congestion Window : $maxCongestion bytes"; 	lappend retVal [ list MaxCongestionWindow $maxCongestion ]
        puts "Status                : $statusValue"; 		lappend retVal [ list statusValue $statusValue ]
        puts ""

        # --- Show the Information of the Client on the Server
        sci $httpServer $httpClient

    } result ] } {
        puts stderr "Caught Exception : ${result}"
        catch { puts "Message   : [ $result Message.Get ]" } dummy
        catch { puts "Timestamp : [ $result Timestamp.Get ]" } dummy
        catch { puts "Trace :\n[ $result Trace.Get ]" } dummy

        # --- Destruct the ByteBlower Exception
        catch { $result Destructor } dummy
    }
    return [ list $retVal ]
}
