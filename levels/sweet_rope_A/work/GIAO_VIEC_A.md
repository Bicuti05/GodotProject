# Giao việc bản A: AI sinh level làm màn 2–91 (90 level)

Người dùng đã chốt sinh lại bản A (27–28/11/2026). AI kiểm đang làm **màn 92–200, từ trên xuống**. AI sinh level làm **màn 2–91** (90 level). **Không** sinh màn ngoài dải của mình. Màn 1 giữ nguyên.

## Yêu cầu (người dùng chốt)

1. **Khung bám bộ `default` của Sort Streak ở cùng màn**: `capacity` **bằng đúng** `khung_sort_streak_cap`, số dây lúc mở = `khung_cols`, số cốc gần `khung_tgt`, 8–10 loại hoa. Khung từng màn có sẵn trong `levels/sweet_rope_A/work/targets_A.csv` (cùng định dạng với `targets_B.csv`; cột `group` = `A`, `file` = `level_###.json`).
2. **Điểm mục tiêu là đường riêng của bản A**: cột `muc_tieu` trong `targets_A.csv`, lấy từ `diem_muc_tieu` của `levels/sweet_rope_A/report.csv`. Không dùng điểm của bản B.
3. Các luật khác giống bản B: hợp lệ, giải được, hoa ẩn từ màn 6, `collect_type` từ màn 11, `collect_count` từ màn 21, tối đa 1 dây khóa, màn bonus (13, 23, …) có ít nhất 1 màu chỉ có 1 chậu, không chép Sort Streak.
4. Chấm bằng `levels/sweet_rope_B/tools/score.py` (`diem_lw`); sinh ≥ 10 ứng viên mỗi màn, chọn bản lệch ít nhất.

## Ghi file

- Ghi tất cả vào `levels/sweet_rope_A/work/gen_2-91/`:
  - bản đề xuất: `level_###.json`;
  - ứng viên: `candidates/level_###.json` (mảng `{uid, raw, lw, diem_lw}`);
  - tự chấm: `self_report.csv` (cột `slot, group, file, valid, solvable, lw, diem_lw, muc_tieu, lech`).
- **Không ghi đè** `levels/sweet_rope_A/level_###.json`: AI kiểm sẽ kiểm rồi chép vào đó.
- Commit và push lên `New_Level` sau mỗi khoảng 25 màn (git pull merge trước; không force push).

## Cách nhanh (dùng pipeline có sẵn)

```bash
cp levels/sweet_rope_B/work/tools/validate_big.gd levels/sweet_rope_B/tools/greedy_ext.gd .godot/
export TARGETS=levels/sweet_rope_A/work/targets_A.csv WORK=levels/sweet_rope_A/work/gen_2-91
python3 levels/sweet_rope_B/work/tools/pipeline.py 2 91 14 /tmp/sra2
```

Lệnh này ghi `work/gen_2-91/level_###.json`, `work/gen_2-91/candidates/` và `work/gen_2-91/self_report.csv`. Cũng có thể dùng bộ sinh của bạn, miễn là đúng các yêu cầu trên. Núm `mix` của `gen.py`: 0,05 → ~2 điểm, 0,10 → ~35, 0,15 → ~57, 0,20 → ~77.
