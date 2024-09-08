#!/bin/bash

#Global Variables
Date=$(date | awk '{print $3,$2,$NF,$4}' | sed 's/ /_/g')
OriginalLocation=$(pwd)
PWD=$(pwd)
ThisLoc=""
Tool=$OriginalLocation/Carver
AlteredName=0
OriginalName=""
NameOfFile=""
FileExt=""
FileNameOnly=""
FilePath=""
bold=$(tput bold)
normal=$(tput sgr0)
Dial_x="	${bold}<x>${normal}"
Dial_o="	${bold}<o>${normal}"
BinwalkFiles=""
UsedCarvers=""
BinwalkRes=""
ForemostRes=""
Bulk_ExtractorRes=""
StringsRes=""
Counter=0
AppLogo=".____       _____  __________  _____ __________ ____ ___  _________ 
|    |     /  _  \ \____    / /  _  \\______   \    |   \/   _____/ 
|    |    /  /_\  \  /     / /  /_\  \|       _/    |   /\_____  \  
|    |___/    |    \/     /_/    |    \    |   \    |  / /        \ 
|_______ \____|__  /_______ \____|__  /____|_  /______/ /_______  / 
        \/       \/        \/       \/       \/      by GH      \/  "

# Function Init - check if root - get file to work on  - checks file validity - extract files - creates report file - zip folder - move to final location   
function Init(){
	
	VerifRoot
	InstallDep
	
	echo -e  "\n\n Welcome to: \n$AppLogo \n\n"
	read -p "$Dial_o Please type in the path to the file you wish to Carve: " File
	
	CheckInput "$File"
	Extract "$NameOfFile"
	CreateOutput
	# ask to display report file
	echo -e "$Dial_o $File was processed.\n$Dial_o Would you like to view the report file? [y/n]"
	read DisplayReport
	
	case $DisplayReport in
		y)
		echo -e "\n\n"
		cat $Tool/Extractor_Report.txt
		;;
	esac
	echo -e "\n\n$Dial_o Compressing  results folder.\n$Dial_o This may take a few moments..."
	# change $Tool directory permissions
	chmod -R 777 $Tool
	cd $Tool
	ZipName="$FileNameOnly.zip"
	# zip folder
	zip -r $ZipName ./ > /dev/null 2>&1
	# move zip file to app directory
	mv $ZipName $OriginalLocation
	# delete $Tool folder
	rm -r $Tool
	echo -e "\n\n$Dial_o All extracted files are available @:\n$Dial_o $OriginalLocation/$ZipName\n$Dial_o Exiting App.\n	Goodbye."
}
# verifies if the user is root - else exit app.
function VerifRoot(){
	
	User=$(whoami)
	if [ "$User" != "root" ]
	then
		echo "$Dial_x Only root user is allowed to use this app. Good bye"
		exit
	fi
}
# instal required app dependencies on the local machine
function InstallDep(){
	
	RequiredApps=("binwalk" "foremost" "bulk_extractor" "Strings")
	# loops on all $RequiredApps values and insalls missing required apps
	for App in "${RequiredApps[@]}";
	do
		dpkg -s "$App" >/dev/null 2>&1 || 
		(echo -e "[*] installing $App..." &&
		sudo apt-get install "$App" -y >/dev/null 2>&1)
		echo "[#] $App installed on remote host."
    done
}

# checks if file exists in local machine, if it does, the app - else exits app
function CheckInput(){
	
	if [  "$1" = ""  ]
	then
		echo "$Dial_x Cannot work without a file. Goodbye"
		exit
	fi
	if  [  ! -f  "$1" ];
	then
		echo "$Dial_x File not found @ given location. Goodbye"
		exit
	fi	
		DecompFileName "$1"
		#set the value of $NameOfFile to the given file location 
		NameOfFile="$1"
	
}
# creates variables with the value of the file name, file path and file extention
function DecompFileName(){
	
	TempString=$(echo $1 | awk -F/ '{print $NF}')
	FileExt=$(echo $TempString | awk -F. '{print $NF}')
	FileNameOnly=${TempString%".$FileExt"}
	TempString="$FileNameOnly.$FileExt"
	FilePath=${1%/"$TempString"}
}

# select extraction methode and calls for the coresponding function
function Extract(){
	
	ThisLoc=$(pwd)
	mkdir $Tool > /dev/null 2>&1
	echo -e "\n\n $Dial_o What type of action would you like to perform?\n\n	x - ${bold}Exit${normal}\n	1 -${bold} Binwalk${normal}\n	2 -${bold} Foremost${normal}\n	3 - ${bold}Bulk Extractor${normal}\n	4 - ${bold}Strings${normal}\n	5 - ${bold}All Carvers${normal}"
	if [ "$FileExt" == "mem" ]
	then
	echo -e "	6 - ${bold}Volatility${normal}"
	fi
	read Action
	case $Action in
	x)
	echo -e "Ok.\nGoodbye..."
	exit
	;;
	1)
	Binwalk "$1"
	;;
	2)
	Foremost "$1"
	;;
	3)
	Bulk_Extractor "$1"
	;;
	4)
	Strings "$1"
	;;
	5)
	Binwalk "$1"
	Foremost "$1"
	Bulk_Extractor "$1"
	Strings "$1"
	;;
	6)
	Vol "$1"
	;;
	*)
	echo "$Dial_x selection not available"
	Extract
	;;
	esac
}
# process file with binwalk
function Binwalk(){
	
	UsedCarvers="$UsedCarvers Binwalk"
	echo "$Dial_o Processing ${bold}$FileNameOnly.$FileExt${normal} with Binwalk"
	binwalk --run-as=root -e "$1" -C $Tool/Binwalk  > /dev/null 2>&1
	#if the app has results store them in $BinwalkRes
	if [ -d "$Tool/Binwalk/_$FileNameOnly.$FileExt.extracted" ];
	then
		cd $Tool/Binwalk/"_$FileNameOnly.$FileExt.extracted"
		BinwalkRes=$(ls)
		cd $ThisLoc
	else
		BinwalkRes="NoRes"
	fi
}
# process file with foremost
function Foremost(){
	
	UsedCarvers="$UsedCarvers Foremost"
	echo "$Dial_o Processing ${bold}$FileNameOnly.$FileExt${normal} with Foremost"
	foremost "$1" -o $Tool/Foremost > /dev/null 2>&1
	# changing permissions of foremost result folder
	sudo -S chmod -R 777 $Tool/Foremost
	cd $Tool/Foremost
	Folders=$(ls -l | grep ^d | awk '{print $NF}')
	for d in $Folders;
	do
		cd "$Tool/Foremost/$d"
		ForemostFolderContent=$(ls -l | grep -v ^d | awk '{print $NF}' | tail -n +2)
		#store results in $ForemostRes
		ForemostRes=$(echo -e "$ForemostRes\n$ForemostFolderContent")
	done
	cd $ThisLoc
}
# process file with bulk_extractor
function Bulk_Extractor(){
	
	UsedCarvers="$UsedCarvers Bulk_Extractor"
	echo "$Dial_o Processing ${bold}$FileNameOnly.$FileExt${normal} with Bulk_Extractor"
	bulk_extractor "$1" -o "$Tool/Bulk_Extractor"  > /dev/null 2>&1
	cd "$Tool/Bulk_Extractor"
	#calls the RemoveEmpty fuction to delete empy files and direcories from results
	RemoveEmpty "$Tool/Bulk_Extractor"
	BulkFolders=$(ls -l | grep ^d | awk '{print $NF}')
	BulkFiles=$(ls -l | grep -v ^d | awk '{print $NF}' | tail -n +2)
	#store results in $Bulk_ExtractorRes
	Bulk_ExtractorRes=$(echo -e "$BulkFolders\n$BulkFiles")
	cd $ThisLoc
}
# process file with strings
function Strings(){
	
	UsedCarvers="$UsedCarvers Strings"
	echo "$Dial_o Processing ${bold}$FileNameOnly.$FileExt${normal} with Strings"
	mkdir $Tool/Strings
	strings "$1" > $Tool/Strings/Strings.txt
	#stores number of lines in strings file in $StringsRes
	StringsRes=$(cat $Tool/Strings/Strings.txt | wc | awk '{print $1}')
	StringsRes="Strings.txt contains $StringsRes lines."
	cd $ThisLoc
}
# process file with Volatility
function Vol(){
	
	UsedCarvers="$UsedCarvers Vol"
	VolRes="Avialable"
	# used Volatility apps in extraction.
	# pstree - for processes
	# pslist - for processes
	# connscan - for communications
	# hivelist - for registery files 
	Apps="pstree pslist connscan hivelist"
	Profile=$(./Vol -f "$1" imageinfo > /dev/null 2>&1 | grep Profile | awk '{print $4}' | sed 's/,/ /g')
	mkdir $Tool/Vol
	for VolAction in $Apps
	do
		echo "$Dial_o Processing ${bold}$FileNameOnly.$FileExt${normal} with ${bold}$VolAction${normal}"
		./Vol -f "$1" > /dev/null 2>&1 --$Profile $VolAction > $Tool/Vol/$VolAction.txt
	done
	
}
# routing to report(s) makers
function CreateOutput(){
	
	if [ "$BinwalkRes,$ForemostRes,$Bulk_ExtractorRes,$StringsRes,$VolRes" != ",,,," ]
	then
		RemoveEmpty "$Tool"
		echo -e "Process date: $Date \nName of file processed: $FileNameOnly.$FileExt \nProcessed by:$UsedCarvers" >> $Tool/Extractor_Report.txt
		if [[ $UsedCarvers == *"Binwalk"* ]];
		then 
			BinwalkOutputMaker
		fi
		if [[ $UsedCarvers == *"Foremost"* ]];
		then
			ForemostOutputMaker
		fi
		if [[ $UsedCarvers == *"Bulk_Extractor"* ]];
		then
			Bulk_ExtractorOutputMaker
		fi
		if [[ $UsedCarvers == *"Strings"* ]];
		then
			StringsOutputMaker
		fi
		if [[ $UsedCarvers == *"Vol"* ]];
		then
			VolOutputMaker
		fi
	fi
}
# create binwalk output 
function BinwalkOutputMaker(){
	EchoString="\n___________________________________\n\n	Binwalk Results \n\n"
	if [ $BinwalkRes != "NoRes" ]
	then
		# get number of files in results
		NumberOfFiles=$(echo $BinwalkRes | grep "." | wc | awk '{print $1}')
		if [ $NumberOfFiles -gt 0 ]
		then
			if [ $NumberOfFiles -eq 1 ]
			then
				# $EchoString value if 1 file was discovered
				EchoString="$EchoString $NumberOfFiles file was discovered. \n"
			else
				# $EchoString value if multiple files were discovered
				EchoString="$EchoString $NumberOfFiles files were discovered. \n"
			fi
			Counter=0
			# loop on $BinwalkRes and echo the file name up to 10
			for l in $BinwalkRes
			do
				if [ $Counter -lt 11 ]
				then 
					EchoString="$EchoString $l \n"
					Counter=$((Counter+1))
				else
					EchoString="$EchoString	Showing 10/$NumberOfFiles files. \n"
					break
				fi
			done
			# adds to $EchoString the directory location
			EchoString="$EchoString \n All files available for viewing in the directory: \n /Binwalk"
		else 
		EchoString="$EchoString Binwalk has not discovered any files. \n"
		fi
	else
		EchoString="$EchoString Binwalk has not discovered any files. \n"
	fi
	
	EchoString="$EchoString \n\n	End Of Binwalk Results \n___________________________________"
	echo -e "$EchoString" >> $Tool/Extractor_Report.txt
}
# create Foremost output 
function ForemostOutputMaker(){
	
	EchoString=""
	NumberOfFiles=$(echo $ForemostRes | wc | awk -F"\n" '{print $1}' | awk '{print $2}')
	EchoString="\n___________________________________\n\n	Foremost Results\n\n"
	# get number of files in results
	if [ $NumberOfFiles -gt 0 ]
	then
		if [ $NumberOfFiles -eq 1 ]
		then
			# $EchoString value if 1 file was discovered
			EchoString="$EchoString$NumberOfFiles file was discovered."
		else
			# $EchoString value if multiple files were discovered
			EchoString="$EchoString$NumberOfFiles files were discovered."
		fi
	echo -e "$EchoString" >> $Tool/Extractor_Report.txt
	Counter=0
	# loop on $ForemostRes and echo the file name up to 10
	for l in $ForemostRes
	do
		if [ $Counter -lt 11 ]
		then
			echo "$l" >> $Tool/Extractor_Report.txt
			Counter=$((Counter+1))
		else
			echo -e "	Showing 10/$NumberOfFiles files." >> $Tool/Extractor_Report.txt
			break
		fi
	done
	# adds to $EchoString the directory location
	echo -e "\n All files available for viewing in the directory:\n/Foremost" >> $Tool/Extractor_Report.txt
	else 
		echo -e "Foremost has not discovered any files." >> $Tool/Extractor_Report.txt
	fi
	echo -e "\n	End Of Foremost Results\n___________________________________" >> $Tool/Extractor_Report.txt
}
# create Bulk_Extractor output 
function Bulk_ExtractorOutputMaker(){
	NumberOfFiles=$(echo $Bulk_ExtractorRes | wc | awk '{print $2}' )
	EchoString="\n___________________________________\n\n	Bulk_Extractor Results \n\n"
	if [ $NumberOfFiles -gt 1 ]
	# any file found
	then
		EchoString="$EchoString $NumberOfFiles files available for viewing: \n"
		Counter=0
		# loop on $Bulk_ExtractorRes and echo the file name up to 10
		for f in $Bulk_ExtractorRes
		do
			if [ $Counter -lt 11 ]
			then
				EchoString="$EchoString $f \n"
				Counter=$((Counter+1))
			else
				EchoString="$EchoString	Showing 10/$NumberOfFiles"
				break
			fi
		done
		cd "$Tool/Bulk_Extractor"
		# find pcap files
		NumberOfPcapFilesFound=$(find . -type f -name '*.pcap' | wc | awk '{print $1}')
		# any pcap file found
		if [ $NumberOfPcapFilesFound -gt 0 ]
		then
			PcapFilesNames=$(find . -type f -name '*.pcap' | awk -F/ '{print $NF}')
			if [ $NumberOfPcapFilesFound -gt 1 ]
			then
				# $EchoString value if multiple files were discovered
				EchoString="$EchoString \n\n Including the following .pcap files: "
			else
				# $EchoString value if 1 files was discovered
				EchoString="$EchoString \n\n Including the following .pcap file: "
			fi
			Counter=0
			c
			for pcap in $PcapFilesNames
			do
				if [ $Counter -lt 11 ]
				then
				SizeOfPcap=$(du -sh "$Tool/Bulk_Extractor/$pcap" | awk '{print $1}')
				EchoString="$EchoString \n $pcap - size: $SizeOfPcap"
				Counter=$((Counter+1))
				else
				EchoString="$EchoString 	Showing 10/$NumberOfPcapFilesFound \n"
				break
				fi
			done
			# adds to $EchoString the directory location
			EchoString="$EchoString \n\n All files available for viewing in the directory:\n /Bulk_Extractor \n"
		fi
	else
		EchoString="$EchoSring 0 files available for viewing."
	fi
	EchoString="$EchoString \n	End Of Bulk_Extractor Results \n___________________________________"
	echo -e "$EchoString" >> $Tool/Extractor_Report.txt
}
# create Strings output 
function StringsOutputMaker(){
	
	EchoString="\n___________________________________\n\n	Strings Results \n\n $StringsRes"
	EchoString="$EchoString \n All files available for viewing in the directory:\n /Strings \n\n	End Of Strings Results\n___________________________________"
	echo -e "$EchoString" >> $Tool/Extractor_Report.txt
}
# create Volatility output 
function VolOutputMaker(){
	
	EchoString=""
	if [ -d  "$Tool/Vol" ];
	then
		echo -e "\n___________________________________\n\n	Volatility Results" >> $Tool/Extractor_Report.txt
		# processes connscan results for report
		if  [ -f  "$Tool/Vol/connscan.txt" ];
		then
			ServiceString=$(cat $Tool/Vol/connscan.txt | grep "No suitable address space mapping found" | wc | awk '{print $1}')
			if [ $ServiceString -eq 0 ]
			then
				echo -e "\n Connscan has found evidence of trafic involving the following IPs \n" >> $Tool/Extractor_Report.txt
				ConnscanRes=$(cat $Tool/Vol/connscan.txt | tail -n +3 | awk '{print $2,$3}' | sort | uniq)
				NumberOfFiles=$(echo $ConnscanRes | wc | awk '{print $1}')
				Counter=0
				# loop on $ConnscanRes and echo the file name up to 10
				for ip in $ConnscanRes
				do
					if [ $Counter -lt 11 ]
					then
						echo $ip | awk -F":" '{print $1}' >> $Tool/Extractor_Report.txt
						Counter=$(($Counter + 1))
					else
						echo "	Showing 10/$NumberOfFiles" >> $Tool/Extractor_Report.txt
					fi
				done
			else
				echo -e "\n Connscan has found no evidence of trafic\n" >> $Tool/Extractor_Report.txt
			fi
		fi
		# processes pslist results for report
		if [ -f "$Tool/Vol/pslist.txt" ];
		then
			ServiceString=$(cat $Tool/Vol/pslist.txt | grep "No suitable address space mapping found" | wc | awk '{print $1}')
			if [ $ServiceString -eq 0 ]
			then
				echo -e "\n Pslist has extracted records of some processes\n" >> $Tool/Extractor_Report.txt
				Processes=$(cat $Tool/Vol/pslist.txt | tail -n +3 | awk '{print $2}' | grep "\.")
				NumberOfFiles=$(echo $Processes | wc | awk '{print $2}')
				Counter=0
				# loop on $Processes and echo the process up to 10
				for p in $Processes
				do
					if [ $Counter -lt 11 ]
					then
						echo "$p " >> $Tool/Extractor_Report.txt
						Counter=$(($Counter + 1))
					else
						echo "	Showing 10/$NumberOfFiles" >> $Tool/Extractor_Report.txt
						break
					fi
				done
			else
				echo -e "\n Pslist has not extracted any records\n" >> $Tool/Extractor_Report.txt
			fi
		fi
		# processes pstree results for report
		if [ -f "$Tool/Vol/pstree.txt" ];
		then
			ServiceString=$(cat $Tool/Vol/pstree.txt | grep "No suitable address space mapping found" | wc | awk '{print $1}')
			if [ $ServiceString -eq 0 ]
			then
				echo -e "\n Pstree has extracted records of some processes\n" >> $Tool/Extractor_Report.txt
				Processes=$(cat $Tool/Vol/pstree.txt | awk '{print $2}' | awk -F":" '{print $2}'| grep "\.")
				NumberOfFiles=$(echo $Processes | wc | awk '{print $2}')
				Counter=0
				# loop on $Processes and echo the process up to 10
				for p in $Processes
				do
					if [ $Counter -lt 11 ]
					then
						echo "$p" >> $Tool/Extractor_Report.txt
						Counter=$(($Counter + 1))
					else
						echo "	Showing 10/$NumberOfFiles" >> $Tool/Extractor_Report.txt
						break
					fi
				done
			else
			echo -e "\n Pstree has not extracted any records\n" >> $Tool/Extractor_Report.txt
			fi
		fi
		# processes hivelist results for report
		if [ -f "$Tool/Vol/hivelist.txt" ];
		then
			ServiceString=$(cat $Tool/Vol/hivelist.txt | grep "No suitable address space mapping found" | wc | awk '{print $1}')
			if [ $ServiceString -eq 0 ]
			then
				echo -e "\n hivelist has extracted locations of registry files. \n" >> $Tool/Extractor_Report.txt
				RegFile=$(cat $Tool/Vol/hivelist.txt | tail -n +3)
				NumberOfFiles=$(echo $RegFile | wc | awk '{print $2}')
				if [ $NumberOfFiles -gt 0 ]
				then
					# echo all registry files found
					echo -e "$RegFile" >> $Tool/Extractor_Report.txt
				fi
			else
			echo -e "\n hivelist has not extracted any records\n" >> $Tool/Extractor_Report.txt
			fi
		fi
		
	echo -e "\n\n All files available for viewing in the directory: \n /Vol" >> $Tool/Extractor_Report.txt
	echo -e "\n	End Of Volatility Results\n___________________________________" >> $Tool/Extractor_Report.txt
	fi
}
# Removes empty files and directories from a directory
function RemoveEmpty(){
	
	cd $1
	find . -empty -delete
}

# calling initialising function
Init
