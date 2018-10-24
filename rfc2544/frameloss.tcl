# XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
# Test Objective:
# ===============
# To determine the DUT throughput as defined in RFC1242
#
# XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
# Procedure:
# ==========
# Send a specific number of frames at a specific rate through
# the DUT and then count the frames that are transmitted by
# the DUT. If the count of offered frames is equal to the
# count of received frames, the fewer frames are received
# than were transmitted, the rate of offered stream is
# reduced and the test is rerun.
# XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX

#------------------------#
#   Test Configuration   #
#------------------------#

source ./frameloss.algo.tcl

# --- ByteBlower Server address
set serverAddress1 byteblower-dev-1300-2.lab.byteblower.excentis.com
set serverAddress2 $serverAddress1

# --- Physical Ports to connect the logical ByteBlowerPorts to
set physicalPort1 trunk-1-14
set physicalPort2 trunk-1-15
# --- Layer2 Configuration
set srcMacAddress1 "00:FF:BB:04:01:01"
set destMacAddress1 "00:FF:BB:04:01:02"

# --- Layer3 Configuration
# --- Back-To-Back Destination Port Layer3 Configuration
#   - Set to 1 if you want to use DHCP
set srcPerformDhcp1 1
#   - else use static IPv4 Configuration
#set srcIpAddress1 "10.10.0.2"
#set srcNetmask1 "255.255.255.0"
#set srcIpGW1 "10.10.0.1"

# --- Back-To-Back Destination Port Layer3 Configuration
#   - Set to 1 if you want to use DHCP
set destPerformDhcp1 1
#   - else use static IPv4 Configuration
#set destIpAddress1 "10.10.0.3"
#set destNetmask1 "255.255.255.0"
#set destIpGW1 "10.10.0.1"

set frameSize 1514
set maxFrameRate 80000
set granularity 10
# XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX

#------------------------#
#   Test Initialisation  #
#------------------------#

#- What would we do without the package ;-)
package require ByteBlower
#- Required ByteBlower HL packages
package require excentis_basic
package require ByteBlowerHL

set bb [ ByteBlower Instance.Get ]
set server1 [ $bb Server.Add $serverAddress1 ]
set server2 [ $bb Server.Add $serverAddress2 ]


### Sender port.
set sender [ $server1 Port.Create $physicalPort1 ]
[ $sender Layer2.EthII.Set ] Mac.Set $srcMacAddress1
# IP
if { $srcPerformDhcp1 == 1 } {
	set srcIpConfig dhcpv4
} else {
	set srcIpConfig [ list $srcIpAddress1 $srcIpGW1 $srcNetmask1 ]
}

eval excentis::ByteBlower::Examples::Setup.Port.Layer3 $sender $srcIpConfig

puts "SENDER SENDER SENDER SENDER"
puts [ $sender Description.Get ]

### Reciever port.
set receiver [ $server2 Port.Create $physicalPort2 ]
[ $receiver Layer2.EthII.Set ] Mac.Set $destMacAddress1

# IP
if { $destPerformDhcp1 == 1 } {
	set destIpConfig dhcpv4
} else {
	set destIpConfig [ list $destIpAddress1 $destIpGW1 $destNetmask1 ]
}
eval excentis::ByteBlower::Examples::Setup.Port.Layer3 $receiver $destIpConfig

puts "RECEIVER RECEIVER RECEIVER RECEIVER"
puts [ $receiver Description.Get ]


set fd [ open "results.txt" w ]

if { [ catch {
            #sender receiver frameSize maxFrameRate granularity { testTime 60 } { timetowait 5 } { NAT 0 } { dutIP null }
            set result [ rfc2544.frameloss $sender $receiver $frameSize $maxFrameRate $granularity ]
            puts $fd "rate, loss"
            foreach subresult $result {
                set rate [lindex $subresult 0]
                set loss [lindex $subresult 1]
                puts  $fd "$rate, $loss"
            }
        } errorString ] } {
    puts $fd $errorString
    puts $errorString
}

close $fd
