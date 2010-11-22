#! /bin/bash

file_connections=$1
iface=${iface:-"wlan0"}
ifconfig $iface up
ap_list=$(iwlist $iface scan | grep -G -i -e "essid")
for ap in $ap_list ; do
    echo "ap is $ap"
    ap_params=$(sed -n "/$ap/{ p ; } " $file_connections)
    echo "ap_params $ap_params" 
    test -n $ap_params || continue
    echo $ap_params | read -r id_esid key_essid type_key type_crypto 
    iwconfig $iface essid $id_essid 
    iwconfig $iface key "s:$key_essid"
    dhclient $iface
done


