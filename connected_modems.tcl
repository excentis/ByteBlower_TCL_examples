#!/usr/bin/tclsh

set server_address "byteblower-tutorial-3100.lab.byteblower.excentis.com"


#
# This example script scans a ByteBlower server on all interfaces for possible
# connected cable modems.  It does this by creating ports on each interface 
# available on the server configured above.  The ports are created twice. Once
# for each technique below:
# 
# - create a port with a static IP address.  
#   The address is set to an IP in the range 192.168.100.x/24 and the gateway
#   is set to the 192.168.100.1 address.  The latter IP address is a standard
#   debug address for cable modems.
#
# - create a port with a DHCP obtained IP address.  This is done 
#   asynchronically, so the script does not have to wait for the DHCP process
#   to finish or fail
#
# Once all ports are provisioned (a list of ports on which the DHCP process 
# passed), the gateway MAC address is asynchronically resolved using ARP.
# Again this is done so all resolving will be done in parallel.
# 
# In the last step all the ports are queried for the resolved MAC address for
# their gateway.  If an address was resolved a line will be printed as follows
#
#     trunk-1-1: 01:23:45:67:89:01 (dhcp gateway 172.16.0.1)
#
#
# Have questions about this script?
# 
#     support.byteblower@excentis.com 
# or  https://support.excentis.com
#

package require ByteBlower



puts "Connecting to server ${server_address}"
set server [ ByteBlower Server.Add ${server_address} ]
set interface_names [ $server Interface.Names.Get ]

set mac_idx 1

set dhcp_ports [ list ]

puts "Creating DHCP ports"
# create DHCP ports, maybe we are behind an eRouter or something
foreach interface_name ${interface_names} {
    set port [ $server Port.Create ${interface_name} ]
    set l2 [ $port Layer2.EthII.Set ]
    $l2 Mac.Set 00bb1f0001[format 02x $mac_idx ]
    
    incr mac_idx
    
    set l3 [ $port Layer3.IPv4.Set ]
    set dhcp [ $l3 Protocol.Dhcp.Get ]
    $dhcp Perform.Async
    
    lappend dhcp_ports $port
    puts -nonewline "."; flush stdout
}
puts " done"

# while we wait for DHCP to complete (or timeout), try creating a port with a
# static configuration, so we can try to resolve the CM debug IP address 
# (192.168.100.1)

set static_ports [ list ]
set mac_idx 1

puts "Creating Static ports"
foreach interface_name ${interface_names} {
    set port [ $server Port.Create ${interface_name} ]
    set l2 [ $port Layer2.EthII.Set ]
    
    $l2 Mac.Set 00bb1f0002[format 02x $mac_idx ]
    
    incr mac_idx
    
    set l3 [ $port Layer3.IPv4.Set ]
    $l3 Ip.Set 192.168.100.[ expr ${mac_idx} + 1 ]
    $l3 Netmask.Set 255.255.255.0
    $l3 Gateway.Set 192.168.100.1
    
    $l3 Protocol.Arp.Async [ $l3 Gateway.Get ]
    
    lappend static_ports $port
    puts -nonewline "."; flush stdout
}
puts " done"


# now iterate over the DHCP list to collect the responding ports
set responding_ports [ list ]
puts "Checking which ports could do DHCP"
foreach port ${dhcp_ports} {
    set l3 [ $port Layer3.IPv4.Get ]
    if { [ catch { [ $l3 Protocol.Dhcp.Get ] Perform } ] } {
        # DHCP failed, nothing to do
        puts -nonewline "."; flush stdout
    } else {
        # start the ARP resolution
        $l3 Protocol.Arp.Async [ $l3 Gateway.Get ]
        lappend responding_ports ${port}
        puts -nonewline "o"; flush stdout
    }
}
puts " done"
puts "[ llength ${responding_ports} ] ports could do DHCP"

# now iterate over all ports to find out to what the ARP resolved

foreach port ${static_ports} {
    if { [ catch { 
        set l3 [ $port Layer3.IPv4.Get ]
        set gateway [ $l3 Gateway.Get ]
        set mac [ $l3 Protocol.Arp ${gateway} ]
        puts "[$port Interface.Name.Get]: ${mac} (static gateway: ${gateway})"
    } dummy ] } {
        # failed, probably nothing connected
    }
}

foreach port ${responding_ports} {
    if { [ catch { 
        set l3 [ $port Layer3.IPv4.Get ]
        set gateway [ $l3 Gateway.Get ]
        set mac [ $l3 Protocol.Arp ${gateway} ]
        puts "[$port Interface.Name.Get]: ${mac} (dhcp gateway ${gateway})"
    } dummy ] } {
        # failed, probably nothing connected
    }
}

$server Destructor