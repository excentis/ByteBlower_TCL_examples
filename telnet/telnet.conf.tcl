#------------------------#
#   Test Configuration   #
#------------------------#

# --- Server configuration
set ::serverAddress byteblower-tp-p860.lab.excentis.com

# --- PhysicalPort configuration
#set physicalPort "usb-4"
set ::physicalPort trunk-1-1

# --- Layer2 configuration
set ::macAddress "00:11:E3:8E:E5:FD"

# --- Layer3 configuration
set ::performDhcp 1
set ::ipAddress "10.10.0.2"
set ::netmask "255.255.255.0"
set ::gateway "10.10.0.1"

# --- Telnet Client Configuration
set ::telnetRemoteAddress "10.3.3.132"
#  - Unset this to set the remote tcp port (default: 23)
set ::telnetRemotePort 23
#  - Unset this to set the local tcp port (default: automatic, first available)
set ::telnetLocalPort 9876

# --- Telnet Client Test configuration

set ::telnetUserName "c4" ;# '\r' is appended automatically

set ::telnetPassword "99" ;# '\r' is appended automatically

set ::waitForTimeout 4000 ;# [ms]

#  - As an example, we telnet to a CMTS and execute some commands:
#    + showing version
#    + showing hostname
#    + printing "test" on the terminal
#    + show list of 'show' possibilities
#    + continue the 'show' command
#    + continue the 'show' command
#    + expand the 'show' command to ' show interface'
#    + finalize the 'show interface' command
#    + continue the 'show interface' command
#    + showing our command history
#    + exit the telnet session
set ::telnetCommandList [ list "show version\r"\
    "show hostname\r"\
    "echo test\r"\
    "show ?"\
    " "\
    " "\
    "interface"\
    "\r"\
    " "\
    " "\
    "history\r"\
    "exit\r"\
]
set ::waitAfterCommand 500; # [ms]
