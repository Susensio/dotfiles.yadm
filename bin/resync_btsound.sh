#!/bin/bash
bluezcard=$(pactl list cards short | awk '/bluez/{print $2}')
pactl set-card-profile "$bluezcard" a2dp
pactl set-card-profile "$bluezcard" hsp
pactl set-card-profile "$bluezcard" a2dp
