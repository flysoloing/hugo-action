#!/bin/sh -l

set -e

#定义日志函数
logger() {
  log_content=$1
  log_date=`date +%F`
  log_time=`date +%T`
  echo "[Hugo Action] $log_date $log_time INFO: ${log_content}"
}

logger "hugo action build start"
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
site_title=$6
language_code=$7
theme_name=$8

logger "theme repo url: $theme_repo_url"
logger "source repo url: $source_repo_url"
logger "target repo url: $target_repo_url"
logger "config file url: $config_file_url"
logger "base url: $base_url"
logger "site_title: $site_title"
logger "language_code: $language_code"
logger "theme_name: $theme_name"

#基本参数校验
if [ -z "$source_repo_url" ]; then
    logger "source repo url is none, exit"
	exit
fi
if [ -z "$target_repo_url" ]; then
    logger "target repo url is none, exit"
	exit
fi

workspace_dir="workspace"
site_dir="hugosite"
source_dir=${source_repo_url##*/}
target_dir=${target_repo_url##*/}

logger "workspace dir: $workspace_dir"
logger "site dir: $site_dir"
logger "source dir: $source_dir"
logger "target dir: $target_dir"

workspace_path=~/$workspace_dir
logger "workspace path: $workspace_path"

#创建工作区
mkdir $workspace_path
cd $workspace_path

#这里的GH_TOKEN很重要，关系到Action是否具有足够的执行权限，设置方式如下：
#1、在GitHub个人账户中设置，路径：Settings --> Developer settings --> Personal access tokens --> Generate new token
#2、在source_repo_url对应的仓库设置，路径：Settings --> Secrets --> Actions --> New repository secret
source_repo_url_with_token=`echo $source_repo_url | sed "s/github/${GH_TOKEN}@&/"`
target_repo_url_with_token=`echo $target_repo_url | sed "s/github/${GH_TOKEN}@&/"`
logger "source_repo_url_with_token: $source_repo_url_with_token"
logger "target_repo_url_with_token: $target_repo_url_with_token"

logger "clone git repository: $source_dir, $target_dir"
#git clone $source_repo_url
#git clone $target_repo_url
#git clone "https://${GITHUB_ACTOR}:${GH_TOKEN}@github.com/flysoloing/articles"
#git clone "https://${GH_TOKEN}@github.com/flysoloing/articles"
git clone $source_repo_url_with_token $source_dir
git clone $target_repo_url_with_token $target_dir

#初始化站点结构
logger "create new site: $site_dir"
hugo new site $site_dir

logger "there are three directories in the workspace"
pwd && ls -l

#进行hugo部署前的配置
cd $workspace_path/$site_dir
pwd && ls -al

echo "theme = \"qiuqiu\"" >> config.toml

#设置config.toml，如果config_file_url参数为空，则用base_url等基本参数进行配置，否则先替换后再进行基本配置，此处可先做非空判断，TODO
if [ -z "$config_file_url" ]; then
    logger "config file url is none, replace basic config with $base_url, $language_code, $site_title, $theme_name"
    #替换config.toml中对应的几个字段，baseURL
    sed -i "/baseURL/ c baseURL = \"${base_url}\"" config.toml
    sed -i "/languageCode/ c languageCode = \"$language_code\"" config.toml
    sed -i "/title/ c title = \"$site_title\"" config.toml
    sed -i "/theme/ c theme = \"$theme_name\"" config.toml
else
    logger "replace config.toml with $config_file_url"
    #TODO 待测试
    wget $config_file_url -O config.toml
fi

logger "show config.toml content"
cat config.toml

#将文章目录中的md文档都移动到$site_dir中的content目录，具体以实际文章分组为准
cd $workspace_path/$source_dir
pwd && ls -al
logger "copy all *.md file to the site content directory"
cp -r *.md $workspace_path/$site_dir/content

#设置themes
cd $workspace_path/$site_dir/themes
if [ -z "$theme_repo_url" ]; then
    logger "theme repo url is none, use default theme"
fi

logger "clone theme git repository: $theme_name"
git clone $theme_repo_url $theme_name
pwd && ls -al

#为每个md文件增加头部信息，如title，date等，title取文件名，date取文件生成时间，然后把md文件的一级标题删除TODO
cd $workspace_path/$site_dir/content

logger "delete the first line of the *.md file in a loop, and then add front matter info"
for file in `pwd`/*
do
  if test -f $file
  then
    echo $file 是文件
    #先删除首行标题，如# H1
    sed -i "1d" $file
    #添加Front Matter信息，如title，date等
    front_matter_title=$(basename $file .md)
    front_matter_str="---\ntitle: \"$front_matter_title\"\ndate: 2020-08-08\ndescription: \"\"\n---\n"
    sed -i "1i $front_matter_str" $file
    cat $file
  fi
  #if test -d $file
  #then
    #echo $file 是目录
  #fi
done

#先删除首行标题，如# H1
#sed -i '1d' xxx.md
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
pwd && ls -al

logger "deploy site: $site_dir"
hugo -D

#清空target目录
cd $workspace_path/$target_dir
pwd && ls -al

target_dir_files_num=`ls | wc -l`
if [ $target_dir_files_num -le 0 ]; then
    logger "the target dir is empty"
else
    logger "remove all target dir content except .git and .gitignore file"
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
pwd && ls -al

logger "copy the site public directory to target dir"
cp -r . $workspace_path/$target_dir

#将target目录提交到GitHub
cd $workspace_path/$target_dir
pwd && ls -al

logger "commit new target dir content to remote repo"
git add .
git commit -m "publish new article"
git push -f -q $target_repo_url_with_token master

logger "hugo action build success"