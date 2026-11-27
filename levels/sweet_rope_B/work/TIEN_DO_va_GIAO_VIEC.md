# Tiến độ bản B và giao việc (cập nhật 27/11/2026)

Hai AI cùng làm trên branch `New_Level`. Đọc file này trước khi làm tiếp.

## 1. Đã xong

- **Màn 2–25:** đã kiểm, chọn bản và chép vào `final/`. Báo cáo ở `reports/2026-11-27_kiem_man_2-25.md`. Còn 11 nhóm lệch > 10 cần sinh lại.
- **Màn 26–50:** đã kiểm 701 phương án của AI sinh level và chép bản chọn vào `final/`. Báo cáo ở `reports/2026-11-27_kiem_man_26-50.md`: 83 nhóm, sai số trung bình 6,4, 17 nhóm lệch > 10 cần sinh lại.
- **Màn 196–200 (lô thử):** đã sinh, kiểm và chép vào `final/`. Báo cáo ở `reports/2026-11-27_kiem_man_196-200.md`.
- **Màn 51–195:** AI kiểm đang sinh **từ trên xuống** (195 → 51), mỗi lô 25 màn. Lô nào xong sẽ có một commit "Generate and check set B levels a-b (top-down batch)" và một file `reports/*_kiem_man_a-b.md`. Xem `git log` để biết đã tới màn nào.

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
