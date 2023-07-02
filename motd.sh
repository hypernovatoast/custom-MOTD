#!/bin/bash

### SECRET KEYS - DO NOT SHARE!!!
haKey="[redacted]"
weatherKey="[redacted]"

### Variables
haURL="http://home.assistant.url:8123/api" #Replace with HA IP address.
weatherNowURL="http://api.weatherapi.com/v1/current.json"
lightsOutput="/scripts/output/ha-lights.txt"

### Greeting
clear
printf "\nWelcome to REPTAR!\n"

### Function to pull current weather information
## replace parameter 'q' with your location. ZIP code or city should work
weatherReport () {
    printf "\nWeather:\n"
    local weather=$(curl -s \
        -d key=$weatherKey \
        -d q=[location] \
        "$weatherNowURL" | \
    jq -r '[.location.localtime, .current.temp_f, .current.last_updated]')
    local time=$(echo "$weather" | jq -r '.[0]')
    local temp=$(echo "$weather" | jq -r '.[1]')
    local lastUpdate=$(echo "$weather" | jq -r '.[2]')
    printf "\nTime: $time\nLast Updated: $lastUpdate\nTemp: $temp\n"
}

### Function to query Home Assistant to see which lights are on and report back appropriately.
haLightsOn () {
    local lights=$(curl -s \
        -H "Authorization: Bearer $haKey" \
        -H "Content-Type: application/json" \
        "$haURL"/states | \
    jq -r '.[] | select(.state=="on" and (.entity_id | startswith("light"))) | .entity_id' | \
    sed 's/^......//' | \
    sort)
    if [ -z "$lights" ]; then
        printf "\nAll lights are off at the moment\n\n"
    else
        printf "\nThe following lights are on:\n$lights\n"
    fi
}

##Script execution
weatherReport
haLightsOn
