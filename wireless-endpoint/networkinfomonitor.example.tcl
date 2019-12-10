#!/usr/bin/tclsh

# This example starts a scenario on the Wireless Endpoint with a 
# NetworkInfoMonitor object.  The NetworkInfoMonitor will collect the network
# information for every snapshot (configurable, see https://api.byteblower.com)
# The downside of this example (when comparing to the networkinfo example), is
# that the results are only available after the test returns.

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


proc select_interface_by_name { interface_list interface_name } {
    foreach interface ${interface_list} {
        if { [ $interface DisplayName.Get ] == ${interface_name} } {
            return ${interface}
        }
    }
    return ""

}


proc select_wifi_interface { wirelessendpoint interface_name } {
    set deviceInfo [ $wirelessendpoint Device.Info.Get ]
    set networkInfo [ ${deviceInfo} Network.Info.Get ]

    if { ${interface_name} != "" } {
        set interface [ select_interface_by_name [ ${networkInfo} Interface.Get ] ${interface_name} ]

        if { ${interface} != "" } {
            return ${interface}
        }
    }

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
    if { ${device} == "" } {
        puts "No suitable device found"
        exit 0
    }

    puts "Selected device: [ $device Description.Get ]"

    # Find the WiFi Interface we want to query
    set interface [ select_wifi_interface ${device} ${::wirelessInterfaceName}]
    if { ${interface} == "" } {
        puts "Could not find a suitable WiFi interface"
        exit 0
    }

    # Get the interface name, so we can search for the interfaces later on.
    set interface_name [ ${interface} DisplayName.Get ]

    # Claim the device
    ${device} Lock 1

    puts "Selected interface: [ $interface Description.Get ]"
    
    # Create a NetworkInfoMonitor
    set networkInfoMonitor [ [ ${device} Device.Info.Get ] Network.Info.Monitor.Add ]

    # Set the duration on the scenario.
    # ${device} Scenario.Duration.Set "${::testDuration_s}s"
    # The statement above will fail due to a BUG in our API, 
    # a workaround is adding a trigger with the desired duration.
    set trigger [ ${device} Rx.Trigger.Basic.Add ]
    ${trigger} Filter.SourceAddress.Set "1.1.1.1"
    ${trigger} Filter.Udp.SourcePort.Set "10000"
    ${trigger} Filter.Udp.DestinationPort.Set "10000"
    ${trigger} Duration.Set "${::testDuration_s}s"

    # Send the scenario to the device
    ${device} Prepare

    # Start the device
    set startTime [ $device Start ]
    set curTime [ $meetingpoint Timestamp.Get ]
    #- Wait until the device is really started
    set wait 0
    after [ expr int((double($startTime) - $curTime) / 1000000) ] "set wait 1"
    vwait wait
    unset wait

    # Wait for the device to finish
    for { set i 0 } { $i < $::testDuration_s } { incr i } {
        puts "Waiting for [ expr $::testDuration_s - $i ]s"
        set wait 0
        after 1000 set wait 1
        vwait wait
    }

    # Test should be finished,
    # wait for the heartbeats to start again (typically 2 seconds)
    set wait 0
    after 2000 "set wait 1"
    vwait wait
    unset wait

    # Let the device collect its results and send them to the meetingpoint.
    ${device} Result.Get

    # Get the results from the meetingpoint
    set history [ ${networkInfoMonitor} Result.History.Get ]
    $history Refresh
    
    # iterate over the history
    foreach snapshot [ ${history} Interval.Get ] {
        # Search our interface of interest
        set interface [ select_interface_by_name [ ${snapshot} Interface.Get ] ${interface_name} ]
        set timestamp [ expr [ $snapshot Timestamp.Get ] / 1000000000 ]

        set ssid "Unknown"
        set bssid "Unknown"
        set channel "Unknown"
        set rssi "Unknown"
        set txrate "Unknown"

        if { ${interface} != "" } {
            # collect the information
            
            set ssid [ ${interface} WiFi.Ssid.Get ]
            set bssid [ ${interface} WiFi.Bssid.Get ]
            set channel [ ${interface} WiFi.Channel.Get ]
            set rssi [ ${interface} WiFi.Rssi.Get ]
            set txrate [ ${interface} WiFi.TxRate.Get ]
        }

        puts "${timestamp};\"${ssid}\";\"${bssid}\";${channel};${rssi};${txrate}"

    }  

} dummy ] } {
    puts "ERROR: an error happended: ${dummy}"
    puts $::errorInfo
    catch { puts [ ${dummy} Message.Get ] }
}

if { ${device} != "" } {
    catch { ${device} Lock 0 }
}

if { ${meetingpoint} != "" } {
    ${meetingpoint} Destructor
}