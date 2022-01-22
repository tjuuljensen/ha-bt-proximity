# Make presence detection RPI
# https://github.com/jxlarrea/ha-bt-proximity
#
# Torsten Juul-Jensen

# Listen for Raspberry pi on network
i=0
while [ $i -lt 30 ] ; do # do this for 50 minutes
  RASPBERRYPIIP=$(dig raspberrypi +short)
  if [ -z $RASPBERRYPIIP ] ; then
    sleep 10
  else
    break
  fi
done

if [ -z $RASPBERRYPIIP ] ; then
  echo No Raspbeery Pi found in the last 5 minutes.
  exit 1
fi

# Chech if the pi has default password
DEFAULTPWD_BOOL=$( ssh -J pi:raspberry@$RASPBERRYPIIP "exit" &>/dev/null )
if ( $DEFAULTPWD_BOOL ) ; then
  LOGINSTRING="pi:raspberry"
else
  LOGINSTRING="pi"
fi


ssh $LOGINSTRING@$RASPBERRYPIIP <<'EOF'
# To avoid running the script using sudo, modify permissions for hcitool.
sudo setcap cap_net_raw+ep /usr/bin/hcitool

# Install dependencies
sudo apt-get install nodejs npm git libmosquitto-dev mosquitto mosquitto-clients libmosquitto1 -y

# Install the ha-bt-proximity script:
git clone git://github.com/tjuuljensen/ha-bt-proximity
cd ha-bt-proximity
npm install

# start the bluetooth daemon in 'compatibility' mode - change config file
BLUETOOTHCFG=/etc/systemd/system/dbus-org.bluez.service
if [ $(grep ExecStart $BLUETOOTHCFG  | wc -l) -eq 1 ] ; then
  sudo sed -i '/ExecStart/ s/$/ -C/' $BLUETOOTHCFG
  sudo sed -i '/^ExecStart.*/a ExecStartPost=/usr/bin/sdptool add SP' $BLUETOOTHCFG
else
  echo The file $BLUETOOTHCFG has multiple ExecStart entries. Either it has been modified before or an error has occured
  exit 1
fi

# Create service file
SERVICEFILE=/etc/systemd/system/ha-bt-proximity.service
TEMPFILE="$(mktemp /tmp/servicefile.XXXXXXXXXX)"

echo '[Unit]
Description=HA BT Proximity Service

[Service]
User=root
ExecStart=/usr/bin/node /home/pi/ha-bt-proximity/index.js
WorkingDirectory=/home/pi/ha-bt-proximity
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target' > /tmp/ha-bt-proximity.service
sudo cp $TEMPFILE $SERVICEFILE

sudo systemctl enable ha-bt-proximity.service
#sudo systemctl start ha-bt-proximity.service

sensor-config.sh

EOF
