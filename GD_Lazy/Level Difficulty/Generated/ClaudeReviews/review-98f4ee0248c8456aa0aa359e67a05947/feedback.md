## Kết quả duyệt

**Không thấy số liệu mâu thuẫn hay level lệch ngưỡng nào chưa được đánh dấu.**

| Hạng mục đối chiếu | Kết quả |
|---|---|
| Bảng kiểm cuối | 74 dòng, 44 `ok=True`, 30 `ok=False`, khớp 44/74 |
| Ngưỡng ±2,31 | Cờ `ok` đúng ở cả 74 dòng. Sát ngưỡng: 175 (−2,28) đạt, 121 (+2,64) không đạt |
| `off_by` = score − aim | Khớp ở cả 74 dòng |
| Danh sách chưa đạt | Đủ 30 level; đích, điểm và độ lệch khớp bảng |
| Lời giải theo bảng kit | 74/74 `solvable=True`, không có `frame_errors` |
| Phạm vi đổi trên 35% | 16 giá trị liệt kê đều trên 35%; 118 và 165 đạt, 14 bàn còn lại đã nằm trong danh sách chưa đạt |
| Cách kết luận | Không suy ra vô nghiệm từ điểm ngoài ngưỡng hay lượt giải không xác nhận; không đặt ngưỡng điểm chậm |
| Bàn mẫu 20, 125, 143 | Số container khớp `orderCount`; số item từng loại khớp sức chứa |
| Chi tiết đối chiếu được | Level 20 có `moves`=63; level 143 còn đúng 5 Hidden |

## Nên xác nhận (chưa đủ căn cứ gọi là lỗi)

- Mẫu khóa **143** có `levelIndex: 18`, còn 20 ghi 20 và 125 ghi 25. Mẫu 143 cũng ghi `Normal`/`difficulty: 3`, trong khi hai mẫu kia là `Hard`/`2`. Nên so các trường này với `start_levels`.

## Giới hạn

- **Replay:** kết quả 74/74 trên Level Designer và C# là theo lần chạy cục bộ bạn nêu. Tôi không replay lại và không có log hay `solutions.json` để đối chiếu, kể cả quy ước chỉ số từ 0.
- **Phạm vi thay đổi:** thiếu todo và `start_levels` nên chưa kiểm được đúng 74 level đó, 74 bàn đã đổi, 176 bàn giữ nguyên, ngoại lệ 107 và các tỷ lệ phần trăm.
- **Chi tiết khác:** chưa kiểm được `report.csv`, số lượt chấm, số lượt giải không xác nhận, mức Hidden trước khi giảm (và sau giảm, trừ 143), cũng như việc chỉ đóng gói lần chạy cuối.
