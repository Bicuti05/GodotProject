# Kiểm bộ B, màn 121–160

Chấm bằng `tools/score.py` (cột `diem_lw`). Luật lọc: hợp lệ, giải được (solver 60 000 nút, hoặc bot greedy thắng ít nhất 1 ván), đúng mốc cơ chế, bonus, 8–10 loại hoa, ≤ 1 dây khóa, **sức chứa đúng bằng Sort Streak cùng màn cùng bộ**. Chọn phương án lệch ít nhất, chép vào `final/<bộ>/level_###.json`.

- 40 nhóm, 40 nhóm có phương án đạt luật. Sai số TB tuyệt đối 6.0; 23 nhóm lệch ≤ 5, 9 nhóm 5–10, 8 nhóm > 10.
- 0 nhóm dùng bản chính thức, 40 nhóm dùng candidates.

## Cần sinh lại (lệch > 10)

| Màn | Nhóm | Mục tiêu | Điểm đo lại | Lệch | Hướng sửa |
|---|---|---|---|---|---|
| 125 | A | 41.0 | 64.62 | +23.6 | làm dễ hơn |
| 145 | A | 31.0 | 15.32 | -15.7 | làm khó hơn |
| 141 | A | 33.0 | 48.34 | +15.3 | làm dễ hơn |
| 149 | A | 28.0 | 13.35 | -14.7 | làm khó hơn |
| 154 | A | 15.0 | 0.84 | -14.2 | làm khó hơn |
| 124 | A | 22.0 | 8.54 | -13.5 | làm khó hơn |
| 132 | A | 22.0 | 8.54 | -13.5 | làm khó hơn |
| 152 | A | 24.0 | 36.84 | +12.8 | làm dễ hơn |
