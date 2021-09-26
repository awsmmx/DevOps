#!/usr/bin/env python
# -*- coding: utf-8 -*-
import sys
import subprocess
import optparse
import re

def get_arguments():
    parser = optparse.OptionParser()
    parser.add_option("-i", "--interface", dest="interface", help="The name of MAC-address")
    parser.add_option("-m", "--mac", dest="new_mac")
    (options, arguments) = parser.parse_args()
    if not options.interface:
        parser.error("[INFO] The interface is not parseable")
    elif not options.new_mac:
        parser.error("[INFO] The MAC-address is not parseable")
    return options


def change_mac(interface, new_mac):
    print("[INFO] Changing MAC-address " + interface + ' on ' + new_mac)
    subprocess.call(['ifconfig', interface, 'down'])
    subprocess.call(['ifconfig', interface, 'hw', 'ether', new_mac])
    subprocess.call(['ifconfig', interface, 'up'])

def get_current_mac(interface):
    ifconfig_result = subprocess.check_output(["ifconfig", interface]).decode('utf-8')
    mac_address_search_result = re.search(r"\w\w:\w\w:\w\w:\w\w:\w\w:\w\w", ifconfig_result)
    if mac_address_search_result:
        return mac_address_search_result.group(0)
    else:
        print('[INFO] The MAC-address is not parseable')
        print(sys.exc_info()[1])


options = get_arguments()
current_mac = get_current_mac(options.interface)
print("Current MAC-address = " + str(current_mac))
change_mac(options.interface, options.new_mac)

current_mac = get_current_mac(options.interface)
if current_mac == options.new_mac:
    print('[DONE] MAC-address was changed ' + current_mac)
else:
    print('[ERROR] MAC-address was not changed')
    print(sys.exc_info()[1])
