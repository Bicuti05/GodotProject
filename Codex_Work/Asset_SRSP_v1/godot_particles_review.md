# Godot Gameplay Particles

Bổ sung 24 PNG cho hiệu ứng gameplay, băng và mở ô Outer Loop. Bản nguồn nằm trong `source/`.

- Hạt dùng ở Home, màn kết quả, mở dây và mở túi giữ lưới 2 × 2, 3 × 3 hoặc 6 × 6 theo từng slot. Kiểm tra từng ô đều có hình và có viền trong suốt để tránh lẫn sang ô kế bên. Hai atlas hạt trắng để scene áp màu.
- Nhóm băng có tia lóe, mảnh băng và bông tuyết riêng. Hạt cộng sáng Outer Loop giữ nền đen và alpha đặc để tương thích với blend cộng.
- Godot headless đọc và tạo texture được cho cả 24 PNG trong project kiểm riêng. Checker báo 20 OK, 4 WARN và 0 FAIL. Các cảnh báo thuộc một hạt tròn và ba glow dựng mới có phân bố alpha tương tự texture tham chiếu. Tint và chuyển động trong scene vẫn chưa được xác minh.

[Contact sheet nền tối](contact_sheets/godot_particles_dark.png) · [Nền sáng](contact_sheets/godot_particles_light.png) · [Báo cáo kiểm](report_godot_particles.csv)
