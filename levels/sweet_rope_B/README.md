# Bản B: năm bộ level như Sort Streak

| Thư mục | Ai ghi | Nội dung |
|---|---|---|
| `final/default`, `final/lv2` … `final/lv5` | AI kiểm (sau khi kiểm) | Bộ level giao cho dev, mỗi bộ `level_002.json` … `level_200.json` |
| `work/` | AI sinh level | Level đã sinh theo nhóm (`L<màn>_<các bộ>.json`), `work/candidates/`, `assignment.csv`, `self_report.csv` |
| `reports/` | AI kiểm | Kết quả kiểm từng lượt: hợp lệ, giải được, độ khó đo lại, điều kiện bonus |
| `docs/` | | `Prompt_sinh_level_B.md` (prompt cho AI sinh level), `targets_B.csv` (680 nhóm cần sinh, điểm mục tiêu), `SweetRope_AB_tong_hop.xlsx` (A/B, vị trí đặc biệt, luật tái sử dụng), `README_LevelGen.md` (định dạng, luật, cách đo độ khó) |
| `tools/` | | `validate_level.gd` (hợp lệ, giải được), `greedy_ext.gd` (đo độ khó `lw`) |

Điểm độ khó do AI sinh level tự ghi chỉ để tham khảo. Điểm dùng để chọn level là điểm AI kiểm đo lại.
