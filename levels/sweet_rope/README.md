# Sweet Rope · 200 màn

Mỗi file `level_###.json` là một object đọc được bằng `JuiceLevel.from_dict()`. Có đúng một bố cục cố định cho mỗi ID từ 1 đến 200, chia thành tám chapter. Màn chia hết cho 5 được ghi `Hard` trong `note` để đội tích hợp dùng cho metadata hiển thị. Bộ level nằm riêng trong thư mục này và chưa được nối vào luồng chọn màn.

## Sinh và kiểm

Bộ sinh tạo chậu, sức chứa và kho quả cân bằng từ seed, xáo các đoạn mở màn rồi đổi quả giữa bàn và hàng chờ. Dữ liệu Sort Streak đi vào phép đối chiếu sau khi sinh. Một ứng viên có thể được dùng cho ID khác phù hợp hơn với độ khó đo được và lịch cơ chế. Seed trong CSV là seed sinh bố cục.

[report.csv](report.csv) ghi điểm mục tiêu, điểm ước lượng, độ lệch, kết quả solver, tỷ lệ thắng ngẫu nhiên, branching, expanded, cơ chế, seed và màn tham chiếu gần nhất. Điểm dùng công thức trong brief và chặn ở 0. Dung sai mục tiêu là ±3 điểm với Normal và ±5 điểm với Hard. Chỉ số này là ước lượng theo solver và chưa được hiệu chỉnh bằng dữ liệu người chơi.

Tương đồng là trọng số chung giữa hai bố cục chia cho tổng trọng số của bố cục lớn hơn. Phép đo xét cấu trúc từng dây, quy luật lặp loại quả, cặp quả liền nhau, vị trí quả, chậu trắng/chậu màu, khóa và sức chứa. Tên loại quả được chuẩn hóa quanh chậu của từng dây. Thứ tự dây được bỏ qua trong từng nhóm bàn mở màn và hàng chờ để vẫn phát hiện việc đổi vị trí đơn thuần. Chỗ trống `x|` được bỏ khỏi phép đo. Nguồn đối chiếu gồm hai bộ chapter 1–5, fallback, Sunlight và Special Challenge. Các bố cục trùng chữ ký được gộp khi đếm tập tham chiếu.

## Kết quả theo chapter

| Chapter | Số màn giải được | Trong dung sai | Sai lệch tuyệt đối TB | Tương đồng cao nhất với bộ gốc |
|---:|---:|---:|---:|---:|
| 1 | 25/25 | 25/25 | 0.21 | 46.00% |
| 2 | 25/25 | 25/25 | 0.27 | 48.61% |
| 3 | 25/25 | 25/25 | 0.26 | 38.25% |
| 4 | 25/25 | 25/25 | 0.17 | 34.33% |
| 5 | 25/25 | 25/25 | 0.32 | 29.20% |
| 6 | 25/25 | 25/25 | 0.30 | 33.33% |
| 7 | 25/25 | 25/25 | 0.33 | 52.00% |
| 8 | 25/25 | 25/25 | 0.18 | 30.68% |

Đối chiếu 1.004 bố cục tham chiếu sau khi gộp chữ ký trùng. Mức tương đồng cao nhất giữa hai màn Sweet Rope là 69,49%. Màn 111 thắng 2/30 lượt chơi ngẫu nhiên dù đạt điểm mục tiêu theo solver.

## Kiểm lại

    python3 levels/sweet_rope/tools/verify.py --godot /path/to/Godot_4.6.1 --jobs 4

Lệnh dùng bản sao tạm của các script engine trong repo để chạy `validate()`, solver với `node_cap=4000`, `state_cap=20000`, 30 lượt chơi ngẫu nhiên và kiểm tương đồng. Lời giải tại các màn ra mắt được chạy lại bằng luật thật để kiểm việc hiện quả ẩn, mở khóa và tan băng.

Sinh một JSON ứng viên độc lập để thử tiếp, ví dụ 20 ứng viên cho mỗi màn 26–50.

    python3 levels/sweet_rope/tools/generate.py 26 50 /tmp/sweet_rope_candidates.json
