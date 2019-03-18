#/bin/bash
systemctl stop tf2

# Cleanup Discord messages
# TODO

# Delete DNS
tnx_file="/tmp/delete-dns.yaml"
hostname=$(curl --silent http://metadata.google.internal/0.1/meta-data/attributes/hostname)
external_ip=$(curl --silent http://metadata.google.internal/0.1/meta-data/network | grep -iEo '[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+' | grep -v "^10.")
dns_zone="tf2-games"

rm $tnx_file

gcloud dns record-sets transaction start --zone=$dns_zone --transaction-file=$tnx_file
gcloud dns record-sets transaction remove -z=$dns_zone --name="$hostname.tf2.games." --type=A --ttl=60 $external_ip --transaction-file=$tnx_file
gcloud dns record-sets transaction execute  --zone=$dns_zone --transaction-file=$tnx_file

# Delete Instance
network_zone=$(curl --silent http://metadata.google.internal/0.1/meta-data/zone | grep -iEo 'us-(east|central|west)[0-9]-[a-z]')
server_name=$(curl --silent http://metadata.google.internal/0.1/meta-data/hostname | cut -f1 -d.)

yes | gcloud compute instances delete --zone=$network_zone $server_name