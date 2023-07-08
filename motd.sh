#!/bin/bash

### SECRET KEYS - DO NOT SHARE!!!
haKey="[redacted]"
weatherKey="[redacted]"

### Variables
haURL="http://home.assistant.url:8123/api" #Replace with HA IP address.
weatherNowURL="http://api.weatherapi.com/v1/current.json"
lightsOutput="/scripts/output/ha-lights.txt"

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

### Function to pull current temps from the thermostats and echo whether they're running or not. 
insideTemps() {
    local indoorTemps=$(curl -s \
        -H "Authorization: Bearer $haKey" \
        -H "Content-Type: application/json" \
        "$haURL"/states | \
    jq -r '.[] | select((.entity_id | startswith("climate."))) | .attributes.friendly_name, .attributes.current_temperature, .state')
    #local variables to separate the JQ results. 
    #NOTE: If any additional items are added to the above arrey,the awk numbers for therm2 variables will need to be raised by a single digit per item added as awk command is pulling from a specific location in the array.
    local therm1=$(echo "$indoorTemps" | awk 'NR==1')
    local therm2=$(echo "$indoorTemps" | awk 'NR==4')
    local therm1Temp=$(echo "$indoorTemps" | awk 'NR==2')
    local therm2Temp=$(echo "$indoorTemps" | awk 'NR==5')
    local isTherm1On=$(echo "$indoorTemps" | awk 'NR==3')
    local isTherm2On=$(echo "$indoorTemps" | awk 'NR==6')

    printf "\nHome:\n$therm1 temp is $therm1Temp and the fan is set to $isTherm1On\n$therm2 temp is $therm2Temp and the fan is set to $isTherm2On\n"
}

### Function to query Home Assistant to see which lights are on and report back appropriately.
lightsOn () {
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
insideTemps
lightsOn
