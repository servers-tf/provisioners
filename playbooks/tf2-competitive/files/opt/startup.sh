#! /bin/bash

SECRET_CONFIG="/usr/games/steam/tf2/tf/cfg/secrets.cfg"
ATTRIBUTES_FILE="/opt/attributes.ini"

AVAILABILITY_ZONE=`curl --silent http://169.254.169.254/latest/meta-data/placement/availability-zone`
REGION=${AVAILABILITY_ZONE::-1}
aws configure set region $REGION

export INSTANCE_ID=`curl --silent http://169.254.169.254/latest/meta-data/instance-id`
export TAGS=$(aws ec2 describe-tags --filters "Name=resource-id,Values=${INSTANCE_ID}" | jq -r ".Tags | from_entries")

rm -f $SECRET_CONFIG
rm -f $ATTRIBUTES_FILE

echo $TAGS | jq -r 'to_entries|map("\(.key)=\(.value|tostring)")|.[]' > $ATTRIBUTES_FILE
for line in $(cat $ATTRIBUTES_FILE); do
    key=`echo $line | cut -f1 -d'='`
    value=`echo $line | cut -f2 -d'='`
    declare -r $key="$value"
    echo "$key = $value"
done

ZONE=$(curl --silent http://169.254.169.254/latest/meta-data/placement/availability-zone | grep -iEo 'us-(east|west)-[0-9]')
declare -A LOCATION
LOCATION["us-east-1"]="US East"
LOCATION["us-east-2"]="US Central"
LOCATION["us-west-1"]="US West"
LOCATION["us-west-2"]="US West"

echo "boottime=$(date -d "$(who -b | awk '{print $4,$3}' | tr - / )" +%s)" >> $ATTRIBUTES_FILE

SECRETS=$(aws ssm get-parameters --names "demostf_api_key" "logstf_api_key" "server_global_admins" "discord_api_key" | jq -r ".Parameters | from_entries")

echo "logstf_apikey" $(echo $SECRETS | jq -r '.logstf_api_key') >> $SECRET_CONFIG
echo "sm_demostf_apikey" $(echo $SECRETS | jq -r '.demostf_api_key') >> $SECRET_CONFIG
echo "discord_api_key" $(echo $SECRETS | jq -r '.discord_api_key') >> $SECRET_CONFIG

echo "discord_message_id $discord_message_id" >> $SECRET_CONFIG
echo "discord_channel_id $discord_channel_id" >> $SECRET_CONFIG
echo "sv_password $server_password" >> $SECRET_CONFIG
echo "tv_password $spectate_password" >> $SECRET_CONFIG
echo "sp_location \"${LOCATION[$ZONE]}\"" >> $SECRET_CONFIG
echo "sp_hostname \"${hostname^}\"" >> $SECRET_CONFIG

chown steam:steam $ATTRIBUTES_FILE
chattr -i $ATTRIBUTES_FILE

hostnamectl set-hostname $hostname
