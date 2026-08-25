FROM --platform=linux/arm64 arm64v8/ros:noetic

ARG user_id=1000
ENV USERNAME=gt
ENV DEBIAN_FRONTEND=noninteractive
RUN echo 'debconf debconf/frontend select Noninteractive' | debconf-set-selections

RUN sed -i 's|http://ports.ubuntu.com/ubuntu-ports|http://mirrors.tuna.tsinghua.edu.cn/ubuntu-ports|g' /etc/apt/sources.list
RUN apt update

RUN apt -y install bash-completion \
    git \
    ros-noetic-serial* \
    ros-noetic-gtsam* \
    ros-noetic-jsk-recognition-msgs \
    ros-noetic-grid-map* \
    ros-noetic-tf2-sensor* \
    ros-noetic-base-local* \
    ros-noetic-mbf-costmap* \
    ros-noetic-control-box-rst \
    ros-noetic-ddynamic-reconfigure* \
    ros-noetic-teb-local-planner \
    ros-noetic-libuvc-camera \
    ros-noetic-geographic-* \
    ros-noetic-map-server* \
    ros-noetic-spatio-temporal-voxel-layer \
    ros-noetic-rtcm-msgs \
    ros-noetic-nmea-msgs \
    ros-noetic-nmea-navsat-driver 
RUN apt -y install libopenvdb-dev \
    libpcap-dev \
    libv4l-dev \
    libcppunit-dev \
    libflann-dev \
    libgmp-dev \
    libmpfr-dev \
    libcgal-dev \
    coinor-libipopt-dev \
    libadolc-dev \
    libgoogle-glog-dev \
    libgflags-dev \
    lm-sensors \
    libeigen3-dev \
    nlohmann-json3-dev=3.7.3-1 \
    ros-noetic-py-trees \
    ros-noetic-py-trees-ros \
    ros-noetic-py-trees-msgs \
    libsdl2-dev 
RUN apt -y install ros-noetic-rosbag-snapshot-msgs \
    bpfcc-tools \
    xserver-xorg-core-hwe-18.04 \
    xserver-xorg-video-dummy \
    libopenblas-dev \
    pip \
    ros-noetic-eigen-conversions \
    ros-noetic-image-geometry \
    ros-noetic-jsk-rviz-plugins \
    libspdlog-dev \
    libompl-dev \
    ros-noetic-xacro \
    ros-noetic-roslint \
    libyaml-cpp-dev libcurl4-openssl-dev libgeographic-dev \
    openssh-server g++ gdb make ninja-build rsync zip gdbserver \
    vim net-tools iputils-ping 
    
RUN pip config set global.index-url https://pypi.tuna.tsinghua.edu.cn/simple
# Python 3.8：必须先升级 pip。系统 pip 20 + packaging 24 会在解析
# 非 PEP440 版本号（如 0.1dev-r1556）时直接崩溃
RUN python3 -m pip install --no-cache-dir --upgrade "pip<24.1" "wheel<0.45"
RUN python3 -m pip install --no-cache-dir \
    pyserial \
    pynvml \
    tornado \
    websocket-client \
    pymap3d \
    opencv-python \
    easydict \
    sentry-cli \
    sentry-sdk \
    boto3 \
    objgraph \
    cos-python-sdk-v5==1.9.31 \
    setuptools==74.1.3 \
    importlib-metadata==6.11.0 \
    packaging==24.2 \
    prometheus_client==0.21.1 \
    catkin_pkg==1.0.0 
    
RUN python3 -m pip install --no-cache-dir \
    ipdb==0.13.13 \
    matplotlib==3.7.2 \
    motmetrics==1.4.0 \
    numpy==1.24.4 \
    onnx==1.14.0 \
    pandas==2.0.3 \
    psutil==5.9.5 \
    PyYAML==6.0.2 \
    Requests==2.32.3 \
    seaborn==0.13.2 \
    pythonping==1.1.4 \
    websockets==13.1 \
    gitpython==3.1.44 \
    icmplib==3.0.4

# 创建用户
RUN useradd -U \
    --uid ${user_id} \
    -G sudo \
    -ms /bin/bash \
    ${USERNAME} \
 && echo "${USERNAME}:guoteng123" | chpasswd \
 && echo "${USERNAME} ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

# 配置用户bash环境
RUN echo "source /opt/ros/noetic/setup.bash" >> /home/${USERNAME}/.bashrc && \
    echo "export MOWER_MODEL='MS4_0'" >> /home/${USERNAME}/.bashrc && \
    echo "export GT_ENV='test'" >> /home/${USERNAME}/.bashrc && \
    echo "export GT_REGION='gotengrobo'" >> /home/${USERNAME}/.bashrc && \
    echo "export GT_WORK_PATH='/home/${USERNAME}/mower-ws'" >> /home/${USERNAME}/.bashrc && \
    echo "export ROSOUT_DISABLE_FILE_LOGGING='True'" >> /home/${USERNAME}/.bashrc && \
    echo "export ACADOS_SOURCE_DIR='/usr/local'" >> /home/${USERNAME}/.bashrc && \
    echo "export DEVICE_ID='9K2BYxz79'" >> /home/${USERNAME}/.bashrc && \
    chown ${USERNAME}:${USERNAME} /home/${USERNAME}/.bashrc

# ==============================
# 拷贝第三方源码
# ==============================

RUN mkdir -p /home/gt/thirdparty

COPY acados.zip /home/gt/thirdparty/
COPY ceres-solver-2.1.0.zip /home/gt/thirdparty/


# 解压第三方源码

RUN cd /home/gt/thirdparty && \
    unzip acados.zip && \
    unzip ceres-solver-2.1.0.zip && \
    rm -f acados.zip ceres-solver-2.1.0.zip



# ==============================
# 拷贝安装脚本
# ==============================

COPY scripts/install_acados_env.sh /home/gt/
COPY scripts/install_ceres.sh /home/gt/


RUN chmod +x \
        /home/gt/install_acados_env.sh \
        /home/gt/install_ceres.sh



# ==============================
# 安装 acados
# ==============================

RUN /home/gt/install_acados_env.sh



# ==============================
# 安装 ceres
# ==============================

RUN /home/gt/install_ceres.sh



# ==============================
# 设置权限
# ==============================

RUN chown -R gt:gt /home/gt/thirdparty

# ==============================
# 环境变量
# ==============================

RUN echo "export ACADOS_SOURCE_DIR=/home/${USERNAME}/thirdparty/acados" \
    >> /home/${USERNAME}/.bashrc
    
# 后续默认使用gt用户
USER ${USERNAME}

WORKDIR /home/${USERNAME}

#EXPOSE 22
