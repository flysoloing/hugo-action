# 基于alpine 3.12版本
FROM alpine:3.14

# 添加新的包镜像地址，国外用官方镜像，国内用清华镜像。官方镜像网址：https://mirrors.alpinelinux.org
#RUN echo "https://alpine.global.ssl.fastly.net/alpine/v3.12/main" >> /etc/apk/repositories \
#    && echo "https://alpine.global.ssl.fastly.net/alpine/v3.12/releases" >> /etc/apk/repositories \
#    && echo "https://alpine.global.ssl.fastly.net/alpine/v3.12/community" >> /etc/apk/repositories

#RUN echo "https://mirrors.tuna.tsinghua.edu.cn/alpine/v3.12/main" >> /etc/apk/repositories \
#    && echo "https://mirrors.tuna.tsinghua.edu.cn/alpine/v3.12/releases" >> /etc/apk/repositories \
#    && echo "https://mirrors.tuna.tsinghua.edu.cn/alpine/v3.12/community" >> /etc/apk/repositories

# 安装hugo、git、curl、libxml2
RUN apk add --no-cache hugo \
    && apk add --no-cache git \
    && apk add --no-cache curl \
    && apk add --no-cache grep \
    && apk add --no-cache libxml2-utils

# 拷贝代码仓库里的entrypoint.sh到容器的/路径下
COPY entrypoint.sh /entrypoint.sh

# 赋予/entrypoint.sh可执行权限
RUN chmod +x /entrypoint.sh

# 设置容器启动后执行/entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]