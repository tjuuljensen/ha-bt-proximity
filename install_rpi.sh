# Listen for raspbeerypi.local machine (default RPI hostname) and start firts update process
#

i=0

echo Looking for Raspbery Pi...
while [ $i -lt 60 ]
do # do this for 10 minutes
  RASPBERRYPIIP=$(dig raspberrypi +short)
  if [ -z $RASPBERRYPIIP ] ; then
    sleep 10
  else
    echo Found with IP address: $RASPBERRYPIIP
    break
  fi
done

if [ -z $RASPBERRYPIIP ] ; then
  echo No Raspbeery Pi detected in 10 minutes.
  exit 1
fi

DEFAULTPWD_BOOL=$( ssh -J pi:raspberry@$RASPBERRYPIIP "exit" &>/dev/null )
if ( $DEFAULTPWD_BOOL ) ; then
  LOGINSTRING="pi:raspberry"
else
  LOGINSTRING="pi"
fi

# Optionally copy ssh keys from local machine to RPI
read -r -p "Do you want to copy ssh keys to RPI [y/N]? (<Enter> to continue) " RESPONSE
RESPONSE=${RESPONSE,,}
if [[ $RESPONSE =~ ^(yes|y| ) ]] ; then
  ssh-copy-id $LOGINSTRING@$RASPBERRYPIIP # enter password manually first time
fi

# if defaultpassword is set, ask to change password of pi user 
if ( $DEFAULTPWD_BOOL ) ; then
  read -r -p "Do you want to change the password of the pi user [y/N]? (<Enter> to continue) " RESPONSE
  RESPONSE=${RESPONSE,,}
  if [[ $RESPONSE =~ ^(yes|y| ) ]] ; then
    echo Changing pi password...
    ssh $LOGINSTRING@$RASPBERRYPIIP "sudo passwd pi"
  fi
fi

# First login - update
ssh $LOGINSTRING@$RASPBERRYPIIP "sudo apt-get update && sudo apt-get upgrade -y && sudo apt-get dist-upgrade -y && sudo reboot"
