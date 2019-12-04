#!/bin/bash -x

# sudo apt-get -y install jq curl gettext-base sed python-yaml
pip install pyyaml

ALI_DOCKER_USERNAME=$ALI_DOCKER_USERNAME
ALI_DOCKER_PASSWORD=$ALI_DOCKER_PASSWORD

REGISTRY=registry.cn-shanghai.aliyuncs.com
NS=cn-goharbor

# v1.2.3 v1.2.2 v1.2.1

HARBOR_VERSION=" v1.2.0  " 

for harbor in $( echo ${HARBOR_VERSION} );
do
    git clone -b $harbor https://github.com/goharbor/harbor-helm.git
    cp get-images.py harbor-helm/get-images.py
    cd harbor-helm
    python get-images.py values.yaml 
    cd ..
    rm -rf harbor-helm
done

echo ===============================================
    IMAGES_NUM=$( cat /tmp/harbor-images.txt | wc -l )
    echo $IMAGES_NUM
    sort -u /tmp/harbor-images.txt -o /tmp/harbor-images.txt
    cat /tmp/harbor-images.txt

echo ===============================================

docker login --username=${ALI_DOCKER_USERNAME}  -p${ALI_DOCKER_PASSWORD} ${REGISTRY}
HARBOR_IMAGES=$( cat /tmp/harbor-images.txt )

i=0
for IMGS in $( echo ${HARBOR_IMAGES} );
do 
    i=$(( $i + 1 ))
    echo "第${i}个镜像，总共${IMAGES_NUM}个镜像。 "
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

