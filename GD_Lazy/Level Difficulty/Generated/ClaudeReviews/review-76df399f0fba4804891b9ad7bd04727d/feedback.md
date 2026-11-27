# Kết quả duyệt level Sweet Rope

| Level | Trạng thái | `off_by` | Đổi vị trí quả | Điểm chậm: thực tế / mục tiêu | `player_win`: mới / default |
|---|---|---:|---:|---:|---:|
| 3 | **ĐẠT** | −0,82 | 25/44 (56,8%) | +0,43 / 0,00 | 84,6% / 82,9% |
| 4 | **ĐẠT** | −1,59 | 33/50 (66,0%) | −0,37 / 0,00 | 70,6% / 72,1% |
| 6 | **ĐẠT** | −0,92 | 23/50 (46,0%) | −0,21 / −0,54 | 69,3% / 68,8% |
| 7 | **CẦN SỬA** | −2,24 | 41/55 (74,5%) | **+4,56 / +0,18** | **21,6% / 79,2%** |
| 9 | **ĐẠT** | −1,15 | 32/60 (53,3%) | −3,21 / −3,60 | 85,4% / 84,2% |

**Kiểm tra chung**

- **Khung:** cả 5 level có `frame_errors` rỗng. Đối chiếu tay cho thấy số dây, sức chứa, số quả từng dây và từng lượt refill, tập container và số mục `Remove` khớp default. Thứ tự container dự trữ có thay đổi ở một số level.
- **Số màu:** số quả mỗi màu bằng sức chứa × số container cùng màu.
- **Thắng:** cả 5 level có `solvable: true`, Level Designer `win: true` bằng **replay**, không lỗi hay cảnh báo. Tôi dựa trên kết quả này, không chạy lại.
- **Phạm vi:** không có Level 1, Challenge hay Endless nên không áp dụng yêu cầu `matches_default`. Không thấy khoá trong dữ liệu.

## Level 3: ĐẠT

- Điểm nhanh 6,60 so với `aim_fast` 7,42, nằm trong giới hạn. Không có Hidden.
- Điểm chậm tăng 0,43 dù mục tiêu giữ nguyên. Ngược lại, `player_win` tăng nhẹ (`bot_win` từ 0% lên 15%), nên các tín hiệu không cùng chiều.
- Dây 2 (container 0) đã có sẵn `0,0,0` ở đáy, tạo cảm giác mở màn khá gọn.
- **Đề xuất:** không bắt buộc sửa. Nên theo dõi khi playtest.

## Level 4: ĐẠT

- Điểm nhanh 8,20 so với `aim_fast` 9,79, nằm trong giới hạn. Không có Hidden.
- Điểm chậm giảm 0,37 nhưng `player_win` cũng giảm nhẹ.
- **Mở màn rất dễ:** dây 3 có một quả 6, còn dây 1 và dây 2 đều có `6,6` trên đỉnh. Đơn màu 6 hoàn tất được gần như ngay.
- **Đơn màu 5 chờ lâu:** container 5 đứng đầu hàng dự trữ, nhưng cả 5 quả màu 5 chỉ nằm ở hai mục refill cuối (container 8 và Free).
- **Đề xuất (tuỳ chọn):** nếu playtest thấy bị nghẽn, đổi một quả 5 ở refill cuối lên refill sớm hơn. Nếu mở màn quá dễ, tách một cặp 6. Sau khi sửa phải chạy lại kiểm tra.

## Level 6: ĐẠT

- Điểm nhanh 8,07 so với `aim_fast` 8,99. Điểm chậm giảm đúng hướng nhưng ít hơn mục tiêu (−0,21 so với −0,54). `player_win` gần như không đổi, còn `bot_win` giảm từ 7,5% xuống 0%.
- Hidden giữ tổng 8 quả, có đổi vị trí.
- Nước đầu `[1,2,5]` chuyển cả cụm ba quả 4 (gồm một quả Hidden) sang dây container 4 đang trống.
- Hidden ở dây 1 nằm ngay dưới hai quả cùng màu, nên có thể gần như không tạo thử thách. Dữ liệu không cho biết kit lộ Hidden trong cụm cùng màu thế nào.
- **Đề xuất (tuỳ chọn):** chuyển Hidden này sang vị trí nằm dưới quả khác màu, rồi đo lại.

## Level 7: CẦN SỬA

**Bằng chứng**

- Điểm chậm tăng từ 12,53 lên **17,09**, tức +4,56 trong khi mục tiêu chỉ +0,18.
- `player_win` giảm từ **79,2% xuống 21,6%**. Đây là rủi ro lớn về độ khó thật, dù level thắng được.
- `off_by` −2,24 vẫn đạt nhưng chỉ cách giới hạn 0,07.
- **Nguyên nhân khả dĩ:** container đang mở là 5, 7, 6, 1, 0. Default không có quả nào ngoài các màu này trên dây. Bản mới có **7/25 quả chưa có container** lúc mở màn:
  - màu 8: dây 1 và dây 2 (container 8 đứng cuối hàng dự trữ);
  - màu 4: dây 3 (Hidden), dây 4 và dây 6;
  - màu 3: dây 3;
  - màu 2: dây 4.
- Hidden vẫn là 12 quả như default, nên số lượng Hidden không giải thích được mức tăng. Vị trí Hidden có đổi và có thể góp phần.

**Phương án thử** (chỉ số đếm từ 0, từ đáy lên; chưa chạy kiểm tra)

| Hoán đổi | Dây sau sửa | Refill sau sửa |
|---|---|---|
| Dây 2[4] (màu 8) ↔ refill container 8 [1] (màu 1) | `6,6,6,7,1` | xem hàng thứ ba |
| Dây 1[3] (màu 8) ↔ refill Free [0] (màu 1) | `5,5,1,1,5` | `8,0H,8H,8,1` |
| Dây 6[1] (màu 4) ↔ refill container 8 [2] (màu 1) | `0,1,0,0` | container 8: `4H,8,4,0,3H` |

Ba hoán đổi này giữ số màu và vị trí Hidden, giảm số quả chưa có container từ 7 xuống 4. Đường đi cũ không còn dùng để chứng minh thắng được.

**Lưu ý xung đột giữa hai mô hình:** điểm chậm cho rằng bàn quá khó, còn điểm nhanh đang **thấp hơn** `aim_fast`. Nếu làm bàn dễ hơn khiến điểm nhanh giảm thêm quá 0,07 (với `aim_fast` không đổi), level sẽ trượt giới hạn 2,31. Vì vậy Codex nên sinh vài ứng viên, loại bản có |`off_by`| > 2,31, rồi chọn bản có `full_delta_from_default` gần +0,18 và đối chiếu `player_win`. Chạy lại cả Level Designer cho bản được chọn.

## Level 9: ĐẠT

- Điểm nhanh 10,59 so với `aim_fast` 11,74. Điểm chậm giảm 3,21, khá sát mục tiêu −3,60. `player_win` tăng nhẹ.
- Hidden giữ tổng 9 quả, có đổi vị trí.
- Nhiều cụm cùng màu có sẵn (màu 1 ở dây 3, màu 5 ở dây 4, màu 2 ở dây 1), phù hợp hướng giảm độ khó.
- **Rủi ro thiết kế:** container 4 (mục dự trữ thứ 2) và container 3 (thứ 4) vào sớm, nhưng toàn bộ quả màu 3 và 4 chỉ nằm ở hai mục refill cuối. Hai đơn này phải chờ lâu.
- **Đề xuất (tuỳ chọn):** nếu playtest thấy giữa màn bị nghẽn, đưa container 4 và 3 về cuối hàng hơn, rồi đo lại điểm và replay.
