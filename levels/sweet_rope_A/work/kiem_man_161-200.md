# Kiểm bộ B, màn 161–200

Chấm bằng `tools/score.py` (cột `diem_lw`). Luật lọc: hợp lệ, giải được (solver 60 000 nút, hoặc bot greedy thắng ít nhất 1 ván), đúng mốc cơ chế, bonus, 8–10 loại hoa, ≤ 1 dây khóa, **sức chứa đúng bằng Sort Streak cùng màn cùng bộ**. Chọn phương án lệch ít nhất, chép vào `final/<bộ>/level_###.json`.

- 40 nhóm, 40 nhóm có phương án đạt luật. Sai số TB tuyệt đối 7.2; 16 nhóm lệch ≤ 5, 16 nhóm 5–10, 8 nhóm > 10.
- 0 nhóm dùng bản chính thức, 40 nhóm dùng candidates.

## Cần sinh lại (lệch > 10)

| Màn | Nhóm | Mục tiêu | Điểm đo lại | Lệch | Hướng sửa |
|---|---|---|---|---|---|
| 189 | A | 29.0 | 4.74 | -24.3 | làm khó hơn |
| 173 | A | 24.0 | 2.01 | -22.0 | làm khó hơn |
| 179 | A | 28.0 | 6.13 | -21.9 | làm khó hơn |
| 200 | A | 43.0 | 57.61 | +14.6 | làm dễ hơn |
| 192 | A | 29.0 | 15.32 | -13.7 | làm khó hơn |
| 171 | A | 22.0 | 8.54 | -13.5 | làm khó hơn |
| 194 | A | 22.0 | 8.54 | -13.5 | làm khó hơn |
| 191 | A | 19.0 | 30.43 | +11.4 | làm dễ hơn |
