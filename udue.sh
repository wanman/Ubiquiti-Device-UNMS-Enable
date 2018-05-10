#Gather fingerprints, push SSH key, enable NTP, and enable UNMS.
#You can change i if you want a different starting point for your IPs.
i=56
#Change network here to suit your needs. Will run on a /24 (or less if you change the number in the 'while' line).
network=10.20.1.
username=$(cat user.txt)
unmskey=$(cat unms.key)
#Set timeout function for 20 seconds per IP.
Timeout=20
timeout_mon() {
 sleep "$Timeout"
 }
 #Error checking function.
 checkerrors() {
  if ! [ $? -eq 0 ]
   then
    $1
    i=$(($i+1))
    killall "$Timeout_monitor_pid" &> /dev/null
    continue
  fi
  }
 #Logging function for offline devices.
 writeoffline() {
  echo "$ipaddress is offline."
  echo "$ipaddress is offline." >> offline.log
  }
 #Function for getting ssh fingerprint.
 scanprint() {
  echo "Getting fingerprint..."
  ssh-keygen -R $ipaddress 2>&1 > /dev/null
  checkerrors fpfail
  ssh-keyscan $ipaddress >> ~/.ssh/known_hosts 2> /dev/null
  checkerrors fpfail
  echo "Fingerprint received for $ipaddress."
  }
 #Logging function for failure to get fingerprint.
 fpfail() {
  echo "$ipaddress failed to supply fingerprint."
  echo "$ipaddress failed to supply fingerprint." >> fail.log
  }
 #Function to copy SSH key.
 cpsshkey() {
 echo "Copying SSH key..."
  sshpass -f pass.txt ssh-copy-id $username@$ipaddress 2>&1 > /dev/null
  if ! [ $? -eq 0 ];
   then
    echo "$ipaddress failed to receive SSH key properly."
    echo "$ipaddress failed to receive SSH key properly." >> fail.log
    i=$(($i+1))
    killall "$Timeout_monitor_pid" &> /dev/null
    continue
   else
    echo "$ipaddress received SSH key."
  fi
  }
 #Function to enable NTP status
 ntpclientenable() {
  echo "Enabling NTP..."
  ssh $username@$ipaddress sed -i -e 's/ntpclient.status.*//g' /tmp/system.cfg
  ssh $username@$ipaddress 'echo "ntpclient.status=enabled" >> /tmp/system.cfg'
  }
 #Function to enable NTP client
 ntpenable() {
  echo "Enabling NTP client..."
  ssh $username@$ipaddress sed -i -e 's/ntpclient.1.status.*//g' /tmp/system.cfg
  ssh $username@$ipaddress 'echo "ntpclient.1.status=enabled" >> /tmp/system.cfg'
  }
 #Function to set NTP server.
 ntpserverset() {
  echo "Setting NTP server..."
  ssh $username@$ipaddress sed -i -e 's/ntpclient.1.server.*//g' /tmp/system.cfg
  ssh $username@$ipaddress 'echo "ntpclient1.server=0.ubnt.pool.ntp.org" >> /tmp/system.cfg'
  }
 #Logging function for enabling NTP failure.
 ntpfail() {
  echo "$ipaddress failed to enable NTP."
  echo "$ipaddress failed to enable NTP." >> fail.log
  }
 #Function to enable UNMS.
 enableunms() {
  echo "Enabling UNMS..."
  ssh $username@$ipaddress sed -i -e 's/unms.status=.*//g' /tmp/system.cfg
  ssh $username@$ipaddress 'echo "unms.status=enabled" >> /tmp/system.cfg'
  }
 #Logging function for enabling UNMS failure.
 enableunmsfail() {
  echo "$ipaddress failed to enable UNMS."
  echo "$ipaddress failed to enable UNMS." >> fail.log
  }
 #Function to write UNMS key.
 writeunmskey() {
  echo "Writing UNMS key..."
  ssh $username@$ipaddress sed -i -e 's/unms.uri.*//g' /tmp/system.cfg
  ssh $username@$ipaddress "echo 'unms.uri='"$unmskey" >> /tmp/system.cfg"
  }
 #Logging function for writing UNMS key failure.
 writeunmskeyfail() {
  echo "$ipaddress failed to receive UNMS key."
  echo "$ipaddress failed to receive UNMS key." >> fail.log
  }
 #Function to write changes to flash memory.
 writemem() {
  echo "Saving changes..."
  ssh -oBatchMode=yes $username@$ipaddress cfgmtd -w -f /tmp/system.cfg
  checkerrors writememfail
  ssh -oBatchMode=yes $username@$ipaddress /usr/etc/rc.d/rc.softrestart save 2>&1 > /dev/null
  }
 #Logging function for failure to write mem.
 writememfail() {
  echo "$ipaddress failed to write flash memory."
  echo "$ipaddress failed to write flash memory." >> fail.log
  }
#Can change network length here, change 254 to last IP to be scanned.
while [ "$i" -le "254" ]
 do
 ipaddress=$network$i
 #Begin timeout
 timeout_mon "$$" &
 Timeout_monitor_pid=$!
 #Check to see if online.
 ping $ipaddress -w 1 -q -c 1 > /dev/null
 checkerrors writeoffline
 scanprint
 cpsshkey 2>&1 > /dev/null
 ntpclientenable
 checkerrors ntpfail
 ntpenable
 checkerrors ntpfail
 ntpserverset
 checkerrors ntpfail
 enableunms
 checkerrors enableunmsfail
 writeunmskey
 checkerrors writeunmskeyfail
 writemem 2> /dev/null
 checkerrors writememfail
 echo "$ipaddress completed successfully." >> win.log
 echo "$ipaddress completed successfully."
 i=$(($i+1))
 killall "$Timeout_monitor_pid" &> /dev/null
done
