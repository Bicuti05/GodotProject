# Duyệt level Sweet Rope: level 2

Người duyệt: Claude, 2026-11-26. Tôi không chỉ đọc số trong hồ sơ mà **chạy lại từng kiểm tra** bằng bộ kit, luật C# của game và Level Designer.

## Level 2: ĐẠT

| Kiểm tra | Hồ sơ ghi | Tôi chạy lại | Kết luận |
|---|---|---|---|
| Bàn default trong hồ sơ đúng bàn của game | (không ghi) | Trùng khớp hoàn toàn | ✅ |
| Luật khung | không lỗi | Không lỗi. Đổi 50% vị trí quả (cần ≥ 25%) | ✅ |
| Lệch điểm nhanh | `off_by` −0,41 | Đích nhanh 13,35, điểm nhanh 12,94, lệch **−0,41** (giới hạn ±2,31) | ✅ |
| Thắng bằng Level Designer | replay thắng | `core.js` replay 22 nước: **thắng**, không lỗi, không cảnh báo | ✅ |
| Thắng bằng luật C# của game | (không có) | Validator không lỗi, `BoardSolver.Replay` chạy lại lời giải: **thắng** | ✅ |
| Bộ giải Python tự tìm | (không có) | Tìm được lời giải 22 nước | ✅ |
| Trùng bàn Sort Streak | (không có) | **Không trùng** với 6.567 bàn gốc nào (đã bỏ qua tên màu và thứ tự Rope) | ✅ |
| `must_keep_default` | false | Level 2 không phải level 1, Challenge hay Endless | ✅ |

### Điểm chậm (full) và rủi ro

- Hồ sơ ghi `full_estimate` 13,14. Tôi chạy lại 3 seed:
  - **bàn mới:** 13,1 / 12,9 / 11,0, trung bình **12,3**;
  - **bàn default:** 12,9 / 12,3 / 13,2, trung bình **12,8**.
- Đường C ở level 2 có đích **4,9, bằng đúng điểm thật của default** (4,9), tức muốn độ khó y như default. Bàn mới chấm ngang bàn default (12,3 so với 12,8, chênh 0,5), nên **phù hợp**.
- Con số 12–13 nằm ở thang Điểm SR, không so thẳng với 4,9 được: với bàn dễ, bộ chấm vốn chấm cao hơn thật khoảng 5–8 điểm. **Không phải dấu hiệu sai.**
- Rủi ro còn lại: điểm SR lệch giữa các seed tới 2 điểm (11,0 đến 13,1), và chưa có người chơi thật thử.

### Cấu trúc bàn

- **Bàn:** 6 Rope sức chứa 4, 1 Free Rope, 5 Order, không Hidden, không khoá, ReserveQueue toàn `Remove`. Khung giữ đúng như default.
- **Lúc mở:**
  - Rope có Container màu 4 đã có quả 4 ở đỉnh; Rope có Container màu 7 có quả 7 ở đáy. Người chơi có nước ghép ngay, hợp với level dễ.
  - Cặp quả 1 nằm giữa Rope Container màu 4 (`8, 1, 1, 4`), phải dời quả 4 đi mới lấy được. Đây là thử thách nhỏ, vừa với level 2 là level mở **Undo**.
- **Bot:** bot đơn giản thắng 87,5%, người chơi máy thắng 65%. Độ khó thấp, hợp vị trí level 2.

### Đề xuất

Không cần sửa. Nếu muốn level 2 có lý do rõ hơn để thử Undo, có thể đặt một nước "bẫy" (ghép sai dễ thấy) ở Free Rope. Đây chỉ là gợi ý thiết kế, không phải lỗi.

## Thiếu bằng chứng

- Chưa có dữ liệu người chơi thật.
- Hồ sơ có `evidence.json` và `core_input.json`, tôi không dùng tới, vì mọi số liệu đã tự chạy lại từ `request.md` và bàn default của game.
