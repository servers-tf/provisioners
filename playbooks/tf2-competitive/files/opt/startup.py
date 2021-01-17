#! /usr/bin/python3.6
import boto3
import os
import requests
import json
import subprocess

TF_SECRETS_FILE = "/usr/games/steam/tf2/tf/cfg/secrets.cfg"
TELEGRAF_ENV_FILE = "/etc/default/telegraf"
TELEGRAF_GLOBAL_TAGS_FILE = "/etc/telegraf/telegraf.d/global_tags.conf"

SECRETS_FILE = "/opt/secrets.json"
TAGS_FILE = "/opt/tags.json"

# Get Region
response = requests.get("http://169.254.169.254/latest/meta-data/placement/availability-zone")
region_name = response.text[:-1]

# Get instance object
response = requests.get("http://169.254.169.254/latest/meta-data/instance-id")
ec2 = boto3.resource("ec2", region_name=region_name)
instance = ec2.Instance(response.text)

# Put tags into file
with open(TAGS_FILE, "w") as file:
    tags = {tag['Key']: tag['Value'] for tag in instance.tags}
    locations = {"us-east-1": "US East", "us-east-2": "US Central", "us-west-1": "US West", "us-west-2": "US West"}
    tags['location'] = locations[region_name]
    tags['launch_time'] = int(instance.launch_time.timestamp())
    file.write(json.dumps(tags, indent=4))

subprocess.run(["/bin/chown", "steam:steam", TAGS_FILE], check=True)
subprocess.run(["/usr/bin/chattr", "-i", TAGS_FILE], check=True)

# Get secrets
ssm = boto3.client('ssm', region_name=region_name)
response = ssm.get_parameters(Names=["influx_token", "influx_org", "influx_bucket", "demostf_api_key", "logstf_api_key", "discord_api_key", "archive_s3_bucket"])
secrets = response['Parameters']
secrets = {secret['Name']: secret['Value'] for secret in secrets}

# Put secrets
with open(TF_SECRETS_FILE, "w") as file:
    file.write(f"logstf_apikey \"{secrets['logstf_api_key']}\"\n")
    file.write(f"logstf_api_key \"{secrets['logstf_api_key']}\"\n")
    file.write(f"demostf_api_key \"{secrets['demostf_api_key']}\"\n")
    file.write(f"sm_demostf_apikey \"{secrets['demostf_api_key']}\"\n")
    file.write(f"discord_api_key \"{secrets['discord_api_key']}\"\n")
    file.write(f"archive_s3_bucket \"{secrets['archive_s3_bucket']}\"\n")
    file.write(f"discord_message_id \"{tags['discord_message_id']}\"\n")
    file.write(f"discord_channel_id \"{tags['discord_channel_id']}\"\n")
    file.write(f"sv_password \"{tags['server_password']}\"\n")
    file.write(f"tv_password \"{tags['spectate_password']}\"\n")
    file.write(f"sp_hostname \"{tags['reservation_id']}\"\n")
    file.write(f"sp_location \"{tags['location']}\"\n")

with open(SECRETS_FILE, "w") as file:
    file.write(json.dumps(secrets, indent=4))

# Setup Telegraf agent
with open(TELEGRAF_ENV_FILE, "w") as file:
    file.write(f"INFLUX_ORG=\"{secrets['influx_org']}\"\n")
    file.write(f"INFLUX_TOKEN=\"{secrets['influx_token']}\"\n")
    file.write(f"INFLUX_BUCKET=\"{secrets['influx_bucket']}\"\n")

with open(TELEGRAF_GLOBAL_TAGS_FILE, "w") as file:
    file.write("[global_tags]\n")
    file.write(f"    reservation_id = \"{tags['reservation_id']}\"\n")
    file.write(f"    requested_by = \"{tags['requested_by']}\"\n")

subprocess.run(["/bin/systemctl", "restart", "telegraf"], check=True)

# Set hostname
subprocess.run(["/usr/bin/hostnamectl", "set-hostname", f"{tags['Name']}"], check=True)
