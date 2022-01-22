#!/bin/bash
# Configuration tool for https://github.com/tjuuljensen/ha-bt-proximity
# Originally forked from https://github.com/jxlarrea/ha-bt-proximity.
#
# The configuration can run multiple times to change config, but is not foolproof.

MQTTFILE=index.js

if [[ ! -f $MQTTFILE ]] ; then
  echo File $MQTTFILE not found. Exiting.
  exit 1
fi

# replace broker ip address
CURRENTBROKER=$(awk -F\" '/^var mqtt_host/{print $2}' $MQTTFILE)
echo Current MQTT broker IP address is $CURRENTBROKER
read -r -p "Enter NEW IP address (or <Enter> to continue unchanged): " NEWBROKER
if [ ! -z $NEWBROKER ] ; then
  sudo sed -i "s/\"$CURRENTBROKER/\"$NEWBROKER/g" $MQTTFILE
fi
# sed -r 's/([0-9]{1,3}\.){3}[xX0-9]{1,3}/x.x.x.x/g'

# Change mqtt user name
CURRENTUSERNAME=$(awk -F\" '/^var mqtt_user/{print $2}' $MQTTFILE)
echo
echo Current MQTT user name is $CURRENTUSERNAME
read -r -p "Enter NEW user name (or <Enter> to continue unchanged): " NEWUSERNAME
if [ ! -z $NEWUSERNAME ] ; then
  sudo sed -i "s/\"$CURRENTUSERNAME/\"$NEWUSERNAME/g" $MQTTFILE
fi

# Change mqtt password
CURRENTPASSWD=$(awk -F\" '/^var mqtt_password/{print $2}' $MQTTFILE)
echo
echo Current password is $CURRENTPASSWD
read -r -p "Enter NEW password (or <Enter> to continue unchanged): " NEWPWD
if [ ! -z $NEWPWD ] ; then
  sudo sed -i "s/\"$CURRENTPASSWD/\"$NEWPWD/g" $MQTTFILE
fi

# Change mqtt room
CURRENTROOM=$(awk -F\" '/^var mqtt_room/{print $2}' $MQTTFILE)
echo
echo Current password is $CURRENTROOM
read -r -p "Enter NEW password (or <Enter> to continue unchanged): " NEWROOM
if [ ! -z $NEWROOM ] ; then
  sudo sed -i "s/\"$CURRENTROOM/\"$NEWROOM/g" $MQTTFILE
fi

LOCALIP=$(hostname -i|cut -f2 -d ' ')

if [ $HOSTNAME == "raspberrypi" ] ; then
  echo
  echo Current hostname is $HOSTNAME
  read -r -p "Enter NEW hostname (or <Enter> to continue unchanged): " NEWHOSTNAME
  if [ ! -z $NEWHOSTNAME ] ; then
    hostnamectl set-hostname --static "$NEWHOSTNAME"
    echo "This host can now be accessed via ssh using pi@$LOCALIP"
    echo
  fi
fi

if [[ ! -z $(grep "00:00:00:00:00:00" $MQTTFILE) ]] ; then # it seems as there has been added no mac addresses
  echo
  echo No sensors seems to be defined
else
  echo
  echo Current sensor config:
  grep  -E "([[:xdigit:]]{1,2}:){5}[[:xdigit:]]{1,2}" $MQTTFILE
fi

# Ask for adding new sensors
read -r -p "Do you want to add new sensors [y/N]? (<Enter> to continue) " RESPONSE
RESPONSE=${RESPONSE,,}
if [[ $RESPONSE =~ ^(yes|y| ) ]] ; then
  read -r -p "Enter NEW mac address (or <Enter> to cancel): " BLUETOOTHMAC
  read -r -p "Enter name of Device (or <Enter> to leave empty): " DEVICENAME
  if [ ! -z $BLUETOOTHMAC ] ; then

    # Insert in top of mac list
    sed -i "'/^var owners .*/a \"$BLUETOOTHMAC\" // $DEVICENAME'" $MQTTFILE

    if [[ -z $(grep "00:00:00:00:00:00" $MQTTFILE) ]] ; then
      # delete line with 00:00:00:00:00:00
      sed '/^"00:00:00:00:00:00"/d'
    fi

    echo
    # reload variables from script for final presentation of results
    CURRENTBROKER=$(awk -F\" '/^var mqtt_host/{print $2}' $MQTTFILE)
    CURRENTUSERNAME=$(awk -F\" '/^var mqtt_user/{print $2}' $MQTTFILE)
    CURRENTPASSWD=$(awk -F\" '/^var mqtt_password/{print $2}' $MQTTFILE)
    CURRENTROOM=$(awk -F\" '/^var mqtt_room/{print $2}' $MQTTFILE)

    echo "Add this as sensor data in Home Assistant:"
    echo "#========================================="
    echo "sensor:"
    echo "  - platform: mqtt"
    echo "    state_topic: 'location/$CURRENTROOM/$BLUETOOTHMAC'"
    echo "    value_template: '{{ value_json.proximity }}'"
    echo "    unit_of_measurement: 'level'"
    echo "    name: '$DEVICENAME $CURRENTROOM Proximity'"
    echo

  fi
fi
