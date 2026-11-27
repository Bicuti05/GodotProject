# Phản hồi Claude

## Lượt review-be667996795942ef832ff09c25c1a9d5

Level trong pack này dùng kết quả lượt này: 2.

# Duyệt level Sweet Rope (Codex)

| Level | Trạng thái | off_by | Luật khung | Level Designer |
|---|---|---|---|---|
| 2 | **ĐẠT** (cần theo dõi `bot_win`) | -0,41 | Không có lỗi | Thắng (replay) |

## Level 2: ĐẠT

### Bằng chứng
- **Điểm nhanh:** `score_fast` 12,94 so với `aim_fast` 13,35, lệch -0,41, nằm trong giới hạn |off_by| ≤ 2,31.
- **Luật khung:** `frame_errors` rỗng. Level Designer không báo lỗi hay cảnh báo.
- **Khả năng thắng:** `solvable: true`, `win: true` bằng replay đường đi 22 bước. Tôi dựa vào kết quả công cụ, không tự replay lại.
- **Bàn default:** `matches_default: false` được chấp nhận vì level này không bắt buộc giữ default.

### Điểm chậm

| Chỉ số | Default | Bản gửi | Thay đổi |
|---|---|---|---|
| `score` | 12,86 | 13,14 | **+0,29** (mục tiêu 0,00) |
| `bot_win` | 55% | 87,5% | **+32,5 điểm %** |
| `player_win` | 61,25% | 65% | +3,75 điểm % |

- `full_delta_from_default` cao hơn `target_delta_from_default` 0,29. Tôi không đặt ngưỡng cho mức lệch này.
- **Rủi ro chính:** `bot_win` tăng mạnh dù mục tiêu là giữ nguyên độ khó. Nếu `score` cao hơn nghĩa là khó hơn thì hai chỉ số đang ngược chiều nhau. Dữ liệu không cho biết quy ước này, cũng không có số ván hay seed, nên chưa kết luận được bản gửi dễ hay khó hơn.

### Cấu trúc
- Có 20 item gồm các loại 1, 4, 6, 7, 8, mỗi loại 4 item, khớp 5 container và `orderCount: 5`.
- So với default, 10/20 vị trí đổi loại item, trên dây 0, 3, 4 và 5. Dây 1 và 2 giữ nguyên.
- Loại dây, sức chứa, container, độ khó và `reserveQueue` (4 mục `Remove`) giống default.
- Dây 3 đổi từ `[8,7,6,4]` thành `[8,1,1,4]`, tạo một cặp `1,1` liền nhau mà default không có. Đây **có thể** là một lý do `bot_win` tăng, nhưng chưa được kiểm chứng.
- Dữ liệu không thể hiện Hidden hay khoá. Thứ tự refill không đổi so với default.

### Đề xuất
1. Không bắt buộc sửa theo các tiêu chí đã nêu.
2. Nên chạy lại điểm chậm cho cả hai bàn với cùng bộ seed và nhiều ván hơn để xem chênh lệch `bot_win` có ổn định không.
3. Nếu chênh lệch được xác nhận và cần sát default hơn, thử đổi `ropes[3].items[2]` (loại 1) với `ropes[4].items[3]` (loại 6):
   - Dây 3 thành `[8,1,6,4]`.
   - Dây 4 thành `[7,4,8,1]`.

   Cách đổi này bỏ cặp `1,1` và giữ nguyên số lượng từng loại. **Phương án chưa được thử**, nên phải kiểm lại luật khung, điểm nhanh, điểm chậm và tìm hoặc replay đường thắng mới.

## Lượt review-a7d52e5c988540df83fa1d77da2f9b71

Level trong pack này dùng kết quả lượt này: 5.

# Kết quả duyệt Sweet Rope: Level 3–6

| Level | Trạng thái | off_by (≤ 2,31) | Thắng (replay) | Δ chậm thực tế / mục tiêu | player_win default → mới |
|---|---|---|---|---|---|
| 3 | **CẦN KIỂM THÊM** (ưu tiên 1) | +1,52 đạt | Có | **+13,61 / 0,00** | 82,9% → **25,8%** |
| 4 | **CẦN KIỂM THÊM** | −1,62 đạt | Có | **+5,49 / 0,00** | 72,1% → 48,2% |
| 5 | **ĐẠT** | +1,98 đạt | Có | −0,41 / 0,00 | 75,9% → 69,7% |
| 6 | **CẦN KIỂM THÊM** | +0,61 đạt | Có | **+3,03 / −0,54** | 68,8% → 52,7% |

## Phần chung

- **Level Designer:** cả 4 level có `win: true` bằng replay, không có error hay warning.
- **Luật khung:** `frame_errors` đều trống. Đối chiếu tay cho thấy sức chứa, số vật phẩm mỗi dây, kích thước từng refill và container ban đầu khớp default. Container dự trữ cùng tập màu nhưng đổi thứ tự.
- **Số lượng màu:** ở cả level mới và default, số vật phẩm mỗi màu bằng số order màu đó × sức chứa.
- **Default:** phạm vi này không có Level 1, Challenge hay Endless, nên `matches_default: false` không phải lỗi.
- **Khoá:** dữ liệu không có trường khoá nào, nên chưa đủ bằng chứng để đánh giá.
- **Điểm chậm:** tôi không đặt ngưỡng. Trạng thái "cần kiểm thêm" phản ánh rủi ro cần người duyệt quyết định, không phải vi phạm luật.

**Chỉ số "dư địa" dùng bên dưới:** số order có đủ vật phẩm từ bàn đầu và k−1 refill đầu, trừ đi k. Dư địa 0 nghĩa là phải hoàn thành hết các order khả thi đó thì refill thứ k mới đến. Chỉ số này giả định refill thứ k đến sau order thứ k hoàn thành. Tôi suy ra giả định này từ cấu trúc, chưa xác nhận trong luật game.

## Level 3: CẦN KIỂM THÊM

**Bằng chứng**
- `score_fast` 8,94, `aim_fast` 7,42. Không có Hidden.
- Điểm chậm tăng từ 7,37 lên 20,98, trong khi mục tiêu là giữ nguyên. `bot_win` bằng 0 ở cả hai bản nên không giúp phân biệt.
- Container 1 thứ hai vào ở refill 2 (default: refill 5). Cả hai bản đều phải chờ refill 6 mới đủ 8 vật phẩm màu 1 cho hai order, nên bản mới giữ dây lâu hơn.
- Container 1 ban đầu chỉ đủ vật phẩm sau refill 3 (default: sau refill 1).
- Dư địa từ k=1 đến 6: mới là **1, 1, 0, 0, 2, 2**; default là 2, 3, 2, 2, 2, 2.

**Rủi ro:** level có thể khó hơn nhiều so với đường cong. Cấu trúc refill là một nguyên nhân khả dĩ, chưa được chứng minh.

**Đề xuất thử:** đổi chỗ một cặp vật phẩm:
- Refill 2 (container 1): `7,0,3,0` → `7,6,3,0`
- Refill 4 (container 5): `6,8,8,5` → `0,8,8,5`

Theo phép đếm, dư địa thành 1, 1, 1, 1, 2, 2 và số lượng màu không đổi.

## Level 4: CẦN KIỂM THÊM

**Bằng chứng**
- `score_fast` 8,17, `aim_fast` 9,79. Không có Hidden.
- Điểm chậm tăng từ 8,95 lên 14,43; `bot_win` giảm từ 5% xuống 0%.
- Điểm nhanh thấp hơn đích, còn điểm chậm cao hơn default. Nếu hai thang cùng chiều "cao là khó", hai tín hiệu này đang ngược nhau.
- Container 1 thứ hai vào ngay refill 1 (default: refill 3) và phải chờ refill 6 mới đủ vật phẩm cho cả hai order màu 1.
- Container 4 có sẵn 4/5 vật phẩm đúng màu trên dây của nó. Refill của container 0 mang theo 4/5 vật phẩm màu 0. Đây là hai điểm trông rất dễ.
- Dư địa **không giải thích** được độ lệch: mới là 1, 1, 0, 1, 1, 0, còn default chặt hơn (0, 1, 0, 0, 0, 0) mà điểm chậm lại thấp hơn.

**Đề xuất thử:** đổi màu container ở slot 1 và slot 3, giữ nguyên refill theo slot. Thứ tự `1,8,5,3,0` thành `5,8,1,3,0`. Đánh đổi là container 5 sẽ vào sớm và phải chờ đến refill 6, nên chưa chắc điểm giảm.

## Level 5: ĐẠT

**Bằng chứng**
- `score_fast` 10,77, `aim_fast` 8,79. Không có Hidden.
- Điểm chậm 12,01 so với default 12,42, gần mục tiêu thay đổi nhất trong bốn level.

**Rủi ro cần theo dõi**
- off_by chỉ còn cách giới hạn 0,33.
- Điểm chậm giảm nhẹ nhưng `player_win` giảm khoảng 6,2 điểm phần trăm và `bot_win` giảm 2,5 điểm. Các chỉ số không hoàn toàn cùng hướng.
- Container 3 vào ở refill 1 (default: refill 3). Cả hai bản đều phải chờ refill 7 mới đủ màu 3, nên bản mới giữ dây lâu hơn.

**Đề xuất:** chưa cần sửa. Nếu playtest thấy bị kẹt, thử lùi container 3 về slot muộn hơn rồi đo lại.

## Level 6: CẦN KIỂM THÊM

**Bằng chứng**
- `score_fast` 9,60, `aim_fast` 8,99.
- Mục tiêu là dễ hơn default (8,5 → 7,96, Δ −0,54), nhưng điểm chậm tăng từ 11,29 lên 14,32. Hai thay đổi **ngược chiều**; `bot_win` giảm từ 7,5% xuống 0%.
- Số Hidden vẫn là 8, nhưng **2 vị trí đã đổi** (chỉ số đếm từ 0):

| Nơi | Default | Level mới |
|---|---|---|
| Dây Free ban đầu | chỉ số 3 | chỉ số 1 |
| Refill 2 | chỉ số 0 | chỉ số 1 |

- Công cụ không báo lỗi khung. Dữ liệu không cho biết vị trí Hidden có bắt buộc cố định hay không, cần xác nhận.
- Dư địa: mới là 2, 2, 1, **0**, 0, 1; default là 2, 2, 1, 1, 0, 1.

**Đề xuất thử**, đo riêng từng phương án để biết tác động:
1. **Refill:** refill 3 `8H,5,0,2,8` → `8H,5,5,2,8`; refill 5 `5,0,7,2H,6` → `0,0,7,2H,6`. Dư địa thành 2, 2, 1, 1, 1, 1.
2. **Hidden:** trả cờ về vị trí default. Dây Free `1,4,3,3,0` đặt Hidden ở số 3 tại chỉ số 3; refill 2 `0,2,6,5` đặt Hidden ở số 0 tại chỉ số 0.

## Giới hạn và bước tiếp theo

- Tôi chỉ duyệt trên dữ liệu được gửi, **chưa tự chạy lại** Level Designer, replay hay mô hình điểm.
- Dữ liệu không giải thích ý nghĩa bộ ba trong `path` và hướng lấy vật phẩm trên dây, nên tôi chưa đánh giá độ khó theo thứ tự vật phẩm trong từng refill hay độ che của Hidden.
- Mọi phương án đề xuất **chưa được kiểm chứng**. Sau khi sửa cần chạy lại luật khung, tìm đường đi mới và replay, rồi đo cả `off_by` lẫn điểm chậm.
- Nếu solver không tìm được lời giải cho bản sửa, điều đó chưa chứng minh level vô nghiệm.

## Lượt review-92779132fb6347d28a1582c4181b59f9

Level trong pack này dùng kết quả lượt này: 8, 10.

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

## Lượt review-b64e12cc90404be5a2b682558dd85850

Level trong pack này dùng kết quả lượt này: 20.

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

## Lượt review-e8c30ce4b86049baab1594d6351ea30b

Level trong pack này dùng kết quả lượt này: 15, 17, 19, 22, 25.

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

## Lượt review-76df399f0fba4804891b9ad7bd04727d

Level trong pack này dùng kết quả lượt này: 3, 4, 6, 9.

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

## Lượt review-ebc3ef6e30714db18c9a1c4eb8a35d28

Level trong pack này dùng kết quả lượt này: 7, 11, 12, 13, 14, 16, 18, 21, 23, 24.

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
