#!/bin/sh

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
curl --version
xmllint --version

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
has_cjk_language=$9
summary_length=${10}

logger "theme repo url: $theme_repo_url"
logger "source repo url: $source_repo_url"
logger "target repo url: $target_repo_url"
logger "config file url: $config_file_url"
logger "base url: $base_url"
logger "site_title: $site_title"
logger "language_code: $language_code"
logger "theme_name: $theme_name"
logger "has_cjk_language: $has_cjk_language"
logger "summary_length: $summary_length"

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
tmp_dir="tmpdir"

logger "workspace dir: $workspace_dir"
logger "site dir: $site_dir"
logger "source dir: $source_dir"
logger "target dir: $target_dir"
logger "tmp dir: $tmp_dir"

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

#创建tmp目录
mkdir $tmp_dir

logger "there are four directories in the workspace"
pwd && ls -l

#进行hugo部署前的配置
cd $workspace_path/$site_dir
pwd && ls -al

echo "theme = \"xxx\"" >> config.toml
echo "hasCJKLanguage = false" >> config.toml
echo "summaryLength = 70" >> config.toml

logger "show config.toml content"
cat config.toml

#设置config.toml，如果config_file_url参数为空，则用base_url等基本参数进行配置，否则先替换后再进行基本配置，此处可先做非空判断，TODO
if [ -z "$config_file_url" ]; then
    logger "config file url is none, replace basic config with input params"
    #替换config.toml中对应的几个字段，baseURL
    sed -i "/baseURL/ c baseURL = \"${base_url}\"" config.toml
    sed -i "/languageCode/ c languageCode = \"$language_code\"" config.toml
    sed -i "/title/ c title = \"$site_title\"" config.toml
    sed -i "/theme/ c theme = \"$theme_name\"" config.toml
    sed -i "/hasCJKLanguage/ c hasCJKLanguage = $has_cjk_language" config.toml
    sed -i "/summaryLength/ c summaryLength = $summary_length" config.toml
else
    logger "replace config.toml with $config_file_url"
    #TODO 待测试
    wget $config_file_url -O config.toml
fi

logger "show config.toml content"
cat config.toml

#将文章目录中的md文档都移动到$site_dir中的content目录，具体以实际文章分组为准
#用rsync命令可以简单实现
cd $workspace_path/$source_dir
pwd && ls -al
logger "find all *.md file from source directory"
find . -type f -name "*.md" | xargs tar -czvf abcxyz.tar.gz
logger "copy all *.md file to the site content directory"
tar -xzvf abcxyz.tar.gz -C $workspace_path/$site_dir/content

#设置themes
cd $workspace_path/$site_dir/themes
if [ -z "$theme_repo_url" ]; then
    logger "theme repo url is none, use default theme"
fi

logger "clone theme git repository: $theme_name"
git clone $theme_repo_url $theme_name
pwd && ls -al

#为每个md文件增加头部信息，如title，date等，title取文件名，date取文件生成时间，然后把md文件的一级标题删除
#实现过于复杂，在文章开始写好Front Matter吧
cd $workspace_path/$site_dir/content
pwd && ls -al

#logger "delete the first line of the *.md file in a loop, and then add front matter info"
#for file in `pwd`/*
#do
#  if test -f $file
#  then
#    echo $file 是文件
#    #先删除首行标题，如# H1
#    sed -i "1d" $file
#    #添加Front Matter信息，如title，date等
#    front_matter_title=$(basename $file .md)
#    #TODO 创建时间是个问题，最好能通过github api获取每个文件的提交时间
#    front_matter_date="2021-04-01"
#    front_matter_str="---\ntitle: \"$front_matter_title\"\ndate: $front_matter_date\ndescription: \"\"\n---"
#    sed -i "1i $front_matter_str" $file
#    cat $file
#  fi
#  #if test -d $file
#  #then
#    #echo $file 是目录
#  #fi
#done

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
#hugo -D
hugo

cd $workspace_path/$site_dir/public
pwd && ls -al

#清空target目录
cd $workspace_path/$target_dir
pwd && ls -al

#检测是否包含CNAME文件，若包含，则需保留该文件
cname_file="CNAME"
dot_cname_file=".CNAME"

if [ -e $cname_file ]; then
    logger "CNAME file exist, CNAME -> .CNAME"
    mv $cname_file $dot_cname_file
else
    logger "CNAME file not exist"
fi

#定义循环比较函数
loopdiff() {
  for file_msg in $1/*; do
    tmp_file=${file_msg//"$target_dir"/"$site_dir/public"}
    if [ -d $file_msg ]; then
      if [ -d $tmp_file ]; then
        loopdiff $file_msg
      else
        logger "$tmp_file not exist"
        rm -rf $file_msg
      fi
    elif [ -f $file_msg ]; then
      if [ ! -f $tmp_file ]; then
        logger "$tmp_file not exist"
        rm $file_msg
      fi
    else
      logger "no such file or directory: $file_msg"
      #考虑空文件夹的情况
    fi
  done
}

loopdiff $workspace_path/$target_dir

#将public目录内容拷贝到target目录
cd $workspace_path/$site_dir/public
logger "copy the site public directory to target dir"
cp -r . $workspace_path/$target_dir

#将target目录提交到GitHub
cd $workspace_path/$target_dir
pwd && ls -al

if [ -e $dot_cname_file ]; then
    logger ".CNAME file exist, .CNAME -> CNAME"
    mv $dot_cname_file $cname_file
else
    logger ".CNAME file not exist"
fi

#判断git status状态，如果没有可提交的，则不执行提交操作
if [ -z "$(git status --porcelain)" ]; then
    logger "nothing to commit, working tree clean"
    exit
fi

logger "commit new target dir content to remote repo"
git add .
git commit -m "publish new article"
git push -f -q $target_repo_url_with_token master

#调用百度API自动提交新增URL
cd $workspace_path/$tmp_dir

#先下载
logger "download old sitemap.xml to tmp dir"
curl -o old-sitemap.xml https://www.crudman.cn/sitemap.xml
#将sitemap.xml拷贝到tmp目录
logger "copy new sitemap.xml to tmp dir"
cp $workspace_path/$site_dir/public/sitemap.xml new-sitemap.xml

#格式化
xmllint --format old-sitemap.xml > old-sitemap.txt
xmllint --format new-sitemap.xml > new-sitemap.txt

#去掉元素<urlset>里的xmlns属性，否则会报“XPath set is empty”的异常，删除<urlset xmlns="...">这行，然后加上新的<urlset>
sed -i "2d" old-sitemap.txt
sed -i "2d" new-sitemap.txt
sed -i "1a <urlset>" old-sitemap.txt
sed -i "1a <urlset>" new-sitemap.txt

#使用libxml2包命令，将url提取到old-urls.txt文本
xmllint --xpath "//url/loc/text()" old-sitemap.txt > old-urls.txt
xmllint --xpath "//url/loc/text()" new-sitemap.txt > new-urls.txt

#由于xmlint命令提取出来的为单行文本，需要将其按行展示
sed -i "s/\/https/\/\r\nhttps/g" old-urls.txt
sed -i "s/\/https/\/\r\nhttps/g" new-urls.txt

#比较old-urls.txt和new-urls.txt文件，找出new-urls.txt中有的url，将新增的url存入urls.txt
grep -vFf old-urls.txt new-urls.txt > urls.txt
pwd && ls -al

#如果urls.txt文件为空，则不进行百度提交
if [ ! -s urls.txt ]; then
    logger "urls.txt is empty, not commit"
    exit
fi

#调用百度API提交
logger "commit new urls to baidu"
cat urls.txt
curl -H 'Content-Type:text/plain' --data-binary @urls.txt "http://data.zz.baidu.com/urls?site=$base_url&token=${BAIDU_TOKEN}"

logger "hugo action build success"
