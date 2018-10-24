##
#
# This configuration file initializes the necessary variables to run the a back-
# to-back latency test. We need to configure the server, ports, mac and ip
# addresses, as well as traffic parameters.
#
##

# --- ByteBlower Server address
set serverAddress byteblower-tp-1300.lab.byteblower.excentis.com

# --- Physical ports (interfaces) on which the logical ByteBlower ports are
#     created.
set srcPort trunk-1-13
set dstPort trunk-1-19

# --- Layer2 Configuration
set srcMacAddress "00:FF:25:00:00:01"
set dstMacAddress "00:FF:25:00:00:02"

# --- Layer3 Configuration
# --- Back-To-Back Source Port Layer3 Configuration
#   - Set to 1 if you want to use DHCP
set srcPerformDhcp 1
#   - else use static IPv4 Configuration
set srcIpAddress "10.10.1.100"
set srcNetmask "255.255.255.0"
set srcIpGW "10.10.1.1"

# --- Back-To-Back Destination Port Layer3 Configuration
#   - Set to 1 if you want to use DHCP
set dstPerformDhcp 1
#   - else use static IPv4 Configuration
set dstIpAddress "10.10.2.100"
set dstNetmask "255.255.255.0"
set dstIpGW "10.10.2.1"

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

