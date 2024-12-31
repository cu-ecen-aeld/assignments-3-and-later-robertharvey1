#!/bin/bash
# Script outline to install and build kernel.
# Author: Siddhant Jajoo.

# Removed cross compiler from source tree and redeployed for runner

set -e
set -u


OUTDIR=/tmp/aeld
KERNEL_REPO=git://git.kernel.org/pub/scm/linux/kernel/git/stable/linux-stable.git
KERNEL_VERSION=v5.15.163
BUSYBOX_VERSION=1_33_1
FINDER_APP_DIR=$(realpath $(dirname $0))
ARCH=arm64

#added below to path so relative CROSS_COMPILE directory is found
#CROSS_COMPILE=/home/robert/CrossCompilers/arm-gnu-toolchain-13.3.rel1-x86_64-aarch64-none-linux-gnu/bin/aarch64-none-linux-gnu-
CROSS_COMPILE=aarch64-none-linux-gnu-

if [ $# -lt 1 ]
then
	echo "Using default directory ${OUTDIR} for output"
else
	OUTDIR=$1
	echo "Using passed directory ${OUTDIR} for output"
fi

mkdir -p ${OUTDIR}

cd "$OUTDIR"
if [ ! -d "${OUTDIR}/linux-stable" ]; then
    #Clone only if the repository does not exist.
	echo "CLONING GIT LINUX STABLE VERSION ${KERNEL_VERSION} IN ${OUTDIR}"
	git clone ${KERNEL_REPO} --depth 1 --single-branch --branch ${KERNEL_VERSION}
fi
if [ ! -e ${OUTDIR}/linux-stable/arch/${ARCH}/boot/Image ]; then
    cd linux-stable
    echo "Checking out version ${KERNEL_VERSION}"
    git checkout ${KERNEL_VERSION}

    # TODO: Add your kernel build steps here
    echo "----> kernel build steps"
    make ARCH=${ARCH} CROSS_COMPILE=${CROSS_COMPILE} mrproper
    make ARCH=${ARCH} CROSS_COMPILE=${CROSS_COMPILE} defconfig
    make -j4 ARCH=${ARCH} CROSS_COMPILE=${CROSS_COMPILE} all
    #make ARCH=${ARCH} CROSS_COMPILE=${CROSS_COMPILE} modules -- Dont need
    make ARCH=${ARCH} CROSS_COMPILE=${CROSS_COMPILE} dtbs
fi

echo "----> Adding the Image in outdir"
    cp -f "${OUTDIR}/linux-stable/arch/${ARCH}/boot/Image" "${OUTDIR}/"

echo "----> Creating the staging directory for the root filesystem"
cd "$OUTDIR"
if [ -d "${OUTDIR}/rootfs" ]
then
	echo "Deleting rootfs directory at ${OUTDIR}/rootfs and starting over"
    sudo rm  -rf ${OUTDIR}/rootfs
fi

# TODO: Create necessary base directories
mkdir rootfs
cd "${OUTDIR}/rootfs"
mkdir -p bin dev etc home lib lib64 proc sbin sys tmp usr var
mkdir -p usr/bin usr/lib usr/sbin
mkdir -p var/log

cd "$OUTDIR"
if [ ! -d "${OUTDIR}/busybox" ]
then
git clone git://busybox.net/busybox.git
    cd busybox
    git checkout ${BUSYBOX_VERSION}
    # TODO:  Configure busybox
    make distclean  # Deletes everything created by make (generated files) and remove the configuration.
    make defconfig # Generates a new config with default from the ARCH supplied defconfig file. Use this option to get back the default configuration file that came with the sources.
else
    cd busybox
fi

# TODO: Make and install busybox
make ARCH=${ARCH} CROSS_COMPILE=${CROSS_COMPILE}
make CONFIG_PREFIX="${OUTDIR}/rootfs" ARCH=${ARCH} CROSS_COMPILE=${CROSS_COMPILE} install

echo "----> Library dependencies"
cd ${OUTDIR}/rootfs
${CROSS_COMPILE}readelf -a bin/busybox | grep "program interpreter"
${CROSS_COMPILE}readelf -a bin/busybox | grep "Shared library"

# TODO: Add library dependencies to rootfs
MYSYSROOT=$(${CROSS_COMPILE}gcc --print-sysroot)
ARM32LIBS=$(${CROSS_COMPILE}readelf -a ${OUTDIR}/rootfs/bin/busybox | grep "Shared library" | awk -F'[][]' '{print $2}')
for LIB in ${ARM32LIBS}; do
    LIB_PATH=$(find ${MYSYSROOT} -name "$LIB")
    if [ -n "$LIB_PATH" ]
    then
        cp $LIB_PATH ${OUTDIR}/rootfs/lib64/
        cp $LIB_PATH ${OUTDIR}/rootfs/lib/
    else
        echo "Library $LIB not found!"
    fi	
done

cp ${MYSYSROOT}/lib/ld-linux-aarch64.so.1 ${OUTDIR}/rootfs/lib/
cp ${MYSYSROOT}/lib64/libm.so.6 ${OUTDIR}/rootfs/lib64
cp ${MYSYSROOT}/lib64/libresolv.so.2 ${OUTDIR}/rootfs/lib64
cp ${MYSYSROOT}/lib64/libc.so.6 ${OUTDIR}/rootfs/lib64

# TODO: Make device nodes
# see https://www.kernel.org/doc/Documentation/admin-guide/devices.txt
echo "Make device nodes"
sudo mknod -m 666 dev/null c 1 3 # Null device
sudo mknod -m 666 dev/console c 5 1 #System console N.B. (5,1) is /dev/console starting with Linux 2.1.71. 

# TODO: Clean and build the writer utility
echo "Clean and build the writer utility"
cd ${FINDER_APP_DIR}
make cleancd ../
make CROSS_COMPILE=${CROSS_COMPILE}

# TODO: Copy the finder related scripts and executables to the /home directory
# on the target rootfs
echo "Copy the finder related scripts and executables to the /home directory"
cd ${FINDER_APP_DIR}
cp ${FINDER_APP_DIR}/finder.sh "${OUTDIR}/rootfs/home/"
cp ${FINDER_APP_DIR}/autorun-qemu.sh "${OUTDIR}/rootfs/home/"
cp ${FINDER_APP_DIR}/finder-test.sh "${OUTDIR}/rootfs/home/"

mkdir "${OUTDIR}/rootfs/home/conf"
cp ${FINDER_APP_DIR}/conf/assignment.txt "${OUTDIR}/rootfs/home/conf/"
cp ${FINDER_APP_DIR}/conf/username.txt "${OUTDIR}/rootfs/home/conf/"

echo "Cross compile writer to the target as simply copying the executable does not seem to work ???"
#cp ${FINDER_APP_DIR}/writer "${OUTDIR}/rootfs/home/"
${CROSS_COMPILE}gcc -o ${OUTDIR}/rootfs/home/writer writer.c


# TODO: Chown the root directory
echo "Chown the root directory"
cd "${OUTDIR}/rootfs"
sudo chown -R root:root *

# TODO: Create initramfs.cpio.gz
echo "Create initramfs.cpio.gz"
find . | cpio -H newc -ov --owner root:root > "${OUTDIR}/initramfs.cpio"
cd ../
gzip -f initramfs.cpio
