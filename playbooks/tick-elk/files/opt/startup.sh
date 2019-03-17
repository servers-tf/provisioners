#!/bin/bash

ATTRIBUTES="http://metadata.google.internal/0.1/meta-data/attributes"


#DISCORD_API_TOKEN=$(curl $ATTRIBUTES/discord-api-token)
PUBLIC_IP_ADDRESS=$(curl --silent http://metadata.google.internal/0.1/meta-data/network | grep -iEo "[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}" | grep -v '^10')

