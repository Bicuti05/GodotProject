# Pending confirmation

## QA-028 · Difficulty trên một bộ level chung

- **Thiết kế đã chốt** — Dùng một bộ level chung. Tăng mức khó theo chuỗi thắng.
- **Checkout hiện tại** — Level Source vẫn đọc UserLevelTag khi chọn nội dung. Source ghi ở workbook Level Unlock, sheet Difficulty Rule.
- **Quyết định cần GD** — Cùng level ID và board chung, bậc lv1–lv5 sẽ thay đổi tham số nào, tại lúc vào ván mới hay chỉ ở lần chuyển level tiếp theo?
- **Ảnh hưởng** — Chọn snapshot để resume, restart, downgrade, assignment A/B và test migration từ build đang dùng tag.

Các mục cần thiết bị hoặc SDK nằm ở Feature Gate và Testability của QA log.

## Quy ước Locked Rope / Sunlight Rope

- **Đề xuất** — Dùng Locked Rope cho cả hai điều kiện: đủ số Container hoặc đủ số Container của một Type ID. Dùng Ice Rope cho visual dạng băng. Giữ Sunlight Rope chờ định nghĩa riêng nếu team cần tên đó.
- **Cần chốt** — Team gọi chung các Rope có điều kiện hay dùng tên Sunlight Rope riêng? Nếu tách, cần chốt mechanic hoặc visual nào mang tên đó.
