#!/bin/bash
base_path="/usr/games/steam/tf2/tf/logs/source-python/"

players=$(cat $base_path/players 2> /dev/null || echo '0')
spectators=$(cat $base_path/spectators 2> /dev/null || echo '0')
bots=$(cat $base_path/bots 2> /dev/null || echo '0')
map=$(cat $base_path/currentmap 2> /dev/null || echo 'itemtest')

echo "srcds map=\"$map\",bots=$bots,players=$players,spectators=$spectators"