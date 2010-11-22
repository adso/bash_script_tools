#! /bin/bash

product_dir="../$(basename $PWD)"
product_new_dir="../freeinstants.basictheme"
namespace_name="plonetheme"
namespace_new_name="freeinstants"
product_name="keepitsimple[-]*[[:alpha:]]*"
product_new_name="basictheme"



# reproducing the new dir tree
find $product_dir -type d | \
    sed "{ s,$product_dir,$product_new_dir,g ; \
           s,$namespace_name,$namespace_new_name,g ; \
           s,$product_name,$product_new_name,g ; }"  | \
    xargs mkdir -p 

# moving files to their new names
find $product_dir -type f | \
    sed -n " { s,\(.*\),\"\1\",g ; \
             p ; \
             s,$product_dir,$product_new_dir,g ; \
             s,$namespace_name,$namespace_new_name,g ; \
             s,$product_name,$product_new_name,g ; \
             p ; } "  |  xargs -L2 -n2  cp 
# TOLEARN what it is the right delimiter ? -d "\n" doesnt work

# changing namespace related content in files
grep -lr "\($namespace_name\|$product_name\)" $product_new_dir | \
xargs sed -i "{ s,$namespace_name,$namespace_new_name,g ; \
              s,$product_name,$product_new_name,g ; }"
exit 0