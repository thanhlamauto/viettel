# Hướng dẫn calibration camera bằng Kalibr và Docker

Nguồn và bản HTML của hướng dẫn Kalibr + Docker, kèm tutorial mentor và kết quả calibration tham khảo. Dùng repo này để tiếp tục biên tập trên máy khác.

- [Hướng dẫn quy trình của mentor — nguồn](calibration/docs/source/index.rst)
- [Bản HTML offline](calibration/docs/html/index.html): tải repo rồi mở file bằng trình duyệt; GitHub không render trực tiếp trang này.
- [Tutorial mentor](calibration/mentor/tutorial-original.md)
- [Log build ban đầu](calibration/mentor/build-session.txt)
- [Dockerfile dùng cấu trúc src/kalibr](calibration/Dockerfile_ros1_20_04)
- [Kết quả tham khảo YAML, TXT, PDF](calibration/docs/source/results/)

## Tiếp tục ở nhà

```bash
git clone https://github.com/thanhlamauto/viettel.git
cd viettel
python3 -m venv calibration/docs/.venv
calibration/docs/.venv/bin/python -m pip install -r calibration/docs/requirements.txt
bash calibration/docs/build.sh
```

Cần Python 3.10 trở lên và hỗ trợ `venv`. Sửa `calibration/docs/source/index.rst` cho nội dung, `_static/custom.css` cho giao diện. Sau khi build, mở `calibration/docs/build/html/index.html` bằng trình duyệt. Trên Linux:

```bash
xdg-open calibration/docs/build/html/index.html
```

Muốn cập nhật bản HTML có sẵn trong repo sau khi sửa và xem lại bản build:

```bash
bash calibration/docs/publish-html.sh
git status --short
```

Nguồn Sphinx là bản để chỉnh sửa; HTML là bản xuất để đọc offline. Giữ cả thư mục HTML khi chia sẻ vì chứa CSS và file tải xuống. Tutorial mentor được giữ riêng để đối chiếu, có các đường dẫn và lỗi đánh máy nguyên bản; dùng hướng dẫn hiện tại khi chạy trên máy khác.

Giao diện ưu tiên iCiel Quarion nếu máy đã cài font đó; bản HTML offline dùng Be Vietnam Pro làm font thay thế có hỗ trợ tiếng Việt. Giấy phép font thay thế nằm tại `calibration/docs/source/_static/fonts/OFL.txt`.

## Dữ liệu chạy calibration

Repo không chứa ROS bag, Docker image hoặc mã Kalibr local. Để chạy calibration, cần tự cung cấp bag, mã Kalibr đầy đủ và bảng target đúng với dữ liệu. File `calibration_70.bag` của phiên làm việc này khoảng 6.9 GB, không được đưa vào Git.

Các kết quả đính kèm là ví dụ thực tế, không phải thông số dùng chung cho mọi camera.
