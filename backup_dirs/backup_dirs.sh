#!/bin/sh
####################################################################################################################
# backupDir.sh:   
# Author:jc hurtado   
# Date : 10-11-2005 
# Description : 
# This scripts create incremental backups 
# ( montly - weekly -daily -from differents branches of directories
# and erase daily files to save space.......................................................................
#
# License : GPL V.2
#    
####################################################################################################################

dow=$(date +%w);
# We detect the day of the week ( dow ) and we use it for copy one part or branche each day
# also we label every mo-disk depending on day of week - TODO same could be possible for tape volumes - 

VOL_NAME[0]="NODEF"      # this day we don't copy anything
VOL_NAME[1]="DEVEL"      # this day we will try to dump developemt branche directory
VOL_NAME[2]="INSTALL"    # this day we will try to dump ready-to-try code directory
VOL_NAME[3]="TESTING"    # this day we will try to dump testing code directory
VOL_NAME[4]="PRODUCT"    # this day we will try to dump production code directory
VOL_NAME[5]="NODEF"      # this day we don't copy anything
VOL_NAME[6]="NODEF"      # this day we don't copy anything


let ANTIGUITY=10	# max days ago to try to keep files if free space needed

LABEL0="LOCAL_MACHINE"	#
DRIVER0=/mnt/backups    # don't put / at the end 
OPTIONS0=""		# 
SIZE_LIMIT0=-1          # ( in Kb ) 
DIR0=$DRIVER0
DIR_BACKUPS=$DIR0	# WE WILL TRY TO SAVE BACKUPS HERE

LABEL1="REMOTE_MACHINE"		#
DRIVER1=/mnt/remotematchine  	# we will try to save backups here ( this should be in fstab ) 
OPTIONS1="username=xxxxxxxx\\naughty,password=xxxxxxx"
DIR1=$DRIVER1/backups
SIZE_LIMIT1=-1  		# (in Kb ) trying to not flood remote machine' free space


LABEL2="MO_DRIVE"		#
DRIVER2=/mnt/mo_drive		#
OPTIONS2=""			#
DIR2=$DRIVER 
SIZE_LIMIT2=-1 		# (in Kb ) don't need to limit it. The script try to detect mo disk usage
FAT_VOL_LABEL="r:"   
# this is required because users want to unzip mo-disks in window$ enviroment: fucking users
# I installed mtools and edited /etc/mtools.conf adding    drive r: file="/dev/sda1" ........   
# ( i mount mo-dynamo fujitsu drive in this path  as i specify in  /etc/fstab ) .............
# then i mounted drive and used mlabel r:"ENCURSO"  for the disk number 1 and so on..........
          																		

# write a list - space between elements - with all dirs you want to backup 
DIRS_TO_DUMP="/home/code_factory/" #   \
#	/home/code_factory/install  \
#	/home/code_factory/devel  \
#	/home/code_factory/testing  \
#	/home/code_factory/olds"


# Set a id for each file where each above dir should be dump
# ( Don't put full names they will be built inside backupDir function )
# ( Don't leave any space in left of first word )
TARFILEID=(devel )#  install testing olds) 

FILE_HIS="historialBackup.txt"
FILE_ERR="errBackup.txt"
FILE_CONT="contentsBackup.txt"

#.........................................  You should not need to touch ...............................................  
# ----------------------------------------------------------------------------------------------------------------------- 
# ----------------------------------------------------------------------------------------------------------------------- 

function mountDriver()
{
# Parameters : $1 path of dir included in /etc/fstab
#              $2 options  
  
   if  [ ! -z $2 ]; then
		OPTIONS=" -o $2" 
	 else
	  unset OPTIONS
	 fi
	
	 let MOUNT_DRIVER=-1
	 CHECK_DRIVE=""
	 CHECK_DRIVE=$(mount | grep $1 ) 
	 if  [[ -z $CHECK_DRIVE ]]  ; then
	  mount $OPTIONS $1
	let MOUNT_DRIVER=$?  
	else
	  let  MOUNT_DRIVER=0
	fi
    echo "Mounting $1 with $2 errors $MOUNT_DRIVER "
	return $MOUNT_DRIVER ;
} 




function removeBeforeAdd()
{
# $1 the file OR expression of files to copy in.
# $2 the place where we need to copy the file
# $3 the limit of usage 

FILE=$1
DRIVE=$2
let SIZE_LIMIT=$3
OLDERTHAN=+$ANTIGUITY
PATTERN="*${TARFILEID[$COUNTER]}*" 

	if [ -d $DRIVE -a -f $FILE -a $# -eq 3 ] ; then   
	 # - checking if they give us a right path dir and path file to copy from ---- 
				if [ $SIZE_LIMIT -lt 1 ]; then SIZE_LIMIT=-1 ; USED_BKP_SIZE=-2 ; fi
		 
		 NUM_ARCH=$(ls --sort=time -1 $DRIVE | wc -l)
		 FILE_BKP_SIZE=$(du --si -k $FILE  | tail -n 1 | cut -s -f 1 )  
     		 FREE_BKP_SIZE=$(df -h  -k  $DRIVE | tail -n 1 | cut -b 42-51 )
		 		
				if [ $SIZE_LIMIT -gt 0 ]; then 	USED_BKP_SIZE=$(du --si -s -k $DRIVE | tail -n 1 | cut -s -f 1 ) ;fi		
		 
				while  [ $ANTIGUITY -ge -1  -a  $FREE_BKP_SIZE -lt $FILE_BKP_SIZE  -o  $USED_BKP_SIZE -ge $SIZE_LIMIT ] #size limit too 
				do
				  echo "Deleting old files anti: $ANTIGUITY "
					echo "  We need $FILE_BKP_SIZE and we have $FREE_BKP_SIZE - Disk usage is $USED_BKP_SIZE and limit is $SIZE_LIMIT "	
					find $2 -type f -mtime $OLDERTHAN -name "$PATTERN"  -exec rm -f {} \;
     					FREE_BKP_SIZE=$(df -h  -k  $DRIVE | tail -n 1 | cut -b 42-51 )
					NUM_ARCH=$(ls --sort=time -1 $DRIVE | wc -l)
					let ANTIGUITY-=1
		 		  	if [ $SIZE_LIMIT -gt 0 ]; then 
							USED_BKP_SIZE=$(du --si -s -k $DRIVE | tail -n 1 | cut -s -f 1 ) 
						fi		
          					if [ $ANTIGUITY -ge 0 ] ; then
							OLDERTHAN="+$ANTIGUITY"
						else
							OLDERTHAN=0
						fi
	   			done	
				
				if  [ $FREE_BKP_SIZE -gt $FILE_BKP_SIZE ] ; then
					echo " function removeBeforeAdd : Copying $FILE to $DRIVE "
					cp $FILE $DRIVE
					return 0
				else
	  			echo " Device $1 with $FREE_BKP_SIZE Kb has not enought space for file $2 with $FILE_BKP_SIZE please change media data "
				 return 1
				fi	
  
	else
 			echo "function removeBeforeAdd : Not valid $2 path dir or $1 path file or missing parameters (size limit ) "
      return 1
	fi
}



function syncDriver ()
{
 #si el parámetro $1 es la etiqueda de las opciones de copia ( "LOCAL_MACHINE" "REMOTE_MACHINE" , o "TAPE" )
 #el parámetro $2 es la ruta de los ficheros a copiar........................................................
 #el parámetro $3 es la ruta del dispositivo.................................................................

LABEL=$1
FILE=$2
DRIVE=$3
let SIZE_LIMIT=$4  # in Kb
FILESPATTERN="*$(basename $TARFILE)*"
	
	case $FREQUENCY in
		$MONTLY_ID)
			OLDFILESPATTERN="*$(basename $TARFILE)$WEEKLY_ID*"
		;;
		$WEEKLY_ID) 
			OLDFILESPATTERN="*$(basename $TARFILE)$DAILY_ID*"
		;;
		*)
			OLDFILESPATTERN=""
	 ;;
	 esac

echo "|||||----> function syncDriver:  what is $TARFILE ... $FREQUENCY ... $MONTLY_ID , $WEEKLY_ID or $DAILY_ID ."
		
		if [ -e $FILE -a -d $DRIVE -a  $# -eq 4 ] ; then 		
  		case $LABEL in
 		 		"$LABEL0")
					echo " ......syncDriver Local for $LABEL file $FILE in $DRIVE  "
						if [ ! -z $OLDFILESPATTERN ]; then 	# zero lenght means daily backup
						 echo "............ Cleaning $LABEL with pattern $OLDFILESPATTERN "
						 find $DRIVE -mtime +0 -name "$OLDFILESPATTERN" -exec rm -f {} \;  
						fi
						
				;;
   			"$LABEL1")
					echo "..... syncDriver Remote for $LABEL file $FILE in $DRIVE "
						if [ ! -z $OLDFILESPATTERN ];  then 
						  echo "............ Cleaning $LABEL with pattern $OLDFILESPATTERN "
						  find $DRIVE -mtime +0 -name "$OLDFILESPATTERN" -exec rm -f {} \;  
						fi
			     removeBeforeAdd  $FILE $DRIVE $SIZE_LIMIT	
		
				;;
    			"$LABEL2") 
					echo "...... syncDriver MO  for $LABEL file $FILE in $DRIVE  "
			 	  VOL_NAME_SET=`mlabel -s $FAT_VOL_LABEL`
			 	 		if [[ "$VOL_NAME_SET"="*${VOL_NAME[$i]}*" ]] ; then
								if [ ! -z $OLDFILESPATTERN ]; then  # zero lenght means daily backup  
						  		echo "............ Cleaning $LABEL with pattern $OLDFILESPATTERN "
						  		find $DRIVE -mtime +0 -name "$OLDFILESPATTERN" -exec rm -f {} \;  
								fi
			     					removeBeforeAdd  $FILE $DRIVE $SIZE_LIMIT 
							# add last week of backups , tape is used just once a week and it should be update with last days' files
				 			VOL_NAME[$i]=$(echo ${VOL_NAME[$i]} | tr '[:upper:]' '[:lower:]')
				 			SIZE=$(expr "0 + "  $(find $PATH_BKP -mmin 0 -mtime -7 -name "*${VOL_NAME[$i]}*" -printf " + "%k) )
				 			LIST_FILES=$(find $DIR_BACKUPS -mmin +0 -mtime -7 -name "$FILESPATTERN" )
				 				for FILE in $LIST_FILES
								do
						  			removeBeforeAdd $FILE $DRIVE $SIZE_LIMIT
				    				done
		     	 else
	   	    		echo  " MO disk labeled: $VOL_NAME_SET is not in its right sequence. Should be ${VOL_NAME[$i]} " 
		    	fi
     	;;
     	*) 
		    echo " $LABEL is not a valid label " 
     	;;
   	esac

	else
		echo "function syncDriver for label $LABEL : missing or wrong arguments "
	fi

}



function backupDir()
{
# Arguments of the function 
# $1 Directory  to backup
# $2 Identification of the backup file ( full name will be built inside this function ) 

# Here we decided about the backup frecuency. 
# In this system ( using --listed-incremental option ) if  tar don't find their list of reference ( called $FILE_BKP_REF in 
# this case ) it is created by itself, so if we relation the name of this list with date when change date a new full backup
# will start.

# At the beginning of the month we create two list of reference ( snapshots ) one for the week and one for the month, 
# every week we will use just one time the montly list of reference to achive the changes of the week. So we could delete
# de daily incremental files of past week. 

DIR_TO_BKP=$1
FILE_ID=$2
FILE_BKP_MONTLY_REF=$FILE_ID"_refm"$(date +%m%Y).tsnp
FILE_BKP_WEEKLY_REF=$FILE_ID"_refw"$(date +%W_%m%Y).tsnp

echo "|||||----> function backupDir: Initializing backup "

if [ -d $DIR_TO_BKP -a  $# -eq 2  ]; then
  	if [ ! -e $FILE_BKP_MONTLY_REF ] ; then 
			FREC_ID=$MONTLY_ID
			FILE_BKP=$FILE_ID$FREC_ID$(date +%m%Y).tar.bz2
			echo " ....  Creating montly backup "
 	  		tar --create   --bzip2  --same-permissions --file=$FILE_BKP --listed-incremental=$FILE_BKP_MONTLY_REF $DIR_TO_BKP 2>&1 >/dev/null
			tar --create  --bzip2 --same-permissions  --listed-incremental=$FILE_BKP_WEEKLY_REF  $DIR_TO_BKP 2>&1 >/dev/null
			# file is not specified in order to don't waste resources overwriting the file created in line above. it will have same content. 

		elif [ ! -e $FILE_BKP_WEEKLY_REF ] ; then 
			FREC_ID=$WEEKLY_ID
			FILE_BKP=$FILE_ID$FREC_ID$(date +%W_%m%Y).tar.bz2
			echo "  ....Creating weekly backup "
	  		tar  --create   --bzip2  --same-permissions --file=$FILE_BKP --listed-incremental=$FILE_BKP_MONTLY_REF $DIR_TO_BKP 2>&1 >/dev/null
			tar  --create   --bzip2  --same-permissions   --listed-incremental=$FILE_BKP_WEEKLY_REF  $DIR_TO_BKP 2>&1 >/dev/null
			# Here, if $FILE_BKP  would created we'll loose  data 
			# Timestamp jumps forward one week in file $FILE_BKP_MONTLY_REF
  			
		else
			FREC_ID=$DAILY_ID
			FILE_BKP=$FILE_ID$FREC_ID$(date +%d%m%Y).tar.bz2
			echo "  .... Creating daily backup "
			tar  --create  --verbose  --bzip2 --same-permissions --file=$FILE_BKP --listed-incremental=$FILE_BKP_WEEKLY_REF  $DIR_TO_BKP
  	fi 
	FREQUENCY=$FREC_ID
	FILE_CREATED=$FILE_BKP
  return 0
else
  echo "function backupDir: Wrong path to dir or missing arguments"
	exit 1
fi

}


	if [ -d $DIR_BACKUPS ] ; then
		echo "Inicio date $(date )" >> $DIR_BACKUPS/$FILE_HIS
		echo "Uncomment to mount ........."
		#DRIVER1_OK= mountDriver $DRIVER1 $OPTIONS1 
		#DRIVER2_OK= mountDriver $DRIVER2 $OPTIONS2 
		FILE_CREATED="dummy"
		FREQUENCY="dummy"
		MONTLY_ID="mon"
		WEEKLY_ID="wee"
		DAILY_ID="day"
		let COUNTER=0
  		 for DIR_TO_DUMP in $DIRS_TO_DUMP 
	 		 do
	  		TARFILE=$DIR_BACKUPS/${TARFILEID[$COUNTER]}	
		 		echo "branche id: $COUNTER ... Dumping $DIR_TO_DUMP in ${TARFILEID[$COUNTER]}  "
		 		ls -lR $DIR_TO_DUMP > $DIR_TO_DUMP/$FILE_CONT
		 		backupDir $DIR_TO_DUMP $TARFILE 
			 echo "  $FREQUENCY "
			  syncDriver $LABEL0 $FILE_CREATED $DIR0 $SIZE_LIMIT0
			  syncDriver $LABEL1 $FILE_CREATED $DIR1 $SIZE_LIMIT1
		 	  echo " ---- -- MTOOLS needed. You need to specify mlabel r:XXXXXX for mo drive "  
			 # syncDriver $LABEL2 $FILE_CREATED $DIR2 $SIZE_LIMIT2
			   let COUNTER++
			done
		#umount $DRIVER1
		#umount $DRIVER2
		echo "Uncomment to UNmount ........."
		echo "Fin date $(date )" >>$DIR_BACKUPS/$FILE_HIS
	else
		echo " Main loop : sure DIR_BACKUPS point to a valid directory ? "
	fi

exit 0
# ----------------------------------------------------------------------------------------------------------
