#------------------------#
#   Test Configuration   #
#------------------------#

#------------------------------------------------------------------------------
# Physical test setup requirements
#------------------------------------------------------------------------------
#
# 1. The HTTP Server (at `dmzPhysicalPort1') MUST be at the CPE (private) side of the NAT/DMZ gateway.
#
# 2. The HTTP Client (at `physicalPort1') MUST be at the NSI (public) side of the NAT/DMZ gateway.
#
#------------------------------------------------------------------------------

# --- ByteBlower Server address
set serverAddress byteblower-tp-1300.lab.byteblower.excentis.com

# --- Physical Ports to connect the logical ByteBlowerPorts to
set dmzPhysicalPort1 trunk-1-25
set physicalPort1 trunk-1-13

# --- Layer2 Configuration
set serverMacAddress "00:ff:bb:ff:ee:ee"
set clientMacAddress "00:ff:bb:ff:ee:dd"

# --- Layer3 Configuration
# --- HTTP Server Port Layer3 Configuration
#   - Set to 1 if you want to use DHCP
set serverPerformDhcp 1
#   - else use static IPv4 Configuration
set serverIpAddress "192.168.1.123"
set serverNetmask "255.255.255.0"
set serverIpGW "192.168.1.1"

# --- HTTP Client Port Layer3 Configuration
#   - Set to 1 if you want to use DHCP
set clientPerformDhcp 1
#   - else use static IPv4 Configuration
set clientIpAddress "10.8.1.61"
set clientNetmask "255.255.255.0"
set clientIpGW "10.8.1.1"

# --- HTTP Session setup
# --- Override the default used TCP ports
#set serverTcpPort 5555
#set serverTcpPort 80
#set clientTcpPort 6666

# --- Number of bytes to request
set requestSize 100000000 ;# 100 MB

# --- Configure the used HTTP Request Method
#
# - ByteBlower Server > version 1.4.8 and ByteBlower Client API > version 1.4.4
#   support configuring the used HTTP Method to transfer the data.
#   note: older versions always used HTTP GET
#
#   using HTTP GET :
#       HTTP Server -----D-A-T-A----> HTTP Client
#
#   using HTTP PUT :
#       HTTP Server <----D-A-T-A----- HTTP Client
#
set httpMethod "GET" ;# ByteBlower default
#set httpMethod "PUT"

#  - Uncomment this to set the initial TCP window size
#set tcpInitialWindowSize 16384
#  - Uncomment this to enable TCP window scaling and set the window scale factor
#set windowScale 4

