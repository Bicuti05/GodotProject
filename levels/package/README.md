# Gói level Sweet Rope cho Unity (`sweetrope.levelpack/1`)

- `SweetRope_A/Levels/pack_001.json` (màn 1–125, stage 1–5) và `pack_002.json` (màn 126–200, stage 6–8): bản A, một bộ cho mọi người chơi.
- `SweetRope_B/<bộ>/Levels/pack_001.json`, `pack_002.json`: bản B, 5 bộ `default`, `lv2`, `lv3`, `lv4`, `lv5`.
- `SweetRope_A.zip`, `SweetRope_B.zip`: nén các thư mục trên.

## Quy ước

- Định dạng giống thư mục `Levels` của LevelDesigner: 25 màn mỗi stage, 125 màn mỗi pack, `levelIndex` 1–25.
- `difficultyType`: Hard ở màn 5, 10, 15… (như Sort Streak). `difficulty` (1–6) suy từ điểm mục tiêu theo ngưỡng của Sort Streak: < 20,5 → 1; < 38 → 2; < 55 → 3; < 70 → 4; < 85 → 5; còn lại → 6.
- Màn 1 của cả bản A và 5 bộ bản B là cùng một level hướng dẫn: sức chứa 3, 3 cốc, 4 dây (trắng 3-2-3; chậu 1: 1-2-3; chậu 2: 2; chậu 3: 1-1).
- `pack_002` chỉ có màn 126–200. Pack của game hiện có màn 126–250, nên khi nhập cần giữ màn 201–250 cũ (hoặc pack sau màn 200) theo quyết định của dev.
- Tất cả level đã qua `validateLevel` của LevelDesigner (`core.js`, bản port C#): 0 lỗi, 0 cảnh báo. Tính giải được đã chứng minh bằng solver Godot khi sinh, chưa giải lại bằng `BoardSolver` của Unity.
- Các tag Bonus (13, 23, …), Challenge (17, 27, …), Endless (30, 40, …) không ghi vào file level, theo luật đã chốt.
