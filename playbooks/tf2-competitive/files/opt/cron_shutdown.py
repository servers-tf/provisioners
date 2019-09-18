#! /usr/bin/python3.6
import time
import subprocess

def main():
    boottime = None
    ttl = None
    
    with open("/opt/attributes.ini") as file:
        for line in file:
            key, value = line.split("=", 1)
            value.rstrip("\n\r")

            if key == "boottime":
                boottime = int(value)
            elif key == "ttl":
                ttl = int(value)

    ttl = ttl * 60
    elapsed = time.time() - boottime
    
    if elapsed >= 60*60*24:
        print("calling for hard shutdown")
        alert()
        subprocess.run('/sbin/shutdown -h now', shell=True, check=True)
    
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

if __name__ == '__main__':
    main()
