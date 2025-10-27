# OpenMANIPULATOR-X noVNC Docker - Browser-based ROS 2 Jazzy Development
# Multi-stage build: First get pre-built librealsense, then add to noVNC image

# Stage 1: Get pre-built librealsense from ROBOTIS image
FROM robotis/ros:jazzy-ros-base-librealsense AS librealsense

# Stage 2: Build on top of noVNC desktop image
FROM ghcr.io/tiryoh/ros2-desktop-vnc:jazzy

# Switch to root for installations
USER root

# Copy pre-built librealsense from ROBOTIS image
COPY --from=librealsense /opt/librealsense /usr/local/
COPY --from=librealsense /usr/local/lib/python3.12/dist-packages/pyrealsense2 /usr/local/lib/python3.12/dist-packages/pyrealsense2
COPY --from=librealsense /usr/src/librealsense/config/99-realsense-libusb.rules /etc/udev/rules.d/
COPY --from=librealsense /usr/src/librealsense/config/99-realsense-d4xx-mipi-dfu.rules /etc/udev/rules.d/
ENV PYTHONPATH=$PYTHONPATH:/usr/local/lib

# Set environment variables
ENV DEBIAN_FRONTEND=noninteractive \
    ROS_DISTRO=jazzy \
    COLCON_WS=/home/ubuntu/omx_ws \
    RMW_IMPLEMENTATION=rmw_fastrtps_cpp \
    ROS_DOMAIN_ID=42

# Install RealSense dependencies and tools
RUN apt-get update && apt-get install -y \
    # RealSense runtime dependencies (pre-built librealsense copied above)
    libusb-1.0-0-dev \
    libglfw3-dev \
    ros-${ROS_DISTRO}-image-transport-plugins \
    ros-${ROS_DISTRO}-usb-cam \
    # Gazebo Harmonic integration
    ros-${ROS_DISTRO}-ros-gz-sim \
    ros-${ROS_DISTRO}-ros-gz-bridge \
    # ros2_control framework
    ros-${ROS_DISTRO}-ros2-control \
    ros-${ROS_DISTRO}-ros2-controllers \
    ros-${ROS_DISTRO}-control-msgs \
    ros-${ROS_DISTRO}-joint-state-broadcaster \
    ros-${ROS_DISTRO}-joint-trajectory-controller \
    # MoveIt (optional, ignore if unavailable)
    ros-${ROS_DISTRO}-moveit || echo "MoveIt not available, continuing..." \
    # Development tools
    vim \
    nano \
    git \
    python3-pip \
    python3-colcon-common-extensions \
    wget \
    curl \
    net-tools \
    iputils-ping \
    # U2D2 (FTDI) serial support
    usbutils \
    && rm -rf /var/lib/apt/lists/*

# Set up workspace directory
RUN mkdir -p ${COLCON_WS}/src && \
    chown -R ubuntu:ubuntu ${COLCON_WS}

# Switch to ubuntu user for ROS operations
USER ubuntu
WORKDIR ${COLCON_WS}

# Clone all required repositories
RUN cd ${COLCON_WS}/src && \
    # Dynamixel SDK and interfaces (for real hardware)
    git clone -b jazzy https://github.com/ROBOTIS-GIT/DynamixelSDK.git && \
    git clone -b jazzy https://github.com/ROBOTIS-GIT/dynamixel_interfaces.git && \
    git clone -b jazzy https://github.com/ROBOTIS-GIT/dynamixel_hardware_interface.git && \
    # OpenMANIPULATOR packages
    git clone -b jazzy https://github.com/ROBOTIS-GIT/open_manipulator.git && \
    # RealSense ROS wrapper (specific version matching original)
    git clone -b r/4.56.4 https://github.com/IntelRealSense/realsense-ros.git && \
    cd realsense-ros && git checkout cbd8b8487d4c0126bb590822db9469414496e62a

# Initialize rosdep and install dependencies
USER root
RUN rosdep update && \
    cd ${COLCON_WS} && \
    rosdep install -r --from-paths src -i -y --rosdistro ${ROS_DISTRO} --skip-keys="librealsense2"

# Build the workspace
USER ubuntu
RUN bash -c "source /opt/ros/${ROS_DISTRO}/setup.bash && \
    cd ${COLCON_WS} && \
    MAKEFLAGS='-j2' colcon build --symlink-install --executor sequential --cmake-args -DCMAKE_BUILD_TYPE=Release"

# Set up U2D2 udev rules for container
USER root
RUN echo 'KERNEL=="ttyUSB*", DRIVERS=="ftdi_sio", MODE="0666", ATTR{device/latency_timer}="1"' > /etc/udev/rules.d/99-u2d2.rules

# Create logs directory
RUN mkdir -p /home/ubuntu/logs && \
    chown -R ubuntu:ubuntu /home/ubuntu/logs

# Configure ubuntu user's bashrc with ROS environment
USER ubuntu
RUN echo "" >> ~/.bashrc && \
    echo "# === OpenMANIPULATOR-X Environment ===" >> ~/.bashrc && \
    echo "source /opt/ros/${ROS_DISTRO}/setup.bash" >> ~/.bashrc && \
    echo "[ -f ${COLCON_WS}/install/setup.bash ] && source ${COLCON_WS}/install/setup.bash" >> ~/.bashrc && \
    echo "" >> ~/.bashrc && \
    echo "# ROS 2 configuration" >> ~/.bashrc && \
    echo "export RMW_IMPLEMENTATION=rmw_fastrtps_cpp" >> ~/.bashrc && \
    echo "export ROS_DOMAIN_ID=42" >> ~/.bashrc && \
    echo "unset ROS_LOCALHOST_ONLY" >> ~/.bashrc && \
    echo "" >> ~/.bashrc && \
    echo "# Convenience aliases" >> ~/.bashrc && \
    echo "alias cb='cd ${COLCON_WS} && colcon build --symlink-install --cmake-args -DCMAKE_BUILD_TYPE=Release'" >> ~/.bashrc && \
    echo "alias cs='cd ${COLCON_WS} && source install/setup.bash'" >> ~/.bashrc && \
    echo "alias cbs='cb && cs'" >> ~/.bashrc && \
    echo "alias ws='cd ${COLCON_WS}'" >> ~/.bashrc && \
    echo "" >> ~/.bashrc && \
    echo "echo '=== OpenMANIPULATOR-X Container ==='" >> ~/.bashrc && \
    echo "echo 'Workspace: ${COLCON_WS}'" >> ~/.bashrc && \
    echo "echo 'ROS_DOMAIN_ID: ${ROS_DOMAIN_ID}'" >> ~/.bashrc && \
    echo "echo 'DDS: ${RMW_IMPLEMENTATION}'" >> ~/.bashrc && \
    echo "echo ''" >> ~/.bashrc && \
    echo "echo 'Quick commands:'" >> ~/.bashrc && \
    echo "echo '  ws  - Go to workspace'" >> ~/.bashrc && \
    echo "echo '  cb  - Build workspace'" >> ~/.bashrc && \
    echo "echo '  cs  - Source workspace'" >> ~/.bashrc && \
    echo "echo '  cbs - Build and source'" >> ~/.bashrc

# Switch back to root for the entrypoint
USER root

# The base image already has the VNC/noVNC setup, so we keep the default CMD
# Port 80 in container maps to 6080 on host for noVNC access
