#!/bin/bash
# 停止相关的镜像
docker ps -a | grep "Exited" | awk '{print $1 }'|xargs docker stop
docker ps -a | grep "Exited" | awk '{print $1 }'|xargs docker rm
# 刪除鏡像
docker images|grep none|awk '{print $3 }'|xargs docker rmi

# 批量删除的方法:
#docker rmi $(docker images | awk '/^<none>/ { print $3 }')
