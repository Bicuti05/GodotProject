# Kiểm bộ B, màn 2–91

Chấm bằng `tools/score.py` (cột `diem_lw`). Luật lọc: hợp lệ, giải được (solver 60 000 nút, hoặc bot greedy thắng ít nhất 1 ván), đúng mốc cơ chế, bonus, 8–10 loại hoa, ≤ 1 dây khóa, **sức chứa đúng bằng Sort Streak cùng màn cùng bộ**. Chọn phương án lệch ít nhất, chép vào `final/<bộ>/level_###.json`.

- 90 nhóm, 90 nhóm có phương án đạt luật. Sai số TB tuyệt đối 4.5; 53 nhóm lệch ≤ 5, 34 nhóm 5–10, 3 nhóm > 10.
- 88 nhóm dùng bản chính thức, 2 nhóm dùng candidates.

## Cần sinh lại (lệch > 10)

| Màn | Nhóm | Mục tiêu | Điểm đo lại | Lệch | Hướng sửa |
|---|---|---|---|---|---|
| 40 | A | 36.0 | 24.21 | -11.8 | làm khó hơn |
| 63 | A | 17.0 | 6.13 | -10.9 | làm khó hơn |
| 69 | A | 28.0 | 38.17 | +10.2 | làm dễ hơn |
