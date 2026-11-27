# Duyệt level Sweet Rope: Level 2

## Level 2: CẦN KIỂM THÊM

**Bằng chứng**

| Hạng mục | Kết quả | Nhận xét |
|---|---|---|
| Luật khung | `frame_errors` rỗng, `notes` rỗng | Không có lỗi. |
| Level Designer | `win: true`, method `replay`, không có error/warning | Thắng được bằng đường đi thật (22 bước), không phải solver, nên bằng chứng chắc. |
| Sai lệch điểm nhanh | `off_by` = -0,41 (aim 13,35, score 12,94) | \|-0,41\| ≤ 2,31 nên đạt. |
| Bàn default | `must_keep_default: false`, `matches_default: false` | Level 2 không bắt buộc giữ default nên việc khác default không phải lỗi. |
| `full_estimate` | score 13,14; bot_win 0,875; player_win 0,65 | Lệch xa `target_curve` và `real_default` (cùng 4,9). |

**Cấu trúc (đã đối chiếu thủ công)**
- 5 đơn (`orderCount` 5), 5 container loại 6, 1, 4, 7, 8, và mỗi loại item có đúng 4 cái (tổng 20 = 5×4). Số lượng khớp.
- Tất cả rope có capacity 4. Không có Hidden, không có khoá. `reserveQueue` gồm 4 mục `Remove`, nên không có thứ tự refill phức tạp.
- So với default, level này đổi thứ tự item của Free rope (1,8,6,7 thay vì 7,1,6,4) và nội dung các rope ở chỉ số 3, 4, 5. Rope 1 (container 6, rỗng) và rope 2 giữ nguyên.

**Rủi ro**
- Điểm full ước tính là 13,14, còn target và real_default là 4,9. Nếu `full_estimate` đo cùng thang với target thì level này khó hơn nhiều so với đường cong dự kiến cho level 2 (difficulty 1, Normal). Tôi không đặt ngưỡng cho full, nhưng khoảng cách này đủ lớn để cần xác nhận.
- `player_win` chỉ 0,65 ở một level mở đầu. Bản thân `score_fast` (12,94) cũng cách xa 4,9, nên có thể chênh lệch là do khác thang đo hoặc do thiết kế level. Dữ liệu hiện tại không cho phép phân biệt hai khả năng này.
- Chưa có bằng chứng nào cho biết `full_estimate` của chính bàn default là bao nhiêu, nên chưa biết công cụ ước tính lệch hệ thống hay level thật sự khó hơn.

**Đề xuất sửa / kiểm thêm**
1. Cho Codex chạy `full_estimate` trên bàn default của level 2 để hiệu chỉnh. Nếu default cũng ra khoảng 13, vấn đề nằm ở công cụ ước tính và level này ổn. Nếu default ra gần 4,9, thì phần đổi bàn làm level khó lên rõ rệt.
2. Trong trường hợp thứ hai, thử bỏ dần các thay đổi để tìm nguyên nhân. Bắt đầu bằng việc trả Free rope về default (7,1,6,4), vì đây là rope người chơi dùng ngay từ đầu và ảnh hưởng lớn nhất đến độ khó đầu game. Sau đó trả lần lượt các rope 3, 4, 5, đo lại điểm sau mỗi lần đổi.
3. Nếu giữ bàn mới, cần Codex giải thích lý do thiết kế cho việc lệch khỏi default, và cho thấy điểm full sau chỉnh gần target hơn.

**Kết luận:** chưa thể kết luận ĐẠT. Luật khung, khả năng thắng và `off_by` đều ổn, nhưng độ lệch giữa `full_estimate` (13,14) và target/real_default (4,9) chưa được giải thích.
