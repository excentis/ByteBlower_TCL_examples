package require ByteBlower

if { [ catch {
	
#-----------#
#   Setup   #
#-----------#
	
    #- Use a ByteBlower Server
    set bb [ ByteBlower Instance.Get ]
    set ::serverAddress byteblower-tutorial-1300.lab.byteblower.excentis.com
    set server [ $bb Server.Add $::serverAddress ]
    
    #- Create 2 ByteBlower Ports, for the server and the client :
    set ::physicalPort1 trunk-1-5
    set ::physicalPort2 trunk-1-6
    set httpServerPort [ $server Port.Create $::physicalPort1 ]
    set httpClientPort [ $server Port.Create $::physicalPort2 ]
    
    #- Ports Layer2 setup
    set serverL2 [ $httpServerPort Layer2.EthII.Set ]
        set ::serverMacAddress "00:ff:bb:ff:ee:dd"
    $serverL2 Mac.Set $::serverMacAddress
    
    set clientL2 [ $httpClientPort Layer2.EthII.Set ]
    set ::clientMacAddress "00:ff:bb:ff:ee:ee"
    $clientL2 Mac.Set $::clientMacAddress
    
    #- Ports Layer3 setup
    set serverL3 [ $httpServerPort Layer3.IPv4.Set ]
    set ::serverIpAddress "10.8.1.61"
    set ::serverGateway "10.8.1.1"
    set ::serverNetmask "255.255.255.0"
    $serverL3 Ip.Set $::serverIpAddress
    $serverL3 Gateway.Set $::serverGateway
    $serverL3 Netmask.Set $::serverNetmask
    $serverL3 Protocol.GratuitousArp.Reply
    
    set clientL3 [ $httpClientPort Layer3.IPv4.Set ]
    set ::clientIpAddress "10.8.1.62"
    set ::clientGateway "10.8.1.1"
    set ::clientNetmask "255.255.255.0"
    $clientL3 Ip.Set $::clientIpAddress
    $clientL3 Gateway.Set $::clientGateway
    $clientL3 Netmask.Set $::clientNetmask
    $serverL3 Protocol.GratuitousArp.Reply
    
    puts "Server port:"
    puts [$httpServerPort Description.Get]
    puts "Client port:"
    puts [$httpClientPort Description.Get]
    
    #- Create a HTTP Server
    set httpServer [ $httpServerPort Protocol.Http.Server.Add ]
    set ::serverTcpPort 5555
    $httpServer Port.Set $serverTcpPort
    
    #- Create a HTTP Client
    set httpClient [ $httpClientPort Protocol.Http.Client.Add ]
    $httpClient Remote.Address.Set $serverIpAddress
    $httpClient Remote.Port.Set $serverTcpPort
        
    set ::clientTcpPort 6666
    $httpClient Local.Port.Set $::clientTcpPort
    
#    #- Descriptions : uncomment to print more information.
#    puts [ $server Description.Get ]
#    puts [ $httpServerPort Description.Get ]
#    puts [ $httpClientPort Description.Get ]

#----------#
#    Run   #
#----------#

    #- Start the HTTP Server
    $httpServer Start
        
    #- Start the HTTP Client (request a certain number of Bytes)
    set ::requestSize 1000000000 ;# 100 MB
    $httpClient Request.Size.Set $requestSize
    $httpClient Request.Start
    
    # Wait for the client to complete the request
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
    
    #- Stop the HTTP client
    puts [ $httpClient Request.Stop ]
    
    #- Stop the HTTP server
    $httpServer Stop

#-------------#
#   Results   #
#-------------#
#	
#    #- Uncomment this block to print results.
	
    set httpSessionInfo [ $httpClient Http.Session.Info.Get ]
    puts "HTTP Client's Session Information : "
    puts [ $httpSessionInfo Description.Get ]

    set statusValue [ $httpClient Request.Status.Get ]	
    puts "Status                 : $statusValue"

    #- Get client HTTP results :
    set httpResult [ $httpSessionInfo Result.Get ]
    $httpResult Refresh
    
    puts "Requested Payload Size : $requestSize bytes"
    set txBytes [ $httpResult Tx.ByteCount.Total.Get ]
    puts "TX Payload             : $txBytes bytes"
    set rxBytes [ $httpResult Rx.ByteCount.Total.Get ]
    puts "RX Payload             : $rxBytes bytes"
    set avgThroughput [ $httpResult AverageDataSpeed.Get ]
    if { $avgThroughput > 0 } {
    	# --- Convert the Throughput from Bps to Mbps
        set avgThroughput [ expr [ expr $avgThroughput / 1000000 ] * 8 ]
    }
    puts "Average Throughput     : $avgThroughput Mbit/s"

    #- Get client TCP results :
    set tcpSessionInfo [ $httpSessionInfo Tcp.Session.Info.Get ]
    set tcpResult [ $tcpSessionInfo Result.Get ]
    $tcpResult Refresh
    set minCongestion [ $tcpResult CongestionWindow.Minimum.Get ]
    puts "Min Congestion Window  : $minCongestion bytes"
    set maxCongestion [ $tcpResult CongestionWindow.Maximum.Get ]
    puts "Max Congestion Window  : $maxCongestion bytes"

} caughtexception ] } {
    #- Exception handling
    puts stderr "Caught Exception : ${caughtexception}"
    catch { puts "Message   : [ $caughtexception Message.Get ]" } dummy
    catch { puts "Timestamp : [ $caughtexception Timestamp.Get ]" } dummy
    catch { puts "Trace :\n[ $caughtexception Trace.Get ]" } dummy
    
    # --- Destroy the ByteBlower Exception
    catch { $caughtexception Destructor } dummy
}
