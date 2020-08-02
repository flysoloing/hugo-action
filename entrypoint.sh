#!/bin/sh -l

set -e

echo "----------------hugo site build start----------------"
hugo version
git --version

#设置git支持中文文件名的处理
git config --global core.quotepath false
git config --global user.name "${GITHUB_ACTOR}"
git config --global user.email "${GITHUB_ACTOR}@users.noreply.github.com"

theme_repo_url=$1
source_repo_url=$2
target_repo_url=$3
config_file_url=$4
base_url=$5
title=$6
language_code=$7
theme=$8

echo "theme repo url: $theme_repo_url"
echo "source repo url: $source_repo_url"
echo "target repo url: $target_repo_url"
echo "config file url: $config_file_url"
echo "base url: $base_url"
echo "title: $title"
echo "language_code: $language_code"
echo "theme: $theme"

if [ -z "$source_repo_url" ]; then
    echo "source repo url is none, exit"
	exit
fi
if [ -z "$target_repo_url" ]; then
    echo "target repo url is none, exit"
	exit
fi

workspace_dir="workspace"
site_dir="hugosite"
source_dir=${source_repo_url##*/}
target_dir=${target_repo_url##*/}

echo "workspace dir: $workspace_dir"
echo "site dir: $site_dir"
echo "source dir: $source_dir"
echo "target dir: $target_dir"

workspace_path=~/$workspace_dir
echo "workspace path: $workspace_path"

mkdir $workspace_path
cd $workspace_path
pwd

git clone $source_repo_url
git clone $target_repo_url

#初始化站点结构
hugo new site $site_dir

#将文章目录中的md文档都移动到$site_dir中的，具体以实际文章分组为准
cd $workspace_path/$source_dir
pwd
ls -al
cp -r *.md $workspace_path/$site_dir/content

#设置themes
cd $workspace_path/$site_dir/themes
if [ -z "$theme_repo_url" ]; then
    echo "theme repo url is none, use default theme"
fi
git clone $theme_repo_url $theme
pwd
ls -al

#替换config.toml文件
cd $workspace_path/$site_dir/themes/$theme/exampleSite
cp config.toml $workspace_path/$site_dir


#进行hugo部署前的配置
cd $workspace_path/$site_dir
pwd
ls -al

#设置config.toml
if [ -z "$config_file_url" ]; then
    echo "config file url is none, use basic config params"
    #替换config.toml中对应的几个字段，baseURL
    sed -i "/baseURL/ c baseURL = \"${base_url}\"" config.toml
    sed -i "/languageCode/ c languageCode = \"$language_code\"" config.toml
    sed -i "/title/ c title = \"$title\"" config.toml
    #sed -i "/theme/ c theme = \"$theme\"" config.toml
	#echo "theme = \"$theme\"" >> config.toml
else
    echo "replace default config.toml"
    wget $config_file_url -O config.toml
fi
cat config.toml

#为每个md文件增加头部信息，如title，
cd $workspace_path/$site_dir/content
#检查是否包含front matter，若没有，则加上，事例如下：
#---
#title: "title"
#date: "2020-07-30T20:20:20Z"
#---

#以上设置完毕，开始hugo部署
cd $workspace_path/$site_dir
pwd
ls -al
hugo -D

#清空target目录
cd $workspace_path/$target_dir
pwd
ls -al
ls | xargs rm -rf
ls -al
git status
git rm $(git ls-files -d)
git status
git commit -m "remove old files"
git status

target_repo_url_with_token=`echo $target_repo_url | sed "s/github/${GH_TOKEN}@&/"`
echo $target_repo_url_with_token
git push -f -q $target_repo_url_with_token master
git status

#将public目录内容拷贝到target目录
cd $workspace_path/$site_dir/public
pwd
ls -al
cp -r . $workspace_path/$target_dir

#将target目录提交到GitHub
cd $workspace_path/$target_dir
pwd
ls -al
#git add .
#git commit -m "...."
#git push origin master

echo "----------------hugo site build end----------------"