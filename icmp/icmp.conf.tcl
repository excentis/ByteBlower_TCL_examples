#------------------------#
#   Test Configuration   #
#------------------------#

# --- Server configuration
set serverAddress byteblower-tp-p860.lab.excentis.com

# --- PhysicalPort configuration
set physicalPort1 "trunk-1-1"
set physicalPort2 "trunk-1-2"

# --- Layer2 configuration
set port1MacAddress "00:ff:12:00:00:01"
set port2MacAddress "00:ff:12:00:00:02"

# --- Layer3 configuration
set port1PerformDhcp 1
set port2PerformDhcp 1
set port1IpAddress "10.10.0.2"
set port2IpAddress "10.10.0.3"
set port1Netmask "255.255.255.0"
set port2Netmask "255.255.255.0"
set port1Gateway "10.10.0.1"
set port2Gateway "10.10.0.1"

# --- ICMP Configuration
#     + An empty IcmpIdentifier will make the server create a random ICMP Identifier.
#     + An non-empty IcmpIdentifier will force the server use the given ICMP Identifier.
#set icmpIdentifier ""
set icmpIdentifier "1234"

#     + Echo Data Size (optional, default is 56Bytes)
set port1IcmpDataSize 0 ;# minimum
set port2IcmpDataSize 1472 ;# maximum for Ethernet MTU of 1500

#     + Echo Loop Interval (default is 10ms, 100pps)
set port1IcmpEchoLoopInterval "50ms" ;# 20pps
set port2IcmpEchoLoopInterval "20ms" ;# 50pps

# --- Test specific configuration
set echoLoopRunTime 5000 ;# ms

#     + Time to wait before receiving ICMP (Echo) statistics [ms] (Default: 100ms)
set echoReplyTimeout 100 ;# ms
