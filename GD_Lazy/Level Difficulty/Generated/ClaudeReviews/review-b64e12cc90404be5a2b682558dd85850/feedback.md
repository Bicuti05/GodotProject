# Kết quả duyệt Sweet Rope: level 11, 12, 16, 20, 21

| Level | Trạng thái | `score_fast` / `aim_fast` | `off_by` (giới hạn ±2,31) | Δ chậm / Δ mục tiêu | Khung | Level Designer |
|---|---|---|---|---|---|---|
| 11 | **CẦN SỬA** | 8,56 / 5,91 | **+2,65** | −6,39 / −11,26 | Không lỗi | Thắng |
| 12 | **CẦN SỬA** | 10,42 / 5,63 | **+4,79** | −5,67 / −11,20 | Không lỗi | Thắng |
| 16 | **CẦN KIỂM THÊM** | 13,15 / 11,93 | +1,22 | +6,51 / +2,01 | Không lỗi | Thắng |
| 20 | **ĐẠT** | 30,19 / 31,28 | −1,09 | +5,14 / +4,65 | Không lỗi | Thắng |
| 21 | **CẦN SỬA** | 4,78 / 1,87 | **+2,91** | −5,82 / −11,39 | Không lỗi | Thắng |

**Cơ sở chung**
- Cả 5 level có `frame_errors` rỗng. Level Designer báo `win: true` bằng replay, không có lỗi hay cảnh báo. Tôi dựa trên kết quả được gửi, không tự chạy lại.
- Tôi đếm tay cả 5 bàn: số vật phẩm mỗi loại đều bằng sức chứa × số container cùng loại, và tổng số container khớp `orderCount`.
- Không level nào bắt buộc giữ default (`must_keep_default: false`), nên `matches_default: false` không phải lỗi.
- Các đề xuất sửa bên dưới **chưa được đo**. Sau mỗi thay đổi cần chạy lại điểm nhanh, điểm chậm, kiểm khung và Level Designer, vì đường đi cũ có thể không còn đúng.

## Level 11: CẦN SỬA
**Bằng chứng**
- Điểm nhanh cần ≤ 8,22, tức phải giảm ít nhất **0,34**.
- Điểm chậm giảm 6,39 so với mục tiêu giảm 11,26 (lệch 4,87). Có rủi ro bàn vẫn khó hơn ý định.
- Có 9 Hidden (default 11). Một Hidden nằm ngay trên bàn đầu (dây 2, loại 2), trong khi default không có Hidden trên bàn.
- Refill thứ 2 (container loại 1) có 3 Hidden: 8, 4, 6.

**Đề xuất**
1. Bỏ Hidden ở vật phẩm loại 2 trên dây 2 (vị trí thứ 4) rồi đo lại.
2. Nếu chưa đủ, bỏ thêm từng Hidden ở refill thứ 2.

## Level 12: CẦN SỬA
**Bằng chứng**
- Điểm nhanh cần ≤ 7,94, tức phải giảm ít nhất **2,48**. Đây là level lệch nhiều nhất.
- Điểm chậm giảm 5,67 so với mục tiêu giảm 11,20 (lệch 5,53).
- Dây 5 (container loại 2) đang mở, nhưng bàn đầu không có vật phẩm loại 2 nào ngoài dây khoá. Một cái nằm trong dây khoá 2, ba cái còn lại ở refill. Default có loại 2 trên Free rope.
- Hidden: 5, bằng default. Hai Hidden loại 7 nằm liền nhau ở refill container loại 4.
- Cả 4 vật phẩm loại 6 đã ở bàn đầu, nên điều kiện mở dây 3 không phụ thuộc refill.

**Đề xuất**
1. Đổi chỗ loại 1 ở Free rope (vị trí thứ 2) với loại 2 ở refill thứ 2 (vị trí thứ 3). Số lượng mỗi loại vẫn giữ nguyên.
2. Nếu điểm còn cao, bỏ hai Hidden loại 7, sau đó xét Hidden ở Free rope và dây 4.
3. Do cần giảm nhiều, có thể phải xếp lại thứ tự refill. Nên đổi từng bước để biết thay đổi nào có tác dụng.

## Level 16: CẦN KIỂM THÊM
**Bằng chứng**
- Điểm nhanh đạt, còn dư 1,09 phía trên (trần 14,24).
- Điểm chậm **tăng 6,51 trong khi mục tiêu chỉ tăng 2,01**, hơn 3 lần.
- `player_win` giảm từ **77,9% xuống 4,8%**, `bot_win` từ 5% xuống 0%. Rủi ro tăng khó đột ngột ở một level Normal là cao, dù replay chứng minh thắng được.
- Dây 1 (loại 3), dây 3 (loại 0) và dây 5 (loại 8) không có vật phẩm đúng loại ở bàn đầu. Default có sẵn ở cả ba.
- Dây khoá 2 cần giao loại 3. Có đúng 5 vật phẩm loại 3 trên các dây mở, vừa bằng một đơn.
- Hidden: 12 (default 11). Hai container loại 1 vào liên tiếp trong hàng chờ, còn default tách chúng ra.

**Đề xuất**
1. Playtest trước khi duyệt.
2. Nếu quá khó, đổi chỗ loại 0 đầu dây 1 với loại 3 ở dây 3. Cả hai dây sẽ có vật phẩm đúng loại.
3. Nếu vẫn khó, thử bớt Hidden ở refill container loại 5 (hai Hidden loại 1), hoặc tách hai container loại 1.
4. Giữ điểm nhanh trong khoảng 9,62–14,24.

## Level 20: ĐẠT
**Bằng chứng**
- Điểm nhanh đạt, còn dư 1,22 phía dưới (sàn 28,97).
- Điểm chậm tăng 5,14 so với mục tiêu 4,65, khá sát (lệch 0,49).
- Hidden: 13, bằng default. Không có dây khoá.
- Free refill có 5 vật phẩm dù sức chứa 6, giống default.

**Lưu ý**
- `player_win` giảm từ **59,7% xuống 10,2%**, `bot_win` từ 17,5% xuống 0%. Level này là Hard và mức tăng điểm phù hợp mục tiêu nên tôi không chặn, nhưng nên playtest hoặc theo dõi tỷ lệ thắng.

**Đề xuất:** chưa cần sửa.

## Level 21: CẦN SỬA
**Bằng chứng**
- Điểm nhanh cần ≤ 4,18, tức phải giảm ít nhất **0,60**.
- Điểm chậm giảm 5,82 so với mục tiêu giảm 11,39 (lệch 5,57).
- `player_win` gần như không đổi (83,8% → 84,6%), còn `bot_win` tăng từ 7,5% lên 20%.
- Khoá `AnyDelivery` ở dây 2 đổi từ **count 2 xuống 1**. `frame_errors` không báo, nhưng nên xác nhận luật khung cho phép đổi giá trị này.
- Hidden: 8 (default 10). Dây 5 có hai Hidden loại 5 liền nhau.

**Đề xuất**
1. Bỏ một Hidden loại 5 ở dây 5 rồi đo lại, nếu chưa đủ thì bỏ cả hai.
2. Nếu vẫn cao, xét hai Hidden loại 8 ở Free refill.

## Phần còn thiếu bằng chứng
- Dữ liệu không nói đầu nào của mảng vật phẩm được lấy trước, nên tôi chưa đánh giá được độ sâu của Hidden hay tác động chính xác của thứ tự refill.
- Không có toàn văn luật khung, chỉ có `frame_errors`.
- Khoá `TypedDelivery` không ghi `type` (level 11 và 12, giống default). Tôi chưa xác định được nó yêu cầu loại nào.
- Không có định nghĩa của `player_win` và `bot_win`, cũng không có ngưỡng cho điểm chậm. Các nhận xét về hai chỉ số này chỉ là cảnh báo rủi ro.
