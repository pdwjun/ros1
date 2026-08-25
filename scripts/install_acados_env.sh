#!/bin/bash

set -e

# ==============================
# 基础配置
# ==============================

ACADOS_DIR=/home/gt/thirdparty/acados

export RUSTUP_DIST_SERVER=https://rsproxy.cn
export RUSTUP_UPDATE_ROOT=https://rsproxy.cn/rustup

echo "========== acados environment install =========="


# ==============================
# 1. 安装 Rust/Cargo 1.92.0
# ==============================

echo "========== Rust Setup =========="


if ! command -v rustup >/dev/null 2>&1; then

    echo "Installing rustup with Rust 1.92.0..."

    curl --proto '=https' \
         --tlsv1.2 \
         -sSf \
         https://rsproxy.cn/rustup-init.sh | \
         sh -s -- -y --default-toolchain 1.92.0

else

    echo "rustup already installed"

fi


if [ -f "$HOME/.cargo/env" ]; then
    source "$HOME/.cargo/env"
fi


rustup default 1.92.0


rustc --version
cargo --version



# ==============================
# 2. 编译 tera_renderer
# ==============================

echo "========== Build tera_renderer =========="


cd ${ACADOS_DIR}/interfaces/acados_template/tera_renderer


if [ ! -f target/release/t_renderer ]; then

    echo "Building t_renderer"

    cargo build --release

else

    echo "t_renderer already built"

fi



# 安装 t_renderer

if [ ! -f /usr/local/bin/t_renderer ]; then

    echo "Installing t_renderer"

    cp target/release/t_renderer /usr/local/bin/t_renderer
    chmod +x /usr/local/bin/t_renderer

else

    echo "t_renderer already exists"

fi


which t_renderer



# ==============================
# 3. 编译 acados C 库
# ==============================

echo "========== Build acados =========="


cd ${ACADOS_DIR}


mkdir -p build

cd build


if [ ! -f ${ACADOS_DIR}/lib/libacados.so ]; then

    echo "Building acados"

    cmake ..

    make -j$(nproc)

else

    echo "acados already built"

fi



# ==============================
# 4. 安装 acados
# ==============================

echo "========== Install acados =========="


cd ${ACADOS_DIR}/build


make install



# ==============================
# 5. 配置环境变量
# ==============================

echo "========== Setup environment =========="


cat > /etc/profile.d/acados.sh <<EOF
export ACADOS_SOURCE_DIR=${ACADOS_DIR}
EOF


chmod +x /etc/profile.d/acados.sh



# ==============================
# 6. 安装 Python acados_template
# ==============================

echo "========== Install acados_template =========="


cd ${ACADOS_DIR}/interfaces/acados_template


python3 -m pip install --upgrade pip wheel


python3 -m pip install -e .



python3 - <<EOF
from acados_template import AcadosOcpSolver
print("acados python ok")
EOF



# ==============================
# 7. 配置动态库
# ==============================

echo "========== Setup ldconfig =========="


echo "${ACADOS_DIR}/lib" > /etc/ld.so.conf.d/acados.conf


ldconfig



ldconfig -p | grep acados || true



# ==============================
# 完成
# ==============================

echo ""
echo "===================================="
echo " acados environment install finished "
echo "===================================="
