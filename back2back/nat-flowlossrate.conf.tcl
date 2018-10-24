#--------------------------#
#--- Port Configuration ---#
#--------------------------#

set ::serverAddress byteblower-tp-p860.lab.excentis.com
set ::physicalPort1 "trunk-1-1"
set ::physicalPort2 "trunk-1-2"

#- Set to 1 if you want to enable DHCP, or to 0 if you want
#  to setup static IP address with settings as below.
set ::netPerformDhcp 1
set ::netMacAddress "00:FF:12:00:00:01"
set ::netIpAddress "10.8.1.61"
set ::netNetmask "255.255.255.0"
set ::netIpGW "10.8.1.1"

#- Set to 1 if you want to enable DHCP, or to 0 if you want
#  to setup static IP address with settings as below.
set ::natPerformDhcp 1
set ::natPrivateMacAddress "00:FF:12:00:00:02"
set ::natPrivateIpAddress "192.168.0.11"
set ::natPrivateNetmask "255.255.255.0"
set ::natPrivateIpGW "192.168.0.1"

set ::netUdpPort 2001
set ::natPrivateUdpPort 2002
set ::ethernetLength 124 ;# without CRC!
set ::udpLength 82 ; # ethernetLength - 42
set ::numberOfFrames 10000
set ::interFrameGap 1ms

#---------------------------------#
#--- Throughput unidirectional ---#
#---------------------------------#

set ::minimumThroughput 2000000 ;# 2 Mbps
set ::maximumThroughput 6000000 ;# 6 Mbps
set ::initialThroughput 4000000 ;# 4 Mbps

set ::resolution 100000 ;# 100 kbps
set ::acceptedLoss 0.1 ;# 0.1 %
set ::backoff 50 ;# 50 %

set ::iterationTime 30 ;# seconds

#- Time to wait between load iteration to let the device recover
#  <= 0 : disabled waiting
#   > 0 : wait for 'deviceRecoverTime' miliseconds
set ::deviceRecoverTime 5000
#- Send Address Resolution packets between iterations?
#  0 : no
#  1 : yes
set ::arpBetweenIterations 1	
