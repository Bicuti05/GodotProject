# Báo cáo Sweet Rope: bản A và bản B (28/11/2026)

Báo cáo chung duy nhất cho toàn bộ level đã sinh. Bản A: 200 màn, một bộ cho mọi người chơi, mục tiêu theo đường độ khó riêng. Bản B: 5 bộ (`default`, `lv2`–`lv5`) × 199 màn (màn 1 dùng level hướng dẫn), mục tiêu bằng `summaryScore` của Sort Streak cùng màn cùng bộ; các bộ có cùng điểm ở cùng màn dùng chung một level (680 level).

**Cách đo:** điểm "thực tế" là điểm bot (`tools/score.py`, cột `diem_lw`), sai số khoảng ±9 mỗi level; màn trên 70 điểm bị chấm thấp khoảng 18.

## 0. Tóm tắt

- Mọi level theo luật Sort Streak: không dây nào đầy sẵn đúng màu chậu (lúc mở và khi vào từ hàng chờ), tối đa 3 hoa thường cùng màu liền nhau (hoa ẩn không tính).
- Tất cả level đúng sức chứa của Sort Streak cùng màn cùng bộ (bản A theo bộ `default`), ≤ 14 cốc, ≤ 7 dây, giải được (solver Godot hoặc bot thắng).
- Sinh lại 875 level vi phạm luật Sort Streak (199 màn A, 676 nhóm B); các bản sinh lại này cùng mọi ứng viên đã chấm tạo thành kho level cho bước phân phối dưới đây.
- Phân phối kho level đã chấm (mỗi level dùng một lần) vào 863 ô màn 10–200 bản A và mọi nhóm bản B trừ màn đầu đã chốt dễ: 863 ô đạt ±5 so với mục tiêu quy về thang bot, sai số TB 0.9.
- Trùng lặp với 21 325 level có sẵn trong project: 0 level giống > 80% (giống nhất 0.667).
- Luật LevelDesigner (`validateLevel`, bản port C#): 1195 level, 0 lỗi, 0 cảnh báo.
- Gói Unity `sweetrope.levelpack/1`: `levels/package/SweetRope_A.zip`, `levels/package/SweetRope_B.zip`.

## 1. Độ khó dự kiến (mục tiêu) và thực tế (đo bằng bot, `diem_lw`)

Lệch tính so với mục tiêu quy về thang bot: bằng mục tiêu nếu ≤ 70; trên 70 thì lấy mục tiêu − 18 (không dưới 55), vì bot chấm thấp khoảng 18 điểm ở vùng này.

| Bộ | Số màn | Mục tiêu TB | Đo TB | Lệch TB (có dấu) | Sai số TB | ≤ 5 | 5–10 | > 10 |
|---|---|---|---|---|---|---|---|---|
| A | 200 | 21.2 | 20.9 | -0.3 | 0.9 | 197 | 3 | 0 |
| default | 199 | 21.1 | 20.7 | -0.4 | 1.2 | 195 | 4 | 0 |
| lv2 | 199 | 26.7 | 26.4 | -0.3 | 1.0 | 198 | 1 | 0 |
| lv3 | 199 | 39.9 | 39.7 | -0.2 | 0.9 | 198 | 1 | 0 |
| lv4 | 199 | 51.2 | 48.4 | +0.1 | 0.9 | 198 | 1 | 0 |
| lv5 | 199 | 59.6 | 53.3 | -0.1 | 1.0 | 198 | 1 | 0 |

Theo chặng 25 màn (mục tiêu → đo):

| Màn | A | default | lv2 | lv3 | lv4 | lv5 |
|---|---|---|---|---|---|---|
| 1–25 | 11.1 → 10.3 | 14.6 → 11.9 | 18.6 → 17.5 | 25.7 → 24.6 | 30.8 → 30.0 | 35.5 → 33.9 |
| 26–50 | 19.9 → 19.9 | 20.6 → 20.5 | 27.9 → 27.6 | 44.2 → 43.8 | 55.3 → 54.3 | 62.6 → 56.8 |
| 51–75 | 20.2 → 19.8 | 21.0 → 20.9 | 27.2 → 27.0 | 40.3 → 40.2 | 51.7 → 48.8 | 61.6 → 55.4 |
| 76–100 | 21.0 → 20.5 | 22.6 → 22.4 | 25.5 → 25.7 | 42.1 → 41.9 | 54.4 → 50.8 | 62.4 → 55.5 |
| 101–125 | 22.3 → 22.0 | 22.2 → 22.3 | 29.4 → 29.2 | 41.9 → 42.1 | 52.4 → 49.1 | 61.0 → 54.1 |
| 126–150 | 23.0 → 22.8 | 21.3 → 20.8 | 27.5 → 27.3 | 41.5 → 41.7 | 54.4 → 50.4 | 62.5 → 57.1 |
| 151–175 | 25.4 → 25.2 | 22.0 → 22.2 | 28.5 → 28.4 | 42.7 → 42.7 | 54.4 → 51.2 | 65.9 → 56.4 |
| 176–200 | 26.4 → 26.7 | 24.6 → 24.5 | 28.5 → 28.2 | 40.3 → 40.4 | 55.0 → 51.8 | 64.6 → 56.5 |

## 2. Bot: tỉ lệ thắng và số bước khi thắng (playtime)

Bốn cấu hình bot greedy có nhiễu, mỗi cấu hình 2 seed × 30 ván. Playtime ước lượng = số bước TB × 3 giây/bước (giả định).

| Bộ | Thắng eps0.3 | Thắng eps0.45 | Thắng eps0.6 | Thắng softmaxT4 | Thắng TB | Số bước TB | Playtime ước lượng |
|---|---|---|---|---|---|---|---|
| A | 62% | 58% | 53% | 57% | 57% | 64 | 3.2 phút |
| default | 61% | 58% | 53% | 58% | 57% | 64 | 3.2 phút |
| lv2 | 51% | 49% | 44% | 49% | 48% | 65 | 3.3 phút |
| lv3 | 31% | 30% | 27% | 31% | 30% | 70 | 3.5 phút |
| lv4 | 21% | 22% | 20% | 22% | 21% | 70 | 3.5 phút |
| lv5 | 16% | 18% | 16% | 17% | 17% | 69 | 3.4 phút |

Theo chặng (thắng TB % / số bước TB):

| Màn | A | default | lv2 | lv3 | lv4 | lv5 |
|---|---|---|---|---|---|---|
| 1–25 | 78% / 57 | 73% / 60 | 63% / 63 | 52% / 66 | 46% / 67 | 41% / 65 |
| 26–50 | 60% / 64 | 57% / 68 | 46% / 68 | 24% / 72 | 15% / 73 | 13% / 68 |
| 51–75 | 59% / 63 | 57% / 64 | 47% / 65 | 28% / 72 | 19% / 69 | 14% / 71 |
| 76–100 | 57% / 64 | 54% / 63 | 50% / 65 | 26% / 72 | 18% / 67 | 14% / 62 |
| 101–125 | 54% / 64 | 55% / 66 | 44% / 67 | 27% / 72 | 19% / 67 | 14% / 71 |
| 126–150 | 54% / 68 | 57% / 62 | 47% / 65 | 26% / 70 | 19% / 76 | 13% / 73 |
| 151–175 | 49% / 66 | 55% / 60 | 44% / 63 | 26% / 66 | 17% / 67 | 12% / 69 |
| 176–200 | 47% / 63 | 50% / 71 | 45% / 66 | 29% / 67 | 18% / 72 | 13% / 70 |

## 3. Bố cục: level mới so với Sort Streak cùng màn, cùng bộ (TB mới / TB Sort Streak, % màn khớp đúng)

| Bộ | Sức chứa | Số dây đầu | Số cốc | Số màu | Hoa ẩn | Dây khóa | Độ dài hàng chờ |
|---|---|---|---|---|---|---|---|
| A | 5.0 / 5.0 (100%) | 6.5 / 6.4 (89%) | 10.9 / 11.1 (41%) | 8.8 / 8.8 (68%) | 2.5 / 1.9 (22%) | 0.1 / 0.5 (68%) | 9.9 / 10.1 (41%) |
| default | 5.0 / 5.0 (100%) | 6.5 / 6.4 (92%) | 10.8 / 11.1 (44%) | 8.8 / 8.8 (67%) | 2.0 / 1.9 (22%) | 0.1 / 0.5 (69%) | 9.8 / 10.1 (44%) |
| lv2 | 5.0 / 5.0 (100%) | 6.5 / 6.4 (93%) | 10.9 / 11.1 (43%) | 8.8 / 8.8 (70%) | 2.4 / 2.0 (20%) | 0.1 / 0.5 (71%) | 9.9 / 10.1 (43%) |
| lv3 | 5.0 / 5.0 (100%) | 6.5 / 6.4 (93%) | 11.1 / 11.3 (36%) | 8.9 / 8.9 (77%) | 2.6 / 2.6 (19%) | 0.2 / 0.5 (72%) | 10.1 / 10.3 (36%) |
| lv4 | 5.0 / 5.0 (100%) | 6.5 / 6.4 (89%) | 11.0 / 11.3 (36%) | 8.9 / 8.9 (77%) | 2.8 / 2.6 (23%) | 0.2 / 0.6 (71%) | 10.0 / 10.3 (36%) |
| lv5 | 5.0 / 5.0 (100%) | 6.6 / 6.4 (85%) | 11.0 / 11.5 (34%) | 8.9 / 8.9 (75%) | 2.9 / 2.7 (23%) | 0.2 / 0.6 (66%) | 10.0 / 10.5 (34%) |

## 4. Bonus

- **A**: 19 màn bonus cố định, 19 đạt luật (có màu chỉ 1 chậu). Ngoài vị trí bonus còn **181 màn** cũng đủ điều kiện bonus.
- **default**: 19 màn bonus cố định, 19 đạt luật (có màu chỉ 1 chậu). Ngoài vị trí bonus còn **180 màn** cũng đủ điều kiện bonus.
- **lv2**: 19 màn bonus cố định, 19 đạt luật (có màu chỉ 1 chậu). Ngoài vị trí bonus còn **180 màn** cũng đủ điều kiện bonus.
- **lv3**: 19 màn bonus cố định, 19 đạt luật (có màu chỉ 1 chậu). Ngoài vị trí bonus còn **180 màn** cũng đủ điều kiện bonus.
- **lv4**: 19 màn bonus cố định, 19 đạt luật (có màu chỉ 1 chậu). Ngoài vị trí bonus còn **180 màn** cũng đủ điều kiện bonus.
- **lv5**: 19 màn bonus cố định, 19 đạt luật (có màu chỉ 1 chậu). Ngoài vị trí bonus còn **180 màn** cũng đủ điều kiện bonus.

Chi tiết màn ngoài vị trí bonus nhưng đủ điều kiện (màu chỉ có 1 chậu): xem cột `mau_1_chau` trong file chi tiết.

## 5. Tag đặc biệt

| Bộ | Hướng dẫn | Hard | Bonus | Challenge | Endless |
|---|---|---|---|---|---|
| A | 1 | 40 | 19 | 19 | 18 |
| default | 0 | 40 | 19 | 19 | 18 |
| lv2 | 0 | 40 | 19 | 19 | 18 |
| lv3 | 0 | 40 | 19 | 19 | 18 |
| lv4 | 0 | 40 | 19 | 19 | 18 |
| lv5 | 0 | 40 | 19 | 19 | 18 |


## 6. Kiểm trùng lặp

So mỗi level mới với mọi level có sẵn: GD_Lazy (branch main), LevelDesigner/Levels (pack, variant, challenge), `assets/builtin`, `assets/game`, bản A cũ. Độ giống = tỉ lệ vị trí (chậu + hoa) trùng nhau sau khi đổi tên màu tối ưu. Level mới không so với nhau.

- Màn 1 bản A (level hướng dẫn giữ nguyên từ bản cũ) không tính, vì chỉ trùng với chính nó; so với Sort Streak giống 0,39.

- Giống > 80%: **0** level. Giống > 70%: 0 level.

| Level | Giống nhất | Level gần nhất |
|---|---|---|
| A/level_050 | 0.667 | GD_Lazy/Level Difficulty/Generated/SR_Final_1-200/Levels/Variants/ab_10.json#784 |
| B/B|170|lv2 | 0.625 | GD_Lazy/Level Difficulty/Generated/SR_Final_1-200/Levels/Variants/ab_10.json#784 |
| A/level_099 | 0.623 | A_cu/level_186 |
| B/B|130|lv2 | 0.611 | GD_Lazy/Level Difficulty/Generated/SR_trial_S1-3/Levels/Variants/ab_10.json#1470 |
| A/level_119 | 0.607 | A_cu/level_186 |

## 7. Luật LevelDesigner và sửa cấu trúc

- Kiểm bằng `validateLevel` của LevelDesigner (`levels/sweet_rope_B/work/tools/designer/core.js`): 1195 level, 0 lỗi, 0 cảnh báo.
- Đã sửa: 2 level có 15 cốc (Unity tối đa 14): bản A màn 86 và bản B màn 36 `lv2`, sinh lại; thêm luật ≤ 14 cốc vào bộ kiểm.
- Không giải lại bằng `BoardSolver` của Unity (theo yêu cầu); tính giải được đã chứng minh khi sinh.

## 8. Sinh lại theo luật Sort Streak

Level cũ có dây đầy sẵn đúng màu chậu (giao cốc ngay khi vào màn) và chuỗi 4–6 hoa cùng màu liền nhau; Sort Streak không có màn nào như vậy. Mỗi level lỗi được sinh lại 16–48 ứng viên đúng luật (đổi hoa chỉ trong bàn chơi hoặc trong hàng chờ), chấm nhanh, chấm đầy đủ 3–4 bản gần mục tiêu nhất, chọn bản gần nhất mà bot thắng được.

| Bản | Số level sinh lại | Sai số TB | Lệch ≤ 5 | Lệch > 10 |
|---|---|---|---|---|
| A | 199 | 6.8 | 118 | 34 |
| B | 676 | 7.3 | 344 | 158 |

## 8b. Chơi bừa ở màn đầu (bot chỉ nhìn một nước: đi nước có lợi nhất trước mắt, đôi khi đi bừa; 120 ván mỗi màn)

Yêu cầu cho bản A: màn 2–5 chơi bừa thắng 100%; màn 6–9 chỉ thua 1–2 lần và thua lúc gần cuối; từ màn 10 giữ nguyên. Áp cho bản A màn 2–9, bản B màn 2–5 (cả 5 bộ) và màn 6–9 bộ `default`. Màn 6–9 của lv2–lv5 giữ độ khó mục tiêu Sort Streak. Từ màn 10 giữ nguyên.

| Bản | Màn | Nhóm | Thắng khi chơi bừa | % cốc đã xong khi thua |
|---|---|---|---|---|
| A | 2 | A | 100.0% | – |
| A | 3 | A | 100.0% | – |
| A | 4 | A | 100.0% | – |
| A | 5 | A | 100.0% | – |
| A | 6 | A | 100.0% | – |
| A | 7 | A | 100.0% | – |
| A | 8 | A | 100.0% | – |
| A | 9 | A | 100.0% | – |
| B | 2 | default+lv2+lv3+lv4+lv5 | 100.0% | – |
| B | 3 | default+lv2+lv3+lv4+lv5 | 100.0% | – |
| B | 4 | default+lv2+lv3+lv4+lv5 | 100.0% | – |
| B | 5 | default+lv2+lv3+lv4+lv5 | 100.0% | – |
| B | 6 | default | 100.0% | – |
| B | 7 | default | 100.0% | – |
| B | 8 | default | 100.0% | – |
| B | 9 | default | 99.2% | 92% |

## 9. Biểu đồ theo màn (không làm trơn)

Mỗi bộ một hình: độ khó mục tiêu (cam, nét đứt) và đo thực tế (xanh); tỉ lệ thắng TB của 4 bot; playtime ước lượng (số bước TB khi thắng × 3 giây).

### Bản A

![A](sweet_rope_B/reports/bieu_do/A.png)

### Bản B – default

![default](sweet_rope_B/reports/bieu_do/default.png)

### Bản B – lv2

![lv2](sweet_rope_B/reports/bieu_do/lv2.png)

### Bản B – lv3

![lv3](sweet_rope_B/reports/bieu_do/lv3.png)

### Bản B – lv4

![lv4](sweet_rope_B/reports/bieu_do/lv4.png)

### Bản B – lv5

![lv5](sweet_rope_B/reports/bieu_do/lv5.png)

## 10. Gói Unity

- `SweetRope_A/Levels/pack_001.json` (màn 1–125), `pack_002.json` (126–200); `SweetRope_B/<bộ>/Levels/pack_001.json`, `pack_002.json`.
- `difficultyType` Hard ở màn 5, 10, …; `difficulty` 1–6 suy từ điểm mục tiêu theo ngưỡng của Sort Streak (< 20,5 → 1; < 38 → 2; < 55 → 3; < 70 → 4; < 85 → 5; còn lại 6).
- Màn 1 bản B là chỗ giữ (màn 1 bản A); dev thay bằng level hướng dẫn. `pack_002` chỉ tới màn 200: khi nhập giữ màn 201–250 cũ.
- Bonus, Challenge, Endless không ghi vào file level (theo luật đã chốt); Challenge và Endless hiện là level thường.

## Phụ lục: file số liệu

- Chi tiết từng màn: `bao_cao_AB_chi_tiet.csv`; bonus tiềm năng: `bao_cao_AB_bonus_tiem_nang.csv`; phân phối kho level: `phan_phoi_kho_level.csv`; chơi bừa: `choi_bua_man_2-10.csv`; trùng lặp: `kiem_trung_lap.csv`; sinh lại theo luật: `sua_luat_chuoi_mau.csv` (cùng thư mục `levels/sweet_rope_B/reports/`).
