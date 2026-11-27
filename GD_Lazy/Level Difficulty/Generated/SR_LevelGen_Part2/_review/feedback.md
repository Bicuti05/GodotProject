# Duyệt 74 level Codex (SweetRope_74_Level.zip)

Người duyệt: Claude, 2026-11-27. Mọi số liệu dưới đây đều chạy lại bằng **kit gốc**, không đọc lại số trong báo cáo của Codex.

## Kết luận

**Cả 74 level đều chơi được và đúng luật.** Về độ khó:
- **44/74** đạt theo điểm nhanh.
- Theo điểm chậm (full), chỉ **20/74** nằm trong ±2,31 quanh đích.
- Bàn mới **khó hơn đích trung bình +4,7 điểm**, giống lỗi ở 106 level của tôi.

## Kiểm tra

| Mục | Kết quả |
|---|---|
| Codex sửa kit (bộ kiểm, bộ chấm, `default_levels`, `start_levels`, `targets.csv`) | **Không**, md5 khớp bản gốc |
| Zip khớp thư mục làm việc | Khớp |
| Level ngoài danh sách 74 bị đổi | 0 |
| Level trong danh sách bị bỏ quên | 0 |
| Lỗi khung | 0 |
| Bộ giải của tôi tự tìm lời giải | 74/74 |
| Lời giải Codex chạy lại bằng luật C# của game (`BoardSolver.Replay`) | **74/74 thắng** |
| Lời giải chạy lại bằng Level Designer (`core.js`) | **74/74 thắng** |
| Trùng bàn Sort Streak (6.567 game) | 0 |
| `report.csv` khớp số tôi chạy lại | Khớp 100% |
| Level Bonus (113, 123…193) còn màu chỉ có 1 chậu | 9/9 còn |
| Level 20 | Đã có bàn giải được (63 nước), lệch −0,9. **Tốt hơn bản của tôi** (tôi phải giữ default) |

## Độ khó

Cách tính điểm chậm: chạy `full` 2 seed (11, 12). Đích quy theo bàn default: `full(default) + curve_c − real_default`.

| Thang | Sai TB | Lệch TB | Trong ±2,31 | Trong ±5 |
|---|---|---|---|---|
| Nhanh (kit) | 4,36 | +2,27 | 44 | – |
| Chậm (full) | 6,63 | **+4,74** | 20 | 41 |

**Lệch hơn 5 điểm (33 level).** Khó hơn đích nhiều nhất:

| Level | 143 | 172 | 113 | 152 | 114 | 133 | 119 | 142 |
|---|---|---|---|---|---|---|---|---|
| Lệch | +26,6 | +22,3 | +18,1 | +17,3 | +17,0 | +16,7 | +16,6 | +16,1 |

Hầu hết là các level mà đích muốn dễ hơn default rất nhiều. Ở đó khung giữ nguyên số Rope, số Order, số màu nên không hạ được (Codex đã ghi đúng trong NOTES).

**Dễ hơn đích:**

| Level | Loại | Lệch | Ghi chú |
|---|---|---|---|
| **125** | Hard | −19,1 | Chấm full còn thấp hơn chính Normal 122, 124 |
| 144 | Normal | −12,4 | |
| 139 | Normal | −12,1 | |
| 195 | Hard | −7,6 | |

**Normal khó hơn Hard cùng nhóm (theo full):**
- 112 và 113 khó hơn Hard 115.
- 122 và 124 khó hơn Hard 125.
- 141, 142, 143 khó hơn Hard 145.

## So với giữ bàn default (ước lượng)

- 48/74 bàn mới gần đích hơn bàn default.
- **15 level xa đích hơn default quá 2 điểm:** 111, 125, 134, 138, 139, 141, 146, 149, 156, 163, 173, 174, 191, 194, 199. Với các level này, giữ bàn default sẽ tốt hơn.

## Đề xuất

1. Nhận cả 74 level vì đều đúng luật và giải được. **Riêng 15 level ở trên thì trả về bàn default.**
2. Sửa nhóm Normal khó hơn Hard: 115, 125, 145.
3. Lệch đích lớn ở level "cần dễ hơn default nhiều" là **giới hạn của khung**, không phải lỗi của Codex. Muốn chạm đích phải nới khung, ví dụ cho giảm số màu hoặc số Order, hoặc đổi đường cong.

## Chưa kiểm

- Chưa có người chơi thật thử.
- Điểm full lệch giữa các seed khoảng ±2.
- Phép so với default dùng điểm thật của default (`summaryScore`) nhưng thang full cho bàn mới, nên chỉ là ước lượng.
