#!/bin/bash

SECRET_CONFIG="/usr/games/steam/tf2/tf/cfg/secrets.cfg"
GAMEMODE_CONFIG="/usr/games/steam/tf2/tf/cfg/sourcemod/gamemodemanager.cfg"
DATABASE_CONFIG="/usr/games/steam/tf2/tf/addons/sourcemod/configs/databases.cfg"
ATTRIBUTES="http://metadata.google.internal/0.1/meta-data/attributes"

# Add secrets to server config
DEMOSTF_API_KEY=$(curl $ATTRIBUTES/demostf-api-key)
LOGSTF_API_KEY=$(curl $ATTRIBUTES/logstf-api-key)
SERVER_PASSWORD=$(curl $ATTRIBUTES/server-password)
SPECTATE_PASSWORD=$(curl $ATTRIBUTES/spectate-password)
#DISCORD_API_TOKEN=$(curl $ATTRIBUTES/discord-api-token)
#DISCORD_CHANNEL=$(curl $ATTRIBUTES/discord-channel)
PUBLIC_IP_ADDRESS=$(curl --silent http://metadata.google.internal/0.1/meta-data/network | grep -iEo "[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}" | grep -v '^10')

echo "logstf_apikey $LOGSTF_API_KEY" >> $SECRET_CONFIG
echo "sm_demostf_apikey $DEMOSTF_API_KEY" >> $SECRET_CONFIG
echo "sv_password $SERVER_PASSWORD" >> $SECRET_CONFIG
echo "tv_password $SPECTATE_PASSWORD" >> $SECRET_CONFIG
echo "sv_downloadurl \"http://$PUBLIC_IP_ADDRESS/\"" >> $SECRET_CONFIG

# Set hostname and location
HOSTNAME=$(curl $ATTRIBUTES/hostname)
HOSTNAME=${HOSTNAME^}
ZONE=$(curl --silent http://metadata.google.internal/0.1/meta-data/zone | grep -iEo 'us-(east|central|west)[0-9]')
LOCATION="Chicago"

if [ $ZONE == 'us-east1' ]; then
    LOCATION='Atlanta'
elif [ $ZONE == 'us-east4' ]; then
    LOCATION='Balitmore'
elif [ $ZONE == 'us-central1' ]; then
    LOCATION='Omaha'
elif [ $ZONE == 'us-west1' ]; then
    LOCATION='Portland'
fi

echo "sm_location $LOCATION" >> $GAMEMODE_CONFIG
echo "sm_hostname $HOSTNAME" >> $GAMEMODE_CONFIG

# Setup sourcemod database
DATABASE_CONNECTION_STRING=$(curl $ATTRIBUTES/database-connection-string)
DATABASE_DRIVER=$(echo $DATABASE_CONNECTION_STRING | gawk 'match($0, /(mysql|postgres):\/\/([A-Za-z]+):(.*)@(.+)/, m) { print m[1]; }')
DATABASE_USER=$(echo $DATABASE_CONNECTION_STRING | gawk 'match($0, /(mysql|postgres):\/\/([A-Za-z]+):(.*)@(.+)/, m) { print m[2]; }')
DATABASE_PASSWORD=$(echo $DATABASE_CONNECTION_STRING | gawk 'match($0, /(mysql|postgres):\/\/([A-Za-z]+):(.*)@(.+)/, m) { print m[3]; }')
DATABASE_HOST=$(echo $DATABASE_CONNECTION_STRING | gawk 'match($0, /(mysql|postgres):\/\/([A-Za-z]+):(.*)@(.+)/, m) { print m[4]; }')

$(cat <<-EOF > $DATABASE_CONFIG
"Databases"
{
        "driver_default"                        "$DATABASE_DRIVER"
        "default"
        {
                "driver"                        "$DATABASE_DRIVER"
                "host"                          "$DATABASE_HOST"
                "database"                      "tf2_default"
                "user"                          "$DATABASE_USER"
                "pass"                          "$DATABASE_PASSWORD"
        }
        "admins"
        {
                "driver"                        "$DATABASE_DRIVER"
                "host"                          "$DATABASE_HOST"
                "database"                      "tf2_admins"
                "user"                          "$DATABASE_USER"
                "pass"                          "$DATABASE_PASSWORD"
        }
        "clientprefs"
        {
                "driver"                        "$DATABASE_DRIVER"
                "host"                          "$DATABASE_HOST"
                "database"                      "tf2_clientprefs"
                "user"                          "$DATABASE_USER"
                "pass"                          "$DATABASE_PASSWORD"
        }
        "storage-local"
        {
                "driver"                        "sqlite"
                "database"                      "tf2_local"
        }
}
EOF)

# Set permissions
chown -R steam:steam /usr/lib/games/steam/tf2/

systemctl restart tf2