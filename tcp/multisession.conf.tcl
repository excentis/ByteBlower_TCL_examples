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

# --- Layer3 Configuration
# --- HTTP Server Port Layer3 Configuration
#   - Set to 1 if you want to use DHCP
set ::serverPerformDhcp 1
#   - else use static IPv4 Configuration
set ::serverIpAddress "10.8.1.61"
set ::serverNetmask "255.255.255.0"
set ::serverIpGW "10.8.1.1"

# --- HTTP Client Port Layer3 Configuration
#   - Set to 1 if you want to use DHCP
set ::clientPerformDhcp 1
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
set ::requestDuration "120s" ;# 2 minutes

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

#  - Uncomment this to specify the TCP congestion avoidance algorithm (CAA)
#    There are 5 options
#    * none
#    * sack
#    * sack-with-cubic (default)
#    * newreno
#    * newreno-with-cubic
#set ::caa sack-with-cubic

# --- Number of HTTP Clients on the HTTP Client Port
set ::numberOfHttpClients 20

# --- Time offset for start time of different HTTP clients.
#   - The default value is 0. All HTTP clients start at the same time.
#   - Uncomment to set fixed offset between every HTTP client.
#set ::timeOffset 4
