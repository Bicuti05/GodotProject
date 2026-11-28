# Kiểm bộ B, màn 92–120

Chấm bằng `tools/score.py` (cột `diem_lw`). Luật lọc: hợp lệ, giải được (solver 60 000 nút, hoặc bot greedy thắng ít nhất 1 ván), đúng mốc cơ chế, bonus, 8–10 loại hoa, ≤ 1 dây khóa, **sức chứa đúng bằng Sort Streak cùng màn cùng bộ**. Chọn phương án lệch ít nhất, chép vào `final/<bộ>/level_###.json`.

- 29 nhóm, 29 nhóm có phương án đạt luật. Sai số TB tuyệt đối 6.9; 14 nhóm lệch ≤ 5, 4 nhóm 5–10, 11 nhóm > 10.
- 0 nhóm dùng bản chính thức, 29 nhóm dùng candidates.

## Cần sinh lại (lệch > 10)

| Màn | Nhóm | Mục tiêu | Điểm đo lại | Lệch | Hướng sửa |
|---|---|---|---|---|---|
| 114 | A | 24.0 | 8.54 | -15.5 | làm khó hơn |
| 101 | A | 16.0 | 0.84 | -15.2 | làm khó hơn |
| 120 | A | 40.0 | 52.84 | +12.8 | làm dễ hơn |
| 119 | A | 28.0 | 15.32 | -12.7 | làm khó hơn |
| 98 | A | 21.0 | 8.54 | -12.5 | làm khó hơn |
| 99 | A | 25.0 | 36.84 | +11.8 | làm dễ hơn |
| 117 | A | 25.0 | 13.82 | -11.2 | làm khó hơn |
| 94 | A | 17.0 | 6.13 | -10.9 | làm khó hơn |
| 103 | A | 17.0 | 6.13 | -10.9 | làm khó hơn |
| 111 | A | 12.0 | 1.34 | -10.7 | làm khó hơn |
| 112 | A | 19.0 | 8.54 | -10.5 | làm khó hơn |
