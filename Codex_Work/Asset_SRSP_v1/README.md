# Sweet Rope – giao việc theo phase

Đọc file này mỗi lần bắt đầu. **Chỉ làm phase đang MỞ**, làm xong thì dừng và chờ duyệt. Không tự mở phase sau.

Quy tắc đầy đủ về style, pixel và bản quyền: `tools/PROMPT.md`. Nếu trái nhau thì file README này đúng.

## Trạng thái

| Phase | Nội dung | Số file | Trạng thái |
|---|---|---|---|
| 0 | Chốt style (đợt 0) | 45 | Đã nộp. 28 file đạt, 17 file phải sửa |
| 0S | Sửa đợt 0 | 17 | **MỞ** |
| 1 | Container 10 màu (còn lại) | 9 | Khóa |
| 2 | Container đầy quả | 10 | Khóa |
| 3 | Phụ kiện bàn chơi, dấu thả, bàn tay | 9 | Khóa |
| 4 | Mở túi, mật chảy, dấu sáp nứt | 10 | Khóa |
| 5 | Hiệu ứng Deliver và màn Thua | 9 | Khóa |
| 6 | Khung và nút dùng chung | 5 | Khóa |
| 7 | Bộ biểu tượng | 12 | Khóa |
| 8 | HUD và Helper | 12 | Khóa |
| 9 | Home và logo | 11 | Khóa |

Sau phase 9 còn phần P1, P2 và bộ Godot: chưa giao.

## Phase 0S – sửa đợt 0

Đã đạt, **không vẽ lại**: các quả trừ chuối, túi vải, dấu sáp, chậu đỏ và chậu trắng, chậu đầy quả, thân dây, hình nút xanh.

| File (trong `Codex_Work/Asset_SRSP_v1/`) | Px | Lỗi cần sửa |
|---|---|---|
| `unity/Assets/_IEC/Image/Mechanic/OBJ_HONEY_TOP.png` | 160×80 | Chưa đọc ra mật ong: ống màu đỏ gạch phẳng. Vẽ mật hổ phách sáng, bóng, có vệt sáng dọc và vân chảy; khác rõ chuối và cam. |
| `unity/Assets/_IEC/Image/Mechanic/OBJ_HONEY_BODY.png` | 160×256 | Cùng tông với đỉnh và đáy; lặp dọc không thấy đường nối; thân đặc (alpha từ 250 trở lên, chỉ mép ngoài được mờ). |
| `unity/Assets/_IEC/Image/Mechanic/OBJ_HONEY_BOTTOM.png` | 160×100 | Bỏ dải xám mờ ở chỗ nối: hiện thấy quả phía sau lọt qua ở cả hai đầu. |
| `unity/Assets/_IEC/Image/Theme/Fruit/BG_BOARD_FRUIT.png` | 1080×2340 | Nguồn 898×1752 bị kéo lên 1080×2340, lá ở mép nhòe thành mảng. Vẽ nguồn từ 1080×2340 trở lên, cùng tỉ lệ. |
| `godot_dropin/assets/sprites/juice_sort/wood_door/frame.png` | 340×1754 | Là lớp mật đóng bản Godot: sửa theo ba mảnh mật ở trên, hết dải xám. |
| `godot_dropin/assets/sprites/juice_sort/quota_slot_empty.png` | 256×261 | Ô Order trống đang giống hệt chậu trắng của Free Rope. Vẽ bản xám mờ, đọc ra là chỗ chờ giao. |
| `godot_dropin/assets/sprites/juice_sort/rope_red_top.png` | 60×121 | Nút buộc chỉ là một hình bầu dục phẳng dán lên dây. Vẽ nút thắt có khối, cùng vân dây. |
| `godot_dropin/assets/sprites/juice_sort/rope_red_bottom.png` | 60×102 | Đuôi dây là một đốm mờ. Vẽ nút đuôi rõ khối. |
| `unity/Assets/_IEC/Image/Board/BOARD_PLANK.png` | 1058×45 | Nguồn 380×105 nhỏ hơn bản xuất. Vẽ nguồn đủ lớn. |
| `godot_dropin/assets/sprites/juice_sort/board.png` | 1144×243 | Cùng lỗi nguồn nhỏ như BOARD_PLANK. |
| `unity/Assets/_IEC/Image/UIKit/BUTTON_GREEN_NORMAL.png` | 520×134 | Nguồn 379×183 nhỏ hơn bề ngang bản xuất. Hình hiện đạt, chỉ cần nguồn đủ lớn. |
| `unity/Assets/_IEC/Image/Theme/Fruit/ITEM_FRUIT_3.png` | 200×200 | Ảnh mẫu đã chốt là MỘT quả chuối; bản nộp là nải 2–3 quả. |
| `godot_dropin/assets/sprites/juice_sort/flower_yellow.png` | 200×200 | Cùng hình với ITEM_FRUIT_3. |
| `unity/Assets/_IEC/Image/Board/MOCK_BOARD_4ROPE.png` | 1080×2340 | Dựng lại với mật và nền mới. Các chậu thử cùng cỡ nhau. |
| `unity/Assets/_IEC/Image/Board/MOCK_BOARD_7ROPE.png` | 1080×2340 | Như trên. |
| `unity/Assets/_IEC/Image/UIKit/MOCK_UI_HOME.png` | 1080×2340 | Mép trên, dưới và hai bên là vệt nhòe. Vẽ nền đúng cỡ. Logo tiếp tục để tạm cho đến khi có file gốc. |
| `unity/Assets/_IEC/Image/UIKit/MOCK_UI_POPUP.png` | 1080×2340 | Dựng trên nền Home mới. |

## Tiêu chí chung (mọi phase)

1. Đúng đường dẫn và đúng pixel.
2. File nguồn trong `source/` rộng và cao **ít nhất bằng** bản xuất. Không phóng to, không kéo giãn, không nhòe mép để lấp khoảng trống.
3. Ảnh mới hoàn toàn, không lấy pixel của Sort Streak.
4. Contact sheet trên nền sáng, nền tối và ảnh xám, đặt ở cỡ chơi thật: `contact_sheets/phase<N>_*.png`.
5. Chạy kiểm: không còn `FAIL`; mỗi `WARN` ghi lý do trong `report_phase<N>.csv` hoặc `questions.md`.

```bash
python Codex_Work/Asset_SRSP_v1/tools/check_assets.py --manifest Codex_Work/Asset_SRSP_v1/asset_manifest.csv --out Codex_Work/Asset_SRSP_v1 --source . --only Mechanic/OBJ_HONEY_TOP.png,Mechanic/OBJ_HONEY_BODY.png,Mechanic/OBJ_HONEY_BOTTOM.png,Fruit/BG_BOARD_FRUIT.png,wood_door/frame.png,juice_sort/quota_slot_empty.png,juice_sort/rope_red_top.png,juice_sort/rope_red_bottom.png,Board/BOARD_PLANK.png,juice_sort/board.png,UIKit/BUTTON_GREEN_NORMAL.png,Fruit/ITEM_FRUIT_3.png,juice_sort/flower_yellow.png,Board/MOCK_BOARD_4ROPE.png,Board/MOCK_BOARD_7ROPE.png,UIKit/MOCK_UI_HOME.png,UIKit/MOCK_UI_POPUP.png --report Codex_Work/Asset_SRSP_v1/report_phase0S.csv
```

## Khi nộp

- Cập nhật cột `status` trong `asset_manifest.csv` thành `chờ duyệt`.
- Commit chỉ trong `Codex_Work/Asset_SRSP_v1/`, tiêu đề `Phase 0S: ...`, rồi **dừng**.
- File nào công cụ của bạn không vẽ đạt thì ghi thẳng `không làm được` kèm lý do, đừng nộp ảnh kém.
