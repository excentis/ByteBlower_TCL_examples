# This configuration file initializes the necessary variables to run the a back-to-back test on a NATed setup.
# We need to configure the server, ports, mac and ip addresses, as well as traffic parameters.

#------------------------#
#   Test Configuration   #
#------------------------#

# --- ByteBlower Server address
set serverAddress byteblower-tp-p860.lab.excentis.com

# --- Physical Ports to connect the logical ByteBlowerPorts to
set publicPort1 trunk-1-19
set privatePort1 trunk-1-25

# --- Layer2 Configuration
set publicMacAddress1 "00:FF:BB:00:00:01"
set privateMacAddress1 "00:FF:BB:00:00:02"

# --- Layer3 Configuration
# --- Back-To-Back Source Port Layer3 Configuration
#   - Set to 1 if you want to use DHCP
set publicPerformDhcp1 1
#   - else use static IPv4 Configuration
set publicIpAddress1 "10.10.0.2"
set publicNetmask1 "255.255.255.0"
set publicIpGW1 "10.10.0.1"

# --- Back-To-Back Destination Port Layer3 Configuration
#   - Set to 1 if you want to use DHCP
set privatePerformDhcp1 1
#   - else use static IPv4 Configuration
set privateIpAddress1 "192.168.1.3"
set privateNetmask1 "255.255.255.0"
set privateIpGW1 "192.168.1.1"

# ---- Frame configuration
set ethernetLength 124 ;# without CRC!

# --- UDP Configuration
#   - UDP Port used on the Public ByteBlower port
set publicUdpPort1 2001

#   - UDP Port on the public IP address of the nat which will forward to the 
#     private IP address of the Private ByteBlower Port
set natPublicUdpPort1 2000

#   - UDP port on the Private ByteBlower port
set privateUdpPort1 3000

# --- Timing configuration
#   - Number of frames to send
set numberOfFrames 5000
#   - Time between two frames
set interFrameGap 1ms


