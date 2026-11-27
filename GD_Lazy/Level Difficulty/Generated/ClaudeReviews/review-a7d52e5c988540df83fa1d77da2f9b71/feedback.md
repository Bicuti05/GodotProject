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
