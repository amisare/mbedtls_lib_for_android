#!/bin/sh
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

VERSION_TAG="2.16.0"

create_directory() {
    rm -rf build/*
    rm -rf target/*
    mkdir -p build
    mkdir -p target/mbedtls/lib
    mkdir -p target/mbedtls/include
}

fetch_mbedtls() {
    git clone https://github.com/ARMmbed/mbedtls.git mbedtls
    git -C mbedtls checkout ${VERSION_TAG}
}

run_cmake() {

    ANDROID_NDK=$1
    ANDROID_ABI=$2

    # clean cmake cache
    find . -iname '*cmake*' -not -name CMakeLists.txt -exec rm -rf {} +
    cmake -DCMAKE_TOOLCHAIN_FILE=../toolchain/android.toolchain.cmake -DANDROID_NDK=${ANDROID_NDK} -DANDROID_TOOLCHAIN=gcc -DANDROID_STL=gnustl_shared -DANDROID_ABI=${ANDROID_ABI} -DUSE_STATIC_MBEDTLS_LIBRARY=OFF -DENABLE_PROGRAMS=OFF -DENABLE_TESTING=OFF -DINSTALL_MBEDTLS_HEADERS=OFF -DUSE_SHARED_MBEDTLS_LIBRARY=ON ../mbedtls
}

main_func() {

    ANDROID_NDK=$1

    if [ $# -ne 1 ]; then
        echo "$0 ERROR: need 1 params, path of android ndk (ndk-bundle)"
        return 1
    fi

    create_directory
    fetch_mbedtls

    cd build

    ARCHS="armeabi-v7a arm64-v8a x86 x86_64 mips mips64"
    for arch in ${ARCHS}
    do
        run_cmake ${ANDROID_NDK} ${arch}
        make
        mkdir -p ${DIR}/target/mbedtls/lib/${arch}
        cp -Rf ${DIR}/build/library/libmbe* ${DIR}/target/mbedtls/lib/${arch}
        make clean
    done
    cp -Rf ${DIR}/build/include/mbedtls/* ${DIR}/target/mbedtls/include
}

ANDROID_NDK=$1
main_func ${ANDROID_NDK}