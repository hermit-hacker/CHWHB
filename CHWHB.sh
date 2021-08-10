#!/bin/bash

##########################################
# Program:    CHWHB (Create Hardware Hacking Box)
# Author:     Brian Mork (Hermit)
# Version:    0.1
# Modified:   2021-08-04
##########################################

######################################################################################
###                             Helper Functions                                   ###
######################################################################################

################
# Function:   showError
# Variables:  First argument is error text
# Requires:   Nothing
# Returns:    Nothing
################
showError() {
  echo " [!] " $1
  exit 1
}

################
# Function:   showWarning
# Variables:  First argument is warning text
# Requires:   Nothing
# Returns:    Nothing
################
showWarning() {
  echo " [W] " $1
}

################
# Function:   showInfo
# Variables:  First argument is informational text
# Requires:   Nothing
# Returns:    Nothing
################
showInfo() {
  echo " [I] " $1
}

################
# Function:   ask
# Variables:  None
# Requires:   Nothing
# Returns:    "1" if user selects Yes, "0" if user selects No
################
ask()
{
  VALID="FALSE"
  while [ "$VALID" = "FALSE" ]; do
    read -p "  ==> $1 [Y/N] " ANS
    case $ANS in
      [Yy]) RETVAL=1; VALID="TRUE";;
      [Nn]) RETVAL=0; VALID="TRUE";;
      *) echo "Invalid choice."
    esac
  done
  return $RETVAL
}

################
# Function:   paktc (Press Any Key To Continue)
# Variables:  None
# Requires:   Nothing
# Returns:    Nothing
################
paktc()
{
   read -p "Press any key to continue..." -n 1 throwaway
   echo
}

################
# Function:   fileExists
# Does:       Quick test/reporting for the existence of a file
# Variables:  First argument is the file to check
# Requires:   Nothing
# Returns:    Nothing
################
fileExists()
{
  if [ -f $1 ]; then
    ISFILE="yes"
  else
    ISFILE="no"
  fi
}


################
# Function:   dirExists
# Does:       Quick test/reporting for the existence of a directory
# Variables:  First argument is the directory to check
# Requires:   Nothing
# Returns:    Nothing
################
dirExists()
{
  if [ -d $1 ]; then
    ISDIR="yes"
  else
    ISDIR="no"
  fi
}


################
# Function:   checkMakeFile
# Does:       Quick test/reporting for the existence of a file, create it if it doesn't exist
# Variables:  First argument is the file to check
# Requires:   Nothing
# Returns:    Nothing
################
checkMakeFile()
{
  fileExists $1
  if [ "$ISFILE" == "no" ]; then
    touch $1
  fi
}


################
# Function:   checkMakeDir
# Does:       Quick test/reporting for the existence of a directory, create it if it doesn't exist
# Variables:  First argument is the directory to check
# Requires:   Nothing
# Returns:    Nothing
################
checkMakeDir()
{
  dirExists $1
  if [ "$ISDIR" == "no" ]; then
    mkdir -p $1
  fi
}


################
# Function:   purgeIfFound
# Does:       If a directory exists, purge everything there to prepare
# Variables:  First argument is the directory to check
# Requires:   Nothing
# Returns:    Nothing
################
purgeIfFound()
{
  dirExists $1
  if [ "$ISDIR" == "yes" ]; then
    rm -Rf $1
    showInfo "Found and cleared $1"
  fi
}


######################################################################################
###                                   Main Program                                 ###
######################################################################################

# Check for root, exit if not
if [[ $EUID -ne 0 ]]; then
  showError "You must be root.  Exiting..."
fi

# Check for Ubuntu-esque operating system, exit if not found
OSNAME=`grep -E '^NAME=' /etc/os-release | cut -d \" -f 2`
if [[ $OSNAME != "Ubuntu" ]]; then
  showWarning "Ubuntu not detected"
  ask "Continue anyways?"
  if [ $RETVAL -eq 0 ]; then
    showError "Exiting now"
  fi
else
  showInfo "Found Ubuntu installation"
fi

# Get to known starting point
cd /root

# Update repositories
showInfo "Updating repositories..."
apt update > chwhb.log 2>&1
showInfo "Repositories updated"

# Build core list of things to install
INSTALLPKGS="android-sdk apktool automake build-essential cmake curl driftnet ettercap-common ettercap-graphical firefoxdriver gcc gcc-arm-none-eabi gdb gdb-multiarch git golang golang-doc hexedit hexdiff libftdi-dev libpci-dev libsmali-java libusb-dev libusb-1.0-0-dev linux-headers-generic linux-headers-$(uname -r) m4 meld minicom nasm nmap openjdk-14-jre picocom python2 python3 python3-dev python3-pip python3-selenium qunit-selenium screen tcptrace tmux tshark wget wireshark xxd"

# Add Arduino-specific items
INSTALLPKGS="$INSTALLPKGS arduino arduino-core arduino-mk arduino-builder arduino-mighty-1284p"

# Add logic analyzer software
INSTALLPKGS="$INSTALLPKGS sigrok sigrok-cli sigrok-firmware-fx2lafw"

# Add firmware tools
INSTALLPKGS="$INSTALLPKGS avrdude binwalk binutils flashrom squashfs-tools squashfs-tools-ng"

# Add filesystem support
INSTALLPKGS="$INSTALLPKGS aptfs exfat-fuse fuse fuse2fs fusefat fuseiso9660 fusesmb httpfs2 ifuse libfuse2 libfuse3-3 libntfs-3g883 lxcfs ntfs-3g python3-fuse rdiff-backup-fs s3fs squashfuse tmfs vmfs-tools winregfs zfs-fuse"

# Add SDR support
INSTALLPKGS="$INSTALLPKGS airspy bladerf cubicsdr cutesdr dump1090-mutability freedv gnuradio gqrx-sdr gr-dab gr-fcdproplus gr-hpsdr gr-limesdr gr-osmosdr hackrf hamradio-sdr horst inspectrum multimon-ng osmo-sdr osmo-trx quisk rtl-sdr sdrangelove soapysdr-module-all soapysdr-tools welle.io"

# Add standard WiFi tools
INSTALLPKGS="$INSTALLPKGS aircrack-ng airgraph-ng kismet kismet-plugins mdk4 wifite"

# Add dependencies for Discord
INSTALLPKGS="$INSTALLPKGS libappindicator1 libgconf-2-4 gconf2-common libdbusmenu-gtk4 libc++1 libc++1-10 libc++abi1-10"

# Install packages
export DEBIAN_FRONTEND=noninteractive
apt -y -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" install $INSTALLPKGS >> chwhb.log  2>&1

# Install Salae software
showInfo "Installing Salae"
SALAEFILE="/usr/local/sbin/salae-logic-analyzer"
fileExists $SALAEFILE
if [ "$ISFILE" == "yes" ]; then
  showInfo "Found Salae Logic Analyzer already installed.  Software will be updated."
  rm -f $SALAEFILE 
fi
wget -O ${SALAEFILE} "https://logic2api.saleae.com/download?os=linux" >> chwhb.log 2>&1
chmod +x $SALAEFILE
showInfo "Installed Salae Logic Analyzer to $SALAEFILE"

# Install Discord
showInfo "Installing Discord"
TMPDIR=`mktemp -d`
wget -O $TMPDIR/discord.deb 'https://discord.com/api/download?platform=linux&format=deb' >> chwhb.log 2>&1
dpkg -i $TMPDIR/discord.deb >> chwhb.log 2>&1
showInfo "Installed Discord"

# Install CHIPSEC
showInfo "Installing CHIPSEC"
pip install setuptools >> chwhb.log 2>&1
purgeIfFound /root/chipsec
git clone https://github.com/chipsec/chipsec.git >> chwhb.log 2>&1
cd chipsec
python setup.py build_ext -i >> chwhb.log 2>&1
cd ..
showInfo "Installed CHIPSEC"

# Install smali
showInfo "Installing smali"
purgeIfFound /root/smali
git clone https://github.com/JesusFreke/smali.git >> chwhb.log 2>&1
cd smali
./gradlew build >> chwhb.log 2>&1
cd ..
showInfo "Installed smali"

# Install Reverse-APK
showInfo "Installing Reverse-APK"
purgeIfFound /root/ReverseAPK
git clone https://github.com/1N3/ReverseAPK.git /root/ReverseAPK >> chwhb.log 2>&1
cd ReverseAPK
./install >> chwhb.log 2>&1
cd /root
showInfo "Installed Reverse-APK"

# Install Postman
showInfo "Installing Postman"
snap install postman >> chwhb.log 2>&1
showInfo "Installed Postman"

# Update root user environment
showInfo "Configuring root environment"
checkMakeDir /root/.tmux
checkMakeDir /root/.tmux/plugins
wget -O /root/.bashrc https://raw.githubusercontent.com/hermit-hacker/ctf-tools/master/root/.bashrc >> chwhb.log 2>&1
wget -O /root/.tmux.conf https://raw.githubusercontent.com/hermit-hacker/ctf-tools/master/root/.tmux.conf >> chwhb.log 2>&1
wget -O /root/.bash_aliases https://raw.githubusercontent.com/hermit-hacker/ctf-tools/master/.bash_aliases >> chwhb.log 2>&1
showInfo "Pulling down helper files from Hermit's GitHub"
wget -O /usr/local/bin/ByteAdder.py https://raw.githubusercontent.com/hermit-hacker/ctf-tools/master/ByteAdder.py >> chwhb.log 2>&1
chmod +x /usr/local/bin/ByteAdder.py
wget -O /usr/local/bin/apk-process.sh https://raw.githubusercontent.com/hermit-hacker/ctf-tools/master/apk-process.sh >> chwhb.log 2>&1
chmod +x /usr/local/bin/apk-process.sh
wget -O /usr/local/bin/ascii2bin.sh https://raw.githubusercontent.com/hermit-hacker/ctf-tools/master/ascii-to-bin.sh >> chwhb.log 2>&1
chmod +x /usr/local/bin/ascii2bin.sh
wget -O /usr/local/bin/rotall.sh https://raw.githubusercontent.com/hermit-hacker/ctf-tools/master/rot-all.sh >> chwhb.log 2>&1
chmod +x /usr/local/bin/rotall.sh
wget -O /usr/local/bin/tarsum.py https://raw.githubusercontent.com/hermit-hacker/ctf-tools/master/tarsum.py >> chwhb.log 2>&1
chmod +x /usr/local/bin/tarsum.py
wget -O /usr/local/bin/wgm.sh https://raw.githubusercontent.com/hermit-hacker/ctf-tools/master/wgm.sh >> chwhb.log 2>&1
chmod +x /usr/local/bin/wgm.sh
purgeIfFound /root/.tmux/plugins/tpm
git clone https://github.com/tmux-plugins/tpm /root/.tmux/plugins/tpm >> chwhb.log 2>&1
purgeIfFound /root/.tmux/plugins/tmux-logging
git clone https://github.com/tmux-plugins/tmux-logging /root/.tmux/plugins/tmux-logging >> chwhb.log 2>&1
purgeIfFound /root/OSCP-Notes
git clone https://github.com/hermit-hacker/OSCP-Study-Notes.git /root/OSCP-Notes >> chwhb.log 2>&1
showInfo "Installations complete!"

showInfo "Cleaning up unused packages"
apt -y -q autoremove >> chwhb.log 2>&1
showInfo "Clean up complete!"

showInfo "Installation tasks completed, exiting CHWHB!"
