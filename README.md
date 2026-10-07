# Tutorial Kalibr theo bản mentor

Bộ tài liệu dùng cấu trúc Sphinx và `sphinx_rtd_theme` như `pcs-docs-master.zip`: có trang chủ, menu trái, ô tìm kiếm, trang Index và footer. Trang tutorial giữ nguyên nội dung và các lệnh của [bản mentor gốc](calibration/mentor/tutorial-original.md), chỉ đổi tiêu đề và bỏ phần lời dẫn ở đầu.

- [Trang chủ HTML offline](calibration/docs/html/index.html)
- [Trang tutorial HTML](calibration/docs/html/tutorial-original.html)
- [Nguồn Markdown của trang tutorial](calibration/docs/source/tutorial-original.md)

Để build lại (Python 3.10 trở lên):

```bash
python3 -m venv calibration/docs/.venv
calibration/docs/.venv/bin/python -m pip install -r calibration/docs/requirements.txt
bash calibration/docs/build.sh
bash calibration/docs/publish-html.sh
```

Giữ cả thư mục `calibration/docs/html` khi chia sẻ để giao diện và tìm kiếm hoạt động offline. Repo không chứa ROS bag, Docker image hoặc mã Kalibr. Các lệnh và đường dẫn trong tutorial chưa được sửa hay xác nhận chạy được trên máy khác.
