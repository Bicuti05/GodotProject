# Godot Streak

Bổ sung 29 PNG theo manifest. Bộ gồm 19 lớp banner ba cấp, 9 lớp cúp mừng chuỗi thắng và một hạt sáng. Các tên kỹ thuật `flower_*` được giữ để scene tìm đúng resource. Hình hiển thị là nho, cam và táo. Khi làm cúp, dùng vành vàng dập dấu chân mèo để nối với theme mèo nông dân bán trái cây.

- Khung và lòng huy hiệu cấp 3 là hai file riêng. Cúp, từng cụm quả và từng lá cũng là lớp riêng để các node hiện có điều khiển.
- Ảnh ráp cúp dùng vị trí và scale tĩnh từ `streak_celebration.tscn`. Đây là cách rà vị trí và tỉ lệ lớp. Chuyển động và tint trong scene vẫn cần xác minh.
- Godot 4.7.2 headless đọc và tạo texture được cho cả 29 PNG trong project kiểm riêng. Checker báo 27 OK, 2 WARN, 0 FAIL. Hai WARN nằm ở glow cấp 1 và 2 do phân bố alpha hướng tâm tương tự. Hai glow được dựng bằng hàm bán kính và góc.

[Contact sheet nền tối](contact_sheets/godot_streak_dark.png) · [Nền sáng](contact_sheets/godot_streak_light.png) · [Ảnh ráp cúp](contact_sheets/godot_streak_trophy_assembly.png) · [Báo cáo](report_godot_streak.csv)
