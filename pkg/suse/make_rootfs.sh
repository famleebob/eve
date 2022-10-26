#! /bin/bash -x

# Create the rootfs tar file from an existing container
# based on https://iximiuz.com/en/posts/docker-image-to-filesystem/

docker pull --platform linux/amd64 $1
CONT_ID=$(docker create --platform linux/amd64 $1)
docker export ${CONT_ID} -o suse-rootfs.tar
# docker stop ${CONT_ID}
docker rmi $1 
