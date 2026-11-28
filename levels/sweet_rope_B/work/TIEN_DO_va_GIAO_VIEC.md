# Tiến độ bản B và giao việc (cập nhật 27/11/2026)

Hai AI cùng làm trên branch `New_Level`. Đọc file này trước khi làm tiếp.

## 1. Đã xong

- **Màn 2–25:** đã kiểm, chọn bản và chép vào `final/`. Báo cáo ở `reports/2026-11-27_kiem_man_2-25.md`. Còn 11 nhóm lệch > 10 cần sinh lại.
- **Màn 26–50:** đã kiểm 701 phương án của AI sinh level và chép bản chọn vào `final/`. Báo cáo ở `reports/2026-11-27_kiem_man_26-50.md`: 83 nhóm, sai số trung bình 6,4, 17 nhóm lệch > 10 cần sinh lại.
- **Màn 196–200 (lô thử):** đã sinh, kiểm và chép vào `final/`. Báo cáo ở `reports/2026-11-27_kiem_man_196-200.md`.
- **Màn 146–195:** đã sinh, kiểm, chép `final/` (`reports/2026-11-27_kiem_man_171-195.md`: sai số 8,6, 33 nhóm >10, 1 nhóm thiếu (174 lv5); `..._146-170.md`: 9,8, 43 nhóm >10, 1 nhóm thiếu (155 lv5)).
- **Màn 71–145:** đã sinh, kiểm, chép `final/` (báo cáo `..._121-145` sai số 8,3/25 nhóm >10/1 thiếu; `..._96-120` 10,3/38; `..._71-95` 8,7/29).
- **CÒN THIẾU: màn 51–70** (chưa sinh). Tiếp theo: chạy `loop.sh 70 51 20 10`, rồi sinh lại các nhóm lệch > 10 và các nhóm thiếu (155 lv5, 174 lv5, 1 nhóm trong 121-145 — xem dòng trống `chon` trong csv báo cáo).

## 1b. Bản A (mới)

- Người dùng chốt sinh lại bản A theo khung `default` Sort Streak (sức chứa bằng đúng), mục tiêu là đường riêng của A. **AI sinh level làm màn 2–91**, AI kiểm làm 92–200. Chi tiết: `levels/sweet_rope_A/work/GIAO_VIEC_A.md`.
- Bản B màn 51–70 và 28 nhóm sửa ở 2–50 (commit c70a838) chờ AI kiểm chấm lại.

## 2. Luật mới (người dùng chốt)

- **Sức chứa (`capacity`) phải bằng đúng** `khung_sort_streak_cap` của Sort Streak ở cùng màn, cùng bộ. `check.py` loại mọi phương án sai sức chứa.
- Các luật cũ vẫn giữ: mốc cơ chế, bonus, 8–10 loại hoa, tối đa 1 dây khóa, phải giải được.

## 3. Giao việc cho AI sinh level (nếu còn token)

1. `git pull`. Xem commit mới nhất để biết lô top-down đã đi xuống tới màn nào. **Không sinh các màn đã có báo cáo top-down.**
2. Làm tiếp các màn còn thiếu theo chiều đi lên, từ màn 51 đến màn ngay dưới lô top-down thấp nhất. Có thể dùng luôn pipeline:
   ```bash
   cp levels/sweet_rope_B/work/tools/validate_big.gd levels/sweet_rope_B/tools/greedy_ext.gd .godot/
   TMPDIR_B=/tmp/srb bash levels/sweet_rope_B/work/tools/loop.sh <màn_cao> <màn_thấp> 25 10
   ```
   `loop.sh` tự sinh, kiểm, chấm, chọn, ghi `work/`, `final/`, `reports/`, rồi commit và push.
3. Sinh lại các nhóm lệch > 10 trong các file `reports/*.md`. Đặt biến `REDO` là danh sách tên file (cách nhau bằng dấu phẩy) rồi chạy `pipeline.py`. Ví dụ:
   ```bash
   REDO=L031_lv4+lv5.json,L047_lv2.json python3 levels/sweet_rope_B/work/tools/pipeline.py 26 50 16 /tmp/srb/redo
   ```
   Sau đó chạy `check.py` cho dải màn đó. `pipeline.py` chỉ thay bản chính thức khi bản mới gần mục tiêu hơn.

## 4. Công cụ (`work/tools/`)

- `gen.py`: sinh một level theo khung Sort Streak (sức chứa, số cốc, số dây, số loại hoa, số hoa ẩn, khóa). Núm chính là `mix` (tỉ lệ hoa bị trộn khỏi dây nhà). Hiệu chỉnh trên lô thử: mix 0,05 → ~2 điểm, 0,10 → ~35, 0,15 → ~57, 0,20 → ~77, 0,25 → ~92. Mix > 0,24 hay cho level không giải được.
- `pipeline.py`: sinh N ứng viên mỗi nhóm, chạy `validate_big.gd` (solver 60 000 nút) và `greedy_ext.gd` (4 shard), chấm bằng `score.py`, ghi `work/`.
- `check.py`: lọc theo luật, chọn phương án lệch ít nhất, chép vào `final/`, ghi `reports/`.
- Godot 4.6.1: tải `https://github.com/godotengine/godot/releases/download/4.6.1-stable/Godot_v4.6.1-stable_linux.x86_64.zip`. Chạy `godot --headless --path . --import` một lần trước khi chạy script.
