#!/bin/sh -l

set -e

echo "----------------hugo site build start----------------"
hugo version
git --version

echo "----------------setup git global config----------------"
#设置git支持中文文件名的处理
echo "GITHUB_ACTOR: ${GITHUB_ACTOR}"
git config --global core.quotepath false
git config --global user.name "${GITHUB_ACTOR}"
git config --global user.email "${GITHUB_ACTOR}@users.noreply.github.com"

theme_repo_url=$1
source_repo_url=$2
target_repo_url=$3
config_file_url=$4
base_url=$5
site_title=$6
language_code=$7
theme_name=$8

echo "theme repo url: $theme_repo_url"
echo "source repo url: $source_repo_url"
echo "target repo url: $target_repo_url"
echo "config file url: $config_file_url"
echo "base url: $base_url"
echo "site_title: $site_title"
echo "language_code: $language_code"
echo "theme_name: $theme_name"

#这里的GH_TOKEN很重要，关系到Action是否具有足够的执行权限，需要在target_repo_url对应的repo中设置
target_repo_url_with_token=`echo $target_repo_url | sed "s/github/${GH_TOKEN}@&/"`

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

echo "----------------clone git repository: $source_dir, $target_dir----------------"
#git clone $source_repo_url
#git clone "https://${GITHUB_ACTOR}:${GH_TOKEN}@github.com/flysoloing/articles"
#git clone "https://${GH_TOKEN}@github.com/flysoloing/articles"
git clone "https://${GITHUB_ACTOR}:${GITHUB_TOKEN}@github.com/flysoloing/articles"
#git clone "https://${GH_TOKEN}@github.com/flysoloing/articles"
git clone $target_repo_url

#初始化站点结构
hugo new site $site_dir

#将文章目录中的md文档都移动到$site_dir中的，具体以实际文章分组为准，TODO
cd $workspace_path/$source_dir
pwd
ls -al
cp -r *.md $workspace_path/$site_dir/content

#设置themes
cd $workspace_path/$site_dir/themes
if [ -z "$theme_repo_url" ]; then
    echo "theme repo url is none, use default theme"
fi
echo "----------------clone git repository: $theme_name----------------"
git clone $theme_repo_url $theme_name
pwd
ls -al

#替换config.toml文件
#echo "----------------replace config.toml with theme exampleSite----------------"
#cd $workspace_path/$site_dir/themes/$theme_name/exampleSite
#cp config.toml $workspace_path/$site_dir


#进行hugo部署前的配置
cd $workspace_path/$site_dir
pwd
ls -al

#设置config.toml，如果config_file_url参数为空，则用base_url等基本参数进行配置，否则先替换后再进行基本配置，此处可先做非空判断，TODO
if [ -z "$config_file_url" ]; then
    echo "config file url is none, replace basic config with $base_url, $language_code, $site_title, $theme_name"
    #替换config.toml中对应的几个字段，baseURL
    sed -i "/baseURL/ c baseURL = \"${base_url}\"" config.toml
    sed -i "/languageCode/ c languageCode = \"$language_code\"" config.toml
    sed -i "/title/ c title = \"$site_title\"" config.toml
    sed -i "/theme/ c theme = \"$theme_name\"" config.toml
else
    echo "replace config.toml with $config_file_url"
    wget $config_file_url -O config.toml
fi
cat config.toml

#为每个md文件增加头部信息，如title，date等，title取文件名，date取文件生成时间，然后把md文件的一级标题删除TODO
cd $workspace_path/$site_dir/content
#先删除首行标题，如# H1
#sed -i '1d' xxx.md
echo "----------------add front matter for every md file----------------"
#检查是否包含front matter，若没有，则加上，事例如下：
#---
#title: "title"
#date: "2020-07-30T20:20:20Z"
#---
#多行文本变量，TODO
#front_matter=''
#sed -i '1 a $front_matter' xxx.md


#以上设置完毕，开始hugo部署
cd $workspace_path/$site_dir
pwd
ls -al
echo "----------------hugo deploy----------------"
hugo -D

#清空target目录
cd $workspace_path/$target_dir
pwd
ls -al
target_dir_files_num=`ls | wc -l`
if [ $target_dir_files_num -le 0 ]; then
    echo "target dir is empty"
else
    echo "remove all git content except .git and .gitignore"
    ls | xargs rm -rf
    ls -al
    git status
    git rm $(git ls-files -d)
    git status
    git commit -m "remove old files"
    git status
    git push -f -q $target_repo_url_with_token master
    git status
fi

#将public目录内容拷贝到target目录
cd $workspace_path/$site_dir/public
pwd
ls -al
cp -r . $workspace_path/$target_dir

#将target目录提交到GitHub
cd $workspace_path/$target_dir
pwd
ls -al
git add .
git commit -m "publish new article"
git push -f -q $target_repo_url_with_token master

echo "----------------hugo site build end----------------"