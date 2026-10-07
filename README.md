# Hướng dẫn calibration camera bằng Kalibr và Docker

Một trang tutorial theo quy trình của mentor: clone mã Kalibr, build Docker image, tạo AprilGrid YAML, chạy calibration với ROS bag và lấy kết quả. Bản trình bày dùng Sphinx Read the Docs theme; chỉ ẩn menu bên trái theo yêu cầu.

- [Mở bản HTML offline](calibration/docs/html/index.html) — tải repo, mở `index.html` bằng trình duyệt; GitHub không hiển thị HTML trực tiếp.
- [Nguồn tutorial](calibration/docs/source/index.rst)
- [Tutorial mentor nguyên bản](calibration/mentor/tutorial-original.md)
- [Dockerfile mẫu](calibration/Dockerfile_ros1_20_04)

Để sửa và xuất lại HTML (Python 3.10 trở lên):

```bash
python3 -m venv calibration/docs/.venv
calibration/docs/.venv/bin/python -m pip install -r calibration/docs/requirements.txt
bash calibration/docs/build.sh
bash calibration/docs/publish-html.sh
```

Mở `calibration/docs/html/index.html` sau khi xuất. Giữ nguyên cả thư mục `html` khi chia sẻ để CSS, font và ba file kết quả mẫu đi kèm hoạt động offline.

Repo không chứa ROS bag, Docker image hay mã Kalibr. Người chạy cần quyền truy cập repository Kalibr nội bộ trong Bước 1, cùng dữ liệu và bảng AprilGrid đúng với camera của mình. Kết quả đính kèm chỉ là ví dụ, không dùng trực tiếp cho camera khác.
