# Godot Progress, Rank Trails và Home

29 PNG có bản nguồn tương ứng trong `source/`.

- Progress Bling có 12 texture màu và một texture Excellent. Shader lấy RGB từ các bảng màu và lấy alpha từ mask riêng. Các mask giữ vùng giữa trong suốt. `mask_outer.png` giữ kích thước gốc để dùng với thông số nine-slice L80/T80/R80/B0 hiện có.
- Hiệu ứng Rank và Home có vệt chuyển động, đốm sáng và biến thể sao trắng/vàng. Hạt của Progress Bling dùng alpha trắng để shader áp màu khi chạy.
- Checker ghi 27 OK, 2 WARN, 0 FAIL. Vệt Rank ngắn có vùng hình cao bằng 71% bản tham chiếu. Mặt nạ ripple `unity_frame.png` được dựng mới từ hình học bo góc và có phân bố alpha tương tự bản tham chiếu.
- Godot 4.7.2 headless đọc và tạo texture thành công cho 29 PNG trong project kiểm riêng. Hiển thị shader và chuyển động trong scene vẫn chưa được xác minh.

[Contact sheet nền tối](contact_sheets/godot_progress_trails_dark.png) · [Nền sáng](contact_sheets/godot_progress_trails_light.png) · [Báo cáo kiểm](report_godot_progress_trails.csv)
