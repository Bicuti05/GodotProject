# SS_Art Handoff – Bàn giao art cho Sort Streak: Color Puzzle

Bản nháp 0.1 · 2026-11-23 · chờ GD và Art lead check · Soạn từ project SortStreak (Godot 4.6.1, Oakever 1.0.10), chỉ đọc, không sửa project.

> **Lưu ý quan trọng về bản quyền.** Art trong zip `SS_Art Reference.zip` là sản phẩm thương mại của Oakever, được lấy từ bản đã giải nén của game. Zip này **chỉ để tham khảo phong cách, bố cục, số lượng và kích thước**. **Không** dùng lại, trace hay vẽ đè lên sprite gốc. Artist vẽ mới hoàn toàn. Không tái tạo logo Oakever (`oakever_games_logo_white`) và không dùng lại tên/nội dung của game gốc.

**Nhãn trạng thái dùng trong file này**
- `Implemented`: có bằng chứng trong mã hoặc scene (có ghi nguồn).
- `Quan sát`: nhận xét của người soạn khi xem ảnh, **không** phải tài liệu gốc. Cần art lead xác nhận.
- `Unverified`: chưa đủ bằng chứng (ví dụ không thấy tham chiếu trực tiếp tới file).
- Kích thước pixel là kích thước file hiện tại, dùng làm **baseline, chưa phải spec**. Chưa kiểm scale và import của Godot nên không khẳng định kích thước hiển thị trong game.

## 1. Tóm tắt game cho artist

- Thể loại: puzzle sort. Người chơi dồn **hoa** cùng màu vào **dây (rope)** có **chậu (pot)** đúng màu. Dây đầy hoa đúng màu thì thu hoạch thành 1 **cốc (cup)**. `Implemented` (juice_rules.gd). Cốc đã thu có thể được vẽ bằng chậu bonsai đầy hoa (`Quan sát`, nơi dùng chưa kiểm).
- **10 màu** hoa (`MAX_TYPES = 10`), tên màu trong file: `blue`, `cyan`, `green`, `lavender`, `orange`, `pink`, `purple`, `red`, `teal`, `yellow`. `Implemented`.
- Dây mang chiều dọc, hoa xếp từ đáy lên đỉnh. Dây trắng (`park`) là dây không chậu, để đặt tạm. `Implemented`.
- Vật thể đặc biệt: hoa ẩn (`?`), dây khóa, hoa băng và chậu băng, Sunlight, đổi gốc. Chi tiết logic xem `SS_Special Object.xlsx`.
- Có hệ **skin**: mặc định là hoa, ngoài ra có skin **Cat** và **Bird**, và theme **Giáng sinh**. Cat/Bird chỉ bật khi A/B `special_theme` khác 0 (mặc định 0 = tắt). Xem mục 4.5. `Implemented` (juice_special_theme_resolver.gd, special_theme_config.gd).

## 2. Phong cách hiện tại (`Quan sát`, cần art lead xác nhận)

Nhận xét sau khi xem hoa, chậu, dây, bonsai, băng, Sunlight, nút helper, skin Cat/Bird và 2 nền Giáng sinh:

- Render **3D mềm, bóng bẩy** (kiểu bóng bay/đất sét/nhựa): hình tròn trịa, bóng sáng (specular) rõ ở trên, cạnh mềm.
- **Không viền đen**. Hình khối tách nền bằng sắc độ và bóng đổ nhẹ phía dưới.
- Màu **bão hòa vừa đến cao**, mỗi màu có 1 tông sáng và 1 tông tối cùng họ để tạo khối. Nền màu trung tính hoặc pastel để màu hoa nổi.
- **Mỗi màu hoa là một loài hoa khác hình** (số cánh, hình cánh, nhụy khác nhau), không chỉ đổi màu. Xem bảng 4.2. Đây là nhận xét; chưa thấy tài liệu nói đó là chủ ý thiết kế.
- Chậu có hoa văn **dập nổi hình đúng loài hoa** của màu đó.
- Skin Cat/Bird dùng nhân vật **mặt tròn dễ thương, mắt to**, cùng bảng màu 10 màu.

## 3. Số lượng asset theo nhóm

Số file ảnh (png/webp/svg) trong `assets/`: **883**. Chưa tính âm thanh, font, shader, file Spine `.skel`, `.tres`, `.tscn`.

| Ưu tiên | Nhóm | Số file | Dung lượng (MB) |
|---|---|---:|---:|
| P0 | Bàn chơi / cột / quota | 23 | 1.5 |
| P0 | Dây khóa (cửa gỗ) | 10 | 1.3 |
| P0 | Halo nhóm / thu hoạch | 38 | 0.5 |
| P0 | Hoa / Chậu / Dây / Bonsai | 64 | 1.6 |
| P0 | Skin Bird | 69 | 5.2 |
| P0 | Skin Cat | 43 | 2.3 |
| P0 | Sunlight / băng | 18 | 3.0 |
| P1 | App icon / launch | 7 | 1.0 |
| P1 | Helper / unlock | 22 | 1.4 |
| P1 | Hướng dẫn (new_guide) | 18 | 0.3 |
| P1 | Màn kết thúc (finish) | 21 | 2.2 |
| P1 | Splash | 3 | 0.9 |
| P1 | Thanh IQ | 2 | 0.0 |
| P1 | Timed Endless UI | 17 | 0.9 |
| P1 | UI chung | 78 | 2.7 |
| P1 | UI trong game (juice_sort) | 11 | 0.3 |
| P2 | Coin Bonus Level | 12 | 5.9 |
| P2 | Effect texture / particle | 130 | 6.3 |
| P2 | Meta: Rank / Challenge / Daily / Home | 171 | 25.1 |
| P2 | Rank collectible | 16 | 1.4 |
| P2 | Spine atlas | 66 | 45.0 |
| P2 | Streak / banner | 32 | 4.5 |
| P2 | Theme Giáng sinh (A/B) | 12 | 2.9 |

Tổng: P0 = 265, P1 = 179, P2 = 439.

Ý nghĩa: **P0** = gameplay (artist làm trước), **P1** = UI chung và màn kết thúc/hướng dẫn, **P2** = meta game, hiệu ứng và sự kiện. Cách chia nhóm do người soạn đề xuất theo tên thư mục và nơi dùng, **chưa phải quyết định của GD**.

## 4. P0 – Gameplay

### 4.1 Bộ asset mặc định cho mỗi màu (skin hoa)

Mỗi màu cần **1 bộ 6 loại sprite** (cộng 1 bộ `park`):

| Sprite | File mẫu | Kích thước hiện tại | Vai trò | Trạng thái |
|---|---|---|---|---|
| Hoa | `flower_{màu}.png` | 200x200 | Phần tử xếp trên dây | Implemented |
| Chậu | `pot_{màu}.png` | 180x184 | Chậu gắn đầu dây, quyết định màu thu hoạch | Implemented |
| Dây – đầu | `rope_{màu}_top.png` | 60x121 | Đoạn trên của dây, có vòng buộc | Implemented (field `rope_top`); hình dạng: Quan sát |
| Dây – giữa | `rope_{màu}_mid.png` | 60x88 | Đoạn thân dây | Implemented (field `rope_mid`) |
| Dây – đáy | `rope_{màu}_bottom.png` | 60x102 | Đoạn dưới của dây, có nút thắt | Implemented (field `rope_bottom`); hình dạng: Quan sát |
| Bonsai (cốc đã thu) | `bonsai_{màu}.png` | 256x261 | Chậu đầy hoa, hiện khi thu hoạch 1 cốc / ở thanh tiến độ | Quan sát, tên theo `completed_container`; nơi dùng chưa kiểm |
| Halo (vầng sáng đi cặp) | `group_halo/flower_{màu}_halo.png` | 194x194 | Mỗi sprite nguồn có 1 halo đi cặp (`JuiceGroupHaloSet`: sources → halos). Thời điểm hiện: chưa kiểm | Implemented (ghép cặp); thời điểm: Unverified |

Cách ghép dây (top + mid kéo hoặc lặp + bottom) và số hàng theo `capacity` chưa kiểm (có A/B `sort_rope_capacity_knots`). `Unverified`.

**Bộ `park` (dây trắng, không chậu)**: `pot_park.png` (180x184), `rope_park_top/mid/bottom.png` (60x121 / 60x88 / 60x102). Là trạng thái cột trống, màu trắng kem, **không phải màu thứ 11**. `Implemented` (juice_level.gd: `SLOT_PARK`).

Tổng bộ mặc định: 10 màu × (hoa + chậu + 3 dây + bonsai) = 60 file, cộng bộ park (1 chậu + 3 dây) = 64 file. Khớp với số file trong thư mục.

### 4.2 Hình dạng từng loài hoa theo màu (`Quan sát`)

Mô tả để artist giữ tính phân biệt hình dạng. Đây là mô tả của người soạn khi nhìn ảnh, cần art lead xác nhận.

| Màu | Quan sát |
|---|---|
| `blue` | hoa 5 cánh tròn dày, nhụy cam nhỏ, màu xanh dương đậm |
| `cyan` | hoa nhiều cánh nhỏ (khoảng 8), nhụy vàng, xanh dương nhạt |
| `green` | hoa 4 thùy kiểu cỏ bốn lá, tâm vàng chuyển xanh lá |
| `lavender` | hoa 5 cánh mềm, tâm vàng, tím nhạt |
| `orange` | hoa 5 cánh có gân, cam chuyển đỏ ở tâm |
| `pink` | hoa 5 cánh gọn, nhụy nhỏ, hồng |
| `purple` | hoa 5 cánh bầu, nhụy cam, tím đậm |
| `red` | dạng dâm bụt (hibiscus), nhụy dài nổi, đỏ |
| `teal` | hoa 5 cánh tròn, nhụy dài, xanh ngọc |
| `yellow` | dạng hướng dương, tâm nâu, nhiều cánh vàng |

### 4.3 Biến thể trên bàn chơi

| Asset | File | Kích thước hiện tại | Ghi chú | Trạng thái |
|---|---|---|---|---|
| Hoa ẩn | `gp_flower_question.png` | 200x200 | Hoa xám có dấu `?`, 1 hình dùng cho mọi màu | Implemented (field `mystery_element`) |
| Ô trống (quota) | `quota_slot_empty.png` | 256x261 | Ô rỗng ở thanh mục tiêu cốc | Quan sát; nơi dùng chưa kiểm |
| Nền thanh quota | `quota_bar_bg.png`, `quota_count_tab.png` | 140x169, 131x62 | | Unverified |
| Bảng gỗ | `board.png` | 1144x243 | Dải gỗ ngang | Unverified |
| Bảng tiến độ chậu | `progress_pot_board.png` | 63x52 | | Unverified |
| Huy hiệu hoa | `flower_badge.png` | 176x171 | Biển gỗ tròn có hoa | Unverified (không thấy tham chiếu trong scripts; thấy trong `juice_lock_overlay.tscn`) |
| Cây bụi hoa trang trí | `flowering_shrubs.png` | 217x1010 | | Unverified (không thấy tham chiếu) |
| Bóng lá phủ nền | `gamepage_bg_leaf_shadow.webp` | 718x1536 | Lớp bóng lá, có trong `juice_game_page.tscn` | Implemented |
| Ánh sáng nền nút helper | `gp_prop_bg_glow.png` | 232x232 | | Unverified |

**Nền màn chơi mặc định**: node `Bg` (TextureRect) trong `juice_game_page.tscn` không gắn ảnh trong scene, và không thấy ảnh nền riêng trong `assets/`. Có thể nền do mã/shader hoặc ảnh khác tạo ra. `Unverified`, cần GD hoặc dev xác nhận trước khi giao việc vẽ nền.

### 4.4 Highlight cột và dấu hiệu (`gp_col_*`)

- `gp_col_highlight_blue_top.png` – 230x302
- `gp_col_highlight_green.png` – 212x284
- `gp_col_highlight_green_bottom.png` – 232x304
- `gp_col_highlight_green_top.png` – 230x302
- `gp_col_highlight_hover_bottom.png` – 230x302
- `gp_col_highlight_red_bottom.png` – 232x304
- `gp_col_highlight_red_top.png` – 232x304
- `gp_col_highlight_ww_blue_top.png` – 230x302
- `gp_col_highlight_ww_hover_bottom.png` – 230x302
- `gp_col_highlight_yellow_bottom.png` – 212x284
- `gp_col_highlight_yellow_top.png` – 230x302
- `gp_col_mark_cross.png` – 88x88
- `gp_col_mark_tick.png` – 88x88

Dùng để tô sáng cột khi chọn/hover và đánh dấu hợp lệ/không hợp lệ (tick/cross). Ý nghĩa từng màu viền (xanh, đỏ, vàng, `ww`) chưa kiểm. `Unverified`.

### 4.5 Skin Cat và Bird

Cấu trúc 1 skin theo `JuiceSkinColorAssets` (**Implemented**, juice_skin_color_assets.gd): mỗi màu cần `element`, `empty_container`, `completed_container`, `target_icon`, `lock_icon`, `rope_top/mid/bottom`; riêng Bird thêm `feather`, `door_atlas`, `open_house`. Dùng chung: `mystery_element`, `parking`, `target_empty_icon`, ảnh hướng dẫn, collectible.

**Khi nào skin xuất hiện** (`Implemented`): `special_theme` A/B = 1 → chỉ vòng Special Challenge; = 2 → Special và các level 12, 22, 32…; = 0 → không dùng (mặc định). Skin chọn xen kẽ: sequence chẵn = `cat`, lẻ = `bird`. Tutorial luôn dùng skin mặc định.

| Skin | Số file | Mỗi màu | Dùng chung (không theo màu) |
|---|---:|---|---|
| Cat | 43 | `element_{c}` (~200–210), `empty_{c}` (180x187), `completed_{c}` (256x261), `completed_head_{c}` (320x320) | `mystery_element` (200x200), `parking` (180x187), `target_empty_icon` (163x164) |
| Bird | 69 | `element_{c}` (200–208), `empty_{c}` (180x187), `completed_{c}` (320x320), `completed_null_{c}` (320x320), `Image_feather_{…}` (128x128), `completed_{…}_door_3x2` (700x320) | `completed_red_door_01..06` (234x160), `mystery_element`, `parking`, `target_empty_icon` (164x164) |

Lưu ý tên màu của Bird: file `feather` và `door_3x2` dùng `light_blue`, `light_green`, `light_purple`, trong khi các file khác dùng `cyan`, `teal`, `lavender`. Ánh xạ `light_blue = cyan` (v.v.) chỉ là **suy đoán**, `Unverified`.

Chỉ thấy cửa (door) có 6 frame cho màu `red`; các màu khác chỉ có sheet `3x2` (700x320), có thể là cùng sheet 3 cột × 2 hàng. `Unverified`.

Số lượng cần vẽ nếu làm thêm 1 skin theo mẫu Cat: 10 màu × 4 loại = 40 + 3 dùng chung = 43 file (khớp thư mục `cat`). `Implemented` (đếm file).

**Halo nhóm** (`group_halo`, 38 file, 194x194): `flower_{c}_halo`, `element_{c}_cat_halo`, `element_{c}_bird_halo` (mỗi loại 10 màu = 30), thêm `group_highlight_star` (128x128), `bonus_coin_halo`, `sunlight_sun_body_top_figma_halo`, và 5 halo cho collectible (bell, elk, gingerbread, snow, tree). `Implemented` (đếm file); cách dùng trong `juice_board_view.gd`.

### 4.6 Vật thể đặc biệt

| Vật thể | Asset | Ghi chú | Trạng thái |
|---|---|---|---|
| Dây khóa (cửa gỗ) | `wood_door/`: backplate, body, clasp, frame, left/right_back, left/right_front, ring, wood_grain (10 file) | Cửa gỗ 2 cánh với then cài. Dùng bởi `juice_board_view.gd` | Implemented |
| Hoa băng, chậu băng | `sunlight_ice_body` (960x1072), `sunlight_ice_frost_figma` (142x50), `sunlight_pot_ice` (180x184), và `effect/texture/ice/` (15 file) | Khối băng trong suốt xanh, có tuyết trên đỉnh | Implemented (bộ level Sunlight) |
| Sunlight collector | `sunlight_collector_body` (199x198), `_empty_figma`, `_glow_*`, `_shadow`, `_sun_glow`, `sunlight_sunlight`, `sunlight_collected_halo_*` (4 file), `sunlight_sun_*` | Bình thủy tinh chứa mặt trời, thu hoạch làm tan băng | Implemented |
| Hoa ẩn | `gp_flower_question` | Xem 4.3 | Implemented |
| Dây rút, đổi gốc | không thấy sprite riêng | Có thể dùng chung sprite dây; chưa kiểm | Unverified |

Danh sách đầy đủ ở Phụ lục A.

## 5. P1 – UI chung

| Nhóm | Số file | Nội dung chính | Nơi dùng | Trạng thái |
|---|---:|---|---|---|
| App icon / launch | 7 | Icon app và logo khởi động | Cửa hàng, splash | Quan sát |
| UI chung | 78 | Nút (xanh, cam, tím, đỏ…), dialog, toast, icon xu, thanh IQ, setting, âm thanh/rung, tiến độ, hướng dẫn luật | Nhiều màn | Implemented / một phần Unverified (xem Phụ lục B) |
| Helper / unlock | 22 | Icon nút Hint, Undo, Rope, Fill Pot (kèm bản disabled/locked), nền nút, badge, ảnh mở khóa 4 helper (kèm sao, tia sáng) | Thanh helper và popup mở khóa. Xem SS_Helper.xlsx | Implemented |
| Màn kết thúc (finish) | 21 | Hạng A/B/S, great/nice/lucky, nền thống kê normal/hard/superhard, ánh sáng, icon thưởng quảng cáo | Popup kết thúc. Xem SS_Game Result.xlsx | Implemented |
| UI trong game (juice_sort) | 11 | Nút reset/reopen/back, toast lỗi, nền tutorial, dialog reset | Trang chơi | Implemented |
| Timed Endless UI | 17 | Đồng hồ (clock_rig: thân, kim, chuông, lá, ruy băng), thanh thời gian 3 màu, popup, icon thưởng | Chế độ Timed Endless. Xem SS_Challenge Modes.xlsx | Implemented |
| Thanh IQ | 2 | Khung và đường ray thanh IQ | Trang chơi | Implemented |
| Hướng dẫn (new_guide) | 18 | Icon flower/bird/cat cho 3 mẫu hướng dẫn, panel luật, thanh tiến độ | Màn hướng dẫn mới (A/B `new_guide`) | Implemented (A/B) |
| Splash | 3 | Ảnh splash | Màn mở app | Quan sát |

Có chữ nhúng trong ảnh hoặc ảnh theo ngôn ngữ: `game_challenge_title_{en,es,fr,pt,ru}` (5 file tiêu đề theo ngôn ngữ). Còn lại chưa rà. `Unverified`: chưa kiểm ảnh nào có chữ in sẵn.

## 6. P2 – Meta game, hiệu ứng, sự kiện

| Nhóm | Số file | Nội dung chính | Tham chiếu GDD | Trạng thái |
|---|---:|---|---|---|
| Theme Giáng sinh (A/B) | 12 | 5 icon game (bell, candy, gift, hat, snowflake), 5 ảnh splash, 2 nền làng bánh gừng (builtin) | A/B `christmas_theme` | Implemented (sprites/christmas_theme); nền builtin: Unverified |
| Effect texture / particle | 130 | Texture hạt, tia sáng, băng, hint guide, rank, progress bling, cat paw… | SS_Game Feel | Unverified (chưa đọc nơi dùng) |
| Spine atlas | 66 | Ảnh atlas của 39 hiệu ứng Spine (combo, win streak, banner khó, rương thưởng, bướm, mèo/chim container…) | SS_Game Feel | Implemented (tên); chức năng từng hiệu ứng: Unverified |
| Meta: Rank / Challenge / Daily / Home | 171 | Rank (cúp 7 hạng, avatar động vật 12, podium, vương miện), Daily First-Win Check-in, Special Challenge (vườn, rương, tán lá), Home (hex) | SS_Rank, SS_Daily First-Win Check-in, SS_Challenge Modes, SS_Home Screen | Implemented |
| Coin Bonus Level | 12 | Heo thưởng, xu, banner coins trái/phải | SS_Challenge Modes | Implemented |
| Rank collectible | 16 | Quà theo mùa: bell, elk, gingerbread, snow, tree, ruy băng, link tuyết | SS_Rank / A/B `rank_collectible_fx` | Implemented (A/B) |
| Streak / banner | 32 | Banner streak theo 3 level (lv1–lv3): khiên, hoa, vàng, hạt | SS_Game Result / A/B `streak_banner` | Implemented (A/B) |

### 6.1 Hiệu ứng Spine (animation)

Artist 2D/animator cần biết có **39** hiệu ứng Spine. Zip chỉ chứa ảnh atlas (sprite sheet đóng gói) làm tham khảo hình, **không** chứa file `.skel` nên không xem được chuyển động. Chức năng suy ra từ tên thư mục, `Unverified`.

`banner_hard`, `banner_super_hard`, `bonus_hammer`, `combo`, `combo_fullscreen`, `combo_timing2`, `daily_checkin`, `effect_bird_container`, `effect_butterfly_bigoringe`, `effect_butterfly_caise`, `effect_butterfly_green`, `effect_butterfly_oringe`, `effect_butterfly_red`, `effect_cat_container`, `effect_coin`, `effect_coin_clover`, `effect_coin_clover_preview`, `effect_difficult_level_001`, `effect_flower_unlock`, `effect_flowerpot_big`, `effect_game_logo`, `effect_good_luck`, `effect_hard_super_hard`, `effect_like`, `effect_smart_move`, `effect_splash_birdie01`, `effect_win_streak`, `empty_col_feedback`, `finish_flower_cart`, `guide_hand01`, `guide_hand02`, `iq_genius`, `long_link_horn_flag`, `long_link_rainbow`, `long_link_seed`, `rank_completion`, `rank_encourage`, `rank_new_season`, `special_challenge_reward`

## 7. Cần xác nhận

| # | Câu hỏi | Vì sao cần |
|---|---|---|
| 1 | Định dạng giao hàng: PNG hay PSD/Figma, độ phân giải (x1/x2/x3), nền trong suốt, tên file | Chưa có spec; kích thước hiện tại chỉ là baseline |
| 2 | Scale, import và 9-slice của Godot (một số ảnh có hậu tố `_9`, `_9s`) | Chưa đọc file `.import` và scene để biết margin 9-slice |
| 3 | Artist vẽ lại toàn bộ hay chỉ phần P0 trước? Skin Cat/Bird và theme Giáng sinh có cần làm không? | Cat/Bird và Giáng sinh chỉ chạy khi A/B bật |
| 4 | Ánh xạ `light_blue/light_green/light_purple` của Bird sang 10 màu chuẩn | File Bird dùng tên màu khác |
| 5 | Nền màn chơi mặc định lấy từ đâu | Không thấy ảnh nền riêng trong assets |
| 6 | Ảnh nào có chữ in sẵn, cần làm bản dịch | Chưa rà; biết chắc có `game_challenge_title_{en,es,fr,pt,ru}` |
| 7 | Cách ghép dây top/mid/bottom và số hàng theo `capacity` | Chưa đọc code vẽ dây |
| 8 | Các file không thấy tham chiếu (Phụ lục B) còn dùng hay đã bỏ | Có thể nạp động theo mẫu tên hoặc là asset thừa |
| 9 | Sprite nào là "figma" (tên có `_figma`) và có file nguồn Figma/REF | Chưa có hình REF hoặc Figma |

## Phụ lục A – Danh sách file P0 (gộp theo mẫu tên)

Đường dẫn tính từ `assets/` của project. `{c}` = một trong 10 màu (và `park` nếu có). Cột cuối là số file trong mẫu không thấy tham chiếu trực tiếp (xem Phụ lục B).

### Bàn chơi / cột / quota

| Mẫu | Số file | Kích thước | Không thấy tham chiếu |
|---|---:|---|---:|
| `sprites/juice_sort/board.png` | 1 | 1144x243 | 0 |
| `sprites/juice_sort/flower_badge.png` | 1 | 176x171 | 0 |
| `sprites/juice_sort/flowering_shrubs.png` | 1 | 217x1010 | 0 |
| `sprites/juice_sort/gamepage_bg_leaf_shadow.webp` | 1 | 718x1536 | 0 |
| `sprites/juice_sort/gp_col_highlight_{c}_top.png` | 4 | 230x302 … 232x304 | 0 |
| `sprites/juice_sort/gp_col_highlight_{c}.png` | 1 | 212x284 | 0 |
| `sprites/juice_sort/gp_col_highlight_{c}_bottom.png` | 3 | 212x284 … 232x304 | 0 |
| `sprites/juice_sort/gp_col_highlight_hover_bottom.png` | 1 | 230x302 | 0 |
| `sprites/juice_sort/gp_col_highlight_ww_{c}_top.png` | 1 | 230x302 | 0 |
| `sprites/juice_sort/gp_col_highlight_ww_hover_bottom.png` | 1 | 230x302 | 0 |
| `sprites/juice_sort/gp_col_mark_cross.png` | 1 | 88x88 | 0 |
| `sprites/juice_sort/gp_col_mark_tick.png` | 1 | 88x88 | 0 |
| `sprites/juice_sort/gp_flower_question.png` | 1 | 200x200 | 0 |
| `sprites/juice_sort/gp_prop_bg_glow.png` | 1 | 232x232 | 0 |
| `sprites/juice_sort/progress_pot_board.png` | 1 | 63x52 | 0 |
| `sprites/juice_sort/quota_bar_bg.png` | 1 | 140x169 | 0 |
| `sprites/juice_sort/quota_count_tab.png` | 1 | 131x62 | 0 |
| `sprites/juice_sort/quota_slot_empty.png` | 1 | 256x261 | 0 |

### Hoa / Chậu / Dây / Bonsai

| Mẫu | Số file | Kích thước | Không thấy tham chiếu |
|---|---:|---|---:|
| `sprites/juice_sort/bonsai_{c}.png` | 10 | 256x261 | 0 |
| `sprites/juice_sort/flower_{c}.png` | 10 | 200x200 | 0 |
| `sprites/juice_sort/pot_{c}.png` | 11 | 180x184 | 0 |
| `sprites/juice_sort/rope_{c}_bottom.png` | 11 | 60x102 | 0 |
| `sprites/juice_sort/rope_{c}_mid.png` | 11 | 60x88 | 0 |
| `sprites/juice_sort/rope_{c}_top.png` | 11 | 60x121 | 0 |

### Sunlight / băng

| Mẫu | Số file | Kích thước | Không thấy tham chiếu |
|---|---:|---|---:|
| `sprites/juice_sort/sunlight_collected_halo_back.png` | 1 | 1280x1200 | 0 |
| `sprites/juice_sort/sunlight_collected_halo_main.png` | 1 | 1280x1800 | 0 |
| `sprites/juice_sort/sunlight_collected_halo_radial_user.png` | 1 | 969x964 | 0 |
| `sprites/juice_sort/sunlight_collected_halo_upper.png` | 1 | 1280x660 | 0 |
| `sprites/juice_sort/sunlight_collector_body.png` | 1 | 199x198 | 0 |
| `sprites/juice_sort/sunlight_collector_empty_figma.png` | 1 | 1024x1024 | 0 |
| `sprites/juice_sort/sunlight_collector_glow_back_figma.png` | 1 | 172x172 | 0 |
| `sprites/juice_sort/sunlight_collector_glow_middle_figma.png` | 1 | 123x123 | 1 |
| `sprites/juice_sort/sunlight_collector_shadow.png` | 1 | 1024x1024 | 0 |
| `sprites/juice_sort/sunlight_collector_sun_glow.png` | 1 | 258x258 | 0 |
| `sprites/juice_sort/sunlight_ice_body.png` | 1 | 960x1072 | 0 |
| `sprites/juice_sort/sunlight_ice_frost_figma.png` | 1 | 142x50 | 0 |
| `sprites/juice_sort/sunlight_pot_ice.png` | 1 | 180x184 | 0 |
| `sprites/juice_sort/sunlight_sun_body_top_figma.png` | 1 | 190x190 | 0 |
| `sprites/juice_sort/sunlight_sun_effect_middle_figma.png` | 1 | 258x258 | 0 |
| `sprites/juice_sort/sunlight_sun_incentive_back_figma.png` | 1 | 237x239 | 0 |
| `sprites/juice_sort/sunlight_sunlight.png` | 1 | 1376x1280 | 0 |
| `sprites/juice_sort/sunlight_sunlight_particle.png` | 1 | 20x20 | 0 |

### Skin Bird

| Mẫu | Số file | Kích thước | Không thấy tham chiếu |
|---|---:|---|---:|
| `sprites/juice_sort/bird/Image_feather_{c}.png` | 7 | 128x128 | 0 |
| `sprites/juice_sort/bird/Image_feather_light_{c}.png` | 3 | 128x128 | 0 |
| `sprites/juice_sort/bird/completed_{c}.png` | 10 | 320x320 | 0 |
| `sprites/juice_sort/bird/completed_{c}_door_3x2.png` | 7 | 700x320 | 0 |
| `sprites/juice_sort/bird/completed_lightblue_door_3x2.png` | 1 | 700x320 | 0 |
| `sprites/juice_sort/bird/completed_lightgreen_door_3x2.png` | 1 | 700x320 | 0 |
| `sprites/juice_sort/bird/completed_lightpurple_door_3x2.png` | 1 | 700x320 | 0 |
| `sprites/juice_sort/bird/completed_null_{c}.png` | 10 | 320x320 | 0 |
| `sprites/juice_sort/bird/completed_{c}_door_01.png` | 1 | 234x160 | 1 |
| `sprites/juice_sort/bird/completed_{c}_door_02.png` | 1 | 234x160 | 1 |
| `sprites/juice_sort/bird/completed_{c}_door_03.png` | 1 | 234x160 | 1 |
| `sprites/juice_sort/bird/completed_{c}_door_04.png` | 1 | 234x160 | 1 |
| `sprites/juice_sort/bird/completed_{c}_door_05.png` | 1 | 234x160 | 1 |
| `sprites/juice_sort/bird/completed_{c}_door_06.png` | 1 | 234x160 | 1 |
| `sprites/juice_sort/bird/element_{c}.png` | 10 | 200x200 … 208x208 | 0 |
| `sprites/juice_sort/bird/empty_{c}.png` | 10 | 180x187 | 0 |
| `sprites/juice_sort/bird/mystery_element.png` | 1 | 200x200 | 0 |
| `sprites/juice_sort/bird/parking.png` | 1 | 180x187 | 0 |
| `sprites/juice_sort/bird/target_empty_icon.png` | 1 | 164x164 | 0 |

### Skin Cat

| Mẫu | Số file | Kích thước | Không thấy tham chiếu |
|---|---:|---|---:|
| `sprites/juice_sort/cat/completed_{c}.png` | 10 | 256x261 | 0 |
| `sprites/juice_sort/cat/completed_head_{c}.png` | 10 | 319x320 … 320x320 | 10 |
| `sprites/juice_sort/cat/element_{c}.png` | 10 | 200x200 … 210x210 | 0 |
| `sprites/juice_sort/cat/empty_{c}.png` | 10 | 180x187 | 0 |
| `sprites/juice_sort/cat/mystery_element.png` | 1 | 200x200 | 0 |
| `sprites/juice_sort/cat/parking.png` | 1 | 180x187 | 0 |
| `sprites/juice_sort/cat/target_empty_icon.png` | 1 | 163x164 | 0 |

### Halo nhóm / thu hoạch

| Mẫu | Số file | Kích thước | Không thấy tham chiếu |
|---|---:|---|---:|
| `sprites/juice_sort/group_halo/bell_rank_collectible_halo.png` | 1 | 194x194 | 0 |
| `sprites/juice_sort/group_halo/bonus_coin_halo.png` | 1 | 194x194 | 0 |
| `sprites/juice_sort/group_halo/element_{c}_bird_halo.png` | 10 | 194x194 | 0 |
| `sprites/juice_sort/group_halo/element_{c}_cat_halo.png` | 10 | 194x194 | 0 |
| `sprites/juice_sort/group_halo/elk_rank_collectible_halo.png` | 1 | 194x194 | 0 |
| `sprites/juice_sort/group_halo/flower_{c}_halo.png` | 10 | 194x194 | 0 |
| `sprites/juice_sort/group_halo/gingerbread_rank_collectible_halo.png` | 1 | 194x194 | 0 |
| `sprites/juice_sort/group_halo/group_highlight_star.png` | 1 | 128x128 | 0 |
| `sprites/juice_sort/group_halo/snow_rank_collectible_halo.png` | 1 | 194x194 | 0 |
| `sprites/juice_sort/group_halo/sunlight_sun_body_top_figma_halo.png` | 1 | 194x194 | 0 |
| `sprites/juice_sort/group_halo/tree_rank_collectible_halo.png` | 1 | 194x194 | 0 |

### Dây khóa (cửa gỗ)

| Mẫu | Số file | Kích thước | Không thấy tham chiếu |
|---|---:|---|---:|
| `sprites/juice_sort/wood_door/backplate.png` | 1 | 178x887 | 0 |
| `sprites/juice_sort/wood_door/body.png` | 1 | 275x336 | 0 |
| `sprites/juice_sort/wood_door/clasp.png` | 1 | 275x336 | 0 |
| `sprites/juice_sort/wood_door/frame.png` | 1 | 340x1754 | 0 |
| `sprites/juice_sort/wood_door/left_back.png` | 1 | 174x1754 | 0 |
| `sprites/juice_sort/wood_door/left_front.png` | 1 | 174x1754 | 0 |
| `sprites/juice_sort/wood_door/right_back.png` | 1 | 160x1754 | 0 |
| `sprites/juice_sort/wood_door/right_front.png` | 1 | 160x1754 | 0 |
| `sprites/juice_sort/wood_door/ring.png` | 1 | 275x336 | 0 |
| `sprites/juice_sort/wood_door/wood_grain.png` | 1 | 340x1754 | 0 |

## Phụ lục B – File không thấy tham chiếu trực tiếp (`Unverified`)

Phương pháp: tìm tên file trong mọi `.tscn`, `.tres`, `.gd`, `.json`, `.res` của project. Không thấy tên thì liệt kê ở đây. Có thể file được nạp động theo mẫu tên, hoặc được Spine atlas / shader tham chiếu, hoặc là asset thừa. **Chưa kết luận file nào thừa.** Chưa quét `project.godot` và file `.atlas`, nên icon app (`app/`) và ảnh Spine có thể được tham chiếu ở đó.

- **P0 / Skin Bird** (6): `bird/completed_red_door_01.png`, `bird/completed_red_door_02.png`, `bird/completed_red_door_03.png`, `bird/completed_red_door_04.png`, `bird/completed_red_door_05.png`, `bird/completed_red_door_06.png`
- **P0 / Skin Cat** (10): `cat/completed_head_blue.png`, `cat/completed_head_cyan.png`, `cat/completed_head_green.png`, `cat/completed_head_lavender.png`, `cat/completed_head_orange.png`, `cat/completed_head_pink.png`, `cat/completed_head_purple.png`, `cat/completed_head_red.png`, `cat/completed_head_teal.png`, `cat/completed_head_yellow.png`
- **P0 / Sunlight / băng** (1): `sunlight_collector_glow_middle_figma.png`
- **P1 / App icon / launch** (6): `app/app_icon.png`, `app/app_icon_bg.png`, `app/app_icon_fg.png`, `app/app_icon_main.png`, `app/app_icon_mono.png`, `app/boot_logo.png`
- **P1 / Màn kết thúc (finish)** (1): `radiated_light_blue.png`
- **P1 / Timed Endless UI** (2): `endless/endless_popup_bg.png`, `endless/reward_popup_coin.png`
- **P1 / UI chung** (17): `common_btn_badge_x2.png`, `common_deco_bubble.png`, `common_particle_diamond_cyan.png`, `common_particle_diamond_yellow.png`, `finish_complete_encourage_bg_brown.png`, `finish_complete_encourage_bg_green.png`, `finish_complete_encourage_bg_purple.png`, `finish_complete_encourage_bg_red.png`, `game_ambient_bubble.png`, `game_coin_pill_bg.png`, `game_coin_spin_sheet.png`, `game_nav_settings.png`, `setting_dialog_card_slot.png`, `setting_ic_weak_help.png`, `setting_ic_weak_privacy.png`, `setting_ic_weak_privacy_preference.png`, `setting_ic_weak_service.png`
- **P2 / Coin Bonus Level** (2): `bonus_banner_figma/coins_left.svg`, `bonus_banner_figma/coins_right.svg`
- **P2 / Effect texture / particle** (6): `effect/texture/hint_guide/hint_guide_soft_dot.png`, `effect/texture/hint_guide/hint_guide_soft_dot_compact.png`, `effect/texture/hint_guide/hint_guide_sparkle.png`, `effect/texture/hint_guide/hint_guide_white_particle.png`, `effect/texture/progress_bling/flow_mask.png`, `effect/texture/rank/eff_fireworks2.png`
- **P2 / Meta: Rank / Challenge / Daily / Home** (1): `daily_first_win_checkin_03bc7.svg`
- **P2 / Streak / banner** (19): `streak_banner/lv1_art_left.png`, `streak_banner/lv1_art_right.png`, `streak_banner/lv1_glow.png`, `streak_banner/lv1_shield.png`, `streak_banner/lv2_art.png`, `streak_banner/lv2_glow.png`, `streak_banner/lv2_scatter.png`, `streak_banner/lv3_deco_left.png`, `streak_banner/lv3_deco_right.png`, `streak_banner/lv3_glow.png`, `streak_banner/lv3_gold_seeds.png`, `streak_banner/lv3_particles.png`, `streak_banner/lv3_scatter.png`, `streak_banner/lv3_shield_frame.png`, `streak_banner/lv3_shield_inner.png`, `streak_banner/lv3_side_gold_1.png`, `streak_banner/lv3_side_gold_2.png`, `streak_banner/lv3_top_flowers.png`, `streak_banner/lv3_top_gem.png`

Với Spine atlas: 61 file không thấy tên trong các file đã quét (chưa quét `.atlas`); không liệt kê.

## Phụ lục C – Cấu trúc zip `SS_Art Reference.zip`

- `P0_Gameplay/`, `P1_UI/`, `P2_Meta_FX/`, mỗi thư mục giữ **nguyên đường dẫn tương đối của project** (ví dụ `P0_Gameplay/sprites/juice_sort/flower_red.png`) để tra khớp với file này.
- Gồm ảnh png, webp, svg. **Không** gồm `.import`, `.skel`, `.tres`, `.tscn`, audio, font, shader.
- Thư mục `P2_Meta_FX/spine/` là ảnh atlas, khá nặng (khoảng 45 MB), có thể xóa nếu không cần.
