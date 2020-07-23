#!/bin/sh -l

set -e

echo "Hello $1"
time=$(date)
echo "--------------------------"
echo ::set-output name=time::$time

testV=$1

echo $testV

echo "the first param is $testV" 

hugo version

git --version

# https://github.com/<USERNAME>/<PROJECT>.git
#source_url=$1
# <PROJECT>
#source_dir=""
# https://github.com/<USERNAME>/<USERNAME>.github.io.git
#target_url=$2
# https://<USERNAME>.github.io
#baseURL=$222

#cd /home/

#git clone $source_url

#cd $source_dir

#hugo -D

#git submodule add -b master $target_url public

#cd public

#git add .

#msg="rebuilding site $(date)"
#if [ -n "$*" ]; then
#	msg="$*"
#fi
#git commit -m "$msg"

#git push origin master