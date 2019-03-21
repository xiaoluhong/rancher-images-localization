#!/bin/bash -xe

NS=cnrancher
RANCHER_VERSION=v2.1.7

ALI_DOCKER_USERNAME=$ALI_DOCKER_USERNAME
ALI_DOCKER_PASSWORD=$ALI_DOCKER_PASSWORD

REGISTRY=registry.cn-shenzhen.aliyuncs.com

IMAGES=$( curl -L https://github.com/rancher/rancher/releases/download/${RANCHER_VERSION}/rancher-images.txt )

docker login --username=${ALI_DOCKER_USERNAME}  -p${ALI_DOCKER_PASSWORD} ${REGISTRY}

for IMGS in $( echo ${IMAGES} );
do 
    cp -rf Dockerfile.template  Dockerfile
    sed -i "s/IMGS/${IMGS}/g"  Dockerfile

    docker build -t ${IMGS} .
    
    n=$( echo ${IMGS} | awk -F"/" '{print NF-1}' )

        #如果镜像名中没有/，那么此镜像一定是library仓库的镜像；

        if [ ${n} -eq 0 ]; then
            IMG_TAG=${IMGS}

            #重命名镜像
            docker tag ${IMGS} ${REGISTRY}/${NS}/${IMG_TAG}

            #上传镜像
            docker push ${REGISTRY}/${NS}/${IMG_TAG}

        #如果镜像名中有1个/，那么/左侧为项目名，右侧为镜像名和tag

        elif [ ${n} -eq 1 ]; then
            IMG_TAG=$(echo ${IMGS} | awk -F"/" '{print $2}')

            #重命名镜像
            docker tag ${IMGS} ${REGISTRY}/${NS}/${IMG_TAG}

            #上传镜像
            docker push ${REGISTRY}/${NS}/${IMG_TAG}

        #如果镜像名中有2个/，

        elif [ ${n} -eq 2 ]; then
            IMG_TAG=$(echo ${IMGS} | awk -F"/" '{print $3}')

            #重命名镜像
            docker tag ${IMGS} ${REGISTRY}/${NS}/${IMG_TAG}

            #上传镜像
            docker push ${REGISTRY}/${NS}/${IMG_TAG}

        else
            #标准镜像为四层结构，即：仓库地址/项目名/镜像名:tag,如不符合此标准，即为非有效镜像。
            echo "No available images"
        fi

done
