#!/bin/bash

# Enable job control
set -m

# These files could be left-over if the container is not shut down cleanly. We just remove it since we should
# only be here during container startup.
rm /tmp/.X1-lock
rm -r /tmp/.X11-unix

# Set up the VNC password
if [ -z "$VNC_PASSWORD" ]; then
    echo "VNC_PASSWORD environment variable is not set. Using a random password. You"
    echo "will not be able to access the VNC server."
    VNC_PASSWORD="$(tr -dc '[:alpha:]' < /dev/urandom | fold -w "${1:-8}" | head -n1)"
fi
mkdir ~/.vnc
echo -n "$VNC_PASSWORD" | /opt/TurboVNC/bin/vncpasswd -f > ~/.vnc/passwd
chmod 400 ~/.vnc/passwd
unset VNC_PASSWORD

# TurboVNC by default will fork itself, so no need to do anything here
/opt/TurboVNC/bin/vncserver -rfbauth ~/.vnc/passwd -geometry 1200x800 -rfbport 5900 -wm openbox :1

export DISPLAY=:1

if [ -z "$GRASS_USERNAME" ] || [ -z "$GRASS_PASSWORD" ]; then
    >&2 echo "The GRASS_USERNAME and GRASS_PASSWORD environment variables need to be set"
    >&2 echo "before docker-grass-desktop can start. If you do not already have a username"
    >&2 echo "and password, sign up in a browser at:"
    >&2 echo "https://app.getgrass.io/register/?referralCode=DLZzmgbPgg46WUJ"
    >&2 echo "The container will now exit."
    exit 243
fi

/usr/bin/grass &

if ! [ -f ~/.grass-configured ]; then
    # Wait for the grass window to be available
    while [[ "$(xdotool search --name Grass | wc -l)" -lt 3 ]]; do
        sleep 10
    done

    # Handle grass login
    xdotool search --name Grass | tail -n1 | xargs xdotool windowfocus
    sleep 5
    xdotool key Tab
    xdotool key Return
    sleep 5
    xdotool key Tab
    xdotool key Tab
    xdotool key Tab
    xdotool type "$GRASS_USERNAME"
    xdotool key Tab
    xdotool type "$GRASS_PASSWORD"
    xdotool key Return
    sleep 5
    xdotool key Escape

    touch ~/.grass-configured
fi

fg %/usr/bin/grass
