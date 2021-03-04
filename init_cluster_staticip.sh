#! /bin/bash




DES_PATH=`find /etc -name "*ens33*"`


# sed -i '$s/no/yes/' $DES_PATH
# service network restart

# replace 
sed -i '/BOOTPROTO/s/dhcp/static/' $DES_PATH
echo "GATEWAY=192.168.52.2" >> $DES_PATH
echo "NETMASK=255.255.255.0" >> $DES_PATH
echo "IPADDR=192.168.52.$1" >> $DES_PATH
echo "DNS1=192.168.124.1" >> $DES_PATH
echo "" >> $DES_PATH

service network restart


exit 0