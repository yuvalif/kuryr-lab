#!/bin/bash

set -e

if [ "$#" -ne 2 ]; then
    echo "Usage: $0 <hostname> <cluster-name>"
    exit 1
fi

set -x

NAME=$1
CLUSTER=$2
HOST=$1.$2
OSVERSION=centos-7.5
OSVARIANT=centos7.0
ARCHITECTURE=x86_64
DISK_SIZE=20G
CPUS=2
RAM=8192
POOL=vms
POOL_DIR=~/${POOL}
IMAGE_FILE=${NAME}-${OSVERSION}-${ARCHITECTURE}-sda.qcow2

set +x

# build the vm pool if does not exists
mkdir -p ${POOL_DIR}

if [ ! -f ${POOL_DIR}/${IMAGE_FILE} ]; then
    # build an image file and store into a local "vms" pool
    virt-builder ${OSVERSION} -o ${POOL_DIR}/${IMAGE_FILE} \
        --no-network --format qcow2 --arch ${ARCHITECTURE} --size ${DISK_SIZE} --root-password=password:centos \
        --hostname ${HOST}
fi

# refresh the pool
virsh pool-refresh vms 

# installl Fedora28 in that image
# "hostpassthrough is defined so that nested VMs will be supported
# "import" option to bypass actuall install
# "extra-args" to allocate static IP
virt-install -n ${NAME}-${OSVERSION}-${ARCHITECTURE} --vcpus ${CPUS} --cpu host-passthrough,cache.mode=passthrough \
    --arch ${ARCHITECTURE} --memory ${RAM} --import --os-variant ${OSVARIANT} --controller scsi,model=virtio-scsi \
    --disk vol=${POOL}/${IMAGE_FILE},device=disk,bus=scsi,discard=unmap \
    --network network=default,model=virtio \
    --graphics spice --channel unix,name=org.qemu.guest_agent.0 --noautoconsole --noreboot
