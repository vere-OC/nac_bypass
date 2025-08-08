#!/bin/bash

# -----
# Name: awareness.sh
# scip AG - Michael Schneider
# -----

## Variables
VERSION="0.1.1-1746786622"

INTERFACE="eth0"
STATE_INTERFACE=0
STATE_COUNTER=0
THRESHOLD_UP=3
THRESHOLD_DOWN=5
TIMER="5s"
url="<TODO Replace with project specific>"

SCRIPT_DIR=$(dirname "$(readlink -f "$0")")

## display usage hints
Usage() {
  echo -e "$0 v$VERSION usage:"
  echo "    -h          display this help"
  echo "    -i <eth>    network interface plugged into docking station"
  exit 0
}

## display version info
Version() {
  echo -e "$0 v$VERSION"
  exit 0
}

## Check if we got all needed parameters
CheckParams() {
  while getopts ":hi:" opts
    do
      case "$opts" in
        "i")
          INTERFACE=$OPTARG
          ;;          
        "h")
          Usage
          ;;
        *)
          INTERFACE="eth0"
          ;;
      esac
  done
}

## Main
CheckParams $@

## Run Initial Configuration
bash "${SCRIPT_DIR}/nac_bypass_setup.sh" -a -i

## Loop
while true
do
    NETWORK_STATE_INTERFACE=`cat "/sys/class/net/$INTERFACE/carrier"`
 
    if [ "$NETWORK_STATE_INTERFACE" -ne "$STATE_INTERFACE" ]; then

        STATE_COUNTER=0

        if [ "$NETWORK_STATE_INTERFACE" -eq 1 ]; then
            echo "[!] $INTERFACE is now up!"
        else
            echo "[!] $INTERFACE is now down!"
        fi
    else

        if [ "$STATE_COUNTER" -eq "$THRESHOLD_UP" ] && [ "$NETWORK_STATE_INTERFACE" -eq 1 ]; then
            echo "[!!] Set new config"
            bash "${SCRIPT_DIR}/nac_bypass_setup.sh" -a -c
            curl -X POST -H "Content-Type:applciation/json" -d '{"text":"Connection Up, client was connected and you should be able to access the network now"}' $url

 
        elif [ "$STATE_COUNTER" -eq "$THRESHOLD_DOWN" ] && [ "$NETWORK_STATE_INTERFACE" -eq 0 ]; then
            echo "[!!] Reset config"
            bash "${SCRIPT_DIR}/nac_bypass_setup.sh" -a -r
            bash "${SCRIPT_DIR}/nac_bypass_setup.sh" -a -i

            curl -X POST -H "Content-Type:applciation/json" -d '{"text":"Connection Down, client was disconnected, going back to pure bridge mode"}' $url
                                                                                                     
        fi

        echo "[*] Waiting"
        ((STATE_COUNTER++))
    fi

    STATE_INTERFACE=$NETWORK_STATE_INTERFACE
    sleep $TIMER
done
