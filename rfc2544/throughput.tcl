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

source ./throughput.algo.tcl

# --- ByteBlower Server address
set serverAddress1 byteblower-dev-4100-2.lab.byteblower.excentis.com 
set serverAddress2 $serverAddress1

# --- Physical Ports to connect the logical ByteBlowerPorts to
set physicalPort1 trunk-1-1
set physicalPort2 trunk-1-2

# --- Layer2 Configuration
set srcMacAddress1 "00:FF:BB:04:01:01"
set destMacAddress1 "00:FF:BB:04:01:02"

# --- Layer3 Configuration
# --- Back-To-Back Destination Port Layer3 Configuration
#   - Set to 1 if you want to use DHCP
set srcPerformDhcp1 0
#   - else use static IPv4 Configuration
set srcIpAddress1 "10.3.3.150"
set srcNetmask1 "255.255.255.0"
set srcIpGW1 "10.3.3.176"

# --- Back-To-Back Destination Port Layer3 Configuration
#   - Set to 1 if you want to use DHCP
set destPerformDhcp1 0
#   - else use static IPv4 Configuration
set destIpAddress1 "10.3.3.170"
set destNetmask1 "255.255.255.0"
set destIpGW1 "10.3.3.176"

set frameSize 440
set initialFrameRate 200000
set factor 0.2
set acceptableLoss 0.1
set testTime 10
set maxTestIterations 300
set timetowait 5000
set interfaceLimit 999960000

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
    puts "Settings:"
    puts " * Frame size: $frameSize"
    puts " * Initial frame rate: $initialFrameRate"
    puts " * Factor: $factor"
    puts " * Acceptable loss: $acceptableLoss"
    puts " * Iteration duration: $testTime"
    puts " * Iteration post-test wait: $timetowait"
    puts " * Maximum # iterations: $maxTestIterations"

    # sender receiver frameSize initialFrameRate factor acceptableLoss { testTime 60 } { maxTestIterations -1 } { timetowait 5 } { NAT 0 } { dutIP null }
    set result [ rfc2544.throughput $sender $receiver $frameSize $initialFrameRate $factor $acceptableLoss $testTime $maxTestIterations $timetowait 0 $interfaceLimit]
    set rate  [lindex $result 1]
    set result [ rfc2544.traffic.rate2speed $frameSize $rate ]
    puts $fd $result
} errorString ] } {
    puts $::errorInfo
    puts $errorString
}

close $fd
