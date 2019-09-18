#!/bin/bash

SECRET_CONFIG="/usr/games/steam/tf2/tf/cfg/secrets.cfg"
ATTRIBUTES_FILE="/opt/attributes.ini"

AVAILABILITY_ZONE=`/usr/bin/curl --silent http://169.254.169.254/latest/meta-data/placement/availability-zone`
REGION=${AVAILABILITY_ZONE::-1}
/usr/bin/aws configure set region $REGION

export INSTANCE_ID=`/usr/bin/curl --silent http://169.254.169.254/latest/meta-data/instance-id`
export TAGS=$(/usr/bin/aws ec2 describe-tags --filters "Name=resource-id,Values=${INSTANCE_ID}" | /usr/bin/jq -r ".Tags | from_entries")

/bin/rm -f $SECRET_CONFIG
/bin/rm -f $ATTRIBUTES_FILE

echo $TAGS | /usr/bin/jq -r 'to_entries|map("\(.key)=\(.value|tostring)")|.[]' > $ATTRIBUTES_FILE
for line in $(/bin/cat $ATTRIBUTES_FILE); do
    key=`echo $line | /usr/bin/cut -f1 -d'='`
    value=`echo $line | /usr/bin/cut -f2 -d'='`
    declare -r $key="$value"
    echo "$key = $value"
done

ZONE=$(/usr/bin/curl --silent http://169.254.169.254/latest/meta-data/placement/availability-zone | /bin/grep -iEo 'us-(east|west)-[0-9]')
declare -A LOCATION
LOCATION["us-east-1"]="US East"
LOCATION["us-east-2"]="US Central"
LOCATION["us-west-1"]="US West"
LOCATION["us-west-2"]="US West"

echo "boottime=$(/bin/date -d "$(/usr/bin/who -b | /usr/bin/awk '{print $4,$3}' | /usr/bin/tr - / )" +%s)" >> $ATTRIBUTES_FILE

SECRETS=$(/usr/bin/aws ssm get-parameters --names "demostf_api_key" "logstf_api_key" "server_global_admins" "discord_api_key" | /usr/bin/jq -r ".Parameters | from_entries")

echo "logstf_apikey" $(echo $SECRETS | /usr/bin/jq -r '.logstf_api_key') >> $SECRET_CONFIG
echo "sm_demostf_apikey" $(echo $SECRETS | /usr/bin/jq -r '.demostf_api_key') >> $SECRET_CONFIG
echo "discord_api_key" $(echo $SECRETS | /usr/bin/jq -r '.discord_api_key') >> $SECRET_CONFIG

echo "discord_message_id $discord_message_id" >> $SECRET_CONFIG
echo "discord_channel_id $discord_channel_id" >> $SECRET_CONFIG
echo "sv_password $server_password" >> $SECRET_CONFIG
echo "tv_password $spectate_password" >> $SECRET_CONFIG
echo "sp_location \"${LOCATION[$ZONE]}\"" >> $SECRET_CONFIG
echo "sp_hostname \"${hostname^}\"" >> $SECRET_CONFIG

/bin/chown steam:steam $ATTRIBUTES_FILE
/usr/bin/chattr -i $ATTRIBUTES_FILE

/usr/bin/hostnamectl set-hostname $hostname
