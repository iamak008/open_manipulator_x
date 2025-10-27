# OpenMANIPULATOR-X noVNC Docker Setup

Browser-based ROS 2 Jazzy development environment for OpenMANIPULATOR-X with Gazebo simulation and real hardware support.

## 🚀 Quick Start

### 1. Start the Container

```bash
chmod +x container.sh
./container.sh start
```

This will:
- Build the Docker image (first time: ~15-20 minutes)
- Start the container
- Open your browser at http://localhost:6080

### 2. Access the Desktop

- **URL:** http://localhost:6080
- **Username:** ubuntu
- **Password:** ubuntu

### 3. Inside the Browser Desktop

Open a terminal and try:

```bash
# Launch Gazebo simulation
ros2 launch open_manipulator_bringup open_manipulator_x_gazebo.launch.py

# In another terminal, launch MoveIt + RViz
ros2 launch open_manipulator_moveit_config open_manipulator_x_moveit.launch.py use_sim:=true
```

## 📋 Available Commands

| Command | Description |
|---------|-------------|
| `./container.sh start` | Start the container and open browser |
| `./container.sh stop` | Stop the container |
| `./container.sh restart` | Restart the container |
| `./container.sh enter` | Open a shell in the running container |
| `./container.sh logs` | View container logs |
| `./container.sh status` | Check container status |
| `./container.sh build` | Rebuild the Docker image |
| `./container.sh clean` | Remove container (keeps image) |
| `./container.sh purge` | Remove everything (container + image) |
| `./container.sh open` | Open noVNC in browser |
| `./container.sh devices` | List USB devices |
| `./container.sh help` | Show help message |

## 🎯 What's Included

### Software Stack
- **ROS 2 Jazzy** (fully configured)
- **Gazebo Harmonic** (3D simulation)
- **MoveIt** (motion planning)
- **RViz** (visualization)
- **ros2_control** (hardware interface)
- **Intel RealSense** support (D435, D435i, D405, etc.)
- **Dynamixel SDK** (for real hardware via U2D2)

### Pre-built Packages
- `DynamixelSDK`
- `dynamixel_interfaces`
- `dynamixel_hardware_interface`
- `open_manipulator` (full stack)
- `realsense-ros`

### Configuration
- **ROS_DOMAIN_ID:** 42 (isolated DDS network)
- **DDS Implementation:** Fast DDS
- **Workspace:** `/home/ubuntu/omx_ws`
- **Logs:** `/home/ubuntu/logs`

## 📁 Directory Structure

```
docker-vnc/
├── Dockerfile              # Image definition
├── docker-compose.yml      # Container configuration
├── container.sh            # Management script
├── README.md              # This file
├── workspace/             # Mounted to /home/ubuntu/omx_ws/src/open_manipulator
└── logs/                  # Mounted to /home/ubuntu/logs
```

## 🔧 Inside the Container

### Convenience Aliases

The container includes these shortcuts:

```bash
ws      # Go to workspace (cd ~/omx_ws)
cb      # Build workspace with Release flags
cs      # Source workspace
cbs     # Build and source workspace
```

### ROS 2 Workspace

```bash
# Your workspace
cd ~/omx_ws

# Source it (done automatically in new terminals)
source ~/omx_ws/install/setup.bash

# Rebuild if needed
colcon build --symlink-install --cmake-args -DCMAKE_BUILD_TYPE=Release
```

### Example: Launch Simulation

**Terminal 1 - Gazebo:**
```bash
ros2 launch open_manipulator_bringup open_manipulator_x_gazebo.launch.py
```

**Terminal 2 - MoveIt:**
```bash
ros2 launch open_manipulator_moveit_config open_manipulator_x_moveit.launch.py use_sim:=true
```

**Terminal 3 - Send Commands:**
```bash
# Check controllers
ros2 control list_controllers

# Check topics
ros2 topic list

# Monitor joint states
ros2 topic echo /joint_states
```

## 🔌 Hardware Support

### USB Devices (U2D2, Cameras)

The container runs in **privileged mode** with `/dev` mounted for:
- **U2D2** (FTDI USB-to-Dynamixel adapter)
- **Intel RealSense cameras**
- Other USB devices

### U2D2 Setup

On **Linux**, the script automatically installs udev rules:
```bash
# Automatically done by container.sh start
# Manual check:
ls -l /dev/ttyUSB*
```

On **macOS/Windows**, USB passthrough requires Docker Desktop configuration.

### Check Devices

```bash
./container.sh devices
```

## 🌐 Network Configuration

### Host Network Mode

The container uses `network_mode: host` for:
- ROS 2 DDS discovery across processes
- Real-time communication with Gazebo
- Hardware device access

### Ports

- **6080:** noVNC web interface (HTTP)
- **5900:** VNC direct access (optional)

## 🐛 Troubleshooting

### Container won't start
```bash
# Check Docker
docker ps

# View logs
./container.sh logs

# Rebuild from scratch
./container.sh purge
./container.sh start
```

### Gazebo is slow in noVNC
```bash
# Run Gazebo headless (in container)
gz sim -s -r --headless-rendering &
ros2 launch open_manipulator_bringup open_manipulator_x_gazebo.launch.py
```

### ROS 2 nodes can't see each other
```bash
# Check DDS settings (inside container)
echo $RMW_IMPLEMENTATION  # Should be: rmw_fastrtps_cpp
echo $ROS_DOMAIN_ID       # Should be: 42

# Verify topics
ros2 topic list

# Check nodes
ros2 node list
```

### Workspace build fails
```bash
# Clean rebuild (inside container)
cd ~/omx_ws
rm -rf build/ install/ log/
source /opt/ros/jazzy/setup.bash
rosdep update
rosdep install -r --from-paths src -i -y --rosdistro jazzy
MAKEFLAGS="-j1" colcon build --symlink-install --executor sequential --cmake-args -DCMAKE_BUILD_TYPE=Release
source install/setup.bash
```

### No USB devices visible
```bash
# Check on host
./container.sh devices

# Check udev rules (Linux)
cat /etc/udev/rules.d/99-u2d2.rules

# Reload udev (Linux)
sudo udevadm control --reload-rules
sudo udevadm trigger

# Check inside container
./container.sh enter
ls -l /dev/ttyUSB* /dev/ttyACM*
```

## 🎓 Learning Path

### 1. Start with Simulation
```bash
# Launch Gazebo
ros2 launch open_manipulator_bringup open_manipulator_x_gazebo.launch.py

# Use MoveIt in RViz
ros2 launch open_manipulator_moveit_config open_manipulator_x_moveit.launch.py use_sim:=true
```

### 2. Send Commands Manually
```bash
# Check active controllers
ros2 control list_controllers

# Send a trajectory
ros2 topic pub --once /arm_controller/joint_trajectory trajectory_msgs/msg/JointTrajectory "
joint_names: ['joint1', 'joint2', 'joint3', 'joint4']
points:
- positions: [0.0, -1.0, 1.0, 0.0]
  time_from_start: {sec: 2, nanosec: 0}
"
```

### 3. Write Python Scripts

See the example scripts in the runbook (referenced in your request) for:
- Publishing `JointTrajectory` messages
- Logging `/joint_states` to CSV
- Using MoveIt Python API

### 4. Connect Real Hardware

Once comfortable with simulation:
```bash
# Connect U2D2 to USB
./container.sh devices  # Verify detection

# Launch real hardware (inside container)
ros2 launch open_manipulator_bringup open_manipulator_x.launch.py
```

## 📊 Data Logging

### Logs Directory

Host: `./logs/`  
Container: `/home/ubuntu/logs`

```bash
# Create a logger script (inside container)
cd ~/omx_ws/src
# (Follow the runbook examples for CSV/bag logging)
```

### Accessing Logs

Logs persist on your host in `./logs/` even after container restarts.

## 🔒 Security Notes

### Change Default Passwords

Edit `docker-compose.yml` before first run:

```yaml
environment:
  - PASSWORD=your_secure_password       # VNC password
  - HTTP_PASSWORD=your_secure_password  # noVNC web password
```

### Network Exposure

By default, noVNC only listens on localhost. To expose to other machines, add port bindings to `docker-compose.yml`:

```yaml
ports:
  - "0.0.0.0:6080:80"  # WARNING: Accessible from network
```

## 🔄 Updates

### Update Packages

```bash
# Inside container
cd ~/omx_ws/src/open_manipulator
git pull

# Rebuild
ws && cb && cs
```

### Update Docker Image

```bash
./container.sh stop
./container.sh build
./container.sh start
```

## 📚 References

- [OpenMANIPULATOR-X Manual](https://emanual.robotis.com/docs/en/platform/openmanipulator_x/)
- [ROS 2 Jazzy Documentation](https://docs.ros.org/en/jazzy/)
- [Gazebo Harmonic Documentation](https://gazebosim.org/docs)
- [MoveIt 2 Tutorials](https://moveit.picknik.ai/main/index.html)
- [RealSense ROS Wrapper](https://github.com/IntelRealSense/realsense-ros)

## 🆘 Support

### Container Issues
```bash
./container.sh help     # Show all commands
./container.sh status   # Check status
./container.sh logs     # View logs
```

### ROS 2 Issues
```bash
# Inside container
ros2 doctor             # Diagnose ROS setup
ros2 wtf                # Troubleshoot (if installed)
```

### Clean Slate
```bash
# Remove everything and start fresh
./container.sh purge
./container.sh start
```

## ✨ Features vs Original Docker

| Feature | Original | noVNC Version |
|---------|----------|---------------|
| Browser Access | ❌ | ✅ http://localhost:6080 |
| X11 Forwarding | ✅ | Not needed |
| Cross-Platform | Requires X11 setup | ✅ Works everywhere |
| Gazebo GUI | Requires X11 | ✅ In browser |
| RViz | Requires X11 | ✅ In browser |
| USB Devices | ✅ | ✅ |
| RealSense | ✅ | ✅ |
| Workspace Persistence | ✅ | ✅ |
| Build Time | ~10 min | ~15-20 min |
| Resource Usage | Lower | +500MB RAM for VNC |

## 🎯 Use Cases

### ✅ Perfect For
- Learning ROS 2 and robotics
- Testing in simulation before hardware
- Cross-platform development (Mac/Windows/Linux)
- Remote development (SSH + browser)
- Reproducible environments
- Teaching and demos

### ⚠️ Consider Alternatives For
- Native performance (use original docker/)
- Minimal resource usage
- CLI-only workflows
- Production deployments

---

**Happy coding!** 🤖🦾

For questions or issues, refer to the original runbook or ROBOTIS documentation.
