#------------------------#
#   Test Configuration   #
#------------------------#
# --- Server configuration
set serverAddress byteblower-tp-p860.lab.excentis.com
# --- PhysicalPort configuration
set physicalPort1 "trunk-1-1"
set physicalPort2 "trunk-1-2"

# --- Layer2 configuration
set port1MacAddress "00:ff:12:66:66:01"
set port2MacAddress "00:ff:12:66:66:02"

# --- Layer3 configuration
#     + AutoConfig can be "dhcp" or "statelessautoconfig",
#       if anything else, the static configuration (see below) will be used.
set port1AutoConfig "statelessautoconfig"
#set port1AutoConfig "dhcp"
#set port1AutoConfig "manual"
set port2AutoConfig "statelessautoconfig"
#set port2AutoConfig "dhcp"
#set port2AutoConfig "manual"
set port1IpAddress "2001:0db8:0001:0081:0000:0000:ff12:0001/64"
set port2IpAddress "2001:0db8:0001:0081:0000:0000:ff12:0002"
set port1Router "2001:0db8:0001:0081:0000:0000:0000:0001"
set port2Router "2001:0db8:0001:0081:0000:0000:0000:0001"

# --- ICMP Configuration
#     + An empty IcmpIdentifier will make the server create a random ICMP Identifier.
#     + An non-empty IcmpIdentifier will force the server use the given ICMP Identifier.
#set icmpIdentifier ""
set icmpIdentifier "1234"

#     + Echo Data Size (optional, default is 56Bytes)
set port1IcmpDataSize 0 ;# minimum
set port2IcmpDataSize 1452 ;# maximum for Ethernet MTU of 1500

#     + Echo Loop Interval (default is 10ms, 100pps)
#set port1IcmpEchoLoopInterval "50ms" ;# 20pps
#set port2IcmpEchoLoopInterval "20ms" ;# 50pps
set port1IcmpEchoLoopInterval 50000000 ;# 20pps
set port2IcmpEchoLoopInterval 20000000 ;# 50pps

# --- Test specific configuration
set echoLoopRunTime 5000 ;# ms

#     + Time to wait before receiving ICMP (Echo) statistics [ms] (Default: 100ms)
set echoReplyTimeout 100 ;# ms
