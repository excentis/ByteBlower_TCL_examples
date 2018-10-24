# This tcl script contains procedures to execute a TCP timebased test.
# It is intended to be used in conjunction with the following scripts:
#  * tcp.time-based.conf.tcl
#  * general.proc.tcl
#  * tcp.time-based.proc.tcl
#  * tcp.time-based.example.tcl
#  * tcp.time-based.run.tcl

source [ file join [ file dirname [ info script ]] .. general.proc.tcl ]

proc TCP.time-based.Setup { } {


    #- Add a Server
    set bb [ ByteBlower Instance.Get ]
    set server [ $bb Server.Add $::serverAddress ]

    #- Create 2 ByteBlower Ports
    set httpServerPort [ $server Port.Create $::physicalPort1 ]
    set httpClientPort [ $server Port.Create $::physicalPort2 ]

    if { [ catch {

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

        # --- Setting Initial TCP Window Size
        if { [ info exists ::tcpInitialWindowSize ] } {
            $httpClient ReceiveWindow.InitialSize.Set $::tcpInitialWindowSize
        }
        
        # --- Setting Congestion Avoidance Algorithm
        if { [ info exists ::caa ] } {
            $httpClient Tcp.CongestionAvoidance.Algorithm.Set $::caa
        }

        # --- Setting TCP Window Scaling
        if { [ info exists ::windowScale ] } {
            $httpServer ReceiveWindow.Scaling.Enable 1
            $httpServer ReceiveWindow.Scaling.Value.Set $::windowScale
            $httpClient ReceiveWindow.Scaling.Enable 1
            $httpClient ReceiveWindow.Scaling.Value.Set $::windowScale
        }

        #- Descriptions
        puts [ $server Description.Get ]
        puts [ $httpServerPort Description.Get ]
        puts [ $httpClientPort Description.Get ]

    } result ] } {
        puts stderr ${::errorInfo}
        puts stderr ""
        puts stderr "Caught Exception : ${result}"
        catch { puts "Message   : [ $result Message.Get ]" } dummy
        catch { puts "Timestamp : [ $result Timestamp.Get ]" } dummy
        catch { puts "Trace :\n[ $result Trace.Get ]" } dummy

        # --- Destruct the ByteBlower Exception
        catch { $result Destructor } dummy
    }
    return [ list $httpServerPort $httpClientPort $httpServer $httpClient $server]
}


    #--------------------------------------#
    #   Show Server Client Info procedure  #
    #--------------------------------------#

    proc sci { httpServer httpClient } {
        puts "HTTP Server's Client Session Information : "
        # We request the HTTP Server's Client Session Info from the HTTP Server.
        set scId [ $httpClient ServerClientId.Get ]
        set httpServerSessionInfo [ $httpServer Http.Session.Info.Get $scId ]
        # --- We may 'Refresh' it to be sure we have the latest status "snapshot"
        #     as known at the ByteBlower Server
        # --- NOTE: If your test has multiple HTTP Clients, it is better to get
        #           the HTTP Session information for that client and refresh it.
        # --- REMARK: Please note that the HTTP Server only keeps one HTTP Session Info for each client!
        #             This means that once you obtained the Session Info for the Client, you MUST use Refresh
        #             on that object to synchronize the status with the ByteBlower Server!
        $httpServerSessionInfo Refresh

        # --- Text based
        puts [ $httpServerSessionInfo Description.Get ]
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
    }

proc TCP.time-based.Wait { ms } {
	# --- Wait a second
    set wait 0
	after ${ms} "set wait 1"
	vwait wait
	unset wait
}

proc TCP.time-based.Run { httpServer httpClient requestDuration } {
    #--------------#
    #   Run Test   #
    #--------------#
    if { [ catch {
        #- Start the HTTP Server
        $httpServer Start

        #- Start the HTTP Client (request to send data during a certain given duration)
        $httpClient Request.Duration.Set $requestDuration
        $httpClient Request.Start

		TCP.time-based.Wait 2000

        # --- ByteBlower API > 1.4.4 (Supports configuring HTTP Method / using HTTP Session Info object)
        set httpClientSessionInfo [ $httpClient Http.Session.Info.Get ]

        #- Wait for the client to complete the request
        set i 0
        while { ![ $httpClient Finished.Get ] } {
            incr i 1

            # --- Wait a second
            TCP.time-based.Wait 1000
            
            puts -nonewline "*"; flush stdout
            if { $i % 30 == 0 } {
                puts " (${i})"; flush stdout
            }

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
        # --- Refresh the local HTTP Session Info to get the final status "snapshot"
        $httpClientSessionInfo Refresh

        puts "HTTP Client's Session Information : "
        puts [ $httpClientSessionInfo Description.Get ]

        #- The final status value of the HTTP client, we expect it to be "finished"
        set statusValue [ $httpClient Request.Status.Get ]

        set httpServerSessionInfo [ $httpServer Http.Session.Info.Get [ $httpClient ServerClientId.Get ] ]

        switch -- [ $httpClientSessionInfo Request.Method.Get ] {
            "GET" {
                # Data is flowing from HTTP Server to HTTP Client

                set httpServerResultSnapshot [ $httpServerSessionInfo Result.Get ]
                $httpServerResultSnapshot Refresh

                set httpClientResultSnapshot [ $httpClientSessionInfo Result.Get ]
                $httpClientResultSnapshot Refresh

                puts "GET httpServerResultSnapshot: [ $httpServerResultSnapshot Description.Get ]"
                puts "GET httpClientResultSnapshot: [ $httpClientResultSnapshot Description.Get ]"

                set rxBytes [ $httpClientResultSnapshot Rx.ByteCount.Total.Get ]
                set txBytes [ $httpServerResultSnapshot Tx.ByteCount.Total.Get ]

                set avgThroughput [ $httpClientResultSnapshot AverageDataSpeed.Get ]
                if { $avgThroughput > 0 } {
                    set avgThroughtput [ expr [ expr $avgThroughput / 1000000 ] * 8 ]
                }
                
                set tcpServerResultSnapshot [ [ $httpServerSessionInfo Tcp.Session.Info.Get ] Result.Get ]
                $tcpServerResultSnapshot Refresh

                set minCongestion [ $tcpServerResultSnapshot CongestionWindow.Minimum.Get ]
                set maxCongestion [ $tcpServerResultSnapshot CongestionWindow.Maximum.Get ]
            }
            "PUT" {
                # Data is flowing from HTTP Client to HTTP Server

                set httpServerResultSnapshot [ $httpServerSessionInfo Result.Get ]
                $httpServerResultSnapshot Refresh

                set httpClientResultSnapshot [ $httpClientSessionInfo Result.Get ]
                $httpClientResultSnapshot Refresh

                puts "PUT httpServerResultSnapshot: [ $httpServerResultSnapshot Description.Get ]"
                puts "PUT httpClientResultSnapshot: [ $httpClientResultSnapshot Description.Get ]"

                set rxBytes [ $httpServerResultSnapshot Rx.ByteCount.Total.Get ]
                set txBytes [ $httpClientResultSnapshot Tx.ByteCount.Total.Get ]

                set avgThroughput [ $httpServerResultSnapshot AverageDataSpeed.Get ]
                if { $avgThroughput > 0 } {
                    set avgThroughtput [ expr [ expr $avgThroughput / 1000000 ] * 8 ]
                }

                set tcpClientResultSnapshot [ [ $httpClientSessionInfo Tcp.Session.Info.Get ] Result.Get ]
                $tcpClientResultSnapshot Refresh

                set minCongestion [ $tcpClientResultSnapshot CongestionWindow.Minimum.Get ]
                set maxCongestion [ $tcpClientResultSnapshot CongestionWindow.Maximum.Get ]
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

        puts "HTTP Client Session information"
        puts [ $httpClientSessionInfo Description.Get ]

        # --- Show the Information of the Client on the Server
        sci $httpServer $httpClient

        set retVal [list ]
        puts "Requested duration    : $requestDuration"	; 		lappend retVal [ list requestDuration $requestDuration ]
        puts "TX Payload            : $txBytes bytes"	;		lappend retVal [ list TxBytes $txBytes ]
        puts "RX Payload            : $rxBytes bytes"	;		lappend retVal [ list RxBytes $rxBytes ]
        puts "Average Throughput    : $avgThroughput Mbit/s"	;	lappend retVal [ list AvgThroughput $avgThroughput ]
        puts "Min Congestion Window : $minCongestion bytes"	;	lappend retVal [ list minCongestionBytes $minCongestion ]
        puts "Max Congestion Window : $maxCongestion bytes";		lappend retVal [ list maxCongestionBytes $maxCongestion ]
        puts "Status                : $statusValue";			lappend retVal [ list statusValue $statusValue ]
        puts ""

    } result ] } {
        puts stderr ${::errorInfo}
        puts stderr ""
        puts stderr "Caught Exception : ${result}"
        catch { puts "Message   : [ $result Message.Get ]" } dummy
        catch { puts "Timestamp : [ $result Timestamp.Get ]" } dummy
        catch { puts "Trace :\n[ $result Trace.Get ]" } dummy

        # --- Destruct the ByteBlower Exception
        catch { $result Destructor } dummy
    }

    catch { unset ::httpServerSessionInfo } dummy
    catch { unset ::httpClientSessionInfo } dummy

    return [ list $retVal ]
}
