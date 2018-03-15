#!/bin/bash




# Todo : create symlink instead of folder 
# version with better copy response (root privileges required) 


smbuser='USER'
smbpasswd='PASSWORD'
smbserver='FQDN'
smbfilepath='PATH'

minecraftDest='.minecraft'

date=$(date +%Y-%m-%d)

_rootDialog () {
	
		PASSWORD=$(whiptail --title "Root privileges required" --passwordbox "Enter your password and choose Ok to continue." 10 60 3>&1 1>&2 2>&3)
		exitstatus=$?
		
		
		# TODO: check if password is correct
		if [ $exitstatus = 0 ]; then
			return 0
		else
			echo "bla"
			exit 1
		fi	
}

_moveClientFiles () {
		
		echo -e "XXX\n60\n move files \nXXX"
		sleep 0.5
		cd $HOME
		mkdir $minecraftDest$date
		#check if folder is already existing
		if [ -d $minecraftDest ]; then 
			# check if folder is a symlink
			if [[ -L $minecraftDest ]]; then
				mv tmp/* $minecraftDest$date
			else
				mv $minecraftDest "$minecraftDest$date"-org
				mv tmp/* $minecraftDest$date
			fi
		else
			
			mv tmp/* $minecraftDest$date

		fi
}


_setupMinecraftClient () {
	mkdir $HOME/tmp
	cd $HOME/tmp
	{
		# copy files from server
		echo -e "XXX\n0\n copy files...  \nXXX"
		smbget -R -n -u -q smb://"$smbuser":"$smbpasswd"@"$smbserver"/"$smbfilepath"
		
		# move files to right directory
		_moveClientFiles ;
	
		echo -e "XXX\n75\n create symlink...\nXXX"
		ln -s $HOME/$minecraftDest$date $minecraftDest
		sleep 2
		echo -e "XXX\n90\nCleanup...\nXXX"
		rmdir $HOME/tmp
		sleep 2   
		echo -e "XXX\n100\nDone...\nXXX"
		sleep 2
	} | whiptail --gauge "Minecraft Setup. Please wait ...." 10 60 0
}

_completeMinecraftClient () {
		
		_rootDialog ;
		mkdir $HOME/tmp
		cd $HOME/tmp
		{
			echo -e "XXX\n0\n Update Repositories ... \nXXX"
			echo $PASSWORD | sudo -S apt-get update
			echo -e "XXX\n10\n Update Repositories ... done \nXXX"
			sleep 2
			
			echo -e "XXX\n15\n Install dependencies ... \nXXX"
			echo $PASSWORD | sudo -S apt-get install openjdk-8-jre-headless -y
			echo -e "XXX\n20\n Install dependencies ... \nXXX"
			echo $PASSWORD | sudo -S apt-get install gvfs-backends gvfs-fuse gvfs-bin -y
			echo -e "XXX\n25\n Install dependencies ... \nXXX"
			echo $PASSWORD | sudo -S apt-get install rsync -y
			echo -e "XXX\n30\n Install dependencies ... Done \nXXX"
			sleep 2
			
			mkdir $HOME/tmp-mount
			echo -e "XXX\n30\n Copy Files... \nXXX"	
			echo $PASSWORD | sudo -S gio mount smb://"$smbuser":"$smbpasswd"@"$smbserver"/"$smbfilepath" $HOME/tmp-mount
					
			
			rsync -avz --progress $HOME/tmp-mount $HOME/tmp  | sed --unbuffered 's/([0-9]*).*/\1/'
			
			echo $PASSWORD | sudo -S gio mount -u $HOME/tmp-mount
			rmdir $HOME/tmp-mount
			
			echo -e "XXX\n50\n Copy Files... Done\nXXX"	
			
			_moveClientFiles ;
			
			echo -e "XXX\n75\n create symlink...\nXXX"
			ln -s $HOME/$minecraftDest$date $minecraftDest
			sleep 2
			echo -e "XXX\n90\nCleanup...\nXXX"
			rmdir $HOME/tmp
			sleep 2   
			echo -e "XXX\n100\nDone...\nXXX"
			sleep 2
			
		} | whiptail --gauge "Minecraft Setup. Please wait ...." 10 60 0
		
		
	sleep 2
}



_main () {
	exec 3>&1
	selected=$(whiptail \
    --title "Menu" \
    --menu "Please select:" 15 80 4 \
    "1" "Setup Minecraft (Client)" \
    "2" "Setup Minecraft (Server)" \
    "3" "Complete Minecraft Client Setup (root privileges required)" \
    2>&1 1>&3)

	
	dialog --clear 
	
	
	case $selected in 
		
		1 ) _setupMinecraftClient ;;
			
		2 ) _setupMinecraftServer ;;
		
		3 ) _completeMinecraftClient ;;
	esac
}

_main
