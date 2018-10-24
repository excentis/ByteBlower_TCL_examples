# This tcl script contains procedures to capture HTTP data.
# It is intended to be used in conjunction with the following scripts:
#  * http_uri_capture.conf.tcl
#  * general.proc.tcl
#  * http_uri_capture.proc.tcl
#  * http_uri_capture.example.tcl
#  * http_uri_capture.run.tcl

source [ file join [ file dirname [ info script ]] .. general.proc.tcl ]

#----------------#
#   Test Setup   #
#----------------#


proc http_uri_capture.Setup {} {
    # --- Connect to the ByteBlower Server
    set ::bb [ ByteBlower Instance.Get ]
    set ::server [ $::bb Server.Add $::serverAddress ]

    # --- Create the ByteBlower Ports
    set ::port [ $::server Port.Create $::physicalPort ]

    if { [ catch {
        # --- Setup Layer2
        set l2 [ $::port Layer2.EthII.Set ]
        $l2 Mac.Set $::macAddress

        # --- Setup Layer3
        set l3 [ $::port Layer3.IPv4.Set ]
        if { $::performDhcp == 1 } {
            # Using Dhcp
            [ $l3 Protocol.Dhcp.Get ] Perform
        } else {
            # Using static IP address
            $l3 Ip.Set $::ipAddress
            $l3 Netmask.Set $::netmask
            $l3 Gateway.Set $::gateway
        }

        # --- Setup Http Client
        #     No further setup is required since the ByteBlower Server does the
        #     parsing of the HTTP Request URI as specified by the URI format
        #     specifications.
        set ::httpClient [ $::port Protocol.Http.Client.Add ]

        # --- Enable Capturing on the HTTP Client
        $::httpClient Capture.Enable

        set ::httpSaveFile [ file join [ pwd ] $::httpSaveFile ]

    } result ] } {

        puts stderr "Caught Exception    : `${result}'"
        catch { puts "Exception Message   : [ $result Message.Get ]" } dummy
        catch { puts "Exception Timestamp : [ $result Timestamp.Get ]" } dummy
        catch { puts "Exception Trace     : [ $result Trace.Get ]" } dummy

        # Destruct the ByteBlower Exception
        catch { $result Destructor } dummy

    }
    return [list 1 2 3]
}

proc http_uri_capture.Run {} {
    #--------------#
    #   Test Run   #
    #--------------#
    set retVal [list ]
    if { [ catch {
    
        $::httpClient Request.Uri.Set $::httpRequestUri
                    
        # --- Show configuration
        puts [ $::server Description.Get ]
        puts [ $::port Description.Get ]

        # --- Request the page

        $::httpClient Request.Start
        
        # --- Wait until the client is connected
        #     maximum 100 ms 
        $::httpClient WaitUntilConnected 100000000 ;#ns
      
        set ::httpClientSessionInfo [$::httpClient Http.Session.Info.Get]

        # --- Wait until the Request finished
        while { ![ $::httpClient Finished.Get ] } {
            set ::waiter 0
            after 1000 "set ::waiter 1"
            vwait ::waiter
            puts -nonewline "*"; update
            $::httpClientSessionInfo Refresh
        }
        puts ""

        # --- Get the HTTP Client Status information
        $::httpClientSessionInfo Refresh
        set ::tcpSessionInfo [ $::httpClientSessionInfo Tcp.Session.Info.Get ]
        set ::tcpSessionResult [ $::tcpSessionInfo Result.Get ]
        $::tcpSessionResult Refresh


        puts "HTTP Client final status:"

        set httpStatus [ $::httpClient Request.Status.Get ]


        puts "  + Status                : $httpStatus"

        puts "  + MinWindowSize         : [ $::tcpSessionResult ReceiverWindow.Minimum.Get ]"
        puts "  + MaxWindowSize         : [ $::tcpSessionResult ReceiverWindow.Maximum.Get ]"
        puts "  + MaxCongestWindowSize  : [ $::tcpSessionResult CongestionWindow.Maximum.Get ]"
        puts "  + CurCongestWindowSize  : [ $::tcpSessionResult CongestionWindow.Current.Get ]"
        puts "  + Retransmissions       : [ $::tcpSessionResult RetransmissionCount.Total.Get ]"
        puts "  + ReceivedSize          : [ $::tcpSessionResult Rx.ByteCount.Total.Get ]"

        lappend retVal [ list StateValue $httpStatus ]

        lappend retVal [ list MinWindowSize [ $::tcpSessionResult ReceiverWindow.Minimum.Get ] ]
        lappend retVal [ list MaxWindowSize [ $::tcpSessionResult ReceiverWindow.Maximum.Get ] ]

        lappend retVal [ list MaxCongestionWindowSize    [ $::tcpSessionResult CongestionWindow.Maximum.Get ] ]
        lappend retVal [ list FinalCongestionWindowSize  [ $::tcpSessionResult CongestionWindow.Current.Get ] ]
        lappend retVal [ list CongestionWindowDowngrades [ $::tcpSessionResult RetransmissionCount.Total.Get ] ]

        lappend retVal [ list ReceivedSize [ $::tcpSessionResult Rx.ByteCount.Total.Get ] ]

        
        set speed [ expr [ $::tcpSessionResult Rx.ByteCount.Total.Get ] / (([ $::tcpSessionResult Timestamp.FinSent.Get   ] - [ $::tcpSessionResult Timestamp.SynSent.Get  ]) / 1000000000.0)]
        
        puts ""
        puts "  + Requested URI         : $::httpRequestUri"
        puts "  + Average Throughput    : $speed bytes/s"
        lappend retVal [ list AverageThroughput $speed ]

        # --- Get the HTTP Capture
        set httpCapture [ $::httpClient Capture.Get ]

        # --- HTTP Capture 'Refresh" method can be used when the data is
        #     parsed while the HTTP Client is still active.
        #     The 'Refresh' method will then synchronise the data with the
        #     captured HTTP Data on the ByteBlower Server.
        #$httpCapture Refresh

        # --- Print the HttpCapture Description
        puts ""
        puts "*** Captured HTTP Data Information ***"
        puts ""
        puts [ $httpCapture Description.Get ]



        # --- Uncomment the following lines to show the received HTTP Data (and Size) in the console
        #puts ""
        #puts "The HTTP Client captured [ $httpCapture Http.Size.Get ] Bytes"
        #puts "The HTTP Client captured data :"
        #puts [ $httpCapture Http.Bytes.Get ]
        lappend retVal [ list size [ $httpCapture Http.Size.Get ] ]
        #lappend retVal [ list bytes [ $httpCapture Http.Bytes.Get ] ]

        # --- Store the Captured HTTP Data
        puts ""
        puts "*** Saving Captured HTTP Data ***"
        puts ""
        $httpCapture Http.Bytes.Save $::httpSaveFile
        puts "The HTTP Client captured data is saved to `${::httpSaveFile}'"

    } result ] } {
        puts stderr "Caught Exception    : `${result}'"
        catch { puts "Exception Message   : [ $result Message.Get ]" } dummy
        catch { puts "Exception Timestamp : [ $result Timestamp.Get ]" } dummy
        catch { puts "Exception Trace     : [ $result Trace.Get ]" } dummy

        # Destruct the ByteBlower Exception
        catch { $result Destructor } dummy
    }
    return [ list $retVal ]
}

