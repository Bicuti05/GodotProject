# Ghi chú lô màn 2–25

- Màn 2 dùng 5 loại theo khung `khung_types_all` và ưu tiên ít loại ở màn đầu. Quy tắc 8–10 loại áp dụng từ màn 3 trong lô này.
- Điểm tự ước lượng nội suy giữa trung điểm các khoảng `lw` của README LevelGen mục 5.1, giới hạn từ 10,2 đến 69,5. Mục tiêu dưới 10,2 vẫn có độ lệch trong báo cáo dù bot thắng thường xuyên. Điểm của bên kiểm độc lập mới dùng để chốt.
- Thư mục candidates giữ các phương án đã qua solver và lọc cấu trúc. Số ứng viên giữ được mỗi nhóm phụ thuộc vào lời giải và kết quả lọc. Mỗi nhóm ở lô đầu đã sinh 16 phương án trước khi lọc.

## Lô màn 26–50

- Đã sinh 14 ứng viên mỗi nhóm. Sáu nhóm có ít lựa chọn nhận thêm 12 ứng viên mỗi nhóm. Các cấu hình khác nhau thử thay đổi lượng hoa đầu màn, độ xáo đầu dây và độ phụ thuộc giữa các hàng chờ.
- Tất cả phương án lưu được đã qua `JuiceLevel.validate()` và có lời giải trên Godot 4.6.1. `lw_screen` là tỷ lệ thắng của 30 ván epsilon-greedy 0,45, seed 11. Chỉ những phương án có trường `lw` đã được đo đủ bốn cấu hình × hai seed × 30 ván. `self_report.csv` dùng phép đo đầy đủ.
- Lượt tinh chỉnh đã sinh thêm 14 ứng viên cho mỗi nhóm trong năm nhóm lệch nhất ở lần đo đầu. Báo cáo giữ phương án gần mục tiêu nhất trong những ứng viên đã đo đủ.
