#! /bin/bash


function check_distro() {
echo -n "check_distro: begin... "
LOWER='abcdefghijklmnopqrstuvwxyz'
UPPER='ABCDEFGHIJKLMNOPQRSTUVWXYZ'
distros="ubuntu vector slackware debian redhat arch suse gentoo conectiva mandriva mandrake pardus kanotix generic-undetected"
shopt -u failglob
distro_file=$(ls /etc/*release 2>/dev/null || true ) 
distro_file+=$(ls /etc/*_version 2>/dev/null || true ) 
shopt -s failglob
if [[ -z $distro_file ]];then
	echo "get_distro: /proc/version approach"
	distro_file=$(cat /proc/version )
elif [[ -z $distro_file ]];then
	echo "get_distro: binary lbs_release approach"
	distro_file=""
elif [[ -z $distro_file ]];then
	echo "get_distro: binary gcc --version approach"
	distro_file=""
else
    foo=""
fi
distro_file=$(echo $distro_file | sed "{ y/$UPPER/$LOWER/ ; s/[ 	$)#(,.:]*//g ; }" )
distribution="generic-undetected"
for distro in $distros ;do
    # with error handling expr raising a 0 means break
    # consider using the \( \) alternative
	i=$(expr "$distro_file" : ".*$distro" || true ) 
	if [[ $i -gt 0 ]];then
		distribution=$distro	
	fi
done
echo " found : $distribution ! "
return 0
}


function distro_tunning()
{
echo "distro_tunning: begin.. "
if [[ -n $distro_type ]];then
	echo "distro_tunning: already set $distro_type "
	#return 0;
fi

case $distribution in
redhat|mandriva)
	sed_opts=""
	find_opts=""
	awk_opts=""
	distro_type="rpm"
;;
debian)
	sed_opts=" --posix "
	find_opts=""
	awk_opts=""
	distro_type="debian"
;;
*)
	sed_opts=""
	find_opts=""
	awk_opts=""
    distro_type=""
;;
esac
echo "distro_tunning: for $distro_type "
echo "sed options: " $sed_opts
echo "find options:" $find_opts
echo "awk options: " $awk_opts
echo "distro_tunning: end.. "
}



check_dirtree()
{
local tree_dir=$1 create=${2:-0}
e=$(ls $tree_dir &> /dev/null ||  echo "0" )  
if [[ $e -eq 0 && $create -gt 0 ]]; then
    echo " fixing tree_dir .."
    eval mkdir -p $tree_dir
fi
return 0
}




check_downloads(){
echo "check_downloads begin"
url_list="$1"
dir_base="${2:-$PWD}"
if [[ -z "$url_list" ]]; then
    echo "$0 check_downloads needs an argument (file_path or var_url_list)"
elif [[ -f "$url_list" ]];then
    cat $url_list | while read url_item ; do
        file_name="$dir_base/"$(basename $url_item)
        test -e "$file_name" || \
            download_files "$url_item" "$dir_base" || \
            { echo "$0 check_downloads : ERROR i can not find $file_name " ; false ; } 
        echo "$file_name found "
    done 
else
    url_list+=" $"
    echo $url_list | while read -d " " url_item ; do
        file_name="$dir_base/"$(basename $url_item)
        test -e "$file_name" || \
            download_files "$url_item"  "$dir_base" || \
                { echo "$0 check_downloads : ERROR i can not find $file_name " ; false ; } 
        echo "$file_name found "
    done 
fi
return 0
}



download_files() {
echo "download_files begin"
local url_path dir_path
url_path=$1
dir_path=${2:-$PWD}
## be polite -w 3 --limit-rate=50K
wget -w 3 --limit-rate=50K  --progress=bar -P $dir_path -- $url_path
##wget --spider -i $links
return 0
}

uncompress_archive(){
local file_path=$1 
local workdir=$2
local file_log=/dev/null
echo $file_path $workdir $file_log | 
    awk '$1 ~ /.bz2$/ {system("tar -xjvkf " $1 " -C " $2 " 2>"$3 )}; 
		 $1 ~ /.tar.gz$|.tgz$/ 	{system("tar -xzvkf " $1 " -C " $2 " 2>"$3 )};
         $1 ~ /.zip$/ {system("zip " $1 " -d " $2 " 2>"$3 )}; '

return 0
}


function load_and_expand()
{
# @params  input_file output_file [vars_file]
# In the input file , variables we want to expand must be in the form @VAR@  
# to difference them from the others $VAR we want to let them be
# It' s not a good idea to use ASCII codes because this codes 
# can change depending the encoding, page code or language
# Some sed versions can not put a \n in the replacement so this function would fail
# Sed raise an error if not match ocurred, this can abort the script 
# depending on bash err  options
shopt -u failglob
Q="'"		 #  token="\"   ( ASCII code \x27 )
D="\$"	     #  token="$"   ( ASCII code \x24 )
TI="@"		 #  token="@"   ( ASCII code \x40 )
TF="@"		 #  token="@"   ( ASCII code \x40 )
CI="{"		 #  curly="{"   ( ASCII code \x7B )
CF="}"       #  curly="}"   ( ASCII code \x7D )
#TOKEN="#{"  #  token="#{"  ( ASCII code \x23\x7B )  his will substitute variables of the form #{VAR} to ${VAR}
if [[ -n $1 && -n $2 ]]; then
	if [[ -e $3 ]]; then
	 . $3  # dot "." means same than "source"
	fi
eval echo -ne $(cat -E $1 | sed $sed_opts ' {  s/^/'$Q'/g ;  s/$/'$Q'/g  ; s/'$TI'\([a-zA-Z0-9_]\+\)'$TF'/'$Q$D$CI'\1'$CF$Q'/g ; } ' ) | \
sed $sed_opts "s,\(\$ \|\$$\),\n,g" >$2 
else 
	echo -e "Usage $0 : INPUT_FILE OUPUT_FILE  [VAR_FILES ] 
			 (vars must be in the form \${VAR})"
fi
}

#function get_missing()
#{
## Consider use custom configurations for apt or urpmi to download the pkgs.
#echo "get_missing: begin... $missing_libs"
#if [[ -z $missing_libs ]] ; then 
#	echo "get_missing: no missing libraries " 
#	return 0
#elif [[ -z $distribution ]] ; then 
#	echo "get_missing: no distribution detected " 
#	return 1
#fi
#pkg="@----------@"
#tmpdir=${abs_top_srcdir}/src/tmp
#if [[ -d $tmpdir ]];then
#	cd $tmpdir
#	case $distribution in
#	ubuntu|debian)
#		URL_PKG=""
#		sys_pkgs="gcc gcc-c++ build-essential automake nonexistent"
#		lib_pkgs="zlib libjpeg libfreetype libreadline libtool zlib1g-dev libjpeg62-dev libfreetype6-dev libreadline5-dev"
#		dev_pkgs="libldap2-dev libssl-dev libsasl2-dev python-ldap python-libxml2 python-libxslt1 python-mysqldb libmysql++-dev python-beautifulsoup"
#		spec_pkgs=""
#		pkgs="$sys_pkgs $lib_pkgs $dev_pkgs $spec_pkgs"
#		comm_get_pkg="apt-get install -d -o=Dir::Cache::archives=$tmpdir $pkg"
#		comm_ext_pkg="ar -m $pkg data.tar.gz | tar -xzvf -C $tmpdir"
#	;;
#	redhat)
#		URL_PKG=""
#		sys_pkgs="gcc gcc-c++ build-essential automake"
#		lib_pkgs="libtool zlib1g-dev libjpeg62-dev libfreetype6-dev libreadline5-dev"
#		dev_pkgs="libldap2-dev libssl-dev libsasl2-dev python-ldap python-libxml2 python-libxslt1 python-mysqldb libmysql++-dev python-beautifulsoup"
#		spec_pkgs=""
#		pkgs="$sys_pkgs $lib_pkgs $dev_pkgs $spec_pkgs"
#		comm_get_pkg="up2date"
#		comm_ext_pkg="$RPM2CPIO $pkg | $CPIO -i --make-directories --no-absolute-filenames --preserve-modification-time -v "

#	;;
#	*)
#		URL_PKG=""
#		sys_pkgs="gcc gcc-c++ build-essential automake"
#		lib_pkgs="zlib libjpeg libfreetype libreadline libtool zlib1g-dev libjpeg62-dev libfreetype6-dev libreadline5-dev"
#		dev_pkgs="libldap2-dev libssl-dev libsasl2-dev python-ldap python-libxml2 python-libxslt1 python-mysqldb libmysql++-dev python-beautifulsoup"
#		spec_pkgs=""
#		pkgs="$sys_pkgs $lib_pkgs $dev_pkgs $spec_pkgs"
#		comm_get_pkg="yum "
#		comm_ext_pkg="$RPM2CPIO $pkg | $CPIO -i --make-directories --no-absolute-filenames --preserve-modification-time -v "
#	;;
#	esac

#	for lib in $missing_libs; do
#	 	for pkg in $pkgs; do
#			echo "get_missing : trying to get $lib from $pkg "
#			j=$(expr match $pkg ".*$lib")
#			if [[ $j -gt 0 ]];then	
#				comm_get=$(echo $comm_get_pkg | sed $sed_opts 's/@[-]\{10,10\}@/'$pkg'/g')
#				comm_ext=$(echo $comm_ext_pkg | sed $sed_opts 's/@[-]\{10,10\}@/'$pkg'/g')
#				echo "get_missing : trying to get $lib for $distribution .. with $comm_get"
#				#$comm_get_pkg
#				#$comm_ext_pkg
#				#rm ${tmpdir}/$pkg && mv ${tmpdir}/* ${prefix}
#			fi
#		done
#	done
#fi
#echo "get_missing: end "
#}




