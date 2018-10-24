#!/usr/bin/tclsh
#
#------------------------#
#   Test Configuration   #
#------------------------#

# --- ByteBlower Server address
set bbServerAddress "byteblower-dev-2100-2.lab.byteblower.excentis.com."

# --- Number of PPPoE Sessions to create
set nrOfSessions 512
#set nrOfSessions 120
#set nrOfSessions 48 ;# dropped performance?
#set nrOfSessions 24 ;# performance OK

# --- Mac address of the first port, next ports will use Mac address + 1
set baseMacAddress 00:ff:12:00:00:01

# --- Base IPv4 address to generate PAP username from, next PAP user names will use IPv4 Address + 1
set baseIpv4Address 10.10.10.2

# --- Only one fixed password "j"
set papPassword "bb-pppoe"

# --- Network Protocol to use
set networkProtocol "ipcp"
#set networkProtocol "ipv6cp"

# --- Configure timing
# --- Time to wait after previous PPPoE Session is started
#set startInterSessionGap 20 ;# in ms
set startInterSessionGap 5 ;# in ms

# --- Wait X ms after Starting all PPPoE Sessions to Terminate all Sessions
#set terminateAfterStartTime 1000 ;# in ms
set terminateAfterStartTime 5000 ;# in ms

# --- Time to wait after previous PPPoE Session is terminated
#set terminateInterSessionGap 20 ;# in ms
set terminateInterSessionGap 10 ;# in ms

#----------------#
#   Test Setup   #
#----------------#

# --- Load the ByteBlower libraries
package require ByteBlower

# --- Get the ByteBlower HL PPPoE support functions
package require ByteBlowerHL

# --- Connect to the ByteBlower Server
set bbServer [ ByteBlower Server.Add $bbServerAddress ]

# --- Create the UserName and Password List
# --- Creating an IPv4 based PAP user name list
#set papUserNameList [ list ]
#set ipv4Address $baseIpv4Address
#for { set i 0 } { $i < $nrOfSessions } { incr i 1 } {
#    # --- Create the username for the given IPv4 address
#    set papUserName [ eval format {"u-%02d-%02d-%02d-%02d@j.net"} [ IP.To.Hex $ipv4Address ] ]
#
#    # --- Add the username to the list
#    lappend papUserNameList $papUserName
#
#    # --- Generate the next IPv4 address
#    set ipv4Address [ IP.Increment $ipv4Address ]
#}
set papUserNameList [ list "bb-pppoe" ]

# --- Fixed password for all PAP users
set papPasswordList [ list $papPassword ]

#------------------#
#   Running Test   #
#------------------#

puts "MultiSession PPPoE example : Setting up $nrOfSessions PPPoE Sessions"
set multiSessionId [ ::excentis::ByteBlower::PPPoE.MultiPPPoESessions.Setup $bbServer $nrOfSessions $baseMacAddress $papUserNameList $papPasswordList $startInterSessionGap $networkProtocol ]

puts "MultiSession PPPoE example : Starting $nrOfSessions PPPoE Sessions"
::excentis::ByteBlower::PPPoE.MultiPPPoESessions.Start $multiSessionId $startInterSessionGap

if { $terminateAfterStartTime > 0 } {
    puts "MultiSession PPPoE example : Waiting [ expr $terminateAfterStartTime - 10000 ]ms before terminating all PPPoE Sessions"
    set waiter 0
    after $terminateAfterStartTime "set waiter 1"
    vwait waiter
}

puts "MultiSession PPPoE example : Terminating PPPoE Sessions"
::excentis::ByteBlower::PPPoE.MultiPPPoESessions.Terminate $multiSessionId $terminateInterSessionGap

puts "MultiSession PPPoE example : Cleaning up PPPoE Sessions"
::excentis::ByteBlower::PPPoE.MultiPPPoESessions.CleanUp $multiSessionId

puts "MultiSession PPPoE example : all done!"

# --- all done
#exit 0
