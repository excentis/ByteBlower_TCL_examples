# This tcl script contains procedures to execute a TCP NAT DMZ Test
# It is intended to be used in conjunction with the following scripts:
#  * TCP.NAT.DMZ.conf.tcl
#  * general.proc.tcl
#  * TCP.NAT.DMZ.proc.tcl
#  * TCP.NAT.DMZ.example.tcl
#  * TCP.NAT.DMZ.run.tcl

source [ file join [ file dirname [ info script ]] .. general.proc.tcl ]

proc tcp-nat-portforwarding.Setup { } {

    #----------------#
    #   Test Setup   #
    #----------------#

    #- Add a Server
    set bb [ ByteBlower Instance.Get ]
    set server [ $bb Server.Add $::serverAddress ]

    #- Create 2 ByteBlower Ports
    set httpServerPort [ $server Port.Create $::privatePhysicalPort1 ]
    set httpClientPort [ $server Port.Create $::publicPhysicalPort1 ]

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

        #- Resolve NAT device public IP address.
        #
        #  NOTE: Since the client is configured as DMZ, we can use the
        #        UDP Discovery for NAT device IP address resolution.
        set clientUdpPort 49152
        set serverPrivateUdpPort 49158
        set natPublicInfo [ ::excentis::ByteBlower::NatDevice.IP.Get $httpClientPort $httpServerPort $clientUdpPort $serverPrivateUdpPort ]
        set serverPublicIpAddress [ lindex $natPublicInfo 0 ]
        #set serverPublicTcpPort [ lindex $natPublicInfo 1 ]
        puts "DMZ Port private IPv4 adress `$serverIpAddress' is mapped to NAT device public IPv4 address '$serverPublicIpAddress'"

        #- Create a HTTP Server
        set httpServer [ $httpServerPort Protocol.Http.Server.Add ]
        if { [ info exists ::serverTcpPort ] } {
            $httpServer Port.Set $::serverTcpPort
        } else {
            set $::serverTcpPort [ $httpServer Port.Get ]
        }

        #- Create a HTTP Client
        set httpClient [ $httpClientPort Protocol.Http.Client.Add ]
        $httpClient Remote.Address.Set $serverPublicIpAddress

        #- Set the private server port as remote tcp port on the client.
        #- DMZ is active for the server IP Address, all ports are forwarded to the TCP Server
        $httpClient Remote.Port.Set $::publicServerTcpPort

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
            $httpServer WindowScaling.Enable 1
            $httpServer RcvWindowScale.Set $::windowScale
            $httpClient WindowScaling.Enable 1
            $httpClient RcvWindowScale.Set $::windowScale
        }

        #- Descriptions
        #puts [ $server Description.Get ]
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

    return [ list $httpServerPort $httpClientPort $httpServer $httpClient $server ]

}


#--------------------------------------#
#   Show Server Client Info procedure  #
#--------------------------------------#

proc sci { httpClient httpServer } {
    puts "HTTP Server's Client Session Information : "

    # If we have the HTTP Server Session Info already, we just refresh it,
    # otherwise, we will request it from the HTTP Server.
    if { [ info exists httpServerSessionInfo ] } {
        # --- Refresh the local HTTP Session Info to get the current status "snapshot"
        $httpServerSessionInfo Refresh
    } else {
        set scId [ $httpClient ServerClientId.Get ]
        set httpServerSessionInfo [ $httpServer Http.Session.Info.Get $scId ]
    }

    # --- If your test has multiple HTTP Clients, it is better to get the HTTP Session information
    #     for that client and refresh it.
    # --- REMARK: Please note that the HTTP Server only keeps one HTTP Session Info for each client!
    #             This means that once you obtained the Session Info for the Client, you MUST use Refresh
    #             on that object to synchronize the status with the ByteBlower Server!
    # --- Text based

    puts [ $httpServerSessionInfo Description.Get ]
}



proc tcp-nat-portforwarding.Run { httpServer httpClient requestDuration } {

    #--------------#
    #   Test Run   #
    #--------------#
    set retVal [list ]
    if { [ catch {

        #- Start the HTTP Server
        $httpServer Start
        

        #- Start the HTTP Client (request a certain number of Bytes)
        $httpClient Request.Duration.Set $requestDuration
        $httpClient Request.Start
        
        puts "HTTP Server description"
        puts [ $httpServer Description.Get ]

        puts "HTTP Client description"
        puts [ $httpClient Description.Get ]

        puts "Waiting for the HTTP client to be connected..."
        $httpClient WaitUntilConnected 30s
        
        puts "Waiting for the HTTP connection to finish..."
        $httpClient WaitUntilFinished 600s


        puts ""
        set httpClientSessionInfo [ $httpClient Http.Session.Info.Get ]

        #- Stop the HTTP client
        puts [ $httpClient Request.Stop ]

        #- Stop the HTTP stop
        $httpServer Stop

        #- Get the HTTP Client status information

        # --- Refresh the local HTTP Session Info to get the final status "snapshot"
        $httpClientSessionInfo Refresh

        puts "HTTP Client's Session Information : "
        puts [ $httpClientSessionInfo Description.Get ]

        set statusValue "finished"

        set httpServerSessionInfo [ $httpServer Http.Session.Info.Get [ $httpClient ServerClientId.Get ] ]
        set httpServerSessionResult [ $httpServerSessionInfo Result.Get ]
        set httpClientSessionResult [ $httpClientSessionInfo Result.Get ]

        switch -- [ $httpClientSessionInfo Request.Method.Get ] {
            "GET" {
                # --- Data is flowing from HTTP Server to HTTP Client
                #     => Getting receiver results from the HTTP Client Session Info

                #- Transmitted number of bits
                if { [ catch { $httpServerSessionResult Tx.ByteCount.Total.Get } txBytes ] } {
                    set txBytes "?"
                }

                # --- Data is flowing from HTTP Server to HTTP Client
                #     => Getting receiver results from the HTTP Client Session Info
                #- Received number of bits
                set rxBytes [ $httpClientSessionResult Rx.ByteCount.Total.Get ]
                if { [ catch { $httpClientSessionResult Rx.ByteCount.Rate.Get } avgThroughput ] } {
                    set avgThroughput "?"
                }
                set tcpSessionInfo [ $httpClientSessionInfo Tcp.Session.Info.Get ]
                set tcpSessionResult [ $tcpSessionInfo Result.Get ]
                set minCongestion [ $tcpSessionResult CongestionWindow.Minimum.Get ]
                set maxCongestion [ $tcpSessionResult CongestionWindow.Maximum.Get ]
            }
            "PUT" {
                # --- Data is flowing from HTTP Client to HTTP Server
                #     => Getting receiver results from the HTTP Server Session Info

                #- Transmitted number of bits
                if { [ catch { $httpClientSessionResult Tx.ByteCount.Total.Get } txBytes ] } {
                    set txBytes "?"
                }

                #- Received number of bits
                set rxBytes [ $httpServerSessionResult Rx.ByteCount.Total.Get ]
                if { [ catch { $httpServerSessionResult Rx.ByteCount.Rate.Get } avgThroughput ] } {
                    set avgThroughput "?"
                }
                
                set tcpSessionInfo [ $httpServerSessionInfo Tcp.Session.Info.Get ]
                set tcpSessionResult [ $tcpSessionInfo Result.Get ]
                set minCongestion [ $tcpSessionResult CongestionWindow.Minimum.Get ]
                set maxCongestion [ $tcpSessionResult CongestionWindow.Maximum.Get ]
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


        puts "Requested Duration     : $requestDuration"
        puts "TX Payload             : $txBytes bytes"
        puts "RX Payload             : $rxBytes bytes"
        puts "Average Throughput     : $avgThroughput B/s"
        puts "Min Congestion Window  : $minCongestion bytes"
        puts "Max Congestion Window  : $maxCongestion bytes"
        puts "Status                 : $statusValue"
        puts ""

        lappend retVal [ list -TxBytes $txBytes -RxBytes $rxBytes -avgThroughput $avgThroughput -minCongestion $minCongestion -maxCongestion $maxCongestion -statusValue $statusValue ]

        # --- Show the Information of the Client on the Server
        sci $httpClient $httpServer

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


