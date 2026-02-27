#!/bin/bash
# DELUGE_IDS is /tmp/deluge_ids.txt
grep -oE "[a-f0-9]{40}" /tmp/deluge_ids.txt | while read -r id; do
    # Get the name of the torrent
    name=$(docker exec binhex-delugevpn deluge-console -c /config "info $id" | head -n 1 | sed -E 's/^\[.*\] +[0-9]+% +//; s/ [a-f0-9]{40}$//' | xargs)
    
    if [[ -n "$name" ]]; then
        echo "Processing ID: $id | Name: $name"
        
        # Search for the name in /mnt/user/plex/tv/
        # Use find with -name and -print -quit to find the first match
        location=$(find /mnt/user/plex/tv/ -name "$name" -print -quit)
        
        if [[ -n "$location" ]]; then
            # Get the parent directory
            parent_dir=$(dirname "$location")
            # Convert host path to container path (/mnt/user/plex -> /data)
            container_loc=$(echo "$parent_dir" | sed 's|/mnt/user/plex/|/data/|')
            
            echo "Found at: $location | Container Path: $container_loc"
            
            # Update Deluge
            docker exec binhex-delugevpn deluge-console -c /config "move $id $container_loc"
            docker exec binhex-delugevpn deluge-console -c /config "recheck $id"
            docker exec binhex-delugevpn deluge-console -c /config "resume $id"
        else
            echo "NOT FOUND: $name"
        fi
    fi
done
echo "Path correction complete."
