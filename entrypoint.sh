#!/bin/sh -l

set -e

echo "----------------hugo site build start----------------"
hugo version
git --version

#设置git支持中文文件名的处理
git config --global core.quotepath false


echo "GITHUB ACTOR: ${GITHUB_ACTOR}"


hugo_version=$1
theme_repo_url=$2
source_repo_url=$3
target_repo_url=$4
config_file_url=$5
base_url=$6
title=$7
language_code=$9
theme=$9

echo "hugo version: $hugo_version"
echo "theme repo url: $theme_repo_url"
echo "source repo url: $source_repo_url"
echo "target repo url: $target_repo_url"
echo "config file url: $config_file_url"
echo "base url: $base_url"
echo "title: $title"
echo "language_code: $language_code"
echo "theme: $theme"

workspace_dir="workspace"
echo "workspace dir: $workspace_dir"

workspace_path=~/$workspace_dir
echo "workspace path: $workspace_path"

mkdir $workspace_path
cd $workspace_path
pwd

site_dir="xxxxxx"
source_dir=${source_repo_url##*/}
target_dir=${target_repo_url##*/}

echo "site dir: $site_dir"
echo "source dir: $source_dir"
echo "target dir: $target_dir"

if [ -z "$source_repo_url" ]; then
    echo "source repo url is none, exit"
	exit
fi
if [ -z "$target_repo_url" ]; then
    echo "target repo url is none, exit"
	exit
fi
git clone $source_repo_url
git clone $target_repo_url

#初始化站点结构
hugo new site $site_dir

#将文章目录中的md文档都移动到$site_dir中的，具体以实际文章分组为准
cd $workspace_path/$source_dir
pwd
ls -al
cp -r *.md $workspace_path/$site_dir/content
#检查是否包含front matter，若没有，则加上，事例如下：
#---
#title: "title"
#date: "2020-07-30T20:20:20Z"
#---

#进行hugo部署前的配置
cd $workspace_path/$site_dir
pwd
ls -al

#设置config.toml
if [ -z "$config_file_url" ]; then
    echo "config file url is none, use basic config params"
    #替换config.toml中对应的几个字段，baseURL
    sed -i '/baseURL/ c baseURL = \"`$base_url`\"' config.toml
    sed -i '/languageCode/ c languageCode = \"$language_code\"' config.toml
    sed -i '/title/ c title = \"$title\"' config.toml
    #sed -i '/theme/ c theme = \"$theme\"' config.toml
	echo "theme = \"`$theme`\"" >> config.toml
else
    echo "replace default config.toml"
    wget $config_file_url -O config.toml
fi
cat config.toml

#设置themes
cd $workspace_path/$site_dir/themes
if [ -z "$theme_repo_url" ]; then
    echo "theme repo url is none, use default theme"
fi
git clone $theme_repo_url
pwd
ls -al

#为每个md文件增加头部信息，如title，
cd $workspace_path/$site_dir/content

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
git push origin master
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