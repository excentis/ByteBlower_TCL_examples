# This configuration file initializes the necessary variables to run the a NetworkInfo example
# We need to configure the meetingpoint, wireless endpoint UUID

#------------------------#
#   Test Configuration   #
#------------------------#

# --- ByteBlower Server address
set meetingpointAddress 10.10.1.202

# --- wireless endpoint UUID
# special value: empty string, the script will automatically select the first
# available device
set wirelessEndpointUUID ""

# --- name of the wireless interface
# special value: empty string, the script will automatically select the first
# available WiFi interface with an SSID assigned.
set wirelessInterfaceName ""

set testDuration_s 30
