# Duyệt level Sweet Rope 7–10

| Level | Trạng thái | `off_by` | Δ chậm / Δ mục tiêu | Chênh hai Δ | `player_win`: default → mới |
|---|---|---:|---:|---:|---:|
| 7 | **CẦN SỬA** | +0,38 | +6,00 / +0,18 | +5,82 | 79,2% → 17,5% |
| 8 | **ĐẠT** | +1,40 | +6,92 / +5,40 | +1,52 | 87,9% → 68,1% |
| 9 | **CẦN KIỂM THÊM** | −0,45 | −1,16 / −3,60 | +2,44 | 84,2% → 77,3% |
| 10 | **ĐẠT** | +1,76 | −4,96 / −6,68 | +1,72 | 53,8% → 81,7% |

## Kiểm tra chung

- **Điểm nhanh:** cả 4 level có |`off_by`| ≤ 2,31.
- **Luật khung:** `frame_errors` đều trống. Đếm tay cho thấy `orderCount` khớp số container, và số hạt mỗi màu bằng `capacity` × số container màu đó. Sức chứa, số hạt từng dây, cỡ từng đợt refill và số mục `Remove` cũng khớp default.
- **Khả năng thắng:** Level Designer báo `win: true` bằng `replay`, không có lỗi hay cảnh báo. Tôi dựa trên kết quả này, không tự replay.
- **Giữ default:** không level nào có `must_keep_default`, nên `matches_default: false` không phải vi phạm.
- **Khoá:** dữ liệu bàn không có trường khoá nào.
- **Giới hạn:** trạng thái dựa thêm trên đánh giá định tính điểm chậm, không dùng ngưỡng số. Không rõ cỡ mẫu của `player_win`. Các giải thích theo cấu trúc bên dưới là giả thuyết.

## Level 7: CẦN SỬA

**Bằng chứng**
- Các kiểm tra bắt buộc đều qua, đường đi replay thắng.
- Mục tiêu gần như giữ nguyên độ khó (+0,18), nhưng điểm chậm tăng +6,00 và `player_win` giảm khoảng 62 điểm phần trăm. Đây là rủi ro lớn nhất của đợt này. `bot_win` bằng 0 ở cả hai bàn nên không giúp phân biệt.
- Hạt trên bàn đầu trùng màu container của dây giảm từ **10 xuống 6**.
- Có **3 hạt chưa có container đang mở** (default: 0): hai hạt màu 4 ở dây 5 (một hạt Hidden) và hạt màu 3 ở dây 6.
- Hidden vẫn tổng 12, nhưng trên bàn tăng từ 2 lên 3.

**Đề xuất** (chỉ đổi `type`, giữ nguyên vị trí Hidden; chỉ số tính từ 0, dây 0 là dây Free, Q0 là mục đầu của `reserveQueue`)
1. Đổi `ropes[5].items[1]` (4) với `Q2.refill[1]` (0). Dây 5 nhận thêm một hạt đúng màu và bớt một hạt bị kẹt.
2. Nếu vẫn quá khó, đổi tiếp `ropes[6].items[0]` (3) với `Q4.refill[2]` (7).
3. Thử từng bước. Sau mỗi bước chạy lại điểm nhanh, điểm chậm và tìm đường đi mới trong Level Designer, vì đường cũ không còn chứng minh được bàn đã sửa.

## Level 8: ĐẠT

**Bằng chứng**
- `off_by` +1,40, replay thắng.
- Điểm chậm tăng cùng chiều mục tiêu, cao hơn dự kiến 1,52. `player_win` giảm khoảng 20 điểm phần trăm, phù hợp với ý định tăng khó.
- Có 2 hạt chưa có container đang mở (default: 0): màu 3 ở dây 2 và màu 8 (Hidden) ở dây 4.
- Hidden vẫn tổng 13, trên bàn tăng từ 9 lên 10.

**Góp ý không bắt buộc:** dây 0 và dây 4 đều có 3 Hidden liên tiếp. Nên chơi thử xem người chơi có phải đoán nhiều không. Nếu cần giảm khó, mở một Hidden ở một trong hai dây rồi chạy lại.

## Level 9: CẦN KIỂM THÊM

**Bằng chứng**
- `off_by` −0,45, replay thắng.
- Điểm chậm chỉ giảm 1,16 trong khi mục tiêu giảm 3,60.
- `player_win` lại **giảm** khoảng 7 điểm phần trăm dù level được định làm dễ hơn. `bot_win` cũng giảm từ 12,5% xuống 2,5%.
- Bàn đầu trông dễ hơn: số hạt đúng màu container tăng từ 8 lên 13. Hidden giữ nguyên số lượng và vị trí.
- Thứ tự container refill đổi từ `7,6,1,2,8,4,3` thành `7,4,6,1,2,3,8`.
- Container màu 4 vào ở **Q1**, nhưng cả 5 hạt màu 4 chỉ nằm ở **Q6 và Q7**. Nếu hàng chờ chạy tuần tự, container này có thể chiếm một dây rất lâu mà không lấp được. Default đưa nó vào ở Q5.

**Đề xuất**
- Thử thứ tự container `7,6,1,2,4,3,8`, giữ nguyên các `refill`, để màu 4 vào muộn hơn.
- Chạy lại điểm nhanh, điểm chậm, luật khung và đường đi.
- Nếu không muốn sửa ngay, chạy lại ước lượng chậm với nhiều mẫu hơn và chơi thử để xác nhận level thật sự dễ hơn default.

## Level 10: ĐẠT

**Bằng chứng**
- `off_by` +1,76 (còn cách giới hạn 0,55), replay thắng.
- Điểm chậm giảm cùng chiều mục tiêu, giảm ít hơn dự kiến 1,72. `player_win` tăng khoảng 28 điểm phần trăm.
- Số hạt đúng màu container tăng từ 5 lên 12. Có 2 hạt màu 0 chưa có container, nhưng container 0 nằm ngay Q0.
- Thứ tự refill đổi từ `0,7,2,4,5` thành `0,2,5,7,4`. Không có Hidden.

**Rủi ro cần theo dõi:** level này gắn nhãn Hard nhưng `player_win` là 81,7%, cao hơn level 7 (17,5%), 8 (68,1%) và 9 (77,3%). Nên chơi thử liền mạch 7–10 để xem đường độ khó có bị đảo không, nhất là sau khi sửa level 7.
