#!/bin/bash -x

NS=rancher
#RANCHER_VERSION="v2.2.2 v2.2.1 v2.2.0 v2.1.8 v2.1.7 v2.1.6 v2.1.5 v2.1.4"
# v2.2.5 v2.2.4 v2.2.3 v2.2.2 v2.2.1 v2.2.0 v2.1.8

RANCHER_VERSION="v2.3.5" 

ALI_DOCKER_USERNAME=$ALI_DOCKER_USERNAME
ALI_DOCKER_PASSWORD=$ALI_DOCKER_PASSWORD

REGISTRY=registry.cn-shanghai.aliyuncs.com

for RANCHER in $( echo ${RANCHER_VERSION} );
do
    sudo curl -L https://github.com/rancher/rancher/releases/download/${RANCHER}/rancher-images.txt >> rancher-images-all.txt
done

echo ===============================================
    sudo curl -LS -o ./rke https://github.com/rancher/rke/releases/download/$(curl -s https://api.github.com/repos/rancher/rke/releases/latest | grep tag_name | cut -d '"' -f 4)/rke_linux-amd64 
    sudo chmod +x ./rke
    sudo ./rke config --system-images --all >> ./rancher-images-all.txt
    sudo sort -u rancher-images-all.txt -o rancher-images-all.txt
echo ===============================================

echo ===============================================
cat rancher-images-all.txt | wc -l 
cat rancher-images-all.txt 
echo ===============================================

docker login --username=${ALI_DOCKER_USERNAME}  -p${ALI_DOCKER_PASSWORD} ${REGISTRY}
IMAGES=$( cat ./rancher-images-all.txt )

for IMGS in $( echo ${IMAGES} );
do 
    docker pull ${IMGS}
    USER=$( docker inspect -f '{{ .ContainerConfig.User }}' ${IMGS} ) 
    
    cp -rf Dockerfile.template  Dockerfile
    sed -i  "s@IMGS@${IMGS}@"  Dockerfile

    docker build --build-arg USER=${USER} -t ${IMGS} .
    rm -rf Dockerfile
    
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

