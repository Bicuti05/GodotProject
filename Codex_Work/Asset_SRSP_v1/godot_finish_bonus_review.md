# Godot Finish, Bonus và hướng dẫn

38 mục drop-in gồm 36 PNG và 2 SVG. Các file đầu ra giữ đường dẫn và kích thước ghi trong manifest. Thư mục `source/` có bản nguồn tương ứng.

- **Finish** — cấp S/A/B, nền bảng điểm theo độ khó, nhãn phản hồi, icon video và phần thưởng Hint/Undo/Extra Rope. Các icon phần thưởng dùng lại art Sweet Rope và được căn vào vùng hình của từng texture Godot.
- **Bonus** — dùng chung hình heo vàng dập táo ở banner, cảnh nạp xu và cảnh đập heo. Các cụm xu PNG dùng art Sweet Rope hiện có. Hai SVG là phiên bản vector có thể sửa, giữ kích thước riêng theo manifest và đã render thử bằng Inkscape.
- **Hiệu ứng** — cầu vồng, tia sáng và tâm sáng là lớp riêng. Khói giữ bốn ô 256 × 256 theo thứ tự đọc trái sang phải, trên xuống dưới, phù hợp lưới 2 × 2 của scene Sunlight. Tệp này cũng được scene đập heo dùng.
- **Kiểm tra** — 36 OK, 2 WARN, 0 FAIL. Hai WARN thuộc các dot Hint có hình alpha tròn tương tự texture gốc. Cả hai được dựng mới bằng hàm falloff. Chưa chạy các scene Godot để xác minh tint, bố cục hoặc chuyển động.

[Contact sheet nền sáng](contact_sheets/godot_finish_bonus_light.png) · [Contact sheet nền tối](contact_sheets/godot_finish_bonus_dark.png) · [Báo cáo](report_godot_finish_bonus.csv)
