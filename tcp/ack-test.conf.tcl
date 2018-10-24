# test configuration

# --- ByteBlower Server address
set ::serverAddress byteblower-tp-p860.lab.excentis.com

# --- Physical Ports to connect the logical ByteBlowerPorts to
set ::physicalPort1 trunk-1-1
set ::physicalPort2 trunk-1-2

# --- Layer2 Configuration
set ::macAddressPort1 "00:00:00:01:01:0A"
set ::macAddressPort2 "00:00:00:01:02:0A"

# TCP Ack configuration

# Change number of different acks to use (numberOfAcks)
set ::numberOfAcks 100

# Change nof to number of frames you want to send
set ::nof 1000

set ::initialTcpAck 268435875
set ::incrementAck 200
