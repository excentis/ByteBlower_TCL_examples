# This tcl script contains procedures to execute a Telnet test.
# It is intended to be used in conjunction with the following scripts:
#  * telnet.conf.tcl
#  * general.proc.tcl
#  * telnet.proc.tcl
#  * telnet.example.tcl
#  * telnet.run.tcl

source [ file join [ file dirname [ info script ]] .. general.proc.tcl ]

proc Telnet.Setup { } {
    # --- Connect to the ByteBlower Server
    set bb [ ByteBlower Instance.Get ]
    set server [ $bb Server.Add $::serverAddress ]

    # --- Create the ByteBlower Ports
    set port [ $server Port.Create $::physicalPort ]

    if { [ catch {

            # --- Setup Layer2
            set l2 [ $port Layer2.EthII.Set ]
            $l2 Mac.Set $::macAddress

            # --- Setup Layer3
            set l3 [ $port Layer3.IPv4.Set ]
            if { $::performDhcp == 1 } {
                # Using Dhcp
                set dhcp [ $l3 Protocol.Dhcp.Get ]
                $dhcp Perform
            } else {
                # Using static IP address
                $l3 Ip.Set $::ipAddress
                $l3 Netmask.Set $::netmask
                $l3 Gateway.Set $::gateway
            }

            # --- Setup Telnet Client
            set telnetClient [ $port Protocol.Telnet.Client.Add ]

            # --- Setting Remote Address
            $telnetClient Remote.Address.Set $::telnetRemoteAddress

            # --- Setting Remote Port
            if { [ info exists ::telnetRemotePort ] } {
                $telnetClient Remote.Port.Set $::telnetRemotePort
            }

            # --- Setting Local Port
            if { [ info exists ::telnetLocalPort ] } {
                $telnetClient Local.Port.Set $::telnetLocalPort
            }

            puts [ $telnetClient Description.Get ]


    } result ] } {
        puts stderr "Caught Exception    : `${result}'"
        catch { puts "Exception Message   : [ $result Message.Get ]" } dummy
        catch { puts "Exception Timestamp : [ $result Timestamp.Get ]" } dummy
        catch { puts "Exception Trace     : [ $result Trace.Get ]" } dummy

        # --- Destruct the ByteBlower Exception
        catch { $result Destructor } dummy

        # --- Close the Telnet Connection
        catch { $telnetClient Close } dummy
    }
    return [ list $server $port $telnetClient ]
}



proc Telnet.Run { server port telnetClient } {
    #--------------#
    #   Test Run   #
    #--------------#

    set retVal [ list ]

    if { [ catch {

        # --- Show configuration
        #puts [ $server Description.Get ]
        #puts [ $port Description.Get ]


        # --- Open the Telnet connection
        $telnetClient Open


        # --- Did we receive a login prompt?
        puts "Rx: [ Telnet.Wait_prompt $telnetClient "telnet login:" $::WaitForTimeout ]"

        # --- Send our UserName
        $telnetClient Send "${::telnetUserName}\r"
        puts "TX: ${::telnetUserName}"

        # --- Wait for the Password prompt
        puts "Rx: [ Telnet.Wait_prompt $telnetClient "Password:" $::WaitForTimeout ]"

        # --- Send our Password
        $telnetClient Send "${::telnetPassword}\r"
        puts "TX: ${::telnetPassword}"

        puts "Rx: [ Telnet.Wait_prompt $telnetClient "$" $::WaitForTimeout ]"

        # --- Now, we can start sending commands
        foreach telnetCommand $::telnetCommandList {
            # --- Send our Telnet command
            $telnetClient Send "${telnetCommand}"
            regsub -all {\r} $telnetCommand '\n' putsTelnetCommand
            puts "TX: `${putsTelnetCommand}'"

            puts "Rx: [ Telnet.Wait_prompt $telnetClient "$" $::WaitForTimeout ]"
        }

        # Exit telnet the session
        $telnetClient Send "exit\r"

        # Discard the output of the exit command.
        $telnetClient Receive

        # --- Print the current Telnet Status
        puts [ $telnetClient Description.Get ]
        # --- Close the Telnet Connection
        $telnetClient Close      
        lappend retVal [ list TcpStatus [ $telnetClient ConnectionState.Get  ] ]



    } result ] } {
        puts stderr "Caught Exception    : `${result}'"
        catch { puts "Exception Message   : [ $result Message.Get ]" } dummy
        catch { puts "Exception Timestamp : [ $result Timestamp.Get ]" } dummy
        catch { puts "Exception Trace     : [ $result Trace.Get ]" } dummy

        # --- Destruct the ByteBlower Exception
        catch { $result Destructor } dummy

        # --- Close the Telnet Connection
        catch { $telnetClient Close } dummy
    }
    return [ list $retVal ]
}

proc Telnet.Wait_prompt { telnetClient prompt timeout } {

    set i 0
    set output ""

    while { $i < $timeout } {
        incr i
        set ::waiter 0
        after 1000 "set ::waiter 1"
        vwait ::waiter
        set newData [ $telnetClient Receive ]
        append output $newData
        if { [ string length $prompt ] > 0 } {
            set promptIndex [ string last [ string tolower $prompt ] [ string tolower $output ] ]
            if { $promptIndex != -1 && $promptIndex >= [ expr [ string length $output ] - [ string length $prompt ] - 3 ] } {
                break;
            }
        }
    }
    return $output
}

