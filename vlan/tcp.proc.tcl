# This tcl script contains procedures to execute a TCP test.
# It is intended to be used in conjunction with the following scripts:
#  * tcp.conf.tcl
#  * general.proc.tcl
#  * tcp.proc.tcl
#  * tcp.example.tcl
#  * tcp.run.tcl
source [ file join [ file dirname [ info script ]] .. general.proc.tcl ]

proc TCP.Setup { } {

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

        #- Layer2.5 setup
        if { $::serverOnVlan == 1 } {
            foreach vlanId $::serverVlanID {
                set serverVlanConfig [list $vlanId]
                if { [info exists ::serverVlanPriority] } {
                    lappend serverVlanConfig $::serverVlanPriority
                } else {
                    lappend serverVlanConfig ""
                }
                if { [info exists ::serverVlanDropEligible] } {
                    lappend serverVlanConfig $::serverVlanDropEligible
                }
                
                eval excentis::ByteBlower::Examples::Setup.Port.Layer2_5.Vlan $httpServerPort $serverVlanConfig
            }
        }
        if { $::clientOnVlan == 1 } {
            foreach vlanId $::clientVlanID {
                set clientVlanConfig [list $vlanId]
                if { [info exists ::clientVlanPriority] } {
                    lappend clientVlanConfig $::clientVlanPriority
                } else {
                    lappend clientVlanConfig ""
                }
                if { [info exists ::clientVlanDropEligible] } {
                    lappend clientVlanConfig $::clientVlanDropEligible
                }
                eval excentis::ByteBlower::Examples::Setup.Port.Layer2_5.Vlan $httpClientPort $clientVlanConfig
            }
        }

        #- Layer3 setup
        if { $::serverPerformDhcp == 1 } {
            set serverIpConfig dhcpv4
        } else {
            set serverIpConfig [ list $::serverIpAddress $::serverIpGW $::serverNetmask ]
        }
        if { $::clientPerformDhcp == 1 } {
            set clientIpConfig dhcpv4
        } else {
            set clientIpConfig [ list $::clientIpAddress $::clientIpGW $::clientNetmask ]
        }

        eval excentis::ByteBlower::Examples::Setup.Port.Layer3 $httpServerPort $serverIpConfig
        eval excentis::ByteBlower::Examples::Setup.Port.Layer3 $httpClientPort $clientIpConfig

        puts "Server port:"
        puts [$httpServerPort Description.Get]
        puts "Client port:"
        puts [$httpClientPort Description.Get]

        #- Get the obtained server IP address
        set serverIpAddress [ [ $httpServerPort Layer3.IPv4.Get ] Ip.Get ]

        #- Create a HTTP Server
        set httpServer [ $httpServerPort Protocol.Http.Server.Add ]
        if { [ info exists ::serverTcpPort ] } {
            $httpServer Port.Set $serverTcpPort
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
        puts [ $server Description.Get ]
        puts [ $httpServerPort Description.Get ]
        puts [ $httpClientPort Description.Get ]

        } result ] } {
            puts stderr "Caught Exception : ${result}"
            catch { puts "Message   : [ $result Message.Get ]" } dummy
            catch { puts "Timestamp : [ $result Timestamp.Get ]" } dummy
            catch { puts "Trace :\n[ $result Trace.Get ]" } dummy
    }
    # --- Destruct the ByteBlower Exception
    catch { $result Destructor } dummy

    # set global variables
    set ::httpClient $httpClient
    set ::httpServer $httpServer
    return [ list $httpServerPort $httpClientPort $httpServer $httpClient $server ]
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

    return $retVal
}


proc TCP.Run { httpServer httpClient requestSize } {
    #--------------------------------------#
    #   Show Server Client Info procedure  #
    #--------------------------------------#

    #--------------#
    #   Test Run   #
    #--------------#
    if { [ catch {

        #- Start the HTTP Server
        $httpServer Start

        #- Start the HTTP Client (request a certain number of Bytes)
        $httpClient Request.Size.Set $requestSize
        $httpClient Request.Start

        # Wait for the client to complete the request
        set ::httpClientStatus "<UNKNOWN>"
        set i 0

        while { ![ $httpClient Finished.Get ] } {
            incr i 1

            # --- Wait a second
            set wait 0
            after 1000 "set wait 1"
            vwait wait
            puts -nonewline "*"
            if { $i % 30 == 0 } {
                puts " (${i})"; flush stdout
            }
            unset wait
        }
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

        #- The final status value of the HTTP client, we expect it to be "finished"
        set statusValue [ $httpClient Request.Status.Get ]

        set httpServerSessionInfo [ $httpServer Http.Session.Info.Get [ $httpClient ServerClientId.Get ] ]

        set httpServerResult [ $httpServerSessionInfo Result.Get ]
        set httpClientResult [ $httpClientSessionInfo Result.Get ]

        set tcpServerSessionInfo [ $httpServerSessionInfo Tcp.Session.Info.Get ]
        set tcpClientSessionInfo [ $httpClientSessionInfo Tcp.Session.Info.Get ]

        set tcpServerResult [ $tcpServerSessionInfo Result.Get ]
        set tcpClientResult [ $tcpClientSessionInfo Result.Get ]

        switch -- [ $httpClientSessionInfo Request.Method.Get ] {
            "GET" {
                set txBytes [ $httpServerResult Tx.ByteCount.Total.Get ] ;# Tx from server
                set rxBytes [ $httpClientResult Rx.ByteCount.Total.Get ] ;# Rx from client

                set avgThroughput [ $httpClientResult AverageDataSpeed.Get ]
                set minCongestion [ $tcpClientResult CongestionWindow.Minimum.Get ]
                set maxCongestion [ $tcpClientResult CongestionWindow.Maximum.Get ]
            }
            "PUT" {
                set txBytes [ $httpClientResult Tx.ByteCount.Total.Get ] ;# Tx from client
                set rxBytes [ $httpServerResult Rx.ByteCount.Total.Get ] ;# Rx from server

                set avgThroughput [ $httpClientResult AverageDataSpeed.Get ]
                set minCongestion [ $tcpServerResult CongestionWindow.Minimum.Get ]
                set maxCongestion [ $tcpServerResult CongestionWindow.Maximum.Get ]
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

        set retVal [list]
        puts "Requested Payload Size : $requestSize bytes"; lappend retVal [ list srequestSize $requestSize ]
        puts "TX Payload             : $txBytes bytes"; lappend retVal [ list TxByte $txBytes]
        puts "RX Payload             : $rxBytes bytes"; lappend retVal [ list RxBytes $rxBytes]
        puts "Average Throughput     : $avgThroughput Mbit/s"; lappend retVal [ list AvgThroughput $avgThroughput ]
        puts "Min Congestion Window  : $minCongestion bytes"; lappend retVal [ list minCongestionBytes $minCongestion ]
        puts "Max Congestion Window  : $maxCongestion bytes"; lappend retVal [ list maxCongestionBytes $maxCongestion ]
        puts "Status                 : $statusValue"; lappend retVal [ list statusValue $statusValue]
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

    catch { unset ::httpServerSessionInfo } dummy
    catch { unset ::httpClientSessionInfo } dummy

    return [ list $retVal ]
}
