#! /bin/bash

check_connection(){ 
wget  --tries=1 --timeout=3 \
    http://www.google.com -O $working_dir/index.google &> /dev/null  || true
if [[ ! -s $working_dir/index.google ]];then 
    return 1 # 1 sale
else
    unlink $working_dir/index.google 
    return 0
fi
}



