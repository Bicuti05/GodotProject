# Kiểm bộ B, màn 86–86

Chấm bằng `tools/score.py` (cột `diem_lw`). Luật lọc: hợp lệ, giải được (solver 60 000 nút, hoặc bot greedy thắng ít nhất 1 ván), đúng mốc cơ chế, bonus, 8–10 loại hoa, ≤ 1 dây khóa, **sức chứa đúng bằng Sort Streak cùng màn cùng bộ**. Chọn phương án lệch ít nhất, chép vào `final/<bộ>/level_###.json`.

- 1 nhóm, 1 nhóm có phương án đạt luật. Sai số TB tuyệt đối 1.5; 1 nhóm lệch ≤ 5, 0 nhóm 5–10, 0 nhóm > 10.
- 0 nhóm dùng bản chính thức, 1 nhóm dùng candidates.

## Cần sinh lại (lệch > 10)

| Màn | Nhóm | Mục tiêu | Điểm đo lại | Lệch | Hướng sửa |
|---|---|---|---|---|---|
