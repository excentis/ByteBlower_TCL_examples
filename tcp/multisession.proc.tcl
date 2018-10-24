# This tcl script contains procedures to execute a tcp multisession Test
# It is intended to be used in conjunction with the following scripts:
#  * tcp.multisession.conf.tcl
#  * general.proc.tcl
#  * tcp.multisession.proc.tcl
#  * tcp.multisession.example.tcl
#  * tcp.multisession.run.tcl

source [ file join [ file dirname [ info script ]] .. general.proc.tcl ]

proc TCP.multisession.Setup { } {
    if { [ catch {
        #- Add a Server
        set bb [ ByteBlower Instance.Get ]
        set server [ $bb Server.Add $::serverAddress ]

        #- Create 2 ByteBlower Ports
        set httpServerPort [ $server Port.Create $::physicalPort1 ]
        set httpClientPort [ $server Port.Create $::physicalPort2 ]

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
            set serverDhcp [ $serverL3 Protocol.Dhcp.Get ]
            $serverDhcp Perform
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
            set clientDhcp [ $clientL3 Protocol.Dhcp.Get ]
            $clientDhcp Perform
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
            set ::serverTcpPort [ $httpServer Port.Get ]
        }

        #- Create a HTTP Clients
        for { set i 0 } { $i < $::numberOfHttpClients } { incr i 1 } {
            set httpClient [ $httpClientPort Protocol.Http.Client.Add ]
            $httpClient Remote.Address.Set $serverIpAddress
            $httpClient Remote.Port.Set $::serverTcpPort
            if { [ info exists ::clientTcpPort ] } {
                $httpClient Local.Port.Set $::clientTcpPort
            }
            if { [ info exists ::httpMethod ] } {
                $httpClient Http.Method.Set $::httpMethod
            }


            # --- Setting Initial TCP Window Size
            if { [ info exists ::tcpInitialWindowSize ] } {
                $httpClient InitialWindowSize.Set $::tcpInitialWindowSize
            }

            # --- Setting TCP Window Scaling
            if { [ info exists ::windowScale ] } {
                $httpServer ReceiveWindow.Scaling.Enable 1
                $httpServer ReceiveWindow.Scaling.Value.Set $::windowScale
                $httpClient ReceiveWindow.Scaling.Enable 1
                $httpClient ReceiveWindow.Scaling.Value.Set $::windowScale
            }
            
        
            # --- Setting Congestion Avoidance Algorithm
            if { [ info exists ::caa ] } {
                $httpClient Tcp.CongestionAvoidance.Algorithm.Set $::caa
            }

            # --- Configure the HTTP client to start synchronous with all other clients
            $httpClient Request.Start.Type.Set "scheduled"

            if { [ info exists ::timeOffset ] } {
                # Using convertToInt and double() instead of pure integer 
                # calculations because on 32-bit systems the initialTimeToWait
                # will easily rollover and the ByteBlower API does not accept
                # doubles
                set initialTimeToWait [ convertToInt [expr double($i) * [ parseTime $::timeOffset ] ] ]
                puts "HTTP Client $i will wait for $initialTimeToWait ns before starting"
                $httpClient Request.InitialTimeToWait.Set $initialTimeToWait
            }
            # --- Configure the number of Bytes to request
            $httpClient Request.Duration.Set $::requestDuration
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


    return [list $httpServer $httpClientPort]
}

    #--------------------------------------#
    #   Show Server Client Info procedure  #
    #--------------------------------------#

proc sci { httpServer httpClient } {
    puts "HTTP Server's Client Session Information : "
    # --- Refresh the HTTP Session Info to get the current status "snapshot"
    set scId [ $httpClient ServerClientId.Get ]
    set httpServerSessionInfo [ $httpServer Http.Session.Info.Get $scId ]

    # --- REMARK: Please note that the HTTP Server only keeps one HTTP Session Info for each client!
    #             This means that once you obtained the Session Info for the Client, you MUST use Refresh
    #             on that object to synchronize the status with the ByteBlower Server!
    $httpServerSessionInfo Refresh

    # --- Text based
    puts [set retVal [ $httpServerSessionInfo Description.Get ]]
    # --- Value based
    #foreach httpSessionInfoMethod [ list "Speed.Mbps.Get"\
    #                                     "Request.Content.Size.Get"\
    #                                     "Request.Header.Size.Get"\
    #                                     "Request.Method.Get"\
    #                                     "Request.Size.Get"\
    #                                     "Request.Duration.Get"\
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
    #    if { [ catch { eval "$httpServerSessionInfo" "$httpSessionInfoMethod" } result ] } {
    #        puts ""
    #        puts stderr "\tCaught Exception: ${result}"
    #        catch { puts stderr "\t[ $result Message.Get ]" } dummy
    #    } else {
    #        puts $result
    #    }
    #}
    return $retVal
}

proc TCP.multisession.Run { httpServer httpClientPort } {
    #--------------#
    #   Test Run   #
    #--------------#
    if { [ catch {
        #- Start the HTTP Server
        puts "#- Start the HTTP Server"
        $httpServer Start

        #- Start the HTTP Clients (request a certain number of Bytes)
        #foreach httpClient [ $httpClientPort Protocol.Http.Client.Get ] {
        #    $httpClient Request.Start
        #}
        #unset httpClient

        puts "#- Start the HTTP Clients"
        ByteBlower Ports.Start $httpClientPort

        # Wait for the clients to complete the request
        set httpClientNr 0
        foreach httpClient [ $httpClientPort Protocol.Http.Client.Get ] {
            incr httpClientNr 1

            puts "Waiting for HTTP Client ${httpClientNr}"

            set i 0
            while { ![ $httpClient Finished.Get ] } {
                incr i 1

                # --- Wait a second
                set wait 0
                after 1000 "set wait 1"
                vwait wait
                puts -nonewline "*"; flush stdout
                if { $i % 30 == 0 } {
                    puts " (${i})"; flush stdout
                }
                unset wait
            }
            puts ""
        }
        unset httpClient
        unset httpClientNr


        #- Stop the HTTP clients
        #  No need to stop the clients since the test is duration based.
        #  The clients will stop after the configured duration
        #foreach httpClient [ $httpClientPort Protocol.Http.Client.Get ] {
        #    $httpClient Request.Stop
        #}
        #unset httpClient

        #- Stop the HTTP stop
        $httpServer Stop

		#- Wait an additional second or two
		set wait 0
		after 2000 "set wait 1"
		vwait wait

        #- Get the HTTP Client status information
        set httpClientNr 0
        set retVal [list ]
        foreach httpClient [ $httpClientPort Protocol.Http.Client.Get ] {
            incr httpClientNr 1
            set httpClientSessionInfo [ $httpClient Http.Session.Info.Get ]

            # --- Refresh the local HTTP Session Info to get the final status "snapshot"
            $httpClientSessionInfo Refresh

            puts "HTTP Client ${httpClientNr}'s Session Information : "
            puts [ $httpClientSessionInfo Description.Get ]

            #- The final status value of the HTTP client, we expect it to be "finished"
            set statusValue [ $httpClient Request.Status.Get ]

            # --- Data is flowing from HTTP Server to HTTP Client
            #     => Getting receiver results from the HTTP Client Session Info
            set httpServerSessionInfo [ $httpServer Http.Session.Info.Get [ $httpClient ServerClientId.Get ] ]

            # --- Refresh the local HTTP Session Info to get the final status "snapshot"
            $httpServerSessionInfo Refresh

            switch -- [ $httpClientSessionInfo Request.Method.Get ] {
                "GET" {
                    # --- Data is flowing from HTTP Server to HTTP Client
                    #     => Getting receiver results from the HTTP Client Session Info
                    set txHttpSessionInfo $httpServerSessionInfo
                    set rxHttpSessionInfo $httpClientSessionInfo
                }
                "PUT" {
                    # --- Data is flowing from HTTP Client to HTTP Server
                    #     => Getting receiver results from the HTTP Server Session Info
                    set txHttpSessionInfo $httpClientSessionInfo
                    set rxHttpSessionInfo $httpServerSessionInfo
                }
                default {
                    puts sterr "Unsupported HTTP Client HTTP Request Method : '[ $httpClientSessionInfo Request.Method.Get ]'"
                }
            }
            if { [ info exists rxHttpSessionInfo ] && [ info exists txHttpSessionInfo ] } {
                set rxHttpResultSnapshot [ $rxHttpSessionInfo Result.Get ]
                $rxHttpResultSnapshot Refresh

                set txHttpResultSnapshot [ $txHttpSessionInfo Result.Get ]
                $txHttpResultSnapshot Refresh

                set rxBytes [ $rxHttpResultSnapshot Rx.ByteCount.Total.Get ]
                set txBytes [ $txHttpResultSnapshot Tx.ByteCount.Total.Get ]

                set avgThroughput [ expr 8 * [ $rxHttpResultSnapshot AverageDataSpeed.Get ] ]
                
                set tcpTxResultSnapshot [ [ $txHttpSessionInfo Tcp.Session.Info.Get ] Result.Get ]
                $tcpTxResultSnapshot Refresh

                set minCongestion [ $tcpTxResultSnapshot CongestionWindow.Minimum.Get ]
                set maxCongestion [ $tcpTxResultSnapshot CongestionWindow.Maximum.Get ]
            } else {
                set txBytes "?"
                set rxBytes "?"
                set avgThroughput "?"
                set minCongestion "?"
                set maxCongestion "?"
            }

            catch { unset txHttpSessionInfo } dummy
            catch { unset rxHttpSessionInfo } dummy
            unset httpServerSessionInfo
            unset httpClientSessionInfo

            # --- Show the Information of the Client on the Server
            sci $httpServer $httpClient

            #puts "Requested Duration     : $requestDuration"
            puts "TX Payload             : $txBytes bytes"
            puts "RX Payload             : $rxBytes bytes"
            puts "Average Throughput     : $avgThroughput Mbit/s"
            puts "Min Congestion Window  : $minCongestion bytes"
            puts "Max Congestion Window  : $maxCongestion bytes"
            puts "Status                 : $statusValue"
            puts ""
            lappend retVal [list -TxBytes $txBytes -RxBytes $rxBytes -AvgThroughput $avgThroughput -MinCongestionBytes $minCongestion -MaxCongestionBytes $maxCongestion -StatusValue $statusValue ]

        }
        unset httpClient
        unset httpClientNr

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

proc parseTime { timeValue } {
    if { [regexp -line {^([0-9][0-9]*)$} $timeValue match number] } {
        return $number
    } elseif { [regexp -line {^([0-9][0-9]*)s$} $timeValue match number] } {
        # Using convertToInt instead of int() because on 32-bit systems the 
        # return value will easily rollover
        return [ convertToInt [ expr double($number) * 1000000000] ]
    } else {
        return "ERROR: Cannot parse time value $timeValue. Use '<amount>' for nanoseconds and '<amount>s' for seconds"
    }
}

proc convertToInt { timeValue } {
    # Hack to work around 32-bit systems.  
    if { [ regexp -line {^([0-9][0-9]*)\..*$} $timeValue match number ] } {
        return $number
    }
    
    return $timeValue
}


