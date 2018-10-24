#------------------------#
#   Test Configuration   #
#------------------------#

# --- Server configuration
set ::serverAddress byteblower-tp-1300-beta.lab.byteblower.excentis.com

# --- PhysicalPort configuration
#set physicalPort "nontrunk-1"
set ::physicalPort "trunk-1-13"

# --- Layer2 configuration
set ::macAddress "00:ff:12:00:00:01"

# --- Layer3 configuration
set ::performDhcp 1
set ::ipAddress "10.10.0.2"
set ::netmask "255.255.255.0"
set ::gateway "10.10.0.1"

# --- HTTP Client Configuration
#     + As an example, we get the Excentis website's index.html.
set ::httpRequestUri "http://88.151.245.65/index.php"
set ::httpSaveFile "excentis_index.php.http.txt"
