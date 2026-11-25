# Sweet Rope FullRun

## A — Sửa asset trong fix list

Đã cập nhật **184/184 file** theo đường dẫn và kích thước yêu cầu. Checker ghi **0 FAIL** cho A. Trạng thái chờ duyệt ghi nhận đã xuất art và kiểm ảnh, phần tích hợp cần chạy trong dự án game.

- Ghép mật TOP/BODY/BOTTOM ở 3–8 Item × 125 px. Hai mối nối trùng hàng pixel. Thân đặc ở dải 125 px. Bốn khung mật chảy dùng cùng độ cao neo.
- Kiểm 11 dây với thân x=25–35. Ba đoạn chung dải nối, nút thắt rộng hơn thân.
- Đối chiếu chậu táo với 9 chậu còn lại. Chậu táo rộng 156 px và đáy y=170 ở ngưỡng alpha 100. Ô Order dùng chậu gốm xám.
- FSRCNN ×2 áp dụng cho nền lớn cần tăng kích thước. Nguồn AI gốc giữ trong source.
- Giữ kích thước khung và metadata 9-slice của các nút. Kiểm thêm bên trong Unity ở nhiều độ rộng.
- 32 file A7 có pixel khác nhau. Cần xác minh vị trí 24 mảnh Hex, pivot trang trí và chuyển động FX trong dự án.
- Đã đặt chồng chip, Quit và bục Rank lên art team. Ba bục có độ giao alpha khoảng 95%. Contact sheet với nền sáng, tối và ảnh xám nằm ở contact_sheets/fullrun_*.

## B — Dòng manifest chưa làm lúc bắt đầu

| Nhóm | Đã xuất, chờ duyệt | Chưa làm | Không làm được lúc này |
| --- | ---: | ---: | ---: |
| P0 draw | 26 | 0 | 2 |
| P1 draw | 18 | 196 | 2 |
| P2 draw | 52 | 54 | 0 |
| P2 layers | 4 | 41 | 1 |
| P2 atlas | 1 | 3 | 0 |

Đã xuất **101/400 dòng**. Còn **294 dòng chưa làm**. Năm dòng bị chặn chờ logo PNG trong suốt đã chốt gồm hai biến thể Store, hai logo Godot và lớp động logo. Giữ chữ logo tạm trong mockup.

Đã giao 5/1106 vùng animation cùng motion.md cho bốn bộ. Atlas Paw Streak đã đóng vào ô có sẵn và kiểm tra chồng lấn. Ba atlas Unity khác còn thiếu.

## C — Mockup

Dựng lại **81/81 mockup và 4/4 ảnh MOCK_BOARD / MOCK_UI** ở 1080 × 2340. Mỗi ảnh có nhãn MOCKUP. Chữ Orchard có thẻ nền riêng. Ô Order, dây và mật dùng art mới. Một số màn vẫn dùng lớp minh họa Sweet Rope hiện có tại vị trí chưa có art sản xuất. Xem [index mockup](mockups/INDEX.md).

## D — Kiểm tra và tích hợp

Checker tự kiểm thành công. Quét toàn bộ cho **699 OK, 114 WARN và 299 FAIL**. Các FAIL đều là dòng còn thiếu đầu ra. **Kiểm tra toàn bộ chưa đạt.** Xem [report_all.csv](report_all.csv) và [xử lý từng WARN](warn_disposition.csv). Ảnh dài được thu trên sheet tổng quan, PNG xuất giữ đúng kích thước trong manifest.

- DEV-01, DEV-02, DEV-22 gắn Container, Item và nền theo ThemeConfig và TypeColorConfig.
- DEV-03 kiểm 24 mảnh Hex, vị trí ba lớp Home và các viewport.
- DEV-04, DEV-08, DEV-11, DEV-12, DEV-14 kiểm Helper, banner, HUD, máy đếm, splash và 9-slice trong scene thật.
- DEV-05, DEV-15, DEV-16, DEV-21 gắn dải mật lặp, dấu sáp, vòng treo, hiệu ứng mở túi và Undo. Kiểm các chiều cao 3–8.
- DEV-13 gắn con trỏ và recipe motion. Kiểm atlas Paw Streak trên rig của team rồi hoàn tất các atlas và lớp còn lại.
- Cần PNG logo đã chốt và các asset còn thiếu để chạy lại checker. Mockup là ảnh dựng tĩnh, chưa xác nhận runtime Unity hoặc Godot.
