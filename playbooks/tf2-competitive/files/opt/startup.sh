#! /bin/bash

SECRET_CONFIG="/usr/games/steam/tf2/tf/cfg/secrets.cfg"
ATTRIBUTES_FILE="/opt/attributes.ini"

ATTRIBUTES=$(curl --silent http://metadata.google.internal/0.1/meta-data/attributes/)

ZONE=$(curl --silent http://metadata.google.internal/0.1/meta-data/zone | grep -iEo 'us-(east|central|west)[0-9]')
declare -A LOCATION
LOCATION["us-east1"]="Atlanta"
LOCATION["us-east4"]="Balitmore"
LOCATION["us-central1"]="Omaha"
LOCATION["us-west1"]="Portland"

rm -f $SECRET_CONFIG
rm -f $ATTRIBUTES_FILE

for attr in $ATTRIBUTES; do
    key=$(echo $attr | sed 's/-/_/g')
    value=`curl --silent http://metadata.google.internal/0.1/meta-data/attributes/$attr`
    
    echo "$key=$value" >> $ATTRIBUTES_FILE
    declare -r $key="$value"
done

echo "boottime=$(date -d "$(who -b | awk '{print $4,$3}' | tr - / )" +%s)" >> $ATTRIBUTES_FILE

echo "logstf_apikey $logstf_api_key" >> $SECRET_CONFIG
echo "sm_demostf_apikey $demostf_api_key" >> $SECRET_CONFIG
echo "sv_password $server_password" >> $SECRET_CONFIG
echo "tv_password $spectate_password" >> $SECRET_CONFIG

echo "sp_location ${LOCATION[$ZONE]}" >> $SECRET_CONFIG
echo "sp_hostname ${hostname^}" >> $SECRET_CONFIG
