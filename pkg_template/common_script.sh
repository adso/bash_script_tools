#! /bin/bash
################################################################################
# Name
# Usage
#
#
# Description :
#
#
#
# Author: 
# Date:
# License: GPL
#
################################################################################### 

check_requeriments(){
#if [[ $EUID -gt 0 ]];then
#    echo "$0: check_requeriments: you need to be root "
#    exit
#fi
#which $command || \
#    { echo "$0 ERROR $command not found in path" ; false ; } 
##... 
return 0
}

die(){
echo ""
# delete temporal files , etc. 
return 0
}
# ..script..........................................................................................





# ............................................................................................
ERROR_LOG=/dev/null
function setErrOptions(){
	echo "$0 : setting error options"
	set -o errexit
	set -o nounset
	set -o errtrace
	set -o posix
	set -o pipefail
	shopt -s failglob
	trap onexit hup int term ERR 
    trap onbreak HUP INT TERM ERR  # la segunda machaca la primera. 

}

function clearErrOptions(){
# This function reset all the error handling options to do not affect the system environment after this script execution
# IMPORTANT : set -o errtrace must be enable or we won't be able to deactivate traps inside a function.
	echo "$0 : cleaning error options"
	trap - ERR   
	set +o errexit
	set +o nounset
	set +o errtrace
	set +o posix
	set +o pipefail
	shopt -u failglob
}


function onexit(){
	local exit_status=${1:-$?}
	local ERROR=""
	if [[ $exit_status -gt 0 ]]; then
        ERROR="ERROR"
	fi
	echo "$0 : $ERROR onexit exiting with estatus: $exit_status"  && die
	clearErrOptions
	exit $exit_status
}

function onbreak(){
	local exit_status=${1:-$?}
	local ERROR=""
	if [[ $exit_status -gt 0 ]]; then
        ERROR="ERROR"
	fi
	echo "$0 : $ERROR onexit exiting with estatus: $exit_status"  && die
	clearErrOptions
 break;
}


# llamada al script ..........................................
setErrOptions
while true;
do 
    echo "$0 : main loop "
    false
    #if # no sale inediatamente si se encuentra dentro de un bucle.
    echo "Hola Mundo sin errores "
    #my command
    break
done 
clearErrOptions 
echo "$0 : end"



