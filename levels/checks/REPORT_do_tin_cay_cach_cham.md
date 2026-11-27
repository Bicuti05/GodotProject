# Độ tin cậy của cách chấm độ khó (27/11/2026)

Cách chấm bàn giao: `levels/sweet_rope_B/tools/score.py`, cột **`diem_lw`**: tỉ lệ thắng trung bình của 4 bot greedy có nhiễu (`greedy_ext.gd`, 4 cấu hình × 2 seed × 30 ván), quy đổi sang thang `summaryScore` bằng bảng hồi quy đơn điệu hiệu chỉnh trên 632 level Sort Streak. Khoảng 9 giây/level trên 1 core.

## Kiểm chứng trên level chưa dùng để hiệu chỉnh

240 bàn Sort Streak lấy ngẫu nhiên từ màn 126–5100 (5 bộ), chia đều theo dải điểm 0–100, không trùng 392 level đã dùng để hiệu chỉnh ban đầu.

| Vùng điểm | Cách chấm | Sai số TB tuyệt đối | Lệch TB | Trong ±10 | Trong ±5 |
|---|---|---|---|---|---|
| 0–70 (vùng của Sweet Rope) | `diem_lw` | 8.8 | +1.8 | 67% | 36% |
| 0–70 | công thức 5 chỉ số (`diem_5f`) | 9.2 | +1.3 | 60% | 36% |
| 0–100 | `diem_lw` | 10.9 | -3.4 | 55% | 28% |

- Tương quan thứ hạng giữa `diem_lw` và điểm thật: 0.906.
- Trên 70 điểm bị chấm thấp khoảng 18 (bot gần như không thắng nên không phân biệt được các màn rất khó).
- Hoa ẩn và dây khóa không làm lệch có hệ thống (tương quan phần dư với số hoa ẩn -0.051, với số dây khóa 0.072), dù bot nhìn thấy loại thật của hoa ẩn.
- 42 bàn nhỏ của Sort Streak (dưới 8 màu hoặc dưới 10 cốc): sai số 8.7, lệch -4.9.
- Chạy lại cùng seed cho cùng kết quả. `score.py` tái tạo đúng điểm của bên kiểm (chênh tối đa 0,02).

## Kết luận

- Đủ tin cậy để **AI sinh level tự chấm và xếp hạng ứng viên**, nhưng sai số mỗi level còn khoảng ±9: chỉ coi "đạt" khi lệch không quá ~5 và kiểm lại định kỳ.
- Bên kiểm vẫn nên chấm lại mẫu ngẫu nhiên (khoảng 10% mỗi lô) để phát hiện sai lệch.
- **Bộ A (bàn rất nhỏ: 5–9 cốc, 3–7 màu, sức chứa 3–4) nằm ngoài vùng đã kiểm chứng.** Với bộ A, `diem_lw` cho lệch trung bình +18.4 (sai số 21.6), công thức 5 chỉ số cho +4.3 (sai số 13.7). Hai cách chưa thống nhất; cần chơi thử vài màn bộ A để chốt.
