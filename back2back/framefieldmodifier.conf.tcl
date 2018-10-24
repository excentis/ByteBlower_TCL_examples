
#------------------------#
#   Test Configuration   #
#------------------------#

###
# Configuration parameters.
###
# Number of modems ( so number of cpe devices )
set numberOfPorts 2

# Total downstream rate in kilo bits.
set maxTotalDownstreamRate 40000
# Total upstream rate in kilo bits
set maxTotalUpstreamRate 7500

# We calculate the stream rate per modem here. You can switch single/total configuration if wanted...
set downstreamRate [ expr $maxTotalDownstreamRate / $numberOfPorts ]
set upstreamRate [ expr $maxTotalUpstreamRate / $numberOfPorts ]

# size of the frame in bytes
set frameSize 250

# Define the type of field modifier to use in the frame.
# Options are "random" and "incremental"
#set fieldModifierType "random"
set fieldModifierType "incremental"

# Offset in bytes where the modifier will start to work on.
set fieldModifierOffset 58

# Number of bytes on which the modifier will work on.  
set fieldModifierLength 2

# Minimum value of the field 
set fieldModifierMinimum 0x0000
# Maximum value of the field
set fieldModifierMaximum 0x0FFF

# Step to increment the field with.  Only needed for incremental modifiers
set fieldModifierStep 1

# Initial value for the field. Only needed for incremental modifiers
set fieldModifierInitialValue 0x01FF



# Test for 1 minute.
set duration 60;# seconds

# Physical and Ip configuration for each port
set net(Server1) "byteblower-tp-1300.lab.byteblower.excentis.com"
set net(PhysicalPort1) "trunk-1-13"
set net(MacAddress1) "00:FF:1F:00:01:01"
set net(PerformDhcp1) 1
set net(IpAddress1) "10.0.0.2"
set net(Netmask1) "255.255.0.0"
set net(IpGW1) "10.0.0.1"


# Example of a cpe configuration
set cpe(Server1) "byteblower-tp-1300.lab.byteblower.excentis.com"
set cpe(PhysicalPort1) "trunk-1-14"
set cpe(MacAddress1) "00:FF:1F:00:02:01"
set cpe(PerformDhcp1) 1
set cpe(IpAddress1) "10.0.0.3"
set cpe(Netmask1) "255.255.0.0"
set cpe(IpGW1) "10.0.0.1"


