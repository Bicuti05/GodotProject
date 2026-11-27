# Kết quả duyệt level 26–33

**Tổng kết:** 4 level **ĐẠT**, 2 level **CẦN SỬA**, 2 level **CẦN KIỂM THÊM**.

| Level | Trạng thái | off_by | Δ chậm: mô hình / mục tiêu | player_win: mới / default | Quả đổi màu theo vị trí |
|---|---|---:|---:|---:|---:|
| 26 | **CẦN SỬA** | **+9,83** | −9,52 / −18,10 | 84,6% / 65,5% | 31/48 (64,6%) |
| 27 | **ĐẠT** | không áp dụng | không áp dụng | không có | giữ default |
| 28 | **CẦN KIỂM THÊM** | −0,51 | **+3,00 / −0,29** | 22,3% / 61,4% | 35/55 (63,6%) |
| 29 | **ĐẠT** | +0,59 | −5,03 / −7,24 | 77,5% / 74,2% | 49/65 (75,4%) |
| 30 | **ĐẠT** | không áp dụng | không áp dụng | không có | giữ default |
| 31 | **ĐẠT** | −0,71 | −5,93 / −6,63 | 87,9% / 83,3% | 19/48 (39,6%) |
| 32 | **CẦN SỬA** | **+4,44** | −1,02 / −10,81 | 40,8% / 59,8% | 33/55 (60,0%) |
| 33 | **CẦN KIỂM THÊM** | +1,33 | +7,97 / +8,16 | **2,5%** / 53,1% | 15/55 (27,3%) |

**Phạm vi kiểm tra**
- Cả 8 level có `frame_errors` rỗng, `solvable=true`, Level Designer `win=true` bằng **replay**, không có lỗi hay cảnh báo. Tôi dựa vào kết quả này, không tự chạy lại replay.
- Tỷ lệ đổi quả và số Hidden là tôi đếm tay từ dữ liệu.
- Dữ liệu không nêu giới hạn Hidden của kit, nên phần này chỉ dựa vào kết quả kiểm khung.
- `levelIndex` 1 ở đây là level 26, không phải Level 1.
- Vị trí quả bên dưới đếm từ 0, từ đáy lên đỉnh. `q0` là mục đầu của `reserveQueue`.

## Level 26: CẦN SỬA

- **Điểm nhanh:** 12,85 so với aim 3,02. Cần về khoảng **0,71–5,33**.
- **Điểm chậm:** giảm đúng hướng nhưng còn thiếu 8,58 so với mức giảm mục tiêu. Có rủi ro level vẫn khó hơn thiết kế.
- **Khung và cấu trúc:** giữ khoá `TypedDelivery`, màu 8, count 1. Hidden giảm từ 7 xuống 5.
- **Điểm nghẽn:** chỉ có một đơn màu 8 để mở khoá. Hai quả 8 nằm ở `r6[0]` và `r6[2]`, nên phải đào tới đáy dây 6.

**Đề xuất, thử riêng từng phương án:**
1. Đổi type của khoá từ **8 sang 1**, giữ count 1. `r1` là dây màu 1 đang trống. Bốn quả 1 đã lấy được ngoài dây khoá: hai quả trên đỉnh `r3`, một ở `r4`, một trên đỉnh `r6`.
2. Nếu muốn giữ màu 8, đổi `r6` từ `[8H, 2, 8H, 1]` thành `[1H, 2, 8H, 8]`.

Khoảng lệch lớn, nên nếu cả hai chưa đủ thì sinh lại bàn.

## Level 27: ĐẠT

- Ghi chú Challenge, `must_keep_default=true`, `matches_default=true`. Đối chiếu dữ liệu cũng thấy bàn trùng default.
- Không có ghi chú `ice_01_ghi_de`.
- Mục tiêu 12,1 khác điểm thật default 31,8. Đây không phải lỗi vì bàn bắt buộc giữ nguyên.
- Không cần sửa.

## Level 28: CẦN KIỂM THÊM

- **Điểm nhanh:** đạt.
- **Rủi ro điểm chậm:** mục tiêu gần như giữ độ khó, nhưng mô hình cho khó hơn 3,00. `player_win` giảm 39,1 điểm phần trăm. `bot_win` từ 2,5% xuống 0%.
- **Cấu trúc:** Hidden giảm từ 11 xuống 9, nên số Hidden không giải thích được việc khó hơn.
- **Nguyên nhân khả dĩ (suy luận):**
  - `q0` là dây màu 2, nhưng bàn đầu chỉ có một quả 2 và refill của `q0` không có quả nào.
  - `q1` là dây màu 4, nhưng bàn đầu và `q0` không có quả 4.

**Đề xuất:** playtest trước. Nếu quá khó, đổi chỗ `q0[2]` với `q1[1]` để được `q0 = [7, 3H, 2, 8, 5]` và `q1 = [4, 0, 4, 2, 7]`. Sau đó kiểm lại, giữ điểm nhanh trong **17,18–21,80** và xem Δ chậm có tiến gần −0,29 không.

## Level 29: ĐẠT

- Điểm nhanh đạt. Điểm chậm giảm cùng hướng, ít hơn mục tiêu 2,21. `player_win` tăng nhẹ.
- Khoá `AnyDelivery` đổi count từ 2 xuống 1, đúng quyền chỉnh. Hidden giảm từ 5 xuống 3.
- `r1` có sẵn bốn quả 6 đúng màu và `q0` có bốn quả 2 trong refill, phù hợp hướng làm dễ hơn.
- Không bắt buộc sửa. Khi playtest, theo dõi xem có còn khó hơn dự kiến không.

## Level 30: ĐẠT

- Ghi chú Endless, `matches_default=true`. Đối chiếu dữ liệu cũng thấy bàn trùng default.
- Không có ghi chú `ice_01_ghi_de`.
- Mục tiêu 25,89 khác điểm thật 29,4, không phải lỗi vì phải giữ default.
- Không cần sửa.

## Level 31: ĐẠT

- Điểm nhanh đạt. Δ chậm chỉ lệch mục tiêu 0,70. `player_win` tăng, đúng hướng dễ hơn.
- Khoá `TypedDelivery` màu 4, count 1 được giữ. `r1` đã có một quả 4, còn các quả 4 trên đỉnh `r2` và `r5` giúp mở khoá sớm.
- Hidden giảm từ 6 xuống 3.
- Không cần sửa.

## Level 32: CẦN SỬA

- **Điểm nhanh:** 14,53 so với aim 10,09. Cần về khoảng **7,78–12,40**.
- **Điểm chậm:** chỉ giảm 1,02 trong khi mục tiêu giảm 10,81. `player_win` còn giảm 19,0 điểm phần trăm, tức tín hiệu này cho thấy **khó hơn default**.
- **Mở đầu dễ:** `r1` có bốn quả 4, quả thứ năm nằm trên đỉnh `r5`. Đáy `r2` có ba quả 8.
- **Nghẽn phía sau (suy luận):**
  - `q0` là dây màu 2, nhưng bàn đầu và `q0` không có quả 2. Quả 2 chỉ đến từ `q1`, `q4`, `q5`, `q6`.
  - `q1` là dây màu 5, còn quả 5 chỉ nằm ở `q3` và `q5`.

**Đề xuất, đo sau từng bước:**
1. Đổi chỗ **màu dây** của `q0` và `q4`, thành `q0` màu 6 và `q4` màu 2. Refill giữ nguyên.
2. Nếu còn khó, đưa quả 2 của `q1` lên đỉnh: `[2, 3, 3, 0, 0]` thành `[0, 3, 3, 0, 2]`.
3. Nếu vẫn ngoài khoảng, đưa bớt quả 5 vào refill sớm hơn bằng cách hoán đổi, giữ nguyên tổng mỗi màu, hoặc sinh lại bàn.

## Level 33: CẦN KIỂM THÊM

- **Đạt các tiêu chí điểm:** điểm nhanh trong ngưỡng, Δ chậm chỉ lệch mục tiêu 0,19.
- **Rủi ro:** `player_win` từ 53,1% xuống **2,5%**, `bot_win` từ 5% xuống 0%. Replay thắng chỉ chứng minh có đường thắng, không chứng minh người chơi dễ tìm ra. Đây là level ghi chú **Bonus**, nên cần xác nhận độ khó này có chủ ý không.
- **Khung:** đổi 15/55 vị trí, chỉ dư một vị trí so với mức tối thiểu 14. Khoá `AnyDelivery` count 1 được giữ. Hidden giảm từ 13 xuống 12.
- **Nguyên nhân khả dĩ (suy luận):** `q3` là dây màu 6, nhưng ba trong năm quả 6 nằm ở `q5`, một quả nằm đáy `q0`.

**Đề xuất:** playtest trước. Nếu quá khó, thử trả màu dây về thứ tự default (`q3` màu 2, `q4` màu 6). Giữ điểm nhanh trong **17,63–22,25**, rồi kiểm lại điểm chậm. Làm dễ hơn có thể khiến Δ chậm xa mục tiêu, nên cần cân giữa mục tiêu điểm và tỷ lệ thắng. Các lần sửa sau phải giữ ít nhất 14 vị trí khác default.

**Lưu ý chung:** mọi đề xuất sửa đều **chưa được chạy thử**. Sau khi sửa cần kiểm lại khung, tỷ lệ đổi quả, replay/solver, điểm nhanh và điểm chậm. Replay hiện tại có thể không còn dùng được cho bàn mới.
