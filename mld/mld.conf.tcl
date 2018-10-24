#***********************#
#**   Configuration   **#
#***********************#

set ::serverIp byteblower-tp-p860.lab.excentis.com
set ::portName1 trunk-1-1
set ::portName2 trunk-1-2

#- ByteBlower port 1 layer2 and layer3
set ::macAddress1 "00:ff:12:66:66:01"
set ::ipAddress1 "2001:0db8:0001:0081:0000:0000:ff12:0001"
set ::ipRouter1 "2001:0db8:0001:0081:0000:0000:0000:0001"

#- ByteBlower port 2 layer2 and layer3
set ::macAddress2 "00:ff:12:66:66:02"
set ::ipAddress2 "2001:0db8:0001:0081:0000:0000:ff12:0002"
set ::ipRouter2 "2001:0db8:0001:0081:0000:0000:0000:0001"

#- Multicast addresses used during test
set ::multicastAddress1 "ff38::8000:21"
set ::multicastAddress2 "ff38::8000:201"

#- Multicast source addresses
set ::sourceIp1 "2001:0db8:0001:0081:0000:0000:ff12:2001"
set ::sourceIp2 "2001:0db8:0001:0081:0000:0000:ff12:2002"
set ::sourceIp3 "2001:0db8:0001:0081:0000:0000:ff12:2003"
set ::sourceIp4 "2001:0db8:0001:0081:0000:0000:ff12:2004"