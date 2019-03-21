#!/bin/bash 

NS=rancher
RANCHER_VERSION=v2.1.7

ALI_DOCKER_USERNAME=$ALI_DOCKER_USERNAME
ALI_DOCKER_PASSWORD=$ALI_DOCKER_PASSWORD

REGISTRY=registry.cn-shanghai.aliyuncs.com

IMAGES=$( curl -L https://github.com/rancher/rancher/releases/download/${RANCHER_VERSION}/rancher-images.txt )

docker login --username=${ALI_DOCKER_USERNAME}  -p${ALI_DOCKER_PASSWORD} ${REGISTRY}

for IMGS in $( echo ${IMAGES} );
do 
    cp -rf Dockerfile.template  Dockerfile
    sed -i  "s@IMGS@${IMGS}@"  Dockerfile

    docker build -t ${IMGS} .
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

images_list="kubernetes-dashboard,k8s-dns-sidecar,k8s-dns-kube-dns,k8s-dns-dnsmasq-nanny,heapster-grafana,heapster-influxdb,heapster,pause,tiller"
images_arch=amd64
images_namespace=rancher

docker_push ()
{
    gcr_namespace=$1
    img_tag=$2
    rancher_namespace=$3

    docker pull gcr.io/${gcr_namespace}/${img_tag}
    docker tag gcr.io/${gcr_namespace}/${img_tag} ${REGISTRY}/${rancher_namespace}/${img_tag}
    docker push ${REGISTRY}/${rancher_namespace}/${img_tag}

    if [ $? -ne 0 ]; then
        logger "synchronized the ${rancher_namespace}/${img_tag} failed."
        exit -1
    else
        logger "synchronized the ${rancher_namespace}/${img_tag} successfully."
        return 0
    fi
}

sync_images_with_arch ()
{
    img_list=$1
    img_arch=$2
    img_namespace=$3

    for imgs in $(echo ${img_list} | tr "," "\n");
    do
        if [ "x${imgs}" == "xtiller" ]; then
            kube_tags=$(curl -k -s -X GET https://gcr.io/v2/kubernetes-helm/${imgs}/tags/list | jq -r '.tags[]'|sort -r)
            rancher_result=$(curl -k -s -X GET https://registry.hub.docker.com/v2/repositories/${img_namespace}/${imgs}/tags/ | jq '.["detail"]' | sed 's/\"//g' | awk '{print $2}')

            if [ "x${rancher_result}" == "xnot" ]; then
                for tags in ${kube_tags}
                do
                    docker_push "kubernetes-helm" ${imgs}:${tags} ${img_namespace}
                done
            else
                rancher_tags=$(curl -k -s -X GET https://registry.hub.docker.com/v2/repositories/${img_namespace}/${imgs}/tags/?page_size=1000 | jq '."results"[]["name"]' |sort -r |sed 's/\"//g' )
                for tags in ${kube_tags}
                do
                    if echo "${rancher_tags[@]}" | grep -w "${tags}" &>/dev/null; then
                        logger "The image ${imgs}:${tags} has been synchronized and skipped."
                    else
                        docker_push "kubernetes-helm" ${imgs}:${tags} ${img_namespace}
                    fi
                done
            fi
        else
            kube_tags=$(curl -k -s -X GET https://gcr.io/v2/google_containers/${imgs}-${img_arch}/tags/list | jq -r '.tags[]'|sort -r)
            rancher_result=$(curl -k -s -X GET https://registry.hub.docker.com/v2/repositories/${img_namespace}/${imgs}-${img_arch}/tags/ | jq '.["detail"]' | sed 's/\"//g' | awk '{print $2}')

            if [ "x${rancher_result}" == "xnot" ]; then
                for tags in ${kube_tags}
                do
                    docker_push "google_containers" ${imgs}-${img_arch}:${tags} ${img_namespace}
                done
            else
                rancher_tags=$(curl -k -s -X GET https://registry.hub.docker.com/v2/repositories/${img_namespace}/${imgs}-${img_arch}/tags/?page_size=1000 | jq '."results"[]["name"]' |sort -r |sed 's/\"//g' )
                for tags in ${kube_tags}
                do
                    if  echo "${rancher_tags[@]}" | grep -w "${tags}" &>/dev/null; then
                        logger "The image ${imgs}-${img_arch}:${tags} has been synchronized and skipped."
                    else
                        docker_push "google_containers" ${imgs}-${img_arch}:${tags} ${img_namespace}
                    fi
                done
            fi
        fi
    done

    logger 'Completed to synchronize.'

    return 0
}

sync_images_with_arch ${images_list} ${images_arch} ${images_namespace}

