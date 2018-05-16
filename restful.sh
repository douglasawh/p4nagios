#!/bin/bash
# requires jq command
# yum -y install jq
# and utils.sh which is usually found in /usr/local/nagios/libexec


#$1 url
#$2 additional header(api key for example. Enter NA if no additional header is required)
#$3 json field
#$4 warning range
#$5 critical range

result=`curl -XGET $1 -H "Accept: application/json" -H "$2" -m 30 -s --insecure | jq $3 | sed s/\"//g`

source /usr/local/nagios/libexec/utils.sh

check_range $result $4 
warning=$?
check_range $result $5
critical=$?

if [ $critical -eq 0 ]
then
        echo "CRITICAL $3@$result|$3=$result"
        exit 2
fi

if [ $warning -eq 1 ]
then
        echo "OK $3@$result|$3=$result"
        exit 0
fi

if [ $warning -eq 0 ]
then
        echo "WARNING $3@$result|$3=$result"
        exit 1
fi
