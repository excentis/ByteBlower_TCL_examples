
#------------------------#
#   Test Configuration   #
#------------------------#

###
# Configuration parameters.
###
# Number of modems ( so number of cpe devices )
set numberOfPorts 4

# Total downstream rate in kilo bits.
set maxTotalDownstreamRate 40000
# Total upstream rate in kilo bits
set maxTotalUpstreamRate 7500

# We calculate the stream rate per modem here. You can switch single/total configuration if wanted...
set downstreamRate [ expr $maxTotalDownstreamRate / $numberOfPorts ]
set upstreamRate [ expr $maxTotalUpstreamRate / $numberOfPorts ]

# Define the minimum and maximum frame size we will use.
set minFrameSize 60
set maxFrameSize 1500

# Test for 3 minutes.
set duration 60;# seconds

# Physical and Ip configuration for each port
set net(Server1) "byteblower-tp-1300.lab.byteblower.excentis.com"
set net(PhysicalPort1) "trunk-1-13"
set net(MacAddress1) "00:FF:0a:00:01:01"
set net(PerformDhcp1) 1
set net(IpAddress1) "10.0.0.2"
set net(Netmask1) "255.255.0.0"
set net(IpGW1) "10.0.0.1"


# Example of a cpe configuration
# set cpe_1_Configuration { EthII { Mac 00:FF:0a:00:02:01} Ipv4 { Ip 10.143.3.2 Netmask 255.255.255.0 Gateway 10.143.3.1 } }
set cpe(Server1) "byteblower-tp-1300.lab.byteblower.excentis.com"
set cpe(PhysicalPort1) "trunk-1-19"
set cpe(MacAddress1) "00:FF:0a:00:02:01"
set cpe(PerformDhcp1) 1
set cpe(IpAddress1) "10.0.0.3"
set cpe(Netmask1) "255.255.0.0"
set cpe(IpGW1) "10.0.0.1"

set cpe(Server2) "byteblower-tp-1300.lab.byteblower.excentis.com"
set cpe(PhysicalPort2) "trunk-1-19"
set cpe(MacAddress2) "00:FF:0a:00:02:02"
set cpe(PerformDhcp2) 1
set cpe(IpAddress2) "10.0.0.4"
set cpe(Netmask2) "255.255.0.0"
set cpe(IpGW2) "10.0.0.1"

set cpe(Server3) "byteblower-tp-1300.lab.byteblower.excentis.com"
set cpe(PhysicalPort3) "trunk-1-14"
set cpe(MacAddress3) "00:FF:0a:00:02:03"
set cpe(PerformDhcp3) 1
set cpe(IpAddress3) "10.0.0.5"
set cpe(Netmask3) "255.255.0.0"
set cpe(IpGW3) "10.0.0.1"

set cpe(Server4) "byteblower-tp-1300.lab.byteblower.excentis.com"
set cpe(PhysicalPort4) "trunk-1-20"
set cpe(MacAddress4) "00:FF:0a:00:02:04"
set cpe(PerformDhcp4) 1
set cpe(IpAddress4) "10.0.0.6"
set cpe(Netmask4) "255.255.0.0"
set cpe(IpGW4) "10.0.0.1"
