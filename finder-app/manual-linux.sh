#!/bin/bash
# Script outline to install and build kernel.
# Author: Siddhant Jajoo.


set -u

OUTDIR=/tmp/aeld
KERNEL_REPO=git://git.kernel.org/pub/scm/linux/kernel/git/stable/linux-stable.git
KERNEL_VERSION=v5.15.163
BUSYBOX_VERSION=1_33_1
FINDER_APP_DIR=$(realpath $(dirname $0))
ARCH=arm64
CROSS_COMPILE=aarch64-none-linux-gnu-

if [ $# -lt 1 ]
then
	echo "Using default directory ${OUTDIR} for output"
else
	OUTDIR=$1
	echo "Using passed directory ${OUTDIR} for output"
fi

mkdir -p ${OUTDIR}
if [ $? -ne 0 ]; then
	echo "failed to mkdir $OUTDIR"
	exit 1
fi
cd "$OUTDIR"
if [ ! -d "${OUTDIR}/linux-stable" ]; then
    #Clone only if the repository does not exist.
	echo "CLONING GIT LINUX STABLE VERSION ${KERNEL_VERSION} IN ${OUTDIR}"
	git clone ${KERNEL_REPO} --depth 1 --single-branch --branch ${KERNEL_VERSION}
fi
if [ -e ${OUTDIR}/linux-stable/arch/${ARCH}/boot/Image ]; then
	echo "Image exists, no build needed"
fi
if [ ! -e ${OUTDIR}/linux-stable/arch/${ARCH}/boot/Image ]; then
    cd linux-stable
    echo "Checking out version ${KERNEL_VERSION}"
    git checkout ${KERNEL_VERSION}

    # TODO: Add your kernel build steps here
    make CROSS_COMPILE=$CROSS_COMPILE ARCH=$ARCH mrproper #clean .config
    make CROSS_COMPILE=$CROSS_COMPILE ARCH=$ARCH defconfig 
    echo "building kernel for $ARCH with ${CROSS_COMPILE}"

    make -j $(nproc) CROSS_COMPILE=$CROSS_COMPILE ARCH=$ARCH 
    cp ${OUTDIR}/linux-stable/arch/${ARCH}/boot/Image ${OUTDIR}/
fi

echo "Adding the Image in outdir"

echo "Creating the staging directory for the root filesystem"
cd "$OUTDIR"
if [ -d "${OUTDIR}/rootfs" ]
then
	echo "Deleting rootfs directory at ${OUTDIR}/rootfs and starting over"
    sudo rm  -rf ${OUTDIR}/rootfs
fi

# TODO: Create necessary base directories

mkdir ${OUTDIR}/rootfs && cd ${OUTDIR}/rootfs
if [ $? -ne 0 ] ; then
	echo "fail create rootfs"
	exit 1
fi
mkdir -p bin dev etc home lib lib64 proc sbin sys tmp usr var

if [ $? -ne 0 ] ; then
	echo "directories for rootfs fail creation"
	exit 1
fi

mkdir -p usr/bin usr/lib usr/sbin

if [ $? -ne 0 ] ; then
	echo "fail create usr/ dirs"
	exit 1
fi

mkdir -p var/log

if [ $? -ne 0 ] ; then
	echo "fail create var/log"
	exit 1
fi

cd "$OUTDIR"
if [ ! -d "${OUTDIR}/busybox" ]
then
git clone git://busybox.net/busybox.git
    cd busybox
    git checkout ${BUSYBOX_VERSION}

else
    cd busybox
fi

# TODO: Make and install busybox
make distclean #clean config

if [ $? -ne 0 ] ; then
   echo "fail make mrproper"
fi

make defconfig

if [ $? -ne 0 ] ; then
   echo "fail make mrproper"
fi

make CROSS_COMPILE=${CROSS_COMPILE} ARCH=${ARCH}

if [ $? -ne 0 ] ; then
    echo "fail make"
fi

make CROSS_COMPILE=${CROSS_COMPILE} ARCH=${ARCH} install CONFIG_PREFIX=${OUTDIR}/rootfs

if [ $? -ne 0 ] ; then
    echo "fail make busybox"
fi

mv busybox ${OUTDIR}/rootfs/bin/

if [ $? -ne 0 ] ; then
    echo "fail mv busybox"
fi

echo "Library dependencies"
data=$(${CROSS_COMPILE}readelf -a ${OUTDIR}/rootfs/bin/busybox | grep "program interpreter" | awk  '{print $4}' | cut -d"]" -f1)
interpreter=${data:5}
	path=$(find / -name "$interpreter" -type f 2>/dev/null)

	#echo $path
	cp $path ${OUTDIR}/rootfs/lib/
	if [ $? -ne 0 ] ; then
		echo "failed cp"
	fi
	if [ ! -f ${OUTDIR}/rootfs/lib/${interpreter} ] ; then
		echo "file not found"
	fi

data=$(${CROSS_COMPILE}readelf -a ${OUTDIR}/rootfs/bin/busybox | grep "Shared library" | cut -d"[" -f2 | cut -d"]" -f1) # TODO: Add library dependencies to rootfs

arr=($data)
len=${#arr[@]}
path=$(dirname $path)
#echo $path
i=0
for ((i = 0; i < len; i++))
do
	echo ${arr[i]}
	lib=$(find $path/../ -type f -name ${arr[i]} 2>/dev/null)
	basename=$(basename $lib)
	echo "${lib}"
	cp $lib ${OUTDIR}/rootfs/lib64/

	if [ ! -f ${OUTDIR}/rootfs/lib64/${basename} ]; then
		echo "${basename} not found"
	fi
done

# TODO: Make device nodes
sudo mknod -m 666 $OUTDIR/rootfs/dev/null c 1 3
sudo mknod -m 600 $OUTDIR/rootfs/dev/console c 5 1
# TODO: Clean and build the writer utility
cd $FINDER_APP_DIR && make clean
make CROSS_COMPILER=aarch64-none-linux-gnu-
# TODO: Copy the finder related scripts and executables to the /home directory
# on the target rootfs
cp writer finder.sh $OUTDIR/rootfs/home/
# TODO: Chown the root directory
sudo chown root $OUTDIR/rootfs/ 
# TODO: Create initramfs.cpio.gz
cd $OUTDIR/rootfs
find . | cpio -H newc -ov --owner root:root > ${OUTDIR}/initramfs.cpio
if [ ! -f ${OUTDIR}/initramfs.cpio ]  ; then
	echo "fail initramfs"
fi
cd ..
gzip -f initramfs.cpio
