# Duyệt level Sweet Rope

**Kết quả: 4 level ĐẠT, 6 level CẦN KIỂM THÊM, chưa level nào bị kết luận CẦN SỬA.** Cả 10 level có `frame_errors` rỗng, Level Designer replay thắng, không lỗi và không cảnh báo. 9 level phải kiểm điểm nhanh đều có |off_by| ≤ 2,31.

| Level | Trạng thái | off_by | Δ full / Δ target | player_win mới / default |
|---|---|---:|---:|---:|
| 13 | **CẦN KIỂM THÊM** | +1,39 | **+0,65 / −8,88** | 17,1% / 73,8% |
| 14 | **CẦN KIỂM THÊM** | +2,06 | **+0,15 / −6,80** | 69,3% / 76,3% |
| 15 | **ĐẠT** | −1,88 | +4,90 / +5,73 | 20,3% / 36,4% |
| 17 | **ĐẠT** | không áp dụng | giữ default | không có dữ liệu |
| 18 | **CẦN KIỂM THÊM** | +0,36 | **+2,28 / −0,90** | 4,8% / 84,2% |
| 19 | **ĐẠT** | +0,55 | +0,71 / +0,98 | 38,0% / 78,5% |
| 22 | **CẦN KIỂM THÊM** | −0,07 | **+2,16 / −0,33** | 2,5% / 85,9% |
| 23 | **CẦN KIỂM THÊM** | −0,31 | +6,38 / +6,04 | **0% / 69,6%** |
| 24 | **CẦN KIỂM THÊM** | −0,17 | **+5,68 / +2,62** | 9,4% / 74,6% |
| 25 | **ĐẠT** | −1,23 | −0,60 / −0,03 | 22,3% / 65,8% |

**Cách xếp trạng thái**
- **ĐẠT:** qua các kiểm tra bắt buộc và điểm chậm không lệch rõ so với mục tiêu. Rủi ro còn lại được ghi riêng.
- **CẦN KIỂM THÊM:** qua kiểm tra bắt buộc, nhưng điểm chậm ngược hướng hoặc lệch nhiều, hoặc `player_win` gần như mất hẳn. Đây là đánh giá định tính, không phải ngưỡng điểm chậm.

**Giới hạn bằng chứng**
- Tôi chỉ đọc dữ liệu được gửi, không chạy lại solver, replay hay mô hình.
- Replay chứng minh có một đường thắng, không cho biết người chơi tìm ra nó dễ đến đâu.
- Dữ liệu không định nghĩa `player_win` và `bot_win`. `bot_win = 0` không chứng minh level vô nghiệm.
- Nhận xét cấu trúc giả định `reserveQueue` vào theo thứ tự (#1 là mục đầu) và `TypedDelivery` là giao đơn đúng màu. Các nguyên nhân độ khó nêu dưới đây là giả thuyết.
- Tôi đếm tay 9 level đã đổi: số item mỗi màu đều bằng capacity × số đơn màu đó.

---

## Level 13 (Bonus): CẦN KIỂM THÊM
- **Bằng chứng:** điểm nhanh 10,72 so với aim 9,33. Mục tiêu yêu cầu dễ hơn nhiều, nhưng full tăng từ 17,90 lên 18,55.
- **Cấu trúc:**
  - Cả hai khoá giờ cần màu 1 (default: một khoá cần màu 6). Dây 0 và 1 đã có đủ 5 item màu 1, nên khoá có vẻ mở sớm.
  - Reserve #7 là đơn màu 2 kèm đủ 5 item màu 2.
  - Hidden tăng từ 7 lên 8.
- **Đề xuất:** đo lại full và chơi thử. Nếu vẫn khó, thử bỏ Hidden ở hai item màu 3 của reserve #4 (`refill[1]`, `refill[2]`) trước.

## Level 14: CẦN KIỂM THÊM
- **Bằng chứng:** mục tiêu giảm 6,80 nhưng full gần như không đổi (16,25 → 16,40). `off_by` +2,06, chỉ còn cách giới hạn 0,25.
- **Cấu trúc:**
  - Hidden giảm từ 11 xuống 10.
  - Cả 5 item màu 5 nằm trên dây 1 và 4, thuận lợi để mở khoá màu 5.
  - Container reserve #3 và #4 đổi chỗ (4, 2 → 2, 4).
- **Đề xuất:** đo lại full. Nếu cần dễ hơn, thử bỏ hai Hidden màu 6 ở dây 0, rồi kiểm lại `off_by`.

## Level 15 (Hard): ĐẠT
- **Bằng chứng:** `off_by` −1,88. Full tăng 4,90, cùng hướng và khá gần mục tiêu +5,73.
- **Cấu trúc:** không có Hidden hay khoá. Container reserve #2 và #4 đổi chỗ (0, 3 → 3, 0), nên đơn màu 0 thứ hai đến muộn hơn. Item trên dây và trong refill cũng được trộn lại.
- **Rủi ro:** `player_win` giảm còn 20,3%.
- **Đề xuất:** không cần sửa. Nên chơi thử vì đây là bước tăng độ khó lớn.

## Level 17 (Challenge): ĐẠT
- **Bằng chứng:** `must_keep_default = true`, `matches_default = true`, replay thắng.
- **Ghi chú:** `real_default` 16,5 khác target 15,06, nhưng yêu cầu ở đây là giữ bàn default.
- **Đề xuất:** giữ nguyên.

## Level 18: CẦN KIỂM THÊM (ưu tiên cao)
- **Bằng chứng:** mục tiêu hơi dễ hơn (−0,90) nhưng full khó hơn (+2,28). `player_win` còn 4,8%.
- **Cấu trúc:**
  - **Cả 5 item màu 8 đến ở reserve #1 và #2, trong khi đơn màu 8 tới #3 mới xuất hiện.** Điều này có thể gây kẹt chỗ chứa.
  - Reserve #5 có 3 item Hidden màu 1. Tổng Hidden tăng từ 15 lên 16.
  - Khoá đổi từ màu 5 sang màu 0.
- **Đề xuất:** thử đổi container reserve #1 (6) với #3 (8), giữ nguyên refill. Sau đó chạy lại toàn bộ kiểm tra.

## Level 19: ĐẠT
- **Bằng chứng:** `off_by` +0,55. Full +0,71, gần mục tiêu +0,98.
- **Cấu trúc:**
  - Hidden giữ 7 item.
  - Chuỗi khoá có vẻ là giao màu 3 → mở dây 2 (đơn màu 1) → giao màu 1 → mở dây 3.
  - Đơn màu 1 trong reserve chuyển từ #1 xuống #5, nên đường mở dây 3 hẹp hơn.
- **Rủi ro:** `player_win` giảm từ 78,5% xuống 38,0%.
- **Đề xuất:** không bắt buộc sửa. Nếu chơi thử thấy kẹt ở khoá, xem lại vị trí đơn màu 1 này.

## Level 22: CẦN KIỂM THÊM (ưu tiên cao)
- **Bằng chứng:** mục tiêu gần như giữ nguyên (−0,33) nhưng full tăng 2,16. `player_win` còn 2,5%.
- **Cấu trúc:**
  - Khoá nới từ 2 xuống 1 lần giao bất kỳ, và không có Hidden. Hai yếu tố này khó giải thích việc tăng độ khó.
  - Reserve #2 và #6 đổi container (3, 4 → 4, 3).
  - **5 item màu 3 đến trong reserve #1–#3, nhưng đơn màu 3 đầu tiên tới #4 mới xuất hiện.**
  - Đơn màu 4 mở ở #2 khi mới có 1 item màu 4 xuất hiện.
- **Đề xuất:** thử trả container reserve #2 về 3 và #6 về 4, giữ nguyên refill, rồi chạy lại.

## Level 23 (Bonus): CẦN KIỂM THÊM (ưu tiên cao nhất)
- **Bằng chứng:** `off_by` −0,31 và Δ full khớp mục tiêu, nhưng **`player_win = 0%`** dù replay thắng.
- **Cấu trúc:**
  - Đơn màu 2 chuyển lên reserve #1. Trước #3, item màu 2 duy nhất là item Hidden trong dây khoá.
  - Dây 1 mất hai item màu 8 đã nằm đúng container.
  - Hidden tăng từ 11 lên 12, trong đó hai item mới nằm ngay trên dây ban đầu.
- **Đề xuất:** thử từng thay đổi và đo riêng:
  1. Đổi thứ tự container reserve #1–#3 từ `2, 1, 0` thành `1, 0, 2`.
  2. Nếu vẫn quá khó, hoán đổi hai item `1, 6` của dây 1 với hai item màu 8 của dây 0.
- **Cần xác nhận:** mức 0% có chấp nhận được với một level Bonus hay không.

## Level 24: CẦN KIỂM THÊM
- **Bằng chứng:** full tăng 5,68, hơn hai lần mục tiêu +2,62. `player_win` còn 9,4%, `bot_win` từ 35% về 0%.
- **Cấu trúc:**
  - Reserve #5 và #7 đổi container (0, 2 → 2, 0). Refill #5 đưa ra 3 item màu 0 trong khi đơn màu 0 này bị lùi xuống #7.
  - 3 item màu 3 đến trước đơn màu 3 ở #4, còn default không có item nào trong #1–#3.
  - Khoá dây 3 đổi từ màu 4 sang màu 0. Hidden giữ 8 item.
- **Đề xuất:** thử trả container #5 về 0 và #7 về 2. Nếu vẫn khó hơn mong muốn, giảm số item màu 3 đến sớm bằng cách hoán đổi với item ở refill phía sau.

## Level 25 (Hard): ĐẠT
- **Bằng chứng:** `off_by` −1,23. Full giảm 0,60, mục tiêu gần như giữ nguyên (−0,03), điểm full mới là 28,36.
- **Cấu trúc:** reserve #2 và #3 đổi container (0, 7 → 7, 0). Hidden giảm từ 13 xuống 12, nhưng dây 2 tăng từ 2 lên 3 Hidden.
- **Rủi ro:** `player_win` giảm từ 65,8% xuống 22,3% dù điểm full thấp hơn.
- **Đề xuất:** không bắt buộc sửa. Nên chơi thử, chú ý dây 2.

---

**Sau mỗi lần sửa:** chạy lại `off_by`, luật khung, Level Designer và full estimate. Đường replay cũ có thể không còn hợp lệ; nếu solver không tìm được đường mới thì chưa thể kết luận level vô nghiệm.
