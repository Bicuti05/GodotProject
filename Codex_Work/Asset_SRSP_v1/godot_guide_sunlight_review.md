# Godot Guide và Sunlight

Bổ sung 18 PNG cho hướng dẫn, Reset và Sunlight. Các hình hướng dẫn dùng lại trái cây và chậu Sweet Rope. Tên các slot Godot giữ nguyên để scene tải đúng texture.

- Ba ô hướng dẫn trong atlas giữ đúng tọa độ region của `juice_tutorial_layer.tscn`. Các nền và viền là texture riêng.
- Sunlight có mặt trời, bình thu rỗng, thân băng và lớp tuyết riêng. Đã kiểm phần giữa thân băng và bình thu có alpha bán trong suốt để các lớp phía sau vẫn đọc được.
- Checker ghi 17 OK, 1 WARN và 0 FAIL. Cảnh báo thuộc glow ellipse của Streak, dựng mới từ hàm bán kính có phân bố alpha gần bản tham chiếu. Godot headless đọc được cả 18 PNG trong project kiểm riêng. Tỉ lệ hiển thị, hoạt cảnh và hiệu ứng làm tan băng trong scene vẫn chưa được xác minh.

[Contact sheet nền tối](contact_sheets/godot_guide_sunlight_dark.png) · [Nền sáng](contact_sheets/godot_guide_sunlight_light.png) · [Báo cáo](report_godot_guide_sunlight.csv)
