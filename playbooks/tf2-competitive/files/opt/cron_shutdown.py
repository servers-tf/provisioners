#! /usr/bin/python3.6
import time
import subprocess
from datetime import datetime
import json
import requests
import boto3

def main():
    with open("/opt/tags.json") as file:
        tags = json.load(file)
    
    ttl = int(tags['ttl'] * 60)
    elapsed = int(time.time() - tags['launch_time'])
    
    # Check if server has been running for more than a day
    if elapsed >= 60*60*24:
        print("calling for hard shutdown")
        alert()
        clear_discord_embed()
        time.sleep(5)
        shutdown()
    
    # Check if server is idle
    with open("/usr/games/steam/tf2/tf/logs/source-python/idle") as file:
        idle_seconds = file.read()
        idle_seconds = float(idle_seconds)
        idle_minutes = idle_seconds / 60
                
        if idle_minutes >= 30 and idle_minutes <= 34:
            shutdown_alert(5)
        elif idle_minutes >= 35:
            alert()
            clear_discord_embed()
            time.sleep(5)
            shutdown()
        
    remaining = int(ttl - elapsed if ttl > elapsed else 0) / 60

    if remaining < 20 and remaining > 19:
        shutdown_alert(20)
    elif remaining < 10 and remaining > 9:
        shutdown_alert(10)
    elif remaining < 5 and remaining > 4:
        shutdown_alert(5)
    elif remaining < 2 and remaining > 1:
        shutdown_alert(2)
    elif remaining == 0:
        print("calling for shutdown")
        alert()
        clear_discord_embed()
        time.sleep(5)
        shutdown()

def shutdown():
    subprocess.run('/sbin/shutdown -h now', shell=True, check=True)

def shutdown_alert(minutes):
    socket_file = "/usr/games/steam/tf2/tmux.sock"
    subprocess.run(f'/usr/bin/tmux -S {socket_file} send -t "srcds" "shutdown_alert {minutes}" ENTER', shell=True, check=True)

def alert():
    try:
        socket_file = "/usr/games/steam/tf2/tmux.sock"
        subprocess.run(f'/usr/bin/tmux -S {socket_file} send -t srcds \'alert \"Reservation has ended, server is shutting down.\"\' ENTER', shell=True, check=True)
    except Exception:
        pass

def clear_discord_embed():
    with open("/opt/secrets.json") as file:
        secrets = json.load(file)

    with open("/opt/tags.json") as file:
        tags = json.load(file)

    token = secrets['discord_api_key']
    channel_id = tags['discord_channel_id']
    message_id = tags['discord_message_id']

    elapsed = int(time.time() - tags['launch_time'])

    auth_headers = {
        "authorization": "Bot " + token,
        "Content-Type": 'application/json'
    }
    base_url = "https://discordapp.com/api"

    embed = {
        "author": {
            "name": "Reservation has ended. Thank you for playing!",
            "icon_url": "http://maps.tf2.games/logo.png"
        },
        "fields": [
            {"name": "Elapsed Time", "value": readable_time(elapsed), "inline": True},
            {"name": "Location", "value": tags['location'],"inline": True},
            {"name": "Reservation ID", "value": tags['reservation_id'],"inline": True}
        ],
        "timestamp": datetime.utcnow().isoformat()
    }

    response = requests.patch(
        f"{base_url}/channels/{channel_id}/messages/{message_id}",
        headers=auth_headers,
        data=json.dumps({"content": "", "embed": embed})
    )

def readable_time(elapsed):
    readable = ""

    days = int(elapsed / (60 * 60 * 24))
    hours = int((elapsed / (60 * 60)) % 24)
    minutes = int((elapsed % (60 * 60)) / 60)

    if(days > 0):
        readable += str(days) + " days "

    if(hours > 0):
        readable += str(hours) + " hours "

    if(minutes > 0):
        readable += str(minutes) + " minutes "

    return readable

if __name__ == '__main__':
    main()
