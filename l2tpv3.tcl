# - Initializing using API
package require ByteBlower

# - Intializing using commercial API
#set bb [ ByteBlower Instance.Get ]
# - Initializing using TOOP
set bb [ TOOP New com.Excentis.Device.Traffic.ByteBlower ]

# --- Connect to the ByteBlower Server
set serverAddress byteblower-tp-p860.lab.excentis.com
#set server [ $bb Server.Add 10.4.3.234 ]
set server [ $bb Server.Add $serverAddress ]

puts [ $server Description.Get ]

# --- Create the logical ByteBlower Port on the Physical Port
#set port [ $server Port.Create nontrunk-1 ]
set port [ $server Port.Create trunk-1-1 ]

# --- Configure the Layer2 Settings
set l2 [ $port Layer2.EthII.Set ]
$l2 Mac.Set 00:ff:12:22:22:01

# --- Configure the Layer3 Settings
set l3 [ $port Layer3.IPv4.Set ]
[ $l3 Dhcp ] Perform

# --- Add the L2TPv3 Protocol
set l2tpv3 [ $l3 Protocol.L2TPv3.Add ]

# --- Add a Session to the L2TPv3 Protocol with the given Session ID
set l2tpv3Session [ $l2tpv3 Session.Add 783 ]

# --- Configure the L2TPv3 Session
$l2tpv3Session Remote.Address.Set 1.2.3.4
$l2tpv3Session Remote.Port.Set 1531
$l2tpv3Session Local.Port.Set 3481
puts [ $l2tpv3Session Description.Get ]

# --- Configure the L2TPv3 Docsis MPT SubLayer
$l2tpv3Session File.Name.Set "mux1_2serv.mux"
$l2tpv3Session InterFrameGap.Set 20ms
#$l2tpv3Session NumberOfFrames.Set 0 ;# infinite loop
$l2tpv3Session NumberOfFrames.Set 700
$l2tpv3Session Header.L2TPv3.MPT.FlowId.Set 5

# --- Start the L2TPv3 Session
$l2tpv3Session Start

set ::waiter 0
after 20000 "set ::waiter 1"
vwait ::waiter

# --- Stop the L2TPv3 Session
$l2tpv3Session Stop

