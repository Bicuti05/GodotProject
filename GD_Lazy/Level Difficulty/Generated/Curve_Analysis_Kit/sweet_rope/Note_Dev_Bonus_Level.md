# Ghi chú cho Dev: Bonus Level

Ngày 2026-11-26. GD đã chốt. Bản này thay bản trước (bản trước ghi "giữ luật x2 theo ngày", nay bỏ).

## Đã chốt: Bonus cố định, kiểu "heo vàng" của Sort Streak

Nguồn: `juice_bonus_level.gd`, `juice_game_page.gd`, `bonus_level_entry.gd` của Sort Streak. Đọc từ mã, chưa xem trong game.

| Mục | Luật |
|---|---|
| Level nào | Cố định: level **13, 23, 33…** (từ 13, cách 10). Không theo ngày, không giới hạn số lần mỗi ngày. Không trùng Challenge (17, 27…) hay Endless (30, 40…) |
| Trên bàn | Chọn **một màu có đúng 1 Container trong cả level**. Quả và chậu của màu đó đổi sang skin **đồng xu vàng ngay khi vào level**. Luật chơi giữ nguyên, chỉ đổi skin |
| Cách chọn màu | Nếu màu đang dùng skin vàng của theme chỉ có 1 chậu thì lấy màu đó. Nếu không, chọn ngẫu nhiên trong các màu chỉ có 1 chậu. Nếu màu vàng của theme có nhiều chậu, các chậu đó đổi sang màu đã chọn để không trùng skin |
| Số quả vàng | Bằng sức chứa của chậu đó. Sort Streak: cả 512 level Bonus đều 5 quả |
| Thưởng | **+100 coin cố định**, cộng thêm vào thưởng thường (10 Gold mỗi Order). Không tính theo số quả vàng. Sort Streak có bản A/B 300 coin; bản đó còn bắt chậu vàng phải có mặt lúc mở level |
| Hiệu ứng (gốc) | Banner "Bonus Level" khi vào; giao chậu vàng thì đồng xu bay vào heo; thắng thì đập heo nhận coin |
| Không có màu đủ điều kiện | Level đó **không làm Bonus** (Sort Streak bỏ qua). Level 1–200 của Sweet Rope đều có màu đủ điều kiện (tính cả chậu trên Rope đang khoá) |
| Nút Play ở Home | Hiện "Bonus Level" nền cam như hiện tại, nhưng đổi điều kiện sang level cố định |

## Dev cần đổi

- `BonusLevelRules` / `BonusLevelController`: bỏ luật theo ngày (`bonusMode`, `bonusEvery`, `bonusMaxPerDay`, `bonusMultiplier`), thay bằng `bonusFirst = 13`, `bonusInterval = 10`, `bonusCoins = 100`. Không còn nhân đôi Gold.
- Khi vào level Bonus: chọn màu vàng như trên, đổi skin quả và chậu màu đó lúc chạy. **Không ghi vào file level.**
- Màn Win: hiện dòng +100 coin của Bonus.
- Bonus vẫn tính IQ? Hiện tài liệu ghi "Bonus không tính IQ"; Sort Streak không loại Bonus khỏi IQ. **Cần GD xác nhận.**

## Level data

- Độ khó level Bonus theo đường C như level thường.
- Bộ sinh level giữ nguyên màu chậu lúc mở và số chậu mỗi màu, nên màu đủ điều kiện vẫn còn. Bộ đóng gói kiểm lại từng level Bonus và báo lỗi nếu thiếu.

## Cần Art

- Skin đồng xu vàng (thay cho quả) và chậu vàng, cùng kích thước với quả và chậu thường.
- Heo vàng (HUD), hiệu ứng đồng xu bay và đập heo, banner "Bonus Level".
