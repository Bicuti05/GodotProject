# Bản A · Đề xuất màn 2–91

Mỗi level mới giữ đúng sức chứa và số dây mở màn từ `targets_A.csv`. Số cốc nằm trong ±1 so với khung, riêng màn 2 dùng 8 cốc để đáp ứng tối thiểu 8 loại, với khung gốc 5 cốc. Điểm đích là đường của bản A.

Ứng viên được kiểm bằng luật Godot 4.6.1 và chỉ lưu khi có lời giải. `lw_screen` là tỷ lệ thắng sàng lọc của 30 ván epsilon-greedy 0,45, seed 11. Các mục `lw` và `diem_lw` bằng `null` đang chờ đo đầy đủ. Các bản đề xuất đã được đo đủ bốn cấu hình, hai seed, 30 ván mỗi cặp và chấm bằng `score.py`. Bên kiểm có thể đọc `uid` và `raw` trực tiếp từ thư mục ứng viên.

Đã sinh đủ màn 2–91 trong bốn lô. Mỗi màn có ít nhất 14 bố cục ban đầu trước khi lọc, với lượt sinh thêm cho nhóm lệch lớn hoặc thiếu phương án giải được. Điểm tự đo chỉ dùng để đề xuất. Bên kiểm phụ trách xác minh và chọn level giao dev.
