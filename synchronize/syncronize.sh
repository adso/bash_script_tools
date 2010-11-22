#! /bin/bash
#######
#
#  host
#  client
# debo hacer un script que :
# encrypte partes sensibles
# eventualmente comprima
# sincronize en los servidores unicamente lo público y lo encriptado.
#
# -projects
#  -- nombre_priv      --> se empaqueta y se pasa de ~/myskel/compressed a ~/myskel/encrypted
#
# En mis hosts en github  (git ) google code 
# (subversion -- mediante importación de un repo git.)
#
# la forma elegida es agruparlo todo bajo un mismo directorio en $HOME/projects, añadiendole enlaces 
# simbólicos según vaya necesitando respaldar nuevos proyectos, y comprimiendo previamente directorios 
# en private para despues encriptarlos y enviarlos.
# ...........................................................................



check_requirements(){
echo -n "check_requirements.. " 
# checking required tools.. 
test -e $file_tools || \
    { echo "$0 ERROR $file_tools is not present " ; false ; }
f_tools_content=$(sed '{ /#.*/d ; } ' $file_tools || false ) 
while read -r tool_item ; do
    a_tool=( $tool_item )  # it is unquoted to avoid space trailing
    which $tool_item  &>/dev/null || \
        { echo "some of this $tool_item are not installed" ; false ; }
    tools+=" ${a_tool[0]} " 
done <<_EOF_
$f_tools_content
_EOF_
# checking required servers.. 
test -e $file_servers || \
    { echo "$0 ERROR $file_servers is not present " ; false ; }
f_servers_content=$(sed '{ /#.*/d ; } ' $file_servers  || false  )
while read -r server_item ; do 
    a_server=( $server_item )
    expr "$tools" : ".*${a_server[2]}" &>/dev/null  || \
        { echo "tool ${a_server[2]} not found. Syntax is ok ?  " ; false ; } 
    servers+=" ${a_server[0]} "
done <<_EOF_
$f_servers_content
_EOF_
# checking the projects..
test -e $file_projects || \
    { echo "$0 ERROR $file_projects is not present " ; false ; }
f_projects_content=$(sed '{ /#.*/d ; } ' $file_projects  || false  )
while read -r project_dir method ; do 
    expr "$tools" : ".*$method" &>/dev/null  || \
        { echo "tool $method is not available  " ; false ; } 
done <<_EOF_
$f_projects_content
_EOF_
# checking  gpg configuration
gpg --armor --export --out  $working_dir/key.pub  $USER_GPG
test -e $working_dir/key.pub || \
    { echo "ERROR key for $USER_GPG is not present " ; false ; }
# checking ssh configuration.. github needs this
test -e $HOME/.ssh/id_rsa       ||  { echo "WARNING no id_rsa " ; true ; }
test -e $HOME/.ssh/id_rsa.pub   ||  { echo "WARNING  no id_rsa.pub " ; true ; }
# installing the crontab
crontab $file_crontab
# installing the symlink for the cron
test -h $prefix/scripts/syncro.sh || \
    ln -s $script_dir/$script_name  $prefix/scripts/syncro.sh
# show results
echo "  $script_name : checks ....... "
echo "  tools :   $tools "
echo "  servers : $servers "
echo "  script dir location : $script_dir "
echo "  working directory   : $working_dir "
echo " .............................end"
return 0
}


check_projects_bkp_methods(){
echo " listing projects.. "
internet=${internet:-"off"}
local f_projects_content project_dir method exists=0
f_projects_content=$(sed '{ /#.*/d ; } ' $file_projects )
while read -r project_dir method
do
    test -d $project_dir || \
        { echo basename $0 " WARNING this project doesn't exist " ; true ;}
    echo "  check_project_status : $project_dir with method $method" 
    exists=$(expr "$tools" : ".*"$method || true )
    if [[ $exists -gt 0 ]]; then
     function_name="do_$method $project_dir"
     eval $function_name || \
	        { echo "method not found " ; continue ; }
	 else
	    echo "method $method not found .."
	 fi
done <<_EOF_
$f_projects_content
_EOF_
echo " end projects "
return 0
}



do_tar(){
echo -n "doing tar "
local project_path=$1 
test -d $project_path/..
token_date=$(date +%Y%m%d%H%M)
dir_name=$(basename $project_path)
file_name="${dir_name}.tar"
echo -n " of $project_path as $compressed_dir/$file_name "
#  follow symlinks ?
# -u can not update compressed archives 
tar --exclude-from=$file_excludes -C $project_path/.. \
     -uvf ${compressed_dir}/${file_name} ${dir_name}/
# lets encrypt it ?
private=$(ls ${compressed_dir}/${file_name} | sed "s,${PRIV_TOKEN},true,1" )
    if [[ x"$private" = x"true" ]]; then
        do_encrypt_tars $file_name
    fi
gzip -f ${compressed_dir}/${file_name} 
echo " end tars "
return 0
}


do_rsync(){
# while rsync ssh password will be prompted or we would need to set authorized_keys
# with rsync daemon we could use  --password-file  
# your web proxy’s configuration must support proxy connections to port 873.
echo -n "doing rsyncs "
local projects_dir=$1
local f_server_contents
    if [[ x"$internet" = x"on" ]]  ; then
        echo  " we are online "
        f_server_contents=$(sed -n '{ /#.*/ d ; /rsync/ { p ; }} ' $file_servers )
    else 
       echo " we are OFFline "
        f_server_contents=$(sed -n '{ /#.*/ d ; /rsync/ { } ; /local/{ p ; } } ' $file_servers ) 
    fi
    while read -r h_ip h_name h_method h_home h_user h_pass h_encr ; do
      if  [[ -z $h_ip ]] ; then 
         echo " no records "
      elif [[ $direction = "host" ]];then  
        echo " sending $project_dir to $h_name "
         # create the remote dir if doesn't exist
         #sshcmd="ssh $h_user@h_ip "test -d $h_home || mkdir -p $h_home "
         #$sshcmd
         rsync -avz --exclude-from=$file_excludes $projects_dir $h_user@$h_ip:$h_home
      elif [[ $direction = "client" ]];then
         echo " getting  $project_dir to this client  "
         #rsync -avz --exclude-from=$file_excludes $user_host@$host_ip:$projects_dir/ $projects_dir/
       else
         echo "ERROR var direction 'host' or 'client' must be defined "
         false
      fi
    done <<_EOF_ 
$f_server_contents 
_EOF_
echo "end rsyncs"
return 0
}

 
do_git(){
# the git working-dir must be already configured
# remote is called "origin" when cloned
# master
echo "doing git "
local project_dir=$1
local f_server_contents
    if [[ x"$internet" = x"on" ]]  ; then
        test -e $HOME/.ssh/id_rsa       ||  { echo "no id_rsa" ; false ; }
        test -e $HOME/.ssh/id_rsa.pub   ||  { echo "no id_rsa" ; false ; }
        test -d $project_dir/.git       ||  { echo "no git directory" ; false ; }
        f_server_contents=$(sed -n '{ /#.*/ d ; /git/ { p ; } } ' $file_servers )
    else
        f_server_contents=$(sed -n '{ /#.*/ d ; /rsync/ { } ; /local/{ p ; } } ' $file_servers ) 
    fi
    while read -r h_ip h_name h_method h_home h_user h_pass h_encr ; do
        if  [[ -z $h_ip ]] ; then 
             echo " no records "
        elif  [[ $direction = "host" ]];then  
            git add $project_dir
            git commit --no-verify -m "sincroniza.sh automatic backup " 
            git push $h_name master
        elif [[ $direction = "client" ]];then
            echo "fetching..." 
            git pull remote
        else
            echo "ERROR var direction 'host' or 'client' must be defined "
             false
        fi
    done <<_EOF_
$f_servers_contents
_EOF_
echo "end git"
return 0
}


do_svn(){
echo "no svn method rightnow "
local project_dir=$1

return 0
}


do_google(){
echo "doing google "
# se supone que acabamos de comprimirlo
local PYTHON=$(which python2.7)
local GOOGLE=$(which google)
local project_path=$1 transform="" date_string="" dir_output=""
    if [[ x"$internet" = x"on" ]]  ; then
        echo ""
    elif [[ x"$internet" = x"off" ]]  ; then
        echo "offline giving up "
        return 0
    fi
#weird things ,necessary to scape \. in the first but not in the second term
transforms=" --transform=s,\.sh,.sh.txt,g" 
date_string=$(date +%Y%m%d%H%M)
dir_name=$(basename $project_path)
dir_output=${dir_name}${date_string}
dir_google_new="${dir_name}_new"
dir_google_old="${dir_name}_old"
file_name="${dir_name}.tar"
test -e $compressed_dir/${file_name}.gz || \
    { echo "file $compressed_dir/$file_name not found " ; false ; }
gzip -d $compressed_dir/$file_name
mkdir -p $working_dir/$dir_output/$dir_google_new
tar -C $working_dir/$dir_output/$dir_google_new $transforms -xvf $compressed_dir/$file_name
cd $working_dir/$dir_output
$PYTHON $GOOGLE docs upload $dir_google_new/* > $control_dir/list_docs_at_.txt || true
$PYTHON $GOOGLE docs delete $dir_google_old >>  $control_dir/list_docs_at_.txt || true
cd $working_dir
gzip -f ${compressed_dir}/${file_name} 
return 0
echo "doing google "
}


do_dropio(){
echo "no dropio method rightnow "
local project_dir=$1

return 0
}




do_encrypt_tars()
{
file_name=$1       
fileenc=${file_name//$PRIV_TOKEN/$ENC_TOKEN}
gpg --batch --yes --trust-model always \
    --recipient $USER_GPG --armor  \
    --out ${encrypted_dir}/$fileenc \
    --encrypt ${compressed_dir}/$file_name
rm ${compressed_dir}/$file_name
file_name=$fileenc
return 0
}





 
die()
{
echo "cleanning"
rm -rf $working_dir
}


function usage()
{
 echo "$0 host / client "
 exit 0;
}

function setErrOptions()
{
	echo "$0 : setting error options"
	set -o errexit
	set -o nounset
	set -o errtrace
	set -o posix
	#set -o pipefail
	shopt -s failglob
	trap onexit hup int term ERR 
    trap onbreak HUP INT TERM ERR  # la segunda machaca la primera. 

}

function clearErrOptions()
{
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
	echo "$0 : $ERROR onexit exiting with estatus: $exit_status" && die
	clearErrOptions
	exit $exit_status
}

function onbreak(){
	local exit_status=${1:-$?}
	local ERROR=""
	if [[ $exit_status -gt 0 ]]; then
        ERROR="ERROR"
	fi
	echo "$0 : $ERROR onBreak exiting with estatus: $exit_status" && die
 break;
 	clearErrOptions 
}



USER_GPG="william"   
PRIV_TOKEN="_priv"
PUB_TOKEN="_pub"
ENC_TOKEN="_enc"

# llamada al script ..........................................
ERROR_LOG=/dev/null 
setErrOptions
while true
do
    direction="host"
    internet="off"
    connect="off"
    script_link=$0
    script_name=$(basename $0)
    script_path=$(readlink -f $script_link)
    cd ${script_path%/*} &>/dev/null || true
    script_dir=$PWD
    common_package="../pkg_template"
    source $script_dir/config/vars
    source $common_package/build-aux/common_vars.sh      
    source $common_package/build-aux/common_functions.sh
    source $common_package/build-aux/common_functions_net.sh
    check_distro
    check_dirtree $myskeldir
    mkdir $working_dir  || true
    cd $working_dir
    check_requirements
    if ! check_connection ; then
        echo "no connection "
        internet="off"
        #sudo ./wifi.sh $file_connections
    else
        echo "connection ok "
        internet="on"
    fi
     check_projects_bkp_methods
     clearErrOptions && die
 break
done 
echo "$0 : end"





