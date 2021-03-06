#!/bin/bash
set -e

TARGET_ROS_VERSION=melodic

if [ ! -e ./aero-ros-pkg ]; then
    git clone https://github.com/seed-solutions/aero-ros-pkg.git
fi
#(cd aero_ros_pkg; git checkout -b for_docker origin/fix_travis)

if [ "$TARGET_ROS_VERSION" == "melodic" ]; then
    cp aero-ros-pkg/Dockerfile.melodic Dockerfile.aero
    TARGET_UBUNTU_VERSION=18.04
elif [ "$TARGET_ROS_VERSION" == "kinetic" ]; then
    cp aero-ros-pkg/Dockerfile.kinetic Dockerfile.aero
    sed -i -e 's@FROM ros:kinetic-robot@FROM yoheikakiuchi/ros_gl:16.04@' Dockerfile.aero
    TARGET_UBUNTU_VERSION=16.04
fi

## change build type
sed -i -e 's@./setup.sh typeF@./setup.sh typeFCESy@' Dockerfile.aero
cat <<EOF >> Dockerfile.aero
### add by robot-simulation-docker
ADD ./my_entrypoint.sh /
ENTRYPOINT ["/my_entrypoint.sh"]
CMD ["bash"]

# nvidia-container-runtime
ENV NVIDIA_VISIBLE_DEVICES \
        ${NVIDIA_VISIBLE_DEVICES:-all}
ENV NVIDIA_DRIVER_CAPABILITIES \
        ${NVIDIA_DRIVER_CAPABILITIES:+$NVIDIA_DRIVER_CAPABILITIES,}graphics,compat32,utility

# Required for non-glvnd setups.
ENV LD_LIBRARY_PATH /usr/lib/x86_64-linux-gnu:/usr/lib/i386-linux-gnu${LD_LIBRARY_PATH:+:${LD_LIBRARY_PATH}}
EOF

cp my_entrypoint.sh aero-ros-pkg

if [ "$TARGET_ROS_VERSION" == "kinetic" ]; then
    docker build -f ../ros_gl/Dockerfile.ros_gl  --tag=yoheikakiuchi/ros_gl:16.04 .
fi

docker build -f Dockerfile.aero    --tag=yoheikakiuchi/aero-ros-pkg:${TARGET_UBUNTU_VERSION} aero-ros-pkg

### TODO add Dockerfile.aero_eus for euslisp interface
