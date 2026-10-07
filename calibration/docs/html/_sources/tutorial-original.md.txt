# Hướng dẫn calibration camera bằng Kalibr và Docker

Create workspace:

```bash
mkdir ~/kalibr_workspace/
cd ~/kalibr_workspace/
mkdir src
```

then, pull kalibr project:

```bash
git clone https://archlinux.tail3e91a1.ts.net/tools/camera_calibration.git
```

## Step 2

- create Docker file ==> to build Image

```bash
cd ~/kalibr_workspace/
touch Dockerfile_ros1_20_04
```

and then fill these below code to Dockerfile_ros1_20_04:

```dockerfile
FROM osrf/ros:noetic-desktop-full

RUN apt-get update && DEBIAN_FRONTEND=noninteractive \
    apt-get install -y --no-install-recommends \
    git wget autoconf automake nano \
    python3-dev python3-pip python3-scipy python3-matplotlib \
    ipython3 python3-wxgtk4.0 python3-tk python3-igraph python3-pyx \
    libeigen3-dev libboost-all-dev libsuitesparse-dev \
    doxygen \
    libopencv-dev \
    libpoco-dev libtbb-dev libblas-dev liblapack-dev libv4l-dev \
    python3-catkin-tools python3-osrf-pycommon \
    byobu \
    && rm -rf /var/lib/apt/lists/*

ENV WORKSPACE=/catkin_ws
ENV MPLBACKEND=Agg
ENV KALIBR_MANUAL_FOCAL_LENGTH_INIT=1

RUN mkdir -p $WORKSPACE/src && \
    cd $WORKSPACE && \
    catkin init && \
    catkin config --extend /opt/ros/noetic && \
    catkin config --cmake-args -DCMAKE_BUILD_TYPE=Release

COPY ./kalibr $WORKSPACE/src/kalibr

RUN cd $WORKSPACE && catkin build -j$(nproc)

RUN echo '#!/bin/bash\n\
set -e\n\
source "$WORKSPACE/devel/setup.bash"\n\
export MPLBACKEND=Agg\n\
export KALIBR_MANUAL_FOCAL_LENGTH_INIT=1\n\
exec "$@"' > /entrypoint.sh && chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
CMD ["bash"]
```

After that, we need to build image by using this command

```bash
docker build -f Dockerfile_ros1_20_04 -t kalibr:local .
```

After building image successfully, you can check by: `sudo docket image list`
then take a look the image like this (for instance):

```text
IMAGE                        ID             DISK USAGE   CONTENT SIZE   EXTRA
kalibr:local                 4708d0af3ec2       7.01GB         1.36GB
```

## STEP 3: create folder which containing yaml and bag file

```bash
cd ~/kalibr_workspace
mkdir data
cd data
touch target.yaml
```

and then fill that file with these configurations:

```yaml
target_type: 'aprilgrid'
tagCols: 6               # Marker Grid Width (6 columns)
tagRows: 6               # Marker Grid Height (6 rows)
tagSize: 0.0235          # Marker Length in meters (2.35 cm)
tagSpacing: 0.2979       # Spacer Length / Marker Length (0.7 / 2.35)
```

In addition, we need to take bag file into `~/kalibr_workspace/data/`
Assume that we have "calibration_70.bag" file inside `~/kalibr_workspace/data/`

## STEP 4: Run image

```bash
docker run -it --rm \
  --net=host \
  --ipc=host \
  -w /data \
  -v /home/getac/Data/kalibr_workspace/data:/data:rw \
  kalibr:local
```

And then cd /catkin_ws/
source /devel/setup.bash
run this command to calibration with recorded bag file:

```bash
cd /catkin_ws/
source /devel/setup.bash
rosrun kalibr kalibr_calibrate_cameras --target /data/target.yaml --bag /data/calibration_70.bag --topics /camera/image_raw --models pinhole-radtan --dont-show-report
```

After finishing calibration, we will get 3 files like this

```text
camchain-calibration_70.yaml report-cam-calibration_70.pdf results-cam-calibration_70.txt
```

And then copy these files to current PC:
Overall, we need to check Container ID:
using this command: docker ps

```text
docker ps
CONTAINER ID   IMAGE               COMMAND                  CREATED          STATUS          PORTS     NAMES
3b84ada49c3c   kalibr:local        "/entrypoint.sh bash"    12 minutes ago   Up 12 minutes             cool_chaum
```

and run at host pc:

```bash
docker cp <CONTAINER_ID_OR_NAME>:/catkin_ws/camchain-calibration_70.yaml /home/getac/kalibr_workspace/data/
docker cp <CONTAINER_ID_OR_NAME>:/catkin_ws/report-cam-calibration_70.pdf /home/getac/kalibr_workspace/data/
docker cp <CONTAINER_ID_OR_NAME>:/catkin_ws/results-cam-calibration_70.txt /home/getac/kalibr_workspace/data/
```

## Ghi chú từ trao đổi

Mentor yêu cầu dùng bản mã local thay cho clone repository nội bộ. Người học đã dừng tại bước build image; log lỗi lúc đó được lưu trong `build-session.txt`.
