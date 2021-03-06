#!/usr/bin/bash -x

# Preprovisioned qcow image
CUSTOM_IMAGE=${CUSTOM_IMAGE:-"0"}
# Expected md5 of CUSTOM_IMAGE, in order to download just when mismatch occurs
EXPECTED_MD5=${EXPECTED_MD5:-"abc6ec90fecc86820ee8f97bdf933681"}
# Provision mode flag
PROVISION_MODE=${PROVISION_MODE:-"0"}
# yum repo file for needed packages
REPO_FILE=${REPO_FILE:-"0"}
# URL where the file is located, file will be fetched from $BASE_URL/$CUSTOM_IMAGE
BASE_URL=${BASE_URL:-"0"}
# Base image for provision mode or when no custom image supplied
BASE_IMAGE=${BASE_IMAGE:-"rhel-server-7.7-x86_64-kvm.qcow2"}
# Determines if the cluster runs within container
CONTAINER_MODE=${CONTAINER_MODE:-"1"}

CONTAINER=$(docker ps | grep kubevirt | grep $KUBEVIRT_PROVIDER | awk '{print $1}')

# Download (if needed) the image, and copy it to the container
if [ $CUSTOM_IMAGE = "0" ] || [ $PROVISION_MODE = "1" ]; then
   if [ ! -f ~/$BASE_IMAGE ]; then
       curl $BASE_URL/$BASE_IMAGE --output ~/$BASE_IMAGE
   fi

   if [ $CONTAINER_MODE = "1" ]; then
      docker exec $CONTAINER bash -c "ls /tmp/base.img"
      RET=$(echo $?)
      if [ $RET != "0" ]; then
         docker cp ~/$BASE_IMAGE $CONTAINER:/tmp/base.img
      fi
   else
      cp ~/$BASE_IMAGE /tmp/base.img
   fi
else
   if [ $CONTAINER_MODE != "1" ]; then
      echo "CUSTOM_IMAGE mode isn't supported for non containerized clusters"
      exit 1
   fi

   if [ ! -f ~/$CUSTOM_IMAGE ]; then
       curl $BASE_URL/$CUSTOM_IMAGE --output ~/$CUSTOM_IMAGE
   else
       MD5=$(md5sum ~/$CUSTOM_IMAGE | awk '{print $1}')
       if [ $MD5 != $EXPECTED_MD5 ]; then
         curl $BASE_URL/$CUSTOM_IMAGE --output ~/$CUSTOM_IMAGE
       fi
   fi
   docker exec $CONTAINER bash -c "ls /tmp/$CUSTOM_IMAGE"
   RET=$(echo $?)
   if [ $RET != "0" ]; then
     docker cp ~/$CUSTOM_IMAGE $CONTAINER:/tmp
   fi
fi

if [ $CONTAINER_MODE = "1" ]; then
   if [ -f $REPO_FILE ]; then
      docker cp $REPO_FILE $CONTAINER:/etc/yum.repos.d
   fi

   docker cp cluster-up/scale.sh $CONTAINER:/

   # Execute scale.sh in the container
   docker exec $CONTAINER chmod +x ./scale.sh
   docker exec $CONTAINER bash -c "REPO_FILE=$REPO_FILE PROVISION_MODE=$PROVISION_MODE CUSTOM_IMAGE=$CUSTOM_IMAGE ./scale.sh"
   docker exec $CONTAINER rm -rf ./scale.sh
else
   if [ -f $REPO_FILE ]; then
      cp $REPO_FILE /etc/yum.repos.d
   fi

   ./cluster-up/scale.sh
fi
