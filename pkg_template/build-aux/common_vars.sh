#! /bin/bash
prefix="$HOME"
test -n $HOME || \
    { echo "no HOME ??? " ; false ; }

myskeldir="$prefix/{working_dir,workspace,projects,recipes,myskel/{control,compressed,encrypted,device,running_dir/{aux,input,output},tools/Templates}}"
working_dir="$prefix/working_dir/.${script_name}"
compressed_dir="$prefix/myskel/compressed"
encrypted_dir="$prefix/myskel/encrypted"
control_dir="$prefix/myskel/control"



# remote
remote_tree="var/cache/syncro_bkp"
