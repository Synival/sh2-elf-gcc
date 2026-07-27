#!/bin/bash

###################################################################
#Script Name	:   build-newlib                                                                                            
#Description	:   build newlib for the SuperH2 toolchain   
#Date           :   samedi, 4 avril 2020                                                                          
#                   Updated 28. July 2026 (version 2.46.1)
#Args           :   Welcome to the next level!                                                                                        
#Author       	:   Jacques Belosoukinski (kentosama)                                                   
#Email         	:   kentosama@genku.net                                          
###################################################################

# Don't build twice!
STAMP_FILE="${STAMP_DIR}/newlib.done"
if [ -f "${STAMP_FILE}" ]; then
    echo "newlib already compiled; skipping."
    exit
fi

VERSION="4.6.0.20260123"
ARCHIVE="newlib-${VERSION}.tar.gz"
URL="ftp://sourceware.org/pub/newlib/${ARCHIVE}"
SHA512SUM="ffa16d6465c0b429264c46395fa760fbcf072d3ff86e87330ba1f483efcfe66393ef83b03932759444a0ebeaef94d3ca58a59e91ab7b97b2a6ac6be2e7589657"
DIR="newlib-${VERSION}"

# Check if user is root
if [ ${EUID} == 0 ]; then
    echo "Please don't run this script as root"
    exit
fi

# Create build folder
mkdir ${BUILD_DIR}/${DIR}

# Move into download folder
cd ${DOWNLOAD_DIR}

# Download newlib if is needed
if ! [ -f "${ARCHIVE}" ]; then
    wget ${URL}
fi

# Extract the newlib archive if is needed
if ! [ -d "${SRC_DIR}/${DIR}" ]; then
    if [ $(sha512sum ${ARCHIVE} | awk '{print $1}') != ${SHA512SUM} ]; then
        echo "SHA512SUM verification of ${ARCHIVE} failed!"
        exit
    else
        tar -zxvf ${ARCHIVE} -C ${SRC_DIR}
    fi
fi

# Export
PREFIX=${PROGRAM_PREFIX}
export CC_FOR_TARGET=${PREFIX}gcc
export LD_FOR_TARGET=${PREFIX}ld
export AS_FOR_TARGET=${PREFIX}as
export AR_FOR_TARGET=${PREFIX}ar
export RANLIB_FOR_TARGET=${PREFIX}ranlib
export newlib_cflags="${newlib_cflags} -DPREFER_SIZE_OVER_SPEED -D__OPTIMIZE_SIZE__"

# Move into build dir
cd ${BUILD_DIR}/${DIR}

# Configure before build
${SRC_DIR}/${DIR}/configure --prefix=${INSTALL_DIR} \
                            --build=${BUILD_MACH} \
                            --host=${HOST_MACH} \
                            --target=${TARGET} \
                            --program-prefix=${PREFIX} \
                            --enable-target-optspac \
                            --enable-libssp \
                            --enable-lto \
                            --disable-newlib-supplied-syscalls \
                            --disable-nls

# Build and install newlib
make -j${NUM_PROC} 2<&1 | tee build.log

# Install newlib
if [ $? -eq 0 ]; then
    make install
fi

# Stamp!
touch ${STAMP_FILE}
