##
#
# This configuration file initializes the necessary variables to run the a back-
# to-back latency test. We need to configure the server, ports, mac and ip
# addresses, as well as traffic parameters.
#
##

# --- ByteBlower Server address
set serverAddress byteblower-dev-1300-2.lab.byteblower.excentis.com

# -- MeetingPoint Address
set meetingpointAddress byteblower-dev-1300-2.lab.byteblower.excentis.com

# --- Wireless Endpoint to use.
set wirelessEndpointUUID "0a89388d-7fc8-49fb-b0db-7f5609a5a79f"

# --- Physical ports (interfaces) on which the logical ByteBlower ports are
#     created.
set srcPort trunk-1-25

# --- Layer2 Configuration
set srcMacAddress "00:FF:25:00:00:01"

# --- Layer3 Configuration
# --- Back-To-Back Source Port Layer3 Configuration
#   - Set to 1 if you want to use DHCP
set srcPerformDhcp 1
#   - else use static IPv4 Configuration
set srcIpAddress "10.10.1.100"
set srcNetmask "255.255.255.0"
set srcIpGW "10.10.1.1"


# ---- Frame configuration
set ethernetLength 124 ;# without CRC!

# --- UDP Configuration
set srcUdpPort 2001
set dstUdpPort 2002

# --- Timing configuration
#   - Number of frames to send
set numberOfFrames 10000
#   - Time between two frames
set interFrameGap 1ms

# ---- Traffic direction configuration
# set to 1 for bidirectional traffic
set bidir 1

