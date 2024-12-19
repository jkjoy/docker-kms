# 编译阶段：使用最新的 Alpine 镜像编译 vlmcsd
FROM alpine:latest as compilingvlmcsd

ARG VLMCSD_VER=1113

# 安装编译依赖
RUN apk add --no-cache build-base \
    && wget -qO- https://github.com/Wind4/vlmcsd/archive/svn${VLMCSD_VER}.tar.gz | tar -xzf- \
    && cd /vlmcsd-svn${VLMCSD_VER} \
    && make

# 最终阶段：使用最新的 Alpine 镜像构建运行时环境
FROM alpine:latest

ARG S6_VER=3.2.0.2
ARG VLMCSD_VER=1113

# 环境变量
ENV UID=1000
ENV GID=1000
ENV KMS_README_WEB=true
ENV KMS_README_WEB_PORT=8080
ENV VLMCSD_SERVER_PORT=1688
ENV S6_CMD_WAIT_FOR_SERVICES_MAXTIME=0

# 复制编译好的 vlmcsd 二进制文件
COPY --from=compilingvlmcsd /vlmcsd-svn${VLMCSD_VER}/bin/vlmcsd /usr/bin/vlmcsd

# 安装运行时依赖
RUN apk add --no-cache darkhttpd ca-certificates bash shadow \
    && wget -qO- https://github.com/just-containers/s6-overlay/releases/download/v${S6_VER}/s6-overlay-noarch.tar.xz | tar -C / -Jxf- \
    && wget -qO- https://github.com/just-containers/s6-overlay/releases/download/v${S6_VER}/s6-overlay-$(uname -m).tar.xz | tar -C / -Jxf- \
    && wget -qO- https://github.com/just-containers/s6-overlay/releases/download/v${S6_VER}/s6-overlay-symlinks-noarch.tar.xz | tar -C / -Jxf- \
    && wget -qO- https://github.com/just-containers/s6-overlay/releases/download/v${S6_VER}/s6-overlay-symlinks-arch.tar.xz | tar -C / -Jxf- \
    # 创建 kms 用户
    && adduser -u ${UID} -D -H -s /bin/false kms \
    && rm -rf /var/cache/apk/* /tmp/*

# 暴露端口
EXPOSE 1688 8080

# 设置入口点
ENTRYPOINT [ "/init" ]