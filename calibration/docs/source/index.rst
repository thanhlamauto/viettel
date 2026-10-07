Hướng dẫn calibration camera bằng Kalibr và Docker
===================================================

Tài liệu này trình bày quy trình calibration một camera từ ROS bag theo tutorial
của mentor. Các lệnh chạy trên **host Linux** trừ khi có nhãn **container**.
Ví dụ dùng bag ``calibration_70.bag``, topic ``/camera/image_raw`` và bảng
AprilGrid 6 × 6. Hãy thay tên file, topic và kích thước bảng theo dữ liệu của bạn.

1. Tạo workspace và chuẩn bị mã Kalibr
--------------------------------------

Trên host, tạo workspace:

.. code-block:: bash

   export KALIBR_WS="$HOME/kalibr_workspace"
   mkdir -p "$KALIBR_WS/src"
   cd "$KALIBR_WS"

Mentor dùng mã Kalibr được cung cấp ở máy local. Copy **toàn bộ** thư mục mã vào
``src/kalibr``; thay đường dẫn nguồn trong lệnh sau bằng đường dẫn thực tế:

.. code-block:: bash

   cp -a /duong/dan/toi/kalibr "$KALIBR_WS/src/kalibr"
   ls "$KALIBR_WS/src/kalibr"

Sau bước này, mã nằm trực tiếp trong ``src/kalibr``. Nếu thư mục đích đã có mã
đầy đủ, bỏ qua lệnh ``cp``. Không để thành ``src/kalibr/kalibr``.

2. Tạo Docker image
-------------------

Tạo file ``Dockerfile_ros1_20_04`` ở gốc workspace và dùng nội dung sau:

.. code-block:: bash

   cd "$KALIBR_WS"
   nano Dockerfile_ros1_20_04

.. literalinclude:: Dockerfile_ros1_20_04.example
   :language: dockerfile

Lưu file rồi build image. Dấu ``.`` cuối lệnh là build context và cần có
``src/kalibr`` bên trong:

.. code-block:: bash

   docker build -f Dockerfile_ros1_20_04 -t kalibr:local .
   docker image ls kalibr:local

Khi thành công, danh sách image có ``kalibr:local``. ID và dung lượng image có
thể khác ví dụ của mentor. Nếu build báo thiếu ``src/kalibr``, kiểm tra lại bước 1
và chạy lệnh build từ gốc workspace.

3. Chuẩn bị target YAML và ROS bag
----------------------------------

Tạo thư mục dữ liệu và file ``target.yaml``:

.. code-block:: bash

   mkdir -p "$KALIBR_WS/data"
   cd "$KALIBR_WS/data"
   nano target.yaml

Nội dung ví dụ từ tutorial mentor:

.. code-block:: yaml

   target_type: 'aprilgrid'
   tagCols: 6
   tagRows: 6
   tagSize: 0.0235
   tagSpacing: 0.2979

``tagSize`` là cạnh tag theo mét (23,5 mm). ``tagSpacing`` là tỷ lệ khoảng
hở/cạnh tag; ở đây khoảng hở xấp xỉ 7 mm. **Đo bảng thực tế** và sửa các giá trị
nếu bảng của bạn khác ví dụ.

Copy bag vào cùng thư mục, rồi xác nhận có cả hai file:

.. code-block:: bash

   cp /duong/dan/toi/calibration_70.bag "$KALIBR_WS/data/"
   ls -lh "$KALIBR_WS/data/target.yaml" "$KALIBR_WS/data/calibration_70.bag"

Nếu bag đã nằm trong ``data``, bỏ qua lệnh ``cp``.

4. Chạy calibration và lấy kết quả
----------------------------------

**Host — terminal thứ nhất:** chạy image, mount thư mục ``data`` vào ``/data``.
Giữ terminal này mở cho đến khi đã copy xong kết quả:

.. code-block:: bash

   docker run -it --rm \
     --net=host \
     --ipc=host \
     -w /catkin_ws \
     -v "$KALIBR_WS/data:/data:rw" \
     kalibr:local

**Container — trong terminal thứ nhất:** kiểm tra bag và chạy Kalibr:

.. code-block:: bash

   source /catkin_ws/devel/setup.bash
   rosbag info /data/calibration_70.bag
   rosrun kalibr kalibr_calibrate_cameras \
     --target /data/target.yaml \
     --bag /data/calibration_70.bag \
     --topics /camera/image_raw \
     --models pinhole-radtan \
     --dont-show-report

Trong ``rosbag info``, xác nhận topic ảnh của bạn có kiểu ``sensor_msgs/Image``.
Nếu topic khác ``/camera/image_raw``, thay giá trị của ``--topics``. Lệnh chạy
trong ``/catkin_ws``, nên Kalibr ghi ba file kết quả vào thư mục đó trong
container:

.. code-block:: text

   camchain-calibration_70.yaml
   results-cam-calibration_70.txt
   report-cam-calibration_70.pdf

**Host — terminal thứ hai:** khi lệnh calibration hoàn tất, khai báo lại cùng
đường dẫn workspace, tìm tên hoặc ID container rồi copy kết quả ra máy. Thay
``<CONTAINER_ID>`` bằng ID từ ``docker ps``:

.. code-block:: bash

   export KALIBR_WS="$HOME/kalibr_workspace"
   docker ps
   docker cp <CONTAINER_ID>:/catkin_ws/camchain-calibration_70.yaml "$KALIBR_WS/data/"
   docker cp <CONTAINER_ID>:/catkin_ws/results-cam-calibration_70.txt "$KALIBR_WS/data/"
   docker cp <CONTAINER_ID>:/catkin_ws/report-cam-calibration_70.pdf "$KALIBR_WS/data/"
   ls -lh "$KALIBR_WS/data/"*calibration_70*

**Quan trọng:** copy trước khi gõ ``exit`` trong container. Tùy chọn ``--rm``
sẽ xóa container khi thoát. Sau khi đã kiểm tra đủ ba file trên host, gõ
``exit`` ở terminal thứ nhất.

Kết quả mẫu để đối chiếu
----------------------------------------------------------------------

Các file dưới đây là kết quả mẫu của ``calibration_70.bag``, không phải thông số
áp dụng cho mọi camera. Dùng ba file do **lần chạy của bạn** tạo ra khi tích hợp.

* :download:`Camera YAML <results/camchain-calibration_70.yaml>`
* :download:`Kết quả TXT <results/results-cam-calibration_70.txt>`
* :download:`Báo cáo PDF <results/report-cam-calibration_70.pdf>`
