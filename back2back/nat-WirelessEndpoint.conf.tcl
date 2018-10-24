# This configuration file initializes the necessary variables to run the a back-to-back test on a NATed setup.
# We need to configure the server, ports, mac and ip addresses, as well as traffic parameters.

#------------------------#
#   Test Configuration   #
#------------------------#

# --- ByteBlower Server address
set serverAddress byteblower-dev-1300-2.lab.byteblower.excentis.com
set meetingPointAddress byteblower-dev-1300-2.lab.byteblower.excentis.com

# --- Physical Ports to connect the logical ByteBlowerPorts to
set publicPort1 trunk-1-13

# --- Wireless Endpoint to use.
#     The Wireless endpoint should be on the private side of the NAT device
set wirelessEndpointUUID "e22fecd0-e662-44f2-bc36-9cf0fd62d73a"

# --- Layer2 Configuration
set publicMacAddress1 "00:FF:BB:00:00:01"

# --- Layer3 Configuration
# --- Back-To-Back Source Port Layer3 Configuration
#   - Set to 1 if you want to use DHCP
set publicPerformDhcp1 1
#   - else use static IPv4 Configuration
set publicIpAddress1 "10.10.0.2"
set publicNetmask1 "255.255.255.0"
set publicIpGW1 "10.10.0.1"


# ---- Frame configuration
set ethernetLength 124 ;# without CRC!

# --- UDP Configuration
set publicUdpPort1 2001
set privateUdpPort1 2002

# --- Timing configuration
#   - Number of frames to send
set numberOfFrames 10000
#   - Time between two frames
set interFrameGap 1ms

# ---- Traffic direction configuration
# set to 1 for bidirectional traffic
set bidir 1

