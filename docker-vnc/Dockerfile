# VNC/noVNC browser desktop base for ROS 2 Jazzy
FROM ghcr.io/tiryoh/ros2-desktop-vnc:jazzy

SHELL ["/bin/bash","-lc"]
ENV DEBIAN_FRONTEND=noninteractive
# Default resolution for the noVNC desktop (can override in compose)
ENV RESOLUTION=1440x900
# Default DDS + domain (can override in compose)
ENV RMW_IMPLEMENTATION=rmw_fastrtps_cpp
ENV ROS_DOMAIN_ID=42

# --- RealSense userspace (copy from prebuilt image to avoid source build) ---
FROM robotis/ros:jazzy-ros-base-librealsense AS librealsense

FROM ghcr.io/tiryoh/ros2-desktop-vnc:jazzy AS app
SHELL ["/bin/bash","-lc"]
ENV DEBIAN_FRONTEND=noninteractive

# Bring in librealsense libs + Python bindings + (optional) udev rules
COPY --from=librealsense /opt/librealsense /usr/local/
COPY --from=librealsense /usr/local/lib/python3.12/dist-packages/pyrealsense2 /usr/local/lib/python3.12/dist-packages/pyrealsense2
# Udev rules inside containers are typically a no-op; host rules are preferred.
COPY --from=librealsense /usr/src/librealsense/config/99-realsense-libusb.rules /etc/udev/rules.d/
COPY --from=librealsense /usr/src/librealsense/config/99-realsense-d4xx-mipi-dfu.rules /etc/udev/rules.d/
ENV PYTHONPATH=/usr/local/lib/python3.12/dist-packages:${PYTHONPATH}

# Core tools + Gazebo Harmonic + ros2_control stack
RUN apt-get update && apt-get install -y --no-install-recommends \
    git vim nano \
    python3-colcon-common-extensions \
    libusb-1.0-0-dev libglfw3-dev \
    ros-jazzy-ros-gz-sim \
    ros-jazzy-ros-gz-bridge \
    ros-jazzy-ros2-control ros-jazzy-ros2-controllers \
    ros-jazzy-control-msgs \
    ros-jazzy-joint-state-broadcaster \
    ros-jazzy-joint-trajectory-controller \
    && rm -rf /var/lib/apt/lists/*

# Workspace layout
ENV COLCON_WS=/home/ubuntu/omx_ws
WORKDIR ${COLCON_WS}
RUN mkdir -p ${COLCON_WS}/src /home/ubuntu/logs && sudo chown -R ubuntu:ubuntu /home/ubuntu
USER ubuntu

# Source clones (pinned)
RUN cd ${COLCON_WS}/src && \
    git clone -b jazzy https://github.com/ROBOTIS-GIT/dynamixel_hardware_interface.git && \
    git clone -b jazzy https://github.com/ROBOTIS-GIT/dynamixel_interfaces.git && \
    git clone -b jazzy https://github.com/ROBOTIS-GIT/DynamixelSDK.git && \
    git clone -b jazzy https://github.com/ROBOTIS-GIT/open_manipulator.git && \
    git clone -b r/4.56.4 https://github.com/IntelRealSense/realsense-ros.git && \
    cd realsense-ros && git checkout cbd8b8487d4c0126bb590822db9469414496e62a

USER root
# rosdep + build
RUN sudo apt-get update && rosdep update && \
    rosdep install -i --from-path src --rosdistro jazzy --skip-keys="librealsense2" -y && \
    rm -rf /var/lib/apt/lists/* && \
    source /opt/ros/jazzy/setup.bash && \
    colcon build --symlink-install --cmake-args -DCMAKE_BUILD_TYPE=Release

# QoL shell
RUN echo 'source /opt/ros/jazzy/setup.bash' >> ~/.bashrc && \
    echo 'source ~/omx_ws/install/setup.bash' >> ~/.bashrc && \
    echo 'alias cb="colcon build --symlink-install --cmake-args -DCMAKE_BUILD_TYPE=Release"' >> ~/.bashrc && \
    echo 'export RMW_IMPLEMENTATION=${RMW_IMPLEMENTATION:-rmw_fastrtps_cpp}' >> ~/.bashrc && \
    echo 'export ROS_DOMAIN_ID=${ROS_DOMAIN_ID:-42}' >> ~/.bashrc && \
    echo 'unset ROS_LOCALHOST_ONLY' >> ~/.bashrc

WORKDIR /home/ubuntu
CMD ["bash"]
