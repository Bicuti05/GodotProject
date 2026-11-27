# Sweet Rope – đợt 3: sửa lỗi và làm nốt, một lần chạy

Đọc file này trước. **Không chia phase, không dừng chờ duyệt.** Làm liên tục: phần B (sửa), C (làm nốt), D (mockup), E (tự kiểm).

File này đúng hơn mọi tài liệu cũ. Các câu trong `tools/PROMPT.md` về dừng ở mỗi đợt, chỉ commit khi được yêu cầu, hỏi trước khi đẩy và thư mục đầu ra cũ **không còn áp dụng**. Đầu ra là `Codex_Work/Asset_SRSP_v1/`. Style, pixel và bản quyền trong PROMPT vẫn giữ.

Đã đạt, **không vẽ lại** nếu không có trong `fix_list2.csv`: mật ong, ô Order, chậu, quả, Item và chậu của theme Flower và Winter, avatar, art cũ của team đã vẽ lại.

**Nền đổi style** (mục A bên dưới): đọc trước khi vẽ bất kỳ nền nào.

## A. Style nền (mới, áp dụng cho cả nền đã vẽ và nền chưa vẽ)

Nền hiện tại **quá tả thực** so với game puzzle trên điện thoại. Đổi sang hai kiểu:

**A1. Màn chơi: phẳng.** Mọi nền nằm sau Item.

- Gần một màu, chuyển sắc rất nhẹ, nhạt hơn Item rõ rệt.
- Chỉ vài họa tiết mờ, đơn giản ở mép trên và chân màn. Vùng từ hàng Level đến hàng Helper **trơn**.
- Không đường chân trời, không cây to, không mặt trời, không phong cảnh.
- Tông theo theme: Fruit kem ấm, Flower hồng hoặc xanh rất nhạt, Winter xanh băng nhạt.
- Tham chiếu độ nhạt: `tools/unity_current/Image/Streak/BG_STREAK.png` và `Rank/BG_CHALL.png`.

**A2. Home, Shop, Splash, icon app: cartoon đơn giản.**

- Hình khối lớn, ít chi tiết, màu tươi và sạch, mỗi vật một màu chính với một đến hai sắc độ bóng mềm.
- Không vân cỏ, đá, gỗ. Không từng ngọn cỏ, viên sỏi. Không ánh sáng kiểu điện ảnh, không làm mờ xa gần như ảnh chụp.
- Vùng sau logo, bảng giữa màn và nút Play thoáng.
- Tham chiếu độ đơn giản: `tools/unity_current/Image/Rank/BG_UPPER2.png` (art của team).
- Chung bảng màu với nút và khung UI.
- `BG_HOME_SKY`, `BG_HOME_HILL`, `BG_HOME_GROUND` là **ba lớp thật**: trời chỉ có trời và mây; đồi chỉ có đồi, nền trên trong hoặc khớp mép; đất chỉ có tiền cảnh.

Không đưa ảnh Sort Streak vào công cụ sinh ảnh.

## Cách chạy

1. Làm **nhóm B2 (nền) đầu tiên**, commit và push ngay để team xem sớm, rồi làm tiếp không chờ.
2. Xong mỗi nhóm thì cập nhật `status` trong `asset_manifest.csv`, commit, push, rồi làm tiếp. Commit chỉ trong `Codex_Work/Asset_SRSP_v1/`.
3. Nếu bị ngắt: lần sau đọc `status` và `fix_list2.csv`, làm tiếp mục chưa xong.
4. Không dừng để hỏi. Chỗ chưa rõ thì chọn mặc định, ghi vào `questions.md`.
5. Không commit `tools/unity_current/` và `tools/SR_Art Task.xlsx` (repo đang công khai): giữ trong `.git/info/exclude`.

## B. Sửa lỗi (`fix_list2.csv`)

| Nhóm | Lỗi | Đạt khi |
|---|---|---|
| B1 Hình bị thu trong khung | Đúng px nhưng hình bị thu nhỏ vào giữa: thanh đầy chỉ còn nửa bề ngang, chữ tràn khỏi banner, thanh IQ rời mảnh. | Phần hình phủ khung **ít nhất bằng `min_w` × `min_h`** trong CSV (script kiểm, thiếu là FAIL). Thanh và nút phải chạm gần hết bề ngang; giữ góc, kéo phần giữa kiểu 9-slice, không kéo méo góc. |
| B1g Godot lệch vùng hình | Vùng hình lệch hơn 25% so với bản cũ, điểm chạm và pivot sẽ sai. | Trong 75–125% của `content_bbox`. Giữ lệch thì ghi lý do cụ thể vào `warn_disposition.csv`. |
| B2a Nền màn chơi | Quá tả thực, phong cảnh nằm sau Item. | Theo mục A1. |
| B2b Nền Home, Shop, Splash, icon | Quá tả thực, nhiều chất liệu; lớp trời chứa cả cảnh. | Theo mục A2. |
| B4 Dây Godot | Thân hẹp hơn yêu cầu (x 26–34), vân phẳng hơn hai nút, mối nối thấy vệt đậm, nút đuôi có quầng xám. | Cả 11 bộ: thân `top`, `mid`, `bottom` đúng **x 25–35** (đo cột đầu và cuối có alpha > 128) trên khung rộng 60; cùng vân xoắn khối như nút; ghép `mid` lặp 3 lần không thấy mối nối; không quầng xám. |
| B5 Ảnh nguồn nhỏ | File nguồn trong `source/` nhỏ hơn bản xuất, trong khi cạnh dài không quá 1536 px. | Nguồn rộng và cao **ít nhất bằng** bản xuất, vẽ lại bằng công cụ sinh ảnh, không phóng to. |
| B6 Lẻ | `x10`, `x10_w` thiếu viền dây mà `x1`, `x8` có. `ef_point_003` là hình tròn trơn trùng 91% ảnh gốc. | Bốn kiểu mũi tên cùng viền. `ef_point_003` vẽ khác (mép mềm hoặc hạt sáng riêng), đúng chức năng. |

## C. Làm nốt phần còn thiếu

Nền còn thiếu (ví dụ `common_homepage_bg`, `rank_header_bg`, `daily_first_win_checkin_*`, `STORE_FEATURE`) vẽ theo mục A.

Mọi dòng `action` khác `skip` và `status` = `chưa làm`, theo thứ tự:

1. P1 Godot.
2. P2 ảnh (Godot, Unity).
3. P2 `layers`: mỗi vùng trong `atlas_regions.json` một PNG đúng px, kèm `motion.md`. Không dùng lại skeleton hay animation của Sort Streak.
4. P2 `atlas`: atlas Unity của team còn thiếu, đúng từng ô.

Các dòng chờ logo PNG trong suốt giữ `không làm được`.

Chất lượng như phần đã đạt: hình do công cụ sinh ảnh vẽ, cùng style khối bóng; không nộp hình phẳng vẽ bằng PIL hay SVG (trừ quầng sáng, gradient mờ). File không vẽ đạt thì ghi `không làm được` kèm lý do.

## D. Mockup

Dựng lại đủ 81 mockup và các ảnh `MOCK_*` sau B và C. Sửa các chỗ còn tạm:

- Cúp ở `streak_*`, `banner_streak*`, `dialog_rank_*`, `rank_page`: dùng cúp mèo đã vẽ, bỏ cúp phẳng màu cam.
- Giỏ ở `finish_result*`: vẽ cùng style, bỏ hình gạch ngang.
- Nền `daily_checkin_*`: có hình theo mục A2, bỏ gradient trơn.
- `home_bonus_level`, `home_scene2`: nửa dưới đang trống.
- Thanh IQ ráp liền: huy hiệu, rãnh, phần đầy và vạch mốc khớp nhau; huy hiệu có chữ IQ.
- Chữ nằm trọn trong banner; nút ở `home_super_hard` nhìn ra nút bấm.

## E. Tự kiểm và báo cáo

```bash
python Codex_Work/Asset_SRSP_v1/tools/check_assets.py --manifest Codex_Work/Asset_SRSP_v1/asset_manifest.csv --out Codex_Work/Asset_SRSP_v1 --source . --fill Codex_Work/Asset_SRSP_v1/fix_list2.csv --report Codex_Work/Asset_SRSP_v1/report_all.csv
```

- Không còn `FAIL`, trừ các dòng `không làm được`. Mỗi `WARN` ghi lý do.
- Script không chấm được: nền rối, mối nối dây, ráp HUD, chữ tràn. **Mở mockup và contact sheet ra xem** trước khi ghi `chờ duyệt`.
- Cập nhật `final_report.md`: đã xong, chưa xong, không làm được kèm lý do.

## Theme xác nhận

Mèo nông dân bán trái cây. Rank dùng tên hiển thị **Fruit Challenge**, sạp trái cây và táo vàng. Quyết định này thay nội dung cá trong mục Rank của handoff cũ. Tên các file Unity hiện hữu được giữ nguyên để bảo toàn đường dẫn tham chiếu.
