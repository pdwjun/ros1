#!/bin/bash

set -e

CERES_DIR=/home/gt/thirdparty/ceres-solver-2.1.0

echo "========== Build Ceres =========="


if [ -f /usr/local/lib/libceres.so ]; then

    echo "Ceres already installed"

    exit 0

fi


cd ${CERES_DIR}


mkdir -p build

cd build


cmake \
    -DCMAKE_BUILD_TYPE=Release \
    ..


make -j$(nproc)


make install


ldconfig


echo "========== Ceres install finished =========="


ls -lh /usr/local/lib/libceres.so
