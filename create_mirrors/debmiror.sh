#! /bin/bash

# if the repository doesn't exist ask if you should create it
# if the repository exists update index files

suites="{stable,testing,unstable}"
branches="{main,contrib,non-free}"
archs="{alfa,i386}"
files="{Release,Packages,Package.gz,Sources.gz}"
remote_mirror="none"
# --------------

check_requeriments()
{
echo "$0 check_requiremnts ... "
test -d -w $localdir || \
     { echo "$0 ERROR i can not write in $localdir" ; false ; } 
which dpkg-scanpackages || \
     { echo "$0 ERROR dpkg-scanpackages not found in path" ; false ; } 
echo "$0 check_requiremnts ... done"
return 0
}

die(){
echo "$0 die"
return 0
}

create_repo_tree(){
eval mkdir -p $deb_metadata_tree
eval mkdir -p $deb_packages_tree
eval touch $deb_metadata_tree/$files
echo "$0 Debian mirror structure is created"
}


populate_repo_tree(){
echo $remote_mirror
# they would hate me for this... i need to configure rsync daemon with port forwarding to avoid proxy restrictions soon.
#wget -r --limit-rate=20K --wait=3 ftp://ftp.rediris.es/debian/pool/main/d/debian-installer .
# 
# Actually i am using apt-move to populate the pool 
return 0
}

update_repo_tree(){
echo "$0 update.."
    #find . -type d -mindepth 1 -maxdepth 1 | cut -c3- | while read d; do
#    dpkg-scanpackages $d $d/override
#done | gzip -c -9 > Packages.gz
file_override=/dev/null
arch="i386"
suite="stable"
branch="main"
dpkg-scanpackages -a $arch \
 $localdir/pool/$branch $file_override 2>/dev/null > \
 $localdir/dists/$suite/$branch/binary-$arch/Packages
gzip -c -9 $localdir/dists/$suite/$branch/binary-$arch/Packages > \
 $localdir/dists/$suite/$branch/binary-$arch/Packages.gz       
# rm Release Release.gpg
#    apt-ftparchive release . \\
#        -o APT::FTPArchive::Release::Origin="TTU CAE Network" \\
#        -o APT::FTPArchive::Release::Codename="etch" \\
#        > /root/Release
#    mv /root/Release .
#    gpg -abs -o Release.gpg Release
            
return 0
}


main(){
echo "$0 main"
return 0
}


usage(){
cat << __EOF__
Usage : basename $0 -d /local/repositori_dir [] 
__EOF__
}

while getopts "d:h:" option ; do
    case $option in
    "d")
        localdir=${OPTARG}
        echo $localdir
    ;;
    "h")
    usage
    ;;
    *)
    usage
    ;;
    esac
done 
#forcing a minimun number or supplied options
if [[ x"$OPTIND" = x"1" ]] ; then
    usage
    exit
fi

deb_metadata_tree="$localdir/dists/$suites/$branches/binary-$archs"
deb_packages_tree="$localdir/pool/$branches/{a..z}/"

check_requeriments
eval ls $deb_metadata_tree 2>/dev/null || exists="no" && true 
if [[ x"$exists" = x"no" ]];then
    read -p "$0 repository does not exists. Create ? y/N " reply
    if [[ x"$reply" = x"y" ]]; then
        create_repo_tree
        #populate_repo_tree
        update_repo_tree
    fi
else
    echo "$0 repository already exists .. updating . "
    #populate_repo_tree
    update_repo_tree
fi





