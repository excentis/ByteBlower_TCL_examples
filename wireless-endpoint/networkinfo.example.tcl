#!/usr/bin/tclsh

# This example polls the Wireless Endpoint for its network information every 
# second.  The meetingpoint collects this information every 10 seconds on the
# Wireless Endpoint.  This gives us a resolution of 10 seconds or so.  If you 
# want a more fine-grained resolution, please have a look at the 
# networkinfomonitor example

package require ByteBlower

# Helper procedures, the real example starts below

proc select_wireless_endpoint { meetingpoint } {

    # if a WirelessEndpoint UUID is given, we do not need to search for a 
    # device
    if { ${::wirelessEndpointUUID} != ""} {
        return [ ${meetingpoint} Device.Get ${::wirelessEndpointUUID} ]
    }

    set deviceList [ ${meetingpoint} Device.List.Get ]
    foreach device ${deviceList} {
        # Check if the device is Available and not locked
        if { [ $device Status.Get ] != "Available"} {
            continue
        }

        if { [ $device Lock.Get ] } {
            continue
        }

        return $device
    }

    return ""
}


proc select_wifi_interface_by_name { wirelessendpoint interface_name } {
    set deviceInfo [ $wirelessendpoint Device.Info.Get ]
    set networkInfo [ ${deviceInfo} Network.Info.Get ]

    foreach interface [ ${networkInfo} Interface.Get ] {
        if { [ $interface DisplayName.Get ] == ${interface_name} } {
            return ${interface}
        }
    }

    return ""
}


proc select_wifi_interface { wirelessendpoint interface_name } {
    if { ${interface_name} != "" } {
        set interface [ select_wifi_interface_by_name $wirelessendpoint $interface_name ]

        if { ${interface} != "" } {
            return ${interface}
        }
    }

    set deviceInfo [ $wirelessendpoint Device.Info.Get ]
    set networkInfo [ ${deviceInfo} Network.Info.Get ]

    foreach interface [ ${networkInfo} Interface.Get ] {
        if { [ ${interface} Type.Get ] == "WiFi" && [ ${interface} WiFi.Ssid.Get ] != "" } {
            return ${interface}
        }
    }

    return ""
}


#
# The example starts here
#

set instance [ ByteBlower Instance.Get ]

set meetingpoint ""
set wirelessendpoint ""

if { [ catch { 
    # Connect to the MeetingPoint
    set meetingpoint [ $instance MeetingPoint.Add ${::meetingpointAddress} ]

    # Find an available device
    set device [ select_wireless_endpoint ${meetingpoint} ]
    puts "Selected device: [ $device Description.Get ]"

    # Find the WiFi Interface we want to query
    set interface [ select_wifi_interface ${device} ${::wirelessInterfaceName}]
    if { ${interface} == "" } {
        puts "Could not find a suitable WiFi interface"
        exit 0
    }

    puts "Selected interface: [ $interface Description.Get ]"
    set networkInfo [ [ ${device} Device.Info.Get ] Network.Info.Get ]

    # for the duration, print the interface parameters and refresh the network information
    puts "\"time\";\"SSID\";\"BSSID\";\"Channel\";\"RSSI\";\"Transmit Rate (bps)\""
    for { set i 0 } { $i < ${::testDuration_s} } { incr i } {
        # we want to iterate every second:
        set ::wait_var 0
        after 1000 set ::wait_var 1

        # collect the information
        set timestamp [ clock seconds ]
        set ssid [ ${interface} WiFi.Ssid.Get ]
        set bssid [ ${interface} WiFi.Bssid.Get ]
        set channel [ ${interface} WiFi.Channel.Get ]
        set rssi [ ${interface} WiFi.Rssi.Get ]
        set txrate [ ${interface} WiFi.TxRate.Get ]

        puts "${timestamp};\"${ssid}\";\"${bssid}\";${channel};${rssi};${txrate}"

        # wait for the configured second expires
        vwait ::wait_var

        # Refresh the network information
        ${networkInfo} Refresh
    }
    

} dummy ] } {
    puts "ERROR: an error happended: ${dummy}"
    puts $::errorInfo
    catch { puts [ ${dummy Message.Get} ] }
}

if { ${meetingpoint} != "" } {
    ${meetingpoint} Destructor
}