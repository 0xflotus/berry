#!/usr/bin/env bash

set -e

THIS_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

ZLIB_VERSION=1.2.11
LIBZIP_VERSION=1.5.1

[[ -f ./zlib-"$ZLIB_VERSION"/libz.a ]] || (
    cd "$THIS_DIR"

    if ! [[ -e zlib-"$ZLIB_VERSION".tar.gz ]]; then
        wget -O ./zlib-"$ZLIB_VERSION".tar.gz "http://zlib.net/zlib-$ZLIB_VERSION.tar.gz"
    fi

    if ! [[ -e zlib-"$ZLIB_VERSION" ]]; then
        tar xvf ./zlib-"$ZLIB_VERSION".tar.gz
    fi

    cd "$THIS_DIR"/zlib-"$ZLIB_VERSION"

    source ~/emsdk-portable/emsdk_env.sh

    emcmake cmake -Wno-dev .
    emmake make zlibstatic
)

[[ -f ./libzip-"$LIBZIP_VERSION"/lib/libzip.a ]] || (
    cd "$THIS_DIR"

    if ! [[ -e libzip-"$LIBZIP_VERSION".tar.gz ]]; then
        wget -O ./libzip-"$LIBZIP_VERSION".tar.gz "https://libzip.org/download/libzip-$LIBZIP_VERSION.tar.gz"
    fi

    if ! [[ -e libzip-"$LIBZIP_VERSION" ]]; then
        tar xvf ./libzip-"$LIBZIP_VERSION".tar.gz
    fi

    cd "$THIS_DIR"/libzip-"$LIBZIP_VERSION"

    source ~/emsdk-portable/emsdk_env.sh

    emcmake cmake -Wno-dev -DBUILD_SHARED_LIBS=OFF -DENABLE_GNUTLS=OFF -DENABLE_OPENSSL=OFF -DENABLE_COMMONCRYPTO=OFF -DZLIB_LIBRARY="$THIS_DIR"/zlib-"$ZLIB_VERSION"/libz.a -DZLIB_INCLUDE_DIR="$THIS_DIR"/zlib-"$ZLIB_VERSION" .
    emmake make zip
)

(
    cd "$THIS_DIR"

    source ~/emsdk-portable/emsdk_env.sh

    emcc \
        -o ../sources/libzip.js \
        -s WASM=1 \
        -s EXPORTED_FUNCTIONS="$(cat ./exported.json)" \
        -s EXTRA_EXPORTED_RUNTIME_METHODS='["FS", "cwrap", "getValue"]' \
        -s ALLOW_MEMORY_GROWTH=1 \
        -s BINARYEN_ASYNC_COMPILATION=0 \
        --pre-js ../sources/shell.pre.js \
        -I./libzip-"$LIBZIP_VERSION"/lib \
        -I./libzip-"$LIBZIP_VERSION" \
        -O3 \
        ./zipstruct.c \
        ./libzip-"$LIBZIP_VERSION"/lib/libzip.a \
        ./zlib-"$ZLIB_VERSION"/libz.a
)