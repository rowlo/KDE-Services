#!/bin/bash

#################################################################
# For KDE-Services. 2014.										#
# By Geovani Barzaga Rodriguez <igeo.cu@gmail.com>				#
#################################################################

PATH=/usr/local/bin:/usr/bin:/bin:/usr/local/sbin:/usr/sbin:/sbin:/home/$USER/bin

if [ "$(pidof adb)" = "" ]; then
  kdesu --caption="Android File Manager" --noignorebutton -d adb start-server
fi

DIR=""
BEGIN_TIME=""
FINAL_TIME=""
ELAPSED_TIME=""
DBUSREF=""
COUNT=""
COUNTFILES=""
OPERATION=""
FILES=/tmp/afm.tmp
DESTINATION=""
KdialogPID=""
SERIAL=$(adb get-serialno)

###################################
############ Functions ############
###################################

check-device() {
  if [ "$SERIAL" = "unknown" ]; then
	kdialog --icon=/usr/share/icons/hicolor/512x512/apps/ks-error.png --title="Android File Manager" \
			--passivepopup="[Canceled]   Check if your device with Android system is connected on your PC and NOT bootloader mode. \
			[1]-Connect your device to PC USB. [2]-Go to device Settings. [3]-Go to Developer options. [4]-Enable USB debugging option. Try again."
	exit 1
  fi
}

check-device

if-cancel-exit() {
    if [ "$?" != "0" ]; then
	  kill -9 $KdialogPID 2> /dev/null
	  exit 1
    fi
}

progressbar-start() {
    COUNT="0"
    COUNTFILES=$(echo $FILES|wc -w)
    COUNTFILES=$((++COUNTFILES))
    DBUSREF=$(kdialog --icon=/usr/share/icons/hicolor/512x512/apps/ks-android-push-pull.png --caption="Android File Manager" --progressbar "				" $COUNTFILES)
}

progressbar-close() {
    qdbus $DBUSREF Set "" value $COUNTFILES
    sleep 1
    qdbus $DBUSREF close
}

qdbusinsert-push() {
    qdbus $DBUSREF setLabelText "Pushing ${i##*/} to device $SERIAL [$COUNT/$((COUNTFILES-1))]"
    qdbus $DBUSREF Set "" value $COUNT
}

qdbusinsert-pull() {
    qdbus $DBUSREF setLabelText "Pulling ${i##*/} to [$COUNT/$((COUNTFILES-1))]"
    qdbus $DBUSREF Set "" value $COUNT
}

elapsedtime() {
    if [ "$ELAPSED_TIME" -lt "60" ]; then
        kdialog --icon=/usr/share/icons/hicolor/512x512/apps/ks-android-push-pull.png --title="Android File Manager" \
                       --passivepopup="[Finished]   $OPERATION ${i##*/}.   Elapsed Time: ${ELAPSED_TIME}s"
    elif [ "$ELAPSED_TIME" -gt "59" ] && [ "$ELAPSED_TIME" -lt "3600" ]; then
        ELAPSED_TIME=$(echo "$ELAPSED_TIME/60"|bc -l|sed 's/...................$//')
        kdialog --icon=/usr/share/icons/hicolor/512x512/apps/ks-android-push-pull.png --title="Android File Manager" \
                       --passivepopup="[Finished]   $OPERATION ${i##*/}.   Elapsed Time: ${ELAPSED_TIME}m"
    elif [ "$ELAPSED_TIME" -gt "3599" ]; then
        ELAPSED_TIME=$(echo "$ELAPSED_TIME/3600"|bc -l|sed 's/...................$//')
        kdialog --icon=/usr/share/icons/hicolor/512x512/apps/ks-android-push-pull.png --title="Android File Manager" \
                       --passivepopup="[Finished]   $OPERATION ${i##*/}.   Elapsed Time: ${ELAPSED_TIME}h"
    fi
}

##############################
############ Main ############
##############################

DIR=$1
cd "$DIR"

mv "$(dirname "$(dirname "$(dirname "$(dirname "$(dirname "$(dirname "$(dirname "$(dirname "$(dirname "$(pwd|grep " ")")")")")")")")")")" \
    "$(dirname "$(dirname "$(dirname "$(dirname "$(dirname "$(dirname "$(dirname "$(dirname "$(dirname "$(pwd|grep " ")")")")")")")")")"|sed\
    's/ /_/g')" 2> /dev/null
cd ./
mv "$(dirname "$(dirname "$(dirname "$(dirname "$(dirname "$(dirname "$(dirname "$(dirname "$(pwd|grep " ")")")")")")")")")" "$(dirname \
    "$(dirname "$(dirname "$(dirname "$(dirname "$(dirname "$(dirname "$(dirname "$(pwd|grep " ")")")")")")")")"|sed 's/ /_/g')" 2> /dev/null
cd ./
mv "$(dirname "$(dirname "$(dirname "$(dirname "$(dirname "$(dirname "$(dirname "$(pwd|grep " ")")")")")")")")" "$(dirname "$(dirname \
    "$(dirname "$(dirname "$(dirname "$(dirname "$(dirname "$(pwd|grep " ")")")")")")")"|sed 's/ /_/g')" 2> /dev/null
cd ./
mv "$(dirname "$(dirname "$(dirname "$(dirname "$(dirname "$(dirname "$(pwd|grep " ")")")")")")")" "$(dirname "$(dirname "$(dirname \
    "$(dirname "$(dirname "$(dirname "$(pwd|grep " ")")")")")")"|sed 's/ /_/g')" 2> /dev/null
cd ./
mv "$(dirname "$(dirname "$(dirname "$(dirname "$(dirname "$(pwd|grep " ")")")")")")" "$(dirname "$(dirname "$(dirname "$(dirname "$(dirname\
    "$(pwd|grep " ")")")")")"|sed 's/ /_/g')" 2> /dev/null
cd ./
mv "$(dirname "$(dirname "$(dirname "$(dirname "$(pwd|grep " ")")")")")" "$(dirname "$(dirname "$(dirname "$(dirname "$(pwd|grep " ")")")")"\
    |sed 's/ /_/g')" 2> /dev/null
cd ./
mv "$(dirname "$(dirname "$(dirname "$(pwd|grep " ")")")")" "$(dirname "$(dirname "$(dirname "$(pwd|grep " ")")")"|sed 's/ /_/g')" 2> /dev/null
cd ./
mv "$(dirname "$(dirname "$(pwd|grep " ")")")" "$(dirname "$(dirname "$(pwd|grep " ")")"|sed 's/ /_/g')" 2> /dev/null
cd ./
mv "$(dirname "$(pwd|grep " ")")" "$(dirname "$(pwd|grep " ")"|sed 's/ /_/g')" 2> /dev/null
cd ./
mv "$(pwd|grep " ")" "$(pwd|grep " "|sed 's/ /_/g')" 2> /dev/null
cd ./

for i in *; do
    mv "$i" "${i// /_}" 2> /dev/null
done

DIR="$(pwd)"

if [ "$DIR" == "/usr/share/applications" ]; then
    DIR="~/"
fi

PRIORITY="$(kdialog --geometry 100x150 --icon=/usr/share/icons/hicolor/512x512/apps/ks-android-push-pull.png --caption="Android File Manager" \
         --radiolist="Choose Scheduling Priority" Highest Highest off High High off Normal Normal on Low Low off Lowest Lowest off 2> /dev/null)"
if-cancel-exit

if [ "$PRIORITY" = "Highest" ]; then
    kdesu --noignorebutton -d -c "ionice -c 1 -n 0 -p $PID && chrt -op 0 $PID && renice -15 $PID" 2> /dev/null
elif [ "$PRIORITY" = "High" ]; then
    kdesu --noignorebutton -d -c "ionice -c 1 -n 0 -p $PID && chrt -op 0 $PID && renice -10 $PID" 2> /dev/null
elif [ "$PRIORITY" = "Normal" ]; then
    true
elif [ "$PRIORITY" = "Low" ]; then
    kdesu --noignorebutton -d -c "renice 10 $PID" 2> /dev/null
elif [ "$PRIORITY" = "Lowest" ]; then
    kdesu --noignorebutton -d -c "renice 15 $PID" 2> /dev/null
fi

OPERATION=$(kdialog --icon=/usr/share/icons/hicolor/512x512/apps/ks-android-push-pull.png --caption="Android File Manager" \
       --combobox="Select Operation" Push Pull --default Push 2> /dev/null)
if-cancel-exit

if [ "$OPERATION" = "Push" ]; then
	FILES=$(kdialog --icon=/usr/share/icons/hicolor/512x512/apps/ks-android-push-pull.png --title="Android File Manager" --caption="Select Files" --multiple --getopenfilename "$DIR" "*.*|*.*" 2> /dev/null)
	if-cancel-exit
	progressbar-start

    for i in $FILES; do
        COUNT=$((++COUNT))
        qdbusinsert-push
        BEGIN_TIME=$(date +%s)
        adb push $i /mnt/sdcard/
        check-device
        FINAL_TIME=$(date +%s)
        ELAPSED_TIME=$((FINAL_TIME-BEGIN_TIME))
        elapsedtime
    done
 elif [ "$OPERATION" = "Pull" ]; then
	adb shell ls /mnt/sdcard*/*.* > $FILES
	DESTINATION=$(kdialog --icon=/usr/share/icons/hicolor/512x512/apps/ks-android-push-pull.png --title="Android File Manager" --caption="Files Destination" --getexistingdirectory "$DIR" 2> /dev/null)
	if-cancel-exit
    kdialog --icon=/usr/share/icons/hicolor/512x512/apps/ks-android-push-pull.png --caption="Android File Manager - $(cat $FILES|wc -l)" --textbox=$FILES --geometry 300x200 2> /dev/null &
 	KdialogPID=$(ps aux|grep "afm.tmp"|grep -v grep|awk -F" " '{print $2}')
 	FILES=$(kdialog --icon=/usr/share/icons/hicolor/512x512/apps/ks-android-push-pull.png --caption="Android File Manager" --inputbox="Enter absolute path filenames from textbox separated by whitespace." 2> /dev/null)
 	if-cancel-exit
 	kill -9 $KdialogPID 2> /dev/null
     progressbar-start
     
     for i in $FILES; do
         COUNT=$((++COUNT))
         qdbusinsert-pull
         BEGIN_TIME=$(date +%s)
         adb pull $i $DESTINATION/
         check-device
         FINAL_TIME=$(date +%s)
         ELAPSED_TIME=$((FINAL_TIME-BEGIN_TIME))
         elapsedtime
     done
fi
progressbar-close
echo "Finish Android File Manager Operation" > /tmp/speak
text2wave -F 48000 -o /tmp/speak.wav /tmp/speak
play /tmp/speak.wav
rm -fr /tmp/speak* $FILES
exit 0
