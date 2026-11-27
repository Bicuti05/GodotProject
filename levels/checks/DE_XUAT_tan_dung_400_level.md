# Đề xuất tận dụng 400 level cũ (bản A trên New_Level và SR_Final_1-200)

Chấm lại bằng `diem_lw` (xem `REPORT_do_tin_cay_cach_cham.md`). Hai file đề xuất được tính bằng ghép tối ưu (Hungarian), giữ đúng: mốc cơ chế theo màn đích (hoa ẩn từ màn 6, khóa theo màu từ màn 11, khóa theo số lần từ màn 21), màn bonus phải có màu chỉ 1 chậu, level phải giải được. Bản B thêm luật 8–10 loại hoa từ màn 3. Ngưỡng "dùng được": lệch không quá 8 điểm.

- `de_xuat_xep_lai_ban_A.csv`: nếu cho phép đổi vị trí, 198/200 màn bản A có level lệch ≤ 8 (sai số TB 2.8), gồm 123 level bộ A và 75 level SR_Final. Gần như mọi level đổi vị trí. Giữ nguyên vị trí hiện tại thì bộ A lệch TB +18.4 (sai số 21.6).
- `de_xuat_tan_dung_cho_ban_B.csv`: level không dùng cho A lấp được 106/680 nhóm của bản B (chủ yếu lv4, lv5 vì SR_Final khó), trong đó 101 nhóm từ màn 26 trở đi.
- Lưu ý: điểm bộ A chưa chắc chắn (xem báo cáo độ tin cậy). Level SR_Final là định dạng Unity; 24 màn có hoa ẩn ở cuối mục incoming (Godot từ chối, Unity cho phép).
- Đề xuất này chưa được chép vào `final/`; cần GD duyệt trước.
