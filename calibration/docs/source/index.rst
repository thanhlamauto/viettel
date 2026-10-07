Hướng dẫn calibration camera bằng Kalibr và Docker
====================================================================================================

.. raw:: html

   <p class="eyebrow">HƯỚNG DẪN THỰC HÀNH · CAMERA CALIBRATION</p>

Hiệu chuẩn một camera từ ROS bag bằng Kalibr trong Docker ROS Noetic.
Mỗi bước gồm lệnh chạy, nơi chạy, ý nghĩa và kết quả mong đợi. Output minh họa
được ghi rõ; ID, dung lượng và thông số có thể khác giữa các lần chạy.

Hướng dẫn dành cho host Linux đã cài Docker và có quyền chạy lệnh Docker.
Chuẩn bị mã Kalibr đầy đủ, ROS bag chứa ảnh và kích thước bảng AprilGrid thực tế.
Các lệnh sử dụng ``calibration_70.bag`` và ``/camera/image_raw`` làm ví dụ;
thay bằng tên bag và topic của bạn. Kết quả tham khảo ở :ref:`ket-qua-cuoi`.
Chạy lại calibration trong cùng thư mục sẽ ghi đè kết quả cùng tên.

.. contents:: Trong trang này
   :local:
   :depth: 1

Luồng và đường dẫn
----------------------------------------------------------------------------------------------------

.. raw:: html

   <div class="workflow" aria-label="Luồng hiệu chuẩn camera">
     <div class="workflow__step"><span>01 · CHUẨN BỊ</span><strong>Mã Kalibr + Dockerfile</strong><small>Build image kalibr:local</small></div>
     <div class="workflow__arrow" aria-hidden="true">→</div>
     <div class="workflow__step"><span>02 · HIỆU CHUẨN</span><strong>Bag + AprilGrid</strong><small>Chạy Kalibr trong container</small></div>
     <div class="workflow__arrow" aria-hidden="true">→</div>
     <div class="workflow__step"><span>03 · KẾT QUẢ</span><strong>YAML · TXT · PDF</strong><small>Kiểm tra và tích hợp</small></div>
   </div>

Thư mục làm việc dự kiến:

.. code-block:: text

   ${KALIBR_WS}/
   ├── Dockerfile_ros1_20_04
   ├── src/kalibr/
   ├── data/
   │   ├── target.yaml
   │   ├── calibration_70.bag
   │   ├── camchain-calibration_70.yaml
   │   ├── results-cam-calibration_70.txt
   │   └── report-cam-calibration_70.pdf
   └── docs/

**Host** là terminal trên máy thật. **Container** là terminal sau lệnh
``docker run``; thư mục ``/catkin_ws`` nằm trong container.

Bước 0 · Kiểm tra dung lượng trên host
----------------------------------------------------------------------------------------------------

.. code-block:: bash

   export KALIBR_WS="$HOME/kalibr_workspace"
   mkdir -p "$KALIBR_WS"
   df -h "$KALIBR_WS"
   docker info --format '{{.DockerRootDir}}'

**Ý nghĩa:** ``KALIBR_WS`` là đường dẫn tuyệt đối đến workspace trên host.
Ví dụ trên dùng home; nếu có ổ dữ liệu riêng, thay bằng đường dẫn trên ổ đó,
chẳng hạn ``/mnt/data/kalibr_workspace``. ``mkdir -p`` tạo workspace nếu chưa có.
Giữ biến này trong terminal host; nếu mở terminal mới, khai báo lại cùng giá trị.

``df -h`` cho biết dung lượng đĩa còn trống trong cột ``Avail``.
``docker info`` in thư mục Docker lưu dữ liệu; Docker storage và workspace có
thể nằm trên hai filesystem khác nhau.

**Kết quả mong đợi:** filesystem chứa workspace đủ chỗ cho mã, bag và kết quả;
filesystem chứa Docker storage đủ chỗ cho image và build cache. Dung lượng
cần thiết phụ thuộc bag và bản mã được build. Chọn workspace trên ổ dữ liệu
không tự chuyển Docker storage sang ổ đó.

Bước 1 · Chuẩn bị workspace và mã nguồn trên host
----------------------------------------------------------------------------------------------------

.. code-block:: bash

   mkdir -p "$KALIBR_WS/src"
   cd "$KALIBR_WS"
   pwd

**Ý nghĩa:** ``mkdir -p`` tạo các thư mục còn thiếu, ``cd`` đổi thư mục làm việc,
``pwd`` in đường dẫn hiện tại.

**Output mong đợi:**

.. code-block:: text

   /duong/dan/ban/chon/kalibr_workspace

Sau khi copy, danh sách mã cần có các thư mục như ``aslam_cv``, ``aslam_offline_calibration``,
``aslam_optimizer``, ``catkin_simple``, ``Schweizer-Messer``.

Copy thư mục mã Kalibr đầy đủ được cung cấp, thay
đường dẫn mẫu bằng đường dẫn thật và chỉ chạy khi đích ``src/kalibr`` chưa tồn tại:

.. code-block:: bash

   cp -a /duong/dan/ma/kalibr "$KALIBR_WS/src/kalibr"
   ls "$KALIBR_WS/src/kalibr"

**Ý nghĩa:** copy cây mã và giữ thuộc tính file. **Kết quả mong đợi:** mã nằm trực tiếp
trong ``src/kalibr``, không bị lồng thành ``src/kalibr/kalibr``.
Nếu đã có mã đầy đủ ở đích, bỏ qua lệnh copy. Thư mục nguồn có thể mang tên
khác; đích vẫn là ``src/kalibr`` để khớp Dockerfile.

Bước 2 · Tạo Dockerfile và build image trên host
----------------------------------------------------------------------------------------------------

Tạo Dockerfile tại thư mục gốc workspace:

.. code-block:: bash

   cd "$KALIBR_WS"
   nano Dockerfile_ros1_20_04

**Ý nghĩa:** mở file bằng nano. Dán nội dung dưới đây, lưu bằng Ctrl+O rồi Enter,
thoát bằng Ctrl+X. **Kết quả mong đợi:** Dockerfile có nội dung và tên chính xác.

.. literalinclude:: Dockerfile_ros1_20_04.example
   :language: dockerfile

Ý nghĩa các phần Dockerfile:

* ``FROM`` chọn môi trường ROS Noetic làm nền.
* ``apt-get update`` cập nhật danh sách package; ``apt-get install`` cài các
  thư viện build, toán học, xử lý ảnh và công cụ Python/catkin.
* ``DEBIAN_FRONTEND=noninteractive`` tránh hộp hỏi tương tác khi cài package.
* ``--no-install-recommends`` giảm package phụ; xóa apt lists giảm phần dữ liệu
  không cần giữ trong layer này.
* ``WORKSPACE=/catkin_ws`` xác định workspace bên trong image.
* ``MPLBACKEND=Agg`` chọn backend vẽ không cần cửa sổ desktop.
* ``KALIBR_MANUAL_FOCAL_LENGTH_INIT=1`` giữ cấu hình khởi tạo focal length của
  tutorial; tác dụng cụ thể phụ thuộc bản Kalibr local có hỗ trợ biến này.
* ``catkin init`` khởi tạo workspace; ``--extend /opt/ros/noetic`` dùng môi trường
  ROS; ``Release`` chọn chế độ build tối ưu.
* ``COPY ./src/kalibr $WORKSPACE/src/kalibr`` đưa mã từ build context trên host
  vào image. Đường dẫn nguồn khớp cấu trúc ``src/kalibr`` của hướng dẫn.
* ``catkin build -j$(nproc)`` biên dịch với số job theo số CPU khả dụng.
* ``/entrypoint.sh`` nạp môi trường đã build rồi chạy lệnh truyền vào container.
* ``CMD ["bash"]`` mở shell Bash mặc định.

Build:

.. code-block:: bash

   docker build -f Dockerfile_ros1_20_04 -t kalibr:local .

**Ý nghĩa:** ``-f`` chỉ định Dockerfile; ``-t`` đặt tên image và tag;
``.`` là build context, tức thư mục hiện tại chứa Dockerfile và ``src/kalibr``.

**Kết quả mong đợi:** build kết thúc thành công và tạo image ``kalibr:local``. Các bước
có thể báo ``CACHED`` nếu dùng lại kết quả trước. ID image không cố định.

Kiểm tra:

.. code-block:: bash

   docker image ls kalibr:local

**Output minh họa:**

.. code-block:: text

   IMAGE          ID             DISK USAGE   CONTENT SIZE
   kalibr:local   <image-id>      <size>       <size>

Docker phiên bản khác có thể hiển thị bảng với cột khác. Điều cần xác nhận là
image tên ``kalibr`` và tag ``local`` tồn tại.

Bước 3 · Chuẩn bị target và bag trên host
----------------------------------------------------------------------------------------------------

.. code-block:: bash

   mkdir -p "$KALIBR_WS/data"
   cd "$KALIBR_WS/data"
   nano target.yaml

**Kết quả mong đợi:** tạo hoặc mở cấu hình bảng calibration. Dán cấu hình phù hợp
với bảng của bạn, lưu bằng Ctrl+O rồi Enter và thoát bằng Ctrl+X. Ví dụ:

.. code-block:: yaml

   target_type: 'aprilgrid'
   tagCols: 6
   tagRows: 6
   tagSize: 0.0235
   tagSpacing: 0.2979

``tagCols`` và ``tagRows`` là số cột và hàng. ``tagSize`` là chiều dài cạnh tag,
đơn vị mét: 0.0235 m = 23.5 mm. ``tagSpacing`` là tỷ lệ khoảng hở/cạnh tag,
không phải khoảng hở tính bằng mét: 0.2979 × 0.0235 ≈ 0.007 m = 7 mm.
Các thông số phải đúng với bảng thực tế trong bag, không chỉ đúng với ví dụ.

Copy bag của bạn vào thư mục data. Thay đường dẫn nguồn mẫu bằng đường dẫn thật:

.. code-block:: bash

   cp /duong/dan/toi/calibration_70.bag "$KALIBR_WS/data/"
   ls -lh "$KALIBR_WS/data/"

**Ý nghĩa:** copy dữ liệu vào thư mục sẽ được chia sẻ với container.
Nếu bag đã có ở đó, bỏ qua ``cp``. **Kết quả mong đợi:** thấy ``target.yaml`` và
bag đầy đủ; dung lượng bag phải khớp file gốc. Không dùng file copy dở.

Nếu cần tránh tạo bản sao và nguồn/đích cùng filesystem, có thể dùng hard link
thay cho ``cp`` khi tên đích chưa tồn tại:

.. code-block:: bash

   ln /duong/dan/toi/calibration_70.bag "$KALIBR_WS/data/calibration_70.bag"

**Kết quả mong đợi:** lệnh thành công không in output, bag có thêm một tên mà
không nhân đôi dữ liệu. Hai tên cùng trỏ đến một dữ liệu; chỉnh sửa qua một tên
ảnh hưởng cả hai. ``Invalid cross-device link`` nghĩa là khác filesystem:
dùng ``cp`` nếu đủ dung lượng. ``File exists`` nghĩa là cần kiểm tra đích hiện có.

Bước 4 · Chạy container từ host
----------------------------------------------------------------------------------------------------

.. code-block:: bash

   cd "$KALIBR_WS"
   docker run -it --rm \
     --net=host \
     --ipc=host \
     -w /data \
     -v "$KALIBR_WS/data:/data:rw" \
     kalibr:local

**Ý nghĩa các tùy chọn:**

* ``-it`` mở terminal tương tác.
* ``--rm`` xóa container sau khi thoát; image và dữ liệu bind mount vẫn còn.
* ``--net=host`` dùng mạng của host theo tutorial trên Linux.
* ``--ipc=host`` chia sẻ IPC với host theo tutorial.
* ``-w /data`` đặt thư mục làm việc mặc định là ``/data``.
* ``-v HOST:CONTAINER:rw`` chia sẻ thư mục data với quyền đọc/ghi.
* ``kalibr:local`` chọn image đã build.

**Kết quả mong đợi:** terminal chuyển vào shell trong container, thường có prompt
``root@...:/data#``. Từ đây chạy các lệnh trong container cho đến ``exit``.

Bước 5 · Kiểm tra môi trường và topic trong container
------------------------------------------------------------------------------------------------------

.. code-block:: bash

   source /catkin_ws/devel/setup.bash
   cd /data
   pwd
   ls -lh
   rospack find kalibr
   rosbag info /data/calibration_70.bag

Ý nghĩa và kết quả mong đợi:

* ``source`` nạp biến môi trường ROS/catkin vào shell hiện tại; thường không in
  output. Entrypoint đã nạp môi trường, lệnh này giúp kiểm tra rõ ràng.
* ``pwd`` in ``/data``; ``ls`` thấy target và bag từ host.
* ``rospack find kalibr`` in đường dẫn package, thường là
  ``/catkin_ws/src/kalibr/aslam_offline_calibration/kalibr``.
* ``rosbag info`` in metadata như thời lượng, dung lượng, số message và topics.
  Trong ``topics`` cần thấy topic ảnh có kiểu ``sensor_msgs/Image``.

**Ví dụ minh họa phần topic, không phải số message đã đo:**

.. code-block:: text

   topics: /camera/image_raw   <so_message> msgs : sensor_msgs/Image

Nếu topic ảnh khác, thay ``--topics`` trong bước 6 bằng tên thực tế. Không cần
``rosbag play`` hoặc mở ``roscore`` riêng để Kalibr đọc trực tiếp bag trong luồng này.

Bước 6 · Chạy calibration trong container
----------------------------------------------------------------------------------------------------

.. code-block:: bash

   cd /data
   rosrun kalibr kalibr_calibrate_cameras \
     --target /data/target.yaml \
     --bag /data/calibration_70.bag \
     --topics /camera/image_raw \
     --models pinhole-radtan \
     --dont-show-report

**Ý nghĩa:** ``rosrun`` gọi chương trình trong package ``kalibr``;
``--target`` cung cấp hình học bảng; ``--bag`` chỉ dữ liệu đầu vào;
``--topics`` chọn ảnh camera; ``--models pinhole-radtan`` chọn mô hình pinhole
với méo radial/tangential; ``--dont-show-report`` vẫn tạo PDF nhưng không mở
cửa sổ báo cáo trong container.

**Kết quả mong đợi:** Kalibr đọc ảnh, phát hiện bảng, khởi tạo thông số và tối ưu.
Nếu bản local hỏi focal length, nhập giá trị ước lượng theo pixel từ thông số
camera hoặc intrinsics đã biết; không nhập trực tiếp tiêu cự tính bằng mm.

**Output mong đợi ở cuối, dạng ví dụ:**

.. code-block:: text

   Processed <N> images with <M> images used
   Results written to file: camchain-calibration_70.yaml
     Detailed results written to file: results-cam-calibration_70.txt

Bản Kalibr local tạo tên kết quả từ tên bag và lưu vào thư mục làm việc hiện tại.
Vì chạy tại ``/data``, ba file nằm trên bind mount và được lưu trực tiếp vào thư mục data trên host.
Nếu tên bag là ``my_recording.bag``, tên output sẽ có phần ``my_recording``
thay cho ``calibration_70`` trong các lệnh kiểm tra bên dưới.

.. code-block:: bash

   ls -lh /data/camchain-calibration_70.yaml \
     /data/report-cam-calibration_70.pdf \
     /data/results-cam-calibration_70.txt

**Kết quả mong đợi:** cả ba file tồn tại và có dung lượng khác 0. File tồn tại chưa đủ
để kết luận calibration tốt; cần xem nội dung và báo cáo ở bước 7.

Bước 7 · Thoát và đọc kết quả trên host
----------------------------------------------------------------------------------------------------

Trong container:

.. code-block:: bash

   exit

**Kết quả mong đợi:** trở về terminal host; container bị xóa do ``--rm``. Các file trong
thư mục data vẫn tồn tại.

Trên host:

.. code-block:: bash

   cd "$KALIBR_WS/data"
   ls -lh
   cat results-cam-calibration_70.txt
   cat camchain-calibration_70.yaml
   xdg-open report-cam-calibration_70.pdf

**Ý nghĩa:** ``cat`` hiển thị nội dung; ``xdg-open`` mở PDF bằng ứng dụng mặc định
trên desktop host. Nếu không có trình xem PDF, mở file qua file manager hoặc
cài ứng dụng xem PDF phù hợp.

**Kết quả mong đợi:** YAML chứa mô hình và intrinsics/distortion; TXT chứa kết quả cùng
độ bất định; PDF giúp kiểm tra phân bố quan sát và reprojection error.

Không cần ``docker cp`` trong luồng này. Nếu chạy tại ``/catkin_ws`` như tutorial
cũ, kết quả nằm ngoài mount và cần copy ra trước khi thoát container ``--rm``.
Các file tạo bởi container chạy với user root có thể thuộc root; nếu cần chỉnh sửa trên
host, chỉ đổi owner các file kết quả cụ thể:

.. code-block:: bash

   sudo chown "$(id -u):$(id -g)" \
     camchain-calibration_70.yaml \
     results-cam-calibration_70.txt \
     report-cam-calibration_70.pdf

**Kết quả mong đợi:** ba file kết quả thuộc user hiện tại. Lệnh này tùy chọn, không cần
để đọc PDF nếu quyền đọc đã cho phép.

.. _ket-qua-cuoi:

Kết quả calibration tham khảo
----------------------------------------------------------------------------------------------------

Ví dụ dưới đây là kết quả thực tế của một lần chạy với ``calibration_70.bag``.
Các file tải xuống là bộ kết quả đi kèm tài liệu để đối chiếu cấu trúc và cách đọc;
không phải kết quả được tạo trên máy của người đọc. Chạy với camera hoặc bag
khác sẽ cho thông số khác. Không áp dụng trực tiếp các thông số mẫu cho camera
của bạn; dùng file output từ lần calibration của chính camera đó.

Camera ``cam0`` sử dụng topic ``/camera/image_raw``, độ phân giải **1280 × 720**,
mô hình **pinhole** và distortion **radtan**. Bảng AprilGrid có 6 × 6 tag,
cạnh tag 23.5 mm và khoảng hở xấp xỉ 7 mm.

.. list-table:: Thông số camera
   :header-rows: 1
   :widths: 20 30 50

   * - Thông số
     - Giá trị
     - Ý nghĩa
   * - fx
     - 936.77460328 px
     - Tiêu cự theo trục ngang
   * - fy
     - 940.07453464 px
     - Tiêu cự theo trục dọc
   * - cx
     - 640.38112082 px
     - Tọa độ ngang của principal point
   * - cy
     - 376.20115077 px
     - Tọa độ dọc của principal point
   * - k1
     - 0.06092825
     - Hệ số méo radial thứ nhất
   * - k2
     - −0.05262379
     - Hệ số méo radial thứ hai
   * - p1
     - 0.00079018
     - Hệ số méo tangential thứ nhất
   * - p2
     - 0.00283614
     - Hệ số méo tangential thứ hai

Ma trận camera K từ intrinsics, đơn vị pixel:

.. code-block:: text

   K = [ 936.77460328    0.00000000   640.38112082 ]
       [   0.00000000  940.07453464   376.20115077 ]
       [   0.00000000    0.00000000     1.00000000 ]

**Sai số reprojection:** trung bình theo hai trục là ``[0.000000, 0.000000]`` px;
độ phân tán được báo cáo là ``[0.342106, 0.313684]`` px. Trung bình gần 0 không
có nghĩa mọi quan sát có sai số bằng 0. Đây không phải giá trị RMS tổng hợp;
không dùng riêng trung bình để kết luận calibration tốt.

Xem PDF để đánh giá phân bố quan sát và sai số. Khi áp dụng, dùng đúng camera,
độ phân giải, thiết lập lấy nét và ống kính của lần calibration.

Tải các file kết quả:

* :download:`Thông số camera YAML <results/camchain-calibration_70.yaml>` — dữ liệu đầy đủ để tích hợp.
* :download:`Kết quả chi tiết TXT <results/results-cam-calibration_70.txt>` — thông số, độ bất định và sai số.
* :download:`Báo cáo calibration PDF <results/report-cam-calibration_70.pdf>` — biểu đồ và báo cáo của Kalibr.

Nội dung YAML nguyên bản, giữ đầy đủ độ chính xác:

.. literalinclude:: results/camchain-calibration_70.yaml
   :language: yaml

Kết quả TXT nguyên bản:

.. literalinclude:: results/results-cam-calibration_70.txt
   :language: text

Đối chiếu và xử lý lỗi
----------------------------------------------------------------------------------------------------

.. list-table:: Lỗi thường gặp
   :header-rows: 1
   :widths: 35 65

   * - Thông báo
     - Cách kiểm tra và xử lý
   * - docker build requires 1 argument
     - Thêm dấu chấm cuối lệnh build để chỉ build context.
   * - Dockerfile cannot be empty
     - Kiểm tra đã lưu nội dung vào đúng Dockerfile_ros1_20_04.
   * - COPY /kalibr not found
     - Build từ workspace root và dùng COPY ./src/kalibr; kiểm tra .dockerignore nếu có.
   * - Dockerfile no such file
     - Không build từ src với tên Dockerfile tương đối ở thư mục cha.
   * - cd ~kalibr_workspace/data thất bại
     - Dùng cd "$KALIBR_WS/data"; nếu dùng home, dấu / sau ~ là cần thiết.
   * - No space left on device
     - Kiểm tra df -h cho workspace và Docker storage; chọn ổ đủ chỗ cho bag và image/cache.
   * - Bag thiếu hoặc không đọc được
     - Kiểm tra đúng bind mount và file đầy đủ; rosbag info phải đọc được bag trước calibration.
   * - Không tìm thấy topic hoặc không có ảnh
     - Đọc rosbag info và dùng đúng tên topic ảnh cùng kiểu dữ liệu phù hợp.
   * - Không phát hiện bảng
     - Kiểm tra hình ảnh, độ rõ tag, hình học target.yaml và bảng thực tế; không sửa kích thước tùy ý.
   * - Container bị killed khi build
     - Kiểm tra tài nguyên; nếu thiếu RAM, giảm job catkin build, ví dụ -j2 -p2, rồi build lại.

Lệnh chạy nhanh khi đã có image và dữ liệu
----------------------------------------------------------------------------------------------------

Host:

.. code-block:: bash

   docker run -it --rm --net=host --ipc=host -w /data \
     -v "$KALIBR_WS/data:/data:rw" kalibr:local

Container:

.. code-block:: bash

   source /catkin_ws/devel/setup.bash
   cd /data
   rosbag info calibration_70.bag
   rosrun kalibr kalibr_calibrate_cameras \
     --target /data/target.yaml --bag /data/calibration_70.bag \
     --topics /camera/image_raw --models pinhole-radtan --dont-show-report
   exit

Host:

.. code-block:: bash

   xdg-open "$KALIBR_WS/data/report-cam-calibration_70.pdf"

Tài liệu tham khảo
----------------------------------------------------------------------------------------------------

* `Kalibr camera calibration <https://github.com/ethz-asl/kalibr/wiki/multiple-camera-calibration>`_
* `Kalibr calibration targets <https://github.com/ethz-asl/kalibr/wiki/calibration-targets>`_
* `Docker bind mounts <https://docs.docker.com/engine/storage/bind-mounts/>`_
