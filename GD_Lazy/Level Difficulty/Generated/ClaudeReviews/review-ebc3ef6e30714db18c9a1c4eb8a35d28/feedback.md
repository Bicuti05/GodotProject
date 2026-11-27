# Kết quả duyệt level Sweet Rope

**ĐẠT: 3** (12, 14, 24) · **CẦN SỬA: 1** (21) · **CẦN KIỂM THÊM: 6** (7, 11, 13, 16, 18, 23)

## Tiêu chí và kết quả chung

- **CẦN SỬA:** vi phạm tiêu chí cứng.
- **CẦN KIỂM THÊM:** qua tiêu chí cứng nhưng có tín hiệu mâu thuẫn, rủi ro độ khó hoặc điểm luật kit chưa rõ. Đây là đánh giá định tính, không đặt ngưỡng cho điểm chậm.
- **Khung:** cả 10 level có `frame_errors` rỗng. Đối chiếu tay cho thấy số quả mỗi dây/refill và kiểu khoá được giữ. Tất cả đổi trên 25% vị trí (tính theo màu tại cùng vị trí).
- **Thắng:** cả 10 có `win=true` bằng replay trong Level Designer, không lỗi hay cảnh báo.
- **Default:** không level nào trong lô bị yêu cầu giữ default (`must_keep_default=false`).
- **Điểm chậm:** cả 10 có `full_delta − target_delta > 0`, tức mô hình chậm đều đánh giá khó hơn mức thay đổi mong muốn (level 23 gần như khớp). Nên kiểm tra hiệu chỉnh giữa hai thang đo.

| Level | off_by | Dư địa tới 2,31 | Δ chậm / Δ mục tiêu | player_win default → mới | Đổi vị trí | Trạng thái |
|---|---:|---:|---:|---:|---:|---|
| 7 | −2,09 | 0,22 | +4,41 / +0,18 | 79,2% → 34,0% | 37/55 (67,3%) | CẦN KIỂM THÊM |
| 11 | +0,61 | 1,70 | −6,88 / −11,26 | 70,0% → 62,2% | 23/50 (46,0%) | CẦN KIỂM THÊM |
| 12 | +1,99 | 0,32 | −6,75 / −11,20 | 65,8% → 74,6% | 30/48 (62,5%) | **ĐẠT** |
| 13 | +1,37 | 0,94 | −1,35 / −8,88 | 73,8% → 29,8% | 34/60 (56,7%) | CẦN KIỂM THÊM |
| 14 | −2,28 | 0,03 | −5,69 / −6,80 | 76,3% → 83,3% | 25/55 (45,5%) | **ĐẠT** |
| 16 | +1,13 | 1,18 | +6,50 / +2,01 | 77,9% → 10,0% | 38/65 (58,5%) | CẦN KIỂM THÊM |
| 18 | +0,51 | 1,80 | +1,79 / −0,90 | 84,2% → 18,3% | 42/60 (70,0%) | CẦN KIỂM THÊM |
| 21 | **+2,34** | **−0,03** | −4,45 / −11,39 | 83,8% → 72,2% | 30/48 (62,5%) | **CẦN SỬA** |
| 23 | −1,23 | 1,08 | +6,12 / +6,04 | 69,6% → 7,7% | 18/55 (32,7%) | CẦN KIỂM THÊM |
| 24 | −1,13 | 1,18 | +4,47 / +2,62 | 74,6% → 23,0% | 36/60 (60,0%) | **ĐẠT** |

Trong các đề xuất dưới đây, chỉ số dây, `queue` (trong `reserveQueue`) và quả đều đếm từ 0. **Các đề xuất chưa được chạy thử**, nên sau khi sửa cần replay (hoặc giải lại) và đo lại cả điểm nhanh lẫn điểm chậm.

## Level 7: CẦN KIỂM THÊM
- **Bằng chứng:** mục tiêu gần như giữ nguyên độ khó (+0,18) nhưng điểm chậm tăng 4,41 và `player_win` giảm hơn một nửa. Số Hidden giữ 12. Không có khoá.
- **Hidden:** `queue[4] = [4H,1,4,0,3H]` có Hidden ngay đỉnh, điều không thấy ở default.
- **Đề xuất:** đổi thành `[4H,1,4H,0,3]`. Nếu cần giảm độ khó chậm, thử bỏ Hidden ở quả 1 của refill Free (`queue[5]`).
- **Lưu ý:** điểm nhanh đang thấp hơn đích, chỉ còn giảm được 0,22. Làm level dễ hơn có thể khiến điểm nhanh trượt chuẩn.

## Level 11: CẦN KIỂM THÊM
- **Bằng chứng:** điểm chậm giảm đúng hướng nhưng ít hơn mục tiêu 4,38. `player_win` lại giảm 7,8 điểm phần trăm, ngược với tín hiệu "dễ hơn".
- **Cấu trúc:** Hidden giảm từ 11 xuống 7. Khoá TypedDelivery thiếu `type` (màu 0), count 1, không đổi.
- **Đề xuất:** mô phỏng thêm để xác nhận `player_win`. Nếu vẫn khó, thử bỏ Hidden ở `queue[2]`, quả 3 (màu 0). Điểm nhanh còn giảm được khoảng 2,92.

## Level 12: ĐẠT
- **Bằng chứng:** `off_by` trong chuẩn, replay thắng, điểm chậm giảm và `player_win` tăng, cùng hướng "dễ hơn".
- **Cấu trúc:** Hidden giảm từ 5 xuống 2, không có Hidden ở đỉnh. Hai khoá giữ nguyên (màu 0 và màu 6, count 1).
- **Rủi ro:** điểm chậm chỉ giảm 6,75 so với mục tiêu 11,20. Điểm nhanh còn cách giới hạn trên 0,32.
- **Đề xuất:** không bắt buộc sửa. Theo dõi độ khó khi chơi thật.

## Level 13 (Bonus): CẦN KIỂM THÊM
- **Bằng chứng:** điểm chậm chỉ giảm 1,35 trong khi mục tiêu giảm 8,88. `player_win` giảm mạnh, ngược hướng mong muốn.
- **Khoá:** dây 5 đổi từ màu 6 sang màu 1, nên cả hai khoá cùng cần màu 1. Nước đầu `[0,0,1]` gom đủ 5 quả màu 1, theo cấu trúc sẽ mở cả hai khoá ngay.
- **Refill:** `queue[6]` có giỏ màu 2 và `[2,2,2,2,2]`, tức đã hoàn thành sẵn khi xuất hiện.
- **Đề xuất:** xác nhận kit và game cho phép refill hoàn thành sẵn. Nếu không, thử đổi chỗ `queue[6]` quả 2 với `queue[4]` quả 1, thành `[2,2,1,2,2]` và `[1,2,4,1,1]`. Thay đổi này có thể làm level khó hơn, mà điểm nhanh chỉ còn tăng được 0,94.
- **Hidden:** giảm từ 7 xuống 6. Chưa đủ bằng chứng để xác định nguyên nhân `player_win` thấp.

## Level 14: ĐẠT
- **Bằng chứng:** điểm chậm giảm 5,69, khá sát mục tiêu 6,80. `player_win` tăng, replay thắng.
- **Cấu trúc:** Hidden giảm từ 11 xuống 9, không có Hidden ở đỉnh. Khoá màu 5, count 1, không đổi.
- **Rủi ro:** `|off_by|=2,28`, chỉ cách giới hạn 0,03. Dây 4 là `[1,1H,1H,1]` trên giỏ màu 1, gần hoàn thành sẵn.
- **Đề xuất:** giữ nguyên. Mọi chỉnh sửa, kể cả Hidden, đều phải đo lại.

## Level 16: CẦN KIỂM THÊM
- **Bằng chứng:** điểm chậm tăng 6,50 so với mục tiêu 2,01. `player_win` chỉ còn 10%.
- **Cấu trúc:** Hidden giảm từ 11 xuống 10 nhưng vẫn khó hơn. Dây 1 đổi thành `[0,5,4,7,8]`, năm màu khác nhau và không quả nào khớp giỏ màu 3. Đây có thể là một nguồn độ khó (suy luận, chưa tách thử). Khoá màu 3 không đổi.
- **Đề xuất:** gom màu ở refill Free (`queue[7]`), từ `[1,0H,0,1H,3]` thành `[1,1H,0,0H,3]`. Điểm nhanh còn giảm được khoảng 3,44.

## Level 18: CẦN KIỂM THÊM
- **Bằng chứng:** mục tiêu dễ hơn (−0,90) nhưng điểm chậm khó hơn (+1,79), **ngược hướng**. `player_win` giảm từ 84,2% xuống 18,3%. Đây là rủi ro lớn dù `off_by` rất tốt.
- **Hidden:** tăng từ 15 lên 16. `queue[4]` có 3 Hidden. `queue[5] = [1,1,6,5,2H]` có Hidden ở đỉnh.
- **Khoá:** đổi từ màu 5 sang màu 0, count 1.
- **Đề xuất:** đổi `queue[5]` thành `[1,1,6,5H,2]`, bỏ Hidden ở `queue[4]` quả 1 và dây 5 quả 2. Tổng còn 14 Hidden, cần xác nhận nằm trong giới hạn kit.

## Level 21: CẦN SỬA
- **Bằng chứng:** điểm nhanh 4,21, đích 1,87, nên `off_by=+2,34 > 2,31` (`ok=false`). Replay thắng không bù được lỗi này.
- **Điểm chậm:** giảm 4,45 so với mục tiêu 11,39, cũng chưa đủ dễ.
- **Cấu trúc:** Hidden giảm từ 10 xuống 5. Khoá AnyDelivery đổi count từ 2 xuống 1.
- **Đề xuất:** đổi dây 5 từ `[5,2,5]` thành `[2,5,5]` để gom hai quả 5. Số vị trí khác default không đổi.
- **Phương án bổ sung:** nếu chưa đạt và kit cho phép, bỏ Hidden ở dây 1 quả 2.
- **Điều kiện đạt:** điểm nhanh phải ≤ 4,18 nếu đích giữ 1,87. Nên chừa thêm biên thay vì chỉ vừa chạm ngưỡng.

## Level 23 (Bonus): CẦN KIỂM THÊM
- **Bằng chứng tốt:** điểm chậm tăng 6,12, gần khớp mục tiêu 6,04. `off_by` đạt.
- **Rủi ro:** `player_win` chỉ 7,7%.
- **Hidden:** tăng từ 11 lên 12. `queue[1] = [1,0,2,0H,3H]` và `queue[2] = [4,7,8H,2H,1H]` có Hidden ở đỉnh, default không có. `queue[2]` còn chứa 3 Hidden.
- **Đề xuất:** đổi thành `[1,0,2H,0H,3]` và `[4,7H,8H,2H,1]`, đồng thời xác nhận giới hạn Hidden mỗi refill. Khoá AnyDelivery count 1 không đổi.

## Level 24: ĐẠT
- **Bằng chứng:** `off_by` đạt, replay thắng. Điểm chậm tăng 4,47 so với mục tiêu 2,62, cùng hướng.
- **Cấu trúc:** Hidden giữ 8, không ở đỉnh. Khoá dây 3 đổi từ màu 4 sang màu 0. Khoá AnyDelivery count 2 không đổi.
- **Rủi ro:** `player_win` giảm còn 23% và `bot_win` từ 35% xuống 0%, nên level có thể khó hơn dự kiến.
- **Đề xuất:** không bắt buộc sửa, nên ưu tiên chơi thử. Nếu cần giảm khó, thử bỏ một Hidden ở đầu refill Free (`queue[7]`, quả 0 hoặc 1).

## Giới hạn bằng chứng
- Kết quả thắng, điểm và tỷ lệ mô phỏng lấy từ dữ liệu được gửi; tôi không chạy lại. Phần đếm vị trí đổi và Hidden là đối chiếu tay.
- Dữ liệu không nêu giới hạn Hidden của kit, kể cả việc có cấm Hidden ở đỉnh refill hay không.
- Dữ liệu không có số lượt mô phỏng, nên chưa đánh giá được độ tin cậy của `player_win`.
