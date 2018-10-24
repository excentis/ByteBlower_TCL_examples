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
    
    set meetingPoint [ $bb MeetingPoint.Add $::meetingPointAddress ]

    #- Create  ByteBlower Port
    set httpServerPort [ $server Port.Create $::physicalPort1 ]
    
    #- Get Wireless Endpoint
    set wirelessEndpoint [ $meetingPoint Device.Get $::wirelessEndpointUUID ]
    
    if { [ catch {

        #- Layer2 setup
        set serverL2 [ $httpServerPort Layer2.EthII.Set ]
        $serverL2 Mac.Set $::serverMacAddress


        #- Layer3 setup
        #-  HTTP Server Layer3 setup
        if { $::serverPerformDhcp == 1 } {
            set serverIpConfig dhcpv4
        } else {
            set serverIpConfig [ list $::serverIpAddress $::serverIpGW $::serverNetmask ]
        }

        eval excentis::ByteBlower::Examples::Setup.Port.Layer3 $httpServerPort $serverIpConfig
        
        puts "Server port:"
        puts [$httpServerPort Description.Get]
        
        puts "Client Endpoint:"
        puts [$wirelessEndpoint Description.Get]

        #- Get the obtained server IP address
        set serverIpAddress [ [ $httpServerPort Layer3.IPv4.Get ] Ip.Get ]

        #- Create a HTTP Server
        set httpServer [ $httpServerPort Protocol.Http.Server.Add ]
        if { [ info exists serverTcpPort ] } {
            $httpServer Port.Set $serverTcpPort
        } else {
            set serverTcpPort [ $httpServer Port.Get ]
        }

        #- Create a HTTP Client
        set httpClient [ $wirelessEndpoint Protocol.Http.Client.Add ]
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
        puts [ $wirelessEndpoint Description.Get ]

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
    return [ list $httpServerPort $wirelessEndpoint $httpServer $httpClient $server $meetingPoint ]
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


#--------------#
#   Test Run   #
#--------------#

proc TCP.Run { wirelessEndpoint httpServer httpClient requestDuration } {
    set retVal [list]
    if { [ catch {

        #- Start the HTTP Server
        $httpServer Start

        #- Start the HTTP Client (request a certain number of Bytes)
        $httpClient Request.Duration.Set $requestDuration

        #- We are ready, claim the device
        $wirelessEndpoint Lock 1

        #- Communicate the scenario to the HTTP Client
        $wirelessEndpoint Prepare
        
        #- Start the client, return value is the starttime on the meetingpoint
        #  On which the device will really start
        set startTime [ $wirelessEndpoint Start ]
        set meetingPoint [ $wirelessEndpoint Parent.Get ]
        set curTime [ $meetingPoint Timestamp.Get ]
        
        #- Wait until the device is really started
        set wait 0
        after [ expr int((double($startTime) - $curTime) / 1000000) ] "set wait 1"
        vwait wait
        unset wait



        set counter 0
        set max_counter 20
        set server_client_id [ $httpClient ServerClientId.Get ]

        while { ! [ $httpServer HasSession $server_client_id ] } {
            puts "Waiting until connection established (${counter}/${max_counter})"

            if { $counter == $max_counter } {
                break;
            }

            set x 0; after 1000 { set x 1; }; vwait x

            incr counter
        }
        if { $counter < $max_counter } {
            puts "Connection established!"
        } else {
            puts "Connection was not established"
        }

        puts "Wait until flow finished ([expr double(${requestDuration}) / 1000000000] seconds)"

        set wait 0
        after [ expr int( double(${requestDuration}) / 1000000 ) ] "set wait 1"
        vwait wait
        unset wait
        
        

        #- Stop the HTTP stop
        $httpServer Stop

        set http_session_info [ $httpServer Http.Session.Info.Get $server_client_id ]
        set tcp_session_info [ $http_session_info Tcp.Session.Info.Get ]


        # --- Refresh the local HTTP Session Info to get the final status "snapshot"
        


        switch -- [ $http_session_info Request.Method.Get ] {
            "GET" {
                # --- Data is flowing from HTTP Server to HTTP Client
                #     => Getting receiver results from the HTTP Client Session Info
                set httpResult [ $http_session_info Result.Get ]
                $httpResult Refresh

                set txBytes [ $httpResult Tx.ByteCount.Total.Get ]
                set rxBytes [ $httpResult Rx.ByteCount.Total.Get ]
                set avgThroughput [ $httpResult AverageDataSpeed.Get ]

                set tcpResult [ $tcp_session_info Result.Get ]
                $tcpResult Refresh

                set minCongestion [ $tcpResult CongestionWindow.Minimum.Get ]
                set maxCongestion [ $tcpResult CongestionWindow.Maximum.Get ]
            }
            "PUT" {
                # --- Data is flowing from HTTP Client to HTTP Server
                #     => Getting receiver results from the HTTP Server Session Info
                set httpResult [ $http_session_info Result.Get ]
                $httpResult Refresh

                set txBytes [ $httpResult Tx.ByteCount.Total.Get ]
                set rxBytes [ $httpResult Rx.ByteCount.Total.Get ]
                set avgThroughput [ $httpResult AverageDataSpeed.Get ]
                


                set tcpResult [ $tcp_session_info Result.Get ]
                $tcpResult Refresh

                set minCongestion [ $tcpResult CongestionWindow.Minimum.Get ]
                set maxCongestion [ $tcpResult CongestionWindow.Maximum.Get ]
            }
            default {
                puts sterr "Unsupported HTTP Client HTTP Request Method : '[ $http_session_info Request.Method.Get ]'"
                set txBytes "?"
                set rxBytes "?"
                set avgThroughput "?"
                set minCongestion "?"
                set maxCongestion "?"
            }
            }

        set retVal [list]
        puts "Requested Duration     : $requestDuration ns"; lappend retVal [ list requestDuration $requestDuration ]
        puts "TX Payload             : $txBytes bytes"; lappend retVal [ list TxBytes $txBytes]
        puts "RX Payload             : $rxBytes bytes"; lappend retVal [ list RxBytes $rxBytes]
        puts "Average Throughput     : $avgThroughput bit/s"; lappend retVal [ list AvgThroughput $avgThroughput ]
        puts "Min Congestion Window  : $minCongestion bytes"; lappend retVal [ list minCongestionBytes $minCongestion ]
        puts "Max Congestion Window  : $maxCongestion bytes"; lappend retVal [ list maxCongestionBytes $maxCongestion ]
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
    
    catch { $wirelessEndpoint Lock 0 }

    catch { unset ::httpServerSessionInfo } dummy

    return [ list $retVal ]
}
