# Sweet Rope – giao một lần: sửa hết và làm hết

Đọc file này trước. **Không còn chia phase, không dừng chờ duyệt.** Làm liên tục đến khi xong toàn bộ: phần A, B, C, D.

File này đúng hơn mọi tài liệu cũ. Các câu sau trong `tools/PROMPT.md` **không còn áp dụng**: dừng ở mỗi đợt (mục 0.4 và mục 8), chỉ commit khi được yêu cầu và hỏi trước khi đẩy (mục 10), thư mục đầu ra cũ. Đầu ra là `Codex_Work/Asset_SRSP_v1/`. Style, pixel và bản quyền trong PROMPT vẫn giữ.

## Cách chạy

1. Thứ tự: **A (sửa lỗi) → B (làm phần thiếu) → C (mockup) → D (tự kiểm, báo cáo)**.
2. Xong mỗi nhóm thì cập nhật `status` trong `asset_manifest.csv`, commit và push, rồi làm nhóm kế tiếp ngay. Commit chỉ trong `Codex_Work/Asset_SRSP_v1/`.
3. Nếu phiên bị ngắt vì hết giới hạn: lần chạy sau đọc `status` và `fix_list.csv`, làm tiếp từ mục chưa xong, không làm lại mục đã xong.
4. Không dừng để hỏi. Chỗ chưa rõ thì chọn phương án mặc định, ghi vào `questions.md`, làm tiếp.
5. Không commit `tools/unity_current/` và `tools/SR_Art Task.xlsx` (repo đang công khai): thêm hai đường dẫn này vào `.git/info/exclude`.

## Chất lượng: áp dụng cho mọi file

- Hình minh họa phải do **công cụ sinh ảnh** vẽ, cùng style khối 3D bóng với chậu, quả, icon và mèo đã nộp. Code chỉ dùng để tách nền, cắt, ghép, thu nhỏ và kiểm.
- **Không nộp hình khối phẳng vẽ bằng PIL/SVG thay cho tranh.** Chỉ quầng sáng và gradient mờ mới được dựng bằng code.
- Sửa quy tắc cũ về ảnh nguồn: với ảnh có một cạnh trên 1536 px, được phóng bằng **super-resolution** nếu công cụ sinh ảnh không đủ px (ghi vào báo cáo). Vẫn cấm kéo lệch tỉ lệ và nhòe mép để lấp chỗ trống.
- File nào không vẽ đạt thì để `status` = `không làm được` kèm lý do. Không nộp hình tạm rồi ghi là xong.

## A. Sửa lỗi (danh sách file: `fix_list.csv`)

Các file này đã nộp nhưng **chưa đạt**, dù `check_assets.py` không báo FAIL.

| Nhóm | Lỗi | Đạt khi |
|---|---|---|
| A1 Mật ong | Đọc ra tấm gỗ, không ra mật. Đáy như giấy rách. | Mật hổ phách lỏng, bóng: đỉnh đọng dày tràn mép tròn, giọt đáy tròn mập, đốm bóng. Đục, không thấy item. Ghép TOP + BODY + BOTTOM liền mạch ở **mọi** chiều cao dây 3–8 Item (mỗi Item 125 px), kể cả khi BODY bị cắt giữa chừng. |
| A2 Dây Godot | Ba đoạn không khớp: `mid` ở x 21–38 (đỏ 24–41), cuối `top` ở x 23–33, đầu `bottom` ở x 28–41. | Cả 11 bộ: thân của `top`, `mid`, `bottom` cùng nằm ở **x 25–35** trên khung rộng 60 px (như file gốc), cùng vân xoắn. Nút được rộng hơn thân. Ghép thử không thấy gãy. |
| A3 Ô Order trống | Xô xám phẳng, khác dáng chậu. | Đúng dáng Container, cùng khối bóng, màu xám mờ, đọc ra là chỗ chờ giao. |
| A4 Cỡ chậu | `CONTAINER_FRUIT_1` có chậu rộng 74% khung, các chậu khác 85%. | Cùng tỉ lệ, cùng đường đáy với 9 chậu còn lại. |
| A5 Nền | Gradient, đồi và lá phẳng, gần như trống. | Tranh vẽ cùng style `BG_STAGE_001`; vùng giữa vẫn thoáng để đặt Item và nút. |
| A6 Nút, khung, thanh | Chữ nhật gradient phẳng, khác hẳn `BUTTON_GREEN_NORMAL`. | Cùng viền, vát khối và đốm bóng với `BUTTON_GREEN_NORMAL`. Ba trạng thái Normal, Pressed, Locked phân biệt rõ. Giữ 9-slice. |
| A7 Hiệu ứng, trang trí | Đa giác và sao phẳng; bốn file glow trùng y nhau; khói gần như không thấy. | Mỗi file đúng chức năng trong `what_to_draw`, khung hình liên tiếp thấy được chuyển động, không trùng nhau trừ khi manifest ghi `same_pixels_as`. |
| A8 Art vẽ lại | Đổi dáng so với art team: mũi tên `x1/x8/x10` thành chữ nhật; `BOARD_DATE` bị in sẵn 7 ô; đuôi `BOARD_REWARD` rời; `BOARD_TOP` đổi cấu trúc; nút Quit tròn thành vuông; tia sáng quá mờ; chữ mất độ cong và quầng; nền mất họa tiết. | Đặt chồng lên bản trong `tools/unity_current/`: cùng đường viền ngoài, cùng vị trí chữ và ô nội dung. Chỉ đổi chất liệu và chủ đề. |

## B. Làm toàn bộ phần còn thiếu

Mọi dòng có `action` khác `skip` và `status` = `chưa làm` (số dòng lấy theo `status` mới nhất).

1. P0.
2. P1.
3. P2 ảnh Godot và Unity. Theme Flower và Winter: dùng tên hoa và hoa văn bánh đang ghi trong manifest làm mặc định, ghi vào `questions.md`.
4. P2 `layers`: mỗi vùng trong `atlas_regions.json` một PNG đúng px, kèm `motion.md`. Không dùng lại skeleton hay animation của Sort Streak.
5. P2 `atlas`: các atlas Unity của team, đúng từng ô.

## C. Mockup (làm sau A và B)

- Dựng lại `MOCK_BOARD_*`, `MOCK_UI_*` và đủ 81 mockup bằng asset đã sửa.
- Chữ không đè lên vùng tranh rối (ví dụ "Orchard 1" ở Home). Ô Order trống phải nhìn ra chậu.
- Logo: tiếp tục để tạm cho đến khi có file PNG gốc.

## D. Tự kiểm và báo cáo cuối

```bash
python Codex_Work/Asset_SRSP_v1/tools/check_assets.py --manifest Codex_Work/Asset_SRSP_v1/asset_manifest.csv --out Codex_Work/Asset_SRSP_v1 --source . --report Codex_Work/Asset_SRSP_v1/report_all.csv
```

- Không còn `FAIL`, trừ các dòng `không làm được`. Mỗi `WARN` ghi lý do.
- Kiểm thêm điều script không kiểm: x của thân dây (A2); mật ghép ở 3–8 Item; tỉ lệ 10 chậu; art vẽ lại đặt chồng lên bản cũ.
- Contact sheet trên nền sáng, nền tối, ảnh xám, ở cỡ chơi thật, cho từng nhóm. **Mở ra xem** trước khi ghi `chờ duyệt`.
- `final_report.md`: số dòng đã xong, chưa xong, không làm được kèm lý do; việc dev phải làm.

## Theme xác nhận

Mèo nông dân bán trái cây. Rank dùng tên hiển thị **Fruit Challenge**, sạp trái cây và táo vàng. Quyết định này thay nội dung cá trong mục Rank của handoff cũ. Tên các file Unity hiện hữu được giữ nguyên để bảo toàn đường dẫn tham chiếu.
