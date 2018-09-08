#!/usr/bin/env bash

a_record=$(host home.tlip.com | awk {'print $4'})
home_ip=$(curl http://icanhazip.com)

ip_address_updater(){

cat <<EOF > /root/change-batch.json
{
  "Comment": "Updating home IP address",
  "Changes": [
	{
	  "Action": "UPSERT",
	  "ResourceRecordSet": {
		"Name": "home.tlip.com",
		"Type": "A",
		"TTL": 60,
		"ResourceRecords": [
		  {
			"Value": "$1"
		  }
		]
	  }
	}
  ]
}
EOF

	aws route53 change-resource-record-sets --hosted-zone-id xxxxxx --change-batch file:///root/change-batch.json --profile dns_updater
}


if [[ $a_record != $home_ip ]]
then
	ip_address_updater $home_ip
	echo "Updating IP address"
else
	echo "IP address is up to date"
fi	
