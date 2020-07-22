# 基于alpine 3.12版本
FROM alpine:3.12

# 添加新的包镜像地址
#RUN echo "???" >> /etc/apk/repositories \
#    && echo "???" >> /etc/apk/repositories
	
# 安装hugo和git
RUN apk add --no-cache hugo \
    && apk add --no-cache git

# 拷贝代码仓库里的entrypoint.sh到容器的/路径下
COPY entrypoint.sh /entrypoint.sh

# 赋予/entrypoint.sh可执行权限
RUN chmod +x /entrypoint.sh

# 设置容器启动后执行/entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]