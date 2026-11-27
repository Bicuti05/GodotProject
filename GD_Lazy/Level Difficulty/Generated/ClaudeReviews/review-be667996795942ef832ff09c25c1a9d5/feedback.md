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
