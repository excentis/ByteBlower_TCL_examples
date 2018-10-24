#------------------------#
#   Test Configuration   #
#------------------------#

# --- ByteBlower Server address
set ::serverAddress byteblower-tp-1300.lab.byteblower.excentis.com

# --- Physical Ports to connect the logical ByteBlowerPorts to
set ::physicalPort1 trunk-1-1
set ::physicalPort2 trunk-1-2

# --- Layer2 Configuration
set ::serverMacAddress "00:ff:bb:ff:ee:dd"
set ::clientMacAddress "00:ff:bb:ff:ee:ee"

# --- Layer2.5 Configuration
# --- HTTP Server Port Layer2.5 Configuration
#   - Set to 1 if you want to place the server on a VLAN subnet
set ::serverOnVlan 1
#   - If so, select a VLAN ID
set ::serverVlanID 2
#set ::serverVlanID {2 3}
#   - Override the default priority (0-7) and drop eligible (0 or 1) fields
#set ::serverVlanPriority 7
#set ::serverVlanDropEligible 1

# --- HTTP Client Port Layer2.5 Configuration
#   - Set to 1 if you want to place the client on a VLAN subnet
set ::clientOnVlan 1
#   - If so, select a VLAN ID
set ::clientVlanID 2
#set ::clientVlanID { 2 3 }
#   - Override the default priority (0-7) and drop eligible (0 or 1) fields
#set ::clientVlanPriority 0
#set ::clientVlanDropEligible 0

# --- Layer3 Configuration
# --- HTTP Server Port Layer3 Configuration
#   - Set to 1 if you want to use DHCP
set ::serverPerformDhcp 0
#   - else use static IPv4 Configuration
set ::serverIpAddress "10.8.1.61"
set ::serverNetmask "255.255.255.0"
set ::serverIpGW "10.8.1.1"

# --- HTTP Client Port Layer3 Configuration
#   - Set to 1 if you want to use DHCP
set ::clientPerformDhcp 0
#   - else use static IPv4 Configuration
set ::clientIpAddress "10.8.1.62"
set ::clientNetmask "255.255.255.0"
set ::clientIpGW "10.8.1.1"

# --- HTTP Session setup
# --- Override the default used TCP ports
#set ::serverTcpPort 5555
#set ::serverTcpPort 80
#set ::clientTcpPort 6666

# --- Number of bytes to request
set ::requestSize 100000000 ;# 100 MB

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
set ::httpMethod "GET" ;# ByteBlower default
#set ::httpMethod "PUT"

#  - Uncomment this to set the initial TCP window size
#set ::tcpInitialWindowSize 16384
#  - Uncomment this to enable TCP window scaling and set the window scale factor
#set ::windowScale 4
