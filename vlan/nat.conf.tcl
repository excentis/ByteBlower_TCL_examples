# This configuration file initializes the necessary variables to run the a back-to-back test on a NATed setup.
# We need to configure the server, ports, mac and ip addresses, as well as traffic parameters.

#------------------------#
#   Test Configuration   #
#------------------------#

# --- ByteBlower Server address
set ::serverAddress byteblower-tp-1300.lab.byteblower.excentis.com

# --- Physical Ports to connect the logical ByteBlowerPorts to
set ::publicInterface trunk-1-19
set ::privateInterface trunk-1-20

# --- Layer2 Configuration
set ::publicMacAddress "00:FF:BB:00:00:01"
set ::privateMacAddress "00:FF:BB:00:00:02"

# --- Back-To-Back Layer2.5 Configuration
# --- Source Port Layer2.5 Configuration
#   - Set to 1 if you want to place the Source Port on a VLAN subnet
set ::publicOnVlan 0
#   - If so, select a VLAN ID
set ::publicVlanID 2
#   - Override the default priority (0-7) and drop eligible (0 or 1) fields
set ::publicVlanPriority 7
set ::publicVlanDropEligible 1

# --- Back-To-Back Destination Port Layer2.5 Configuration
#   - Set to 1 if you want to place the Destination Port on a VLAN subnet
set ::privateOnVlan 0
#   - If so, select a VLAN ID
set ::privateVlanID 2
#   - Override the default priority (0-7) and drop eligible (0 or 1) fields
#set ::privateVlanPriority 0
#set ::privateVlanDropEligible 0

# --- Layer3 Configuration
# --- Back-To-Back Source Port Layer3 Configuration
#   - Set to 1 if you want to use DHCP
set ::publicPerformDhcp 1
#   - else use static IPv4 Configuration
set ::publicIpAddress "10.10.0.2"
set ::publicNetmask "255.255.255.0"
set ::publicIpGW "10.10.0.1"

# --- Back-To-Back Destination Port Layer3 Configuration
#   - Set to 1 if you want to use DHCP
set ::privatePerformDhcp 1
#   - else use static IPv4 Configuration
set ::privateIpAddress "192.168.1.3"
set ::privateNetmask "255.255.255.0"
set ::privateIpGW "192.168.1.1"

# ---- Frame configuration
set ::ethernetLength 124 ;# without CRC!

# --- UDP Configuration
set ::publicUdpPort 2001
set ::privateUdpPort 2002

# --- Timing configuration
#   - Number of frames to send
set ::numberOfFrames 10000
#   - Time between two frames
set ::interFrameGap 1ms

# ---- Traffic direction configuration
# set to 1 for bidirectional traffic
set ::bidir 1

