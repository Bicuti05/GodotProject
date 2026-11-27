# Chỉ số độ khó dựa trên solver và bot (engine Sort Streak / Sweet Rope) so với summaryScore

Phạm vi: 392 level Sort Streak chapter 1-5 (unique theo `levelUniqueId`, có `summaryScore`). Mọi số liệu do tôi tự tính bằng engine Godot 4.6.1 headless; "nguồn" là file/dữ liệu cục bộ, không có nguồn web. Thư mục làm việc: `/tmp/claude-0/-home-user-GodotProject/789c606f-fe6b-525e-85bc-e2eb0b400faa/scratchpad/research_work/solver/` (features.csv, final_table.csv, out_*.json, ge_*.json, var_*.json, build.py, models.py, final.py, mkvariants.py, mkge.py).

## Câu hỏi 1: Chỉ số engine nào bám summaryScore nhất, bao nhiêu (rho, R2, MAE)?

### Takeaway
Bot "greedy có nhiễu" (chọn nước đi tốt nhất theo `JuiceSolver.move_score`, với xác suất eps đi ngẫu nhiên, hoặc softmax) cho Spearman |rho| khoảng 0,77-0,81 mỗi chỉ số riêng lẻ, và trung bình 4 cấu hình đạt rho = -0,839 (CI95 -0,871..-0,793); random-play thuần chỉ đạt -0,51 và solver DFS `expanded` chỉ 0,34. Một mình trung bình greedy win-rate cho R2 cv = 0,66 / MAE 9,45 điểm; gộp thêm vài chỉ số khác tới R2 ≈ 0,70-0,75, MAE 8-8,8 (baseline đoán trung vị: MAE 16,9; công thức cũ trong README: R2 0,28-0,33, MAE 13,4-14,4).

### Cited Findings
(Nguồn: `features.csv`, `greedy_feat.csv`, `final.py`, `models.py` trong thư mục làm việc. n = 392, Spearman với `summaryScore`; CI95 = bootstrap 300 lần.)

| Chỉ số (cách tính) | rho | CI95 | ổn định giữa seed (rho 2 seed độc lập) | chi phí/level |
|---|---|---|---|---|
| lw = TB win-rate của 4 bot greedy-noisy (e30,e45,e60,sm4; 2 seed x 30 ván mỗi cấu hình) | -0,839 | -0,871..-0,793 | (xem từng cấu hình) | ~9,3 s |
| ge_e45_win: eps-greedy eps=0,45 | -0,809 | -0,850..-0,769 | 0,864 | ~2,3 s |
| ge_sm4_win: softmax(move_score/4) | -0,805 | -0,841..-0,764 | 0,905 | ~2,3 s |
| ge_e60_win (eps 0,6) | -0,799 | | 0,836 | |
| ge_e30_win (eps 0,3) | -0,771 | | 0,884 | |
| g35_win: eps 0,35 (30 ván, 1 seed) | -0,750 | -0,804..-0,700 | | ~0,6 s |
| g15_win: eps 0,15 | -0,681 | -0,739..-0,613 | | |
| g0_win: greedy tất định (1 ván) | -0,335 | | | rất rẻ |
| rand_win: random-play 3 seed x 40 ván (cap 300 nước) | -0,506 | -0,577..-0,435 | 0,71-0,74 | ~3,5 s |
| rand_done: tỉ lệ cốc hoàn thành TB khi random | -0,484 | -0,558..-0,408 | | |
| win-rate cũ (30 ván, seed 12345) | -0,457 | -0,525..-0,376 | | |
| beam_logw: log độ rộng beam tối thiểu thắng (W in 1,3,8,20,50,120) | 0,436 | 0,355..0,521 | tất định | ~0,9 s |
| opt_len: độ dài lời giải beam (xấp xỉ tối ưu) | 0,397 | 0,303..0,476 | tất định | |
| beam_dead: tỉ lệ nước dẫn tới trạng thái doomed/hết nước ngay (trong beam) | 0,354 | 0,253..0,442 | | |
| log(1+expanded) của DFS solver (node_cap 4000) | 0,341 | 0,240..0,419 | tất định, nhưng phụ thuộc thứ tự sinh nước | ~1,5 s |
| p_nonmono (tỉ lệ nước dùng đoạn cắt không đơn sắc trên đường beam) | 0,249 | 0,168..0,333 | | |
| cap (capacity) | 0,337 | 0,252..0,421 | | 0 |
| hidden0 (số hoa ẩn ban đầu) | 0,168 | 0,069..0,261 | | 0 |
| h_depth (độ sâu TB hoa ẩn tính từ đuôi) | 0,165 | | | 0 |
| p_hburden, p_reveal_n (chi phí thông tin hoa ẩn trên đường giải) | 0,161 / 0,165 | | | |
| p_lock_steps, locks0 | -0,144 / -0,150 | | | |
| total (số cốc), dfs_path, p_rank, rand_stuck | |rho| < 0,08 | | |

Mô hình (cv 5-fold lặp 10 lần với LinearRegression; cột "slot-out" = GroupKFold theo slot (chapter, levelIndex) từ `models.py`):

| Tập đặc trưng | k | R2 cv | MAE |
|---|---|---|---|
| Công thức cũ (old_win, old_branch, log expanded), ridge / GBR | 3 | 0,28 / 0,33 | 14,4 / 13,4 |
| rand_win (ridge / GBR) | 1 | 0,11 / 0,21 | 16,1 / 15,2 |
| Chỉ cấu trúc tĩnh (cap, ncols, total, hidden0, locks0, h_depth) | 6 | 0,17 / 0,19 | 15,6 / 15,2 |
| g35_win (ridge) | 1 | 0,547 | 11,0 |
| lw (TB 4 bot greedy-noisy, tuyến tính) | 1 | 0,660 | 9,45 |
| lw + beam_logw | 2 | 0,675 | 9,22 |
| lw + ld + rand_win + beam_logw + opt_len (công thức đề xuất) | 5 | 0,698 | 8,76 |
| + log_dfs, p_nonmono, cap | 8 | 0,696 | 8,81 |
| Tất cả 4 cấu hình greedy_ext (ridge / GBR) | 8 | 0,670 / 0,691 | 9,39 / 8,98 |
| greedy_ext + 30 chỉ số khác (ridge / GBR) | 38 | 0,741 / 0,750 | 8,16 / 7,99 |
| solver + static (5 đặc trưng + 6 tĩnh) | 11 | 0,702 | 8,77 |
| Baseline (luôn đoán trung vị) | 0 | 0 | 16,9 |

GroupKFold theo slot cho kết quả gần giống KFold thường (chênh < 0,01 R2) nên không có rò rỉ do level cùng slot.

### Inferences
- Điều quyết định không phải "solver mạnh cỡ nào" mà là "một người chơi có heuristic nhưng sai sót thắng được bao nhiêu". Random thuần quá mù (win-rate hầu hết bằng 0 ở màn khó), solver/beam quá mạnh (hầu hết màn đều giải được bằng beam rộng 1-8) nên đều ít phân biệt; bot greedy-noisy nằm đúng vùng giữa nên phân giải tốt khắp thang (không có sàn: không level nào có lw = 0).
- Bảng hiệu chuẩn lw -> score: lw (0,001-0,05] TB 69,5; (0,05-0,15] 58,3; (0,15-0,3] 44,2; (0,3-0,5] 30,6; (0,5-0,7] 20,0; (0,7-1] 10,2 (độ lệch chuẩn trong mỗi ô 7-16 điểm).

### Gaps
- Chưa thử nhiều chính sách khác (MCTS, bot có "bộ nhớ", chính sách học được); chưa thử tối ưu eps/T theo score (4 cấu hình chỉ dò sơ bộ, rho 0,77-0,81 khá phẳng).
- Không tìm được công thức gốc của summaryScore trong repo.

## Câu hỏi 2: Chỉ số nào rẻ và đủ ổn định để chạy trên hàng trăm level sinh ra?

### Takeaway
Bot greedy-noisy (softmax T=4 hoặc eps 0,45) vừa ổn định nhất vừa tương quan nhất; beam và DFS rẻ, tất định nhưng chỉ bổ trợ. Random win-rate với 40 ván/seed khá nhiễu (rho giữa seed 0,71-0,74).

### Cited Findings
Thời gian GDScript, 1 core, trung bình/level (392 level; `t_*` trong out_*.json, `t_ge` trong ge_*.json):
- random 3 x 40 ván: 3,5 s; greedy (1 + 30 + 30 ván): 1,9 s; DFS node_cap 4000: 1,5 s; beam (tối đa 6 độ rộng, dừng sau 2 lần thắng): 0,9 s; tổng `solver_metrics.gd` ~7,9 s/level (max 25 s). `greedy_ext.gd` (4 cấu hình x 2 seed x 30 ván): ~9,3 s/level. Toàn bộ 392 level trên 4 tiến trình song song: ~14 phút cho solver_metrics và ~11 phút cho greedy_ext.
- Độ ổn định (Spearman giữa hai seed độc lập, n = 392): greedy softmax T=4: 0,905; eps 0,3: 0,884; eps 0,45: 0,864; eps 0,6: 0,836; random-play: 0,709-0,741 (3 seed x 40 ván). Mỗi seed riêng lẻ của greedy tương quan -0,75..-0,79 với score; trung bình 4 cấu hình lên -0,839.
- Beam và DFS tất định; DFS `expanded` phụ thuộc thứ tự sinh nước nên là chỉ số "nhiễu cấu trúc".

### Inferences
- Để đo level mới (Sweet Rope): chạy `greedy_ext.gd` (~9 s/level) là tối thiểu; thêm `solver_metrics.gd` ở chế độ mặc định (~8 s) để có beam_logw, opt_len, rand_win. Cho 200 level x 20 ứng viên (4000 level) cần ~16 giờ-core, ~4 giờ trên 4 core; nên lọc thô bằng 1 cấu hình (eps 0,45, 30 ván, ~1 s) rồi mới tính đầy đủ.
- Giảm nhiễu: tăng ván/seed hoặc trung bình nhiều cấu hình (rho giữa 2 seed 0,84-0,90 là mức nhiễu hiện tại).

### Gaps
- Chưa đo độ nhiễu của beam do chọn heuristic (done*12 - sort_lower_bound) khác nhau.

## Câu hỏi 3: Công thức tốt nhất trên thang summaryScore và sai số thật

### Takeaway
Công thức 5 đặc trưng cho R2 cv 0,70, MAE 8,8 điểm; sai số tuyệt đối trung vị 7,4, 80% level lệch dưới ~14, 90% dưới ~17,8. Dùng để xếp hạng/so sánh tương đối và lọc ngoại lai, không dùng như điểm chính xác. Có bias hồi quy về trung bình ở hai đầu (màn rất khó bị đánh giá thấp ~14 điểm).

### Cited Findings
Công thức (hồi quy tuyến tính trên 392 level, `final.py`):
```
score_hat = 32.83 - 53.67*lw - 24.49*ld + 32.32*rand_win + 4.13*ln(beam_w) + 0.602*opt_len
lw = TB win-rate 4 bot greedy-noisy (ge_e30, ge_e45, ge_e60, ge_sm4), ld = TB tỉ lệ cốc hoàn thành cùng 4 bot
rand_win = TB win-rate random 3 seed x 40 ván; beam_w = độ rộng beam nhỏ nhất thắng (999 -> cắt 200); opt_len = độ dài đường thắng của beam
```
Hệ số rand_win dương là do cộng tuyến với lw (đã được lw hấp thụ), nên không diễn giải riêng lẻ. Công thức đơn giản hơn: score_hat ~ lw-only (R2 0,66, MAE 9,45); hiệu chuẩn bảng ở Câu 1.

Sai số cv (KFold, trung bình 10 lần), theo khoảng điểm gốc:

| Điểm gốc | n | MAE | bias (thực - dự đoán) |
|---|---|---|---|
| 0-10 | 24 | 9,6 | -6,0 |
| 10-20 | 42 | 8,8 | -1,8 |
| 20-30 | 64 | 9,9 | -7,2 |
| 30-40 | 80 | 8,1 | -4,5 |
| 40-55 | 85 | 6,3 | +1,2 |
| 55-70 | 53 | 7,3 | +5,9 |
| 70-95 | 44 | 14,2 | +14,1 |

Sai số dư: sd 11,2; abs err phân vị 50% = 7,4; 80% = 13,9; 90% = 17,8.

### Inferences
- Để chọn ứng viên "gần điểm mục tiêu" nên dung sai ±3 như README là không khả thi với đo lường này; thực tế chỉ phân biệt được khoảng cách >= ~15 điểm một cách tin cậy theo từng level đơn lẻ. Trong cùng slot (Câu 4) phân biệt tốt hơn nhiều.
- Đầu trên của thang (>70) bị đánh giá thấp: có thể dùng hàm phi tuyến/isotonic trên lw (đã thấy GBR ngang ridge nên cải thiện còn nhỏ).

### Gaps
- Chưa thử hiệu chuẩn phi tuyến riêng cho phần đuôi; chưa kiểm định trên level ngoài tập 392 (không có nhãn).

## Câu hỏi 4: summaryScore phản ánh độ khó người chơi, độ khó solver, hay thứ khác?

### Takeaway
Bằng chứng cho thấy summaryScore là một điểm do mô phỏng bot (rất giống một người chơi heuristic có sai sót) rồi chia thành 6 tier; nó không phải thống kê người chơi thật và không đo độ khó solver tìm đường. Trong cùng slot, bot greedy-noisy xếp đúng thứ tự ~90% cặp có chênh >= 5 điểm.

### Cited Findings
Nguồn: `assets/builtin/chapter_default_1_5.json` (trường `difficulty`, `levelIndex`, `summaryScore`, `levelUniqueId`), `slots.csv`, `final.py`.
- File gồm 587 mục -> 392 level unique; mỗi mục là một "slot" (chapter, levelIndex 1-25) có nhiều biến thể; cùng uid lặp lại trong nhiều mục (155 uid lặp, tối đa 4 lần), lặp lại có cùng score. Trong một slot, các biến thể có `difficulty` (tier) tăng dần, ví dụ chapter 2 slot 1: tier 2 (24,6), tier 3 (47,4).
- Tier là bin của score: tier 1: 0-20,4; tier 2: 20,5-35,4; tier 3: 35,5-50,4; tier 4: 50,5-69,4; tier 5: 70,5-85,4; tier 6: 86,7-89,7 (Spearman tier-score 0,976). Tức tier được suy ra từ score (không dùng tier làm đặc trưng, vì rò rỉ).
- 118 slot có >= 2 biến thể (385 level). Độ lệch chuẩn của score trong slot (17,0) lớn hơn độ lệch chuẩn giữa các slot mean (13,1); R2 của slot mean trên score chỉ 0,33. Tức vị trí slot ít quyết định điểm, mỗi slot có biến thể dễ-khó (dạng điều chỉnh độ khó động).
- Tương quan within-slot (đã trừ trung bình slot): lw -0,828 (so với toàn cục -0,839, gần như không giảm), mô hình pred 0,835, ld -0,790, rand_win -0,491, beam_logw 0,372, log_dfs 0,322, opt_len 0,270, total 0,329, cap 0,087 (số cốc cùng cap gần như không đổi trong slot), hidden0 0,122.
- Độ chính xác xếp thứ tự cặp trong slot (cặp chênh score >= 5): lw 0,904 (n=457), pred 0,897, random win 0,758, opt_len 0,622.
- Phần dư của mô hình không tương quan với chapter (rho 0,03), slot (0,07), total (0,03), locks (0,03); dư hơi dương với hidden0 (rho 0,20) và level Hard (+3,8 điểm so với -1,1 của Normal): score của màn Hard / nhiều hoa ẩn cao hơn bot dự đoán một chút.

### Inferences
- Vì bot greedy-noisy (bắt chước thao tác "dùng gợi ý/heuristic với sai sót") xếp thứ tự rất khớp và các thước đo "solver mạnh" (DFS, độ dài tối ưu, chiều rộng beam) khớp yếu (|rho| 0,3-0,44), summaryScore có vẻ đo xác suất thất bại của người chơi thông thường (có heuristic, không tối ưu) chứ không đo độ khó tìm nghiệm. Có thể score do bot mô phỏng / hoặc do dữ liệu thật hiệu chỉnh; từ dữ liệu này không phân biệt được hai khả năng đó (kết luận "là bot" là suy luận, chưa chứng minh).
- Phần phương sai chưa giải thích (R2 0,70-0,75, sai số ~8 điểm) có thể đến từ (a) công thức/bot thật khác bot của tôi, (b) nhiễu mô phỏng của chính score, (c) yếu tố ẩn như thông tin hoa ẩn mà bot omniscient của tôi không thấy (xem Câu 5).
- Độ khó "người chơi" thực sự (tỉ lệ thắng/lần thử của người) không có dữ liệu để kiểm chứng.

### Gaps
- Không có dữ liệu người chơi thật; không xác định được công thức hay seed của bot gốc; không biết quy tắc phân phối biến thể trong slot.

## Câu hỏi 5: Chỉ số nào nhạy với vị trí và phân bố hoa ẩn (hoa ẩn dồn đáy dây so với xen kẽ)?

### Takeaway
Trên thí nghiệm hoán vị có kiểm soát (cùng loại hoa, chỉ đổi vị trí dấu `?`), chỉ beam_w (độ rộng beam tối thiểu) và các đại lượng đo trực tiếp vị trí (độ sâu hoa ẩn, hburden) phân biệt được "ẩn sâu gần chậu" với "ẩn nông gần đuôi"; win-rate của mọi bot (random, greedy) và độ dài tối ưu hầu như không nhạy. Lý do: bot và solver đều nhìn được loại thật của hoa ẩn (omniscient), chỉ bị chặn việc dùng hoa ẩn làm đầu đoạn cắt.

### Cited Findings
Thí nghiệm (`mkvariants.py`, `var_*.json`, `variants_feat.csv`): lấy 48 level có >= 1 dây chứa >= 2 hoa ẩn (tổng <= 8). Giữ nguyên loại hoa và số hoa ẩn mỗi dây; đổi vị trí dấu `?` thành: deep = các vị trí sát chậu (index 0..h-1, lộ ra sau cùng), shallow = ngay phía trên đuôi (n-1-h..n-2, lộ ngay khi hoa trên đỡ), alt = cách một hoa tính từ đuôi (xen kẽ); orig = gốc. 47-48 level mỗi biến thể. Chênh trung bình ghép cặp, Wilcoxon:

| Chỉ số | deep | alt | shallow | orig | deep - shallow (p) | alt - shallow (p) |
|---|---|---|---|---|---|---|
| h_depth (độ sâu hoa ẩn TB tính từ đuôi) | 3,12 | 1,26 | 1,11 | 2,12 | +2,02 (<0,001) | +0,15 (<0,001) |
| p_hburden (tổng độ sâu hoa ẩn trên mỗi bước đường giải) | 7,55 | 3,15 | 2,75 | 4,59 | +4,75 (<0,001) | +0,39 (0,028) |
| beam_w (độ rộng beam tối thiểu) | 3,98 | 2,92 | 2,73 | 2,44 | +1,28 (0,011) | +0,15 (0,71) |
| p_reveal_n (số nước làm lộ hoa) | 6,08 | 6,36 | 6,38 | 6,23 | -0,30 (0,024) | -0,02 (0,71) |
| dfs_res (tỉ lệ DFS thắng trong 4000 nút) | 0,979 | 0,915 | 0,917 | 0,958 | +0,06 (0,18) | 0 |
| log(1+dfs expanded) | 6,75 | 6,57 | 6,69 | 6,52 | +0,06 (0,60) | -0,13 (0,17) |
| opt_len | 49,98 | 49,87 | 50,04 | 50,02 | -0,11 (0,74) | -0,30 (0,29) |
| rand_win | 0,052 | 0,041 | 0,048 | 0,052 | +0,005 (0,42) | -0,002 (0,94) |
| g15_win | 0,358 | 0,330 | 0,336 | 0,392 | +0,021 (0,78) | -0,001 (0,84) |
| g35_win | 0,335 | 0,318 | 0,337 | 0,351 | -0,006 (0,85) | -0,012 (0,16) |
| g35_done | 0,448 | 0,438 | 0,454 | 0,465 | -0,009 (0,54) | -0,010 (0,36) |

Chú thích: các dấu hiệu "độ khó" nghịch hướng: deep có beam_w cao hơn (hơi khó hơn với beam) và hburden cao hơn nhiều, nhưng win-rate bot không đổi. `orig` có g15_win cao hơn shallow 0,059 (p = 0,037) chỉ là một kết quả lẻ; không có xu hướng nhất quán.
- Trên 392 level thật: số hoa ẩn (hidden0) chỉ tương quan 0,168 với score, và dư của mô hình tương quan +0,20 với hidden0; p_hburden/h_depth/p_reveal_n đều ~0,16.
- Code: `JuiceSolver._hint_type` trả `JuiceLevel.true_type(fruit_type)` nên heuristic của bot và solver thấy loại thật của hoa ẩn (xác nhận từ đọc `juice_solver.gd` dòng 71-72); `useful_moves` chỉ chặn hoa ẩn làm đầu đoạn cắt.

### Inferences
- Phân biệt "2 hoa ẩn dồn đáy dây (gần chậu) dễ hơn 2 hoa ẩn xen kẽ" bằng bot hiện tại: không thể; biến thể alt và shallow gần như bằng nhau trên mọi chỉ số, và deep chỉ khác ở beam_w/hburden. Chỉ số nhạy vị trí: h_depth, p_hburden (đo cấu trúc), beam_w (yếu). Chỉ số không nhạy: opt_len, rand_win, mọi win-rate greedy, DFS expanded.
- Hướng khuyến nghị (chưa thực hiện, nằm ngoài ngân sách): một bot "mù một phần" (xem hoa ẩn như loại chưa biết cho tới khi lộ, chọn nước theo xác suất) mới đo được chi phí thông tin; cần sửa `move_score`/`_hint_type` trong bản sao riêng, không sửa file tracked.
- Giới hạn thí nghiệm: chỉ đổi dấu `?`, giữ thứ tự loại hoa; level có thể mất tính giải được (dfs_res 0,92-0,98 trong 4000 nút; không phân biệt UNKNOWN với UNWINNABLE); kích thước mẫu 47 cặp có thể nhỏ cho hiệu ứng nhỏ; không có điểm summaryScore thật cho biến thể nên không kiểm được hiệu ứng lên score.

### Gaps
- Không biết summaryScore gốc có xét vị trí hoa ẩn hay không; chưa chạy bot mù/một phần thông tin.

## Phương pháp tái lập và phụ lục

Các bước (từ `/home/user/GodotProject`; sao chép file `.gd` ở phụ lục vào `.godot/`; xóa `*.import` untracked sau đó, `git status --short`; repo đã sạch lúc kết thúc):
1. `godot --headless --path . -s res://.godot/solver_metrics.gd -- /tmp/claude-0/uniq.json out_$i.json $i 4` với i = 0..3 (chạy song song; tham số thứ 5 `full` bật thêm nhãn nước đi gốc/quỹ đạo, mặc định tắt vì tốn ~65% thời gian mà solver nhãn UNKNOWN gần hết: node_cap 150-300 không chứng minh được thắng/thua).
2. `godot ... -s res://.godot/greedy_ext.gd -- /tmp/claude-0/uniq.json ge_$i.json $i 4`.
3. `python3 build.py` (features.csv), `python3 mkge.py` (greedy_feat.csv), `python3 models.py`, `python3 final.py`.
4. Thí nghiệm hoa ẩn: `python3 mkvariants.py` -> variants.json; chạy `solver_metrics.gd` trên variants.json; phân tích bằng `build.row()` (xem phân tích ghép cặp trong notes: Wilcoxon).
Tham số cố định: random seed 12345/777/4242 x 40 ván, tối đa 300 nước; greedy eps in {0, 0,15, 0,35} seed 999; greedy_ext seed 11 và 22 x 30 ván, cấu hình eps 0,3/0,45/0,6 và softmax T=4; DFS node_cap 4000, state_cap 20000; beam heuristic h = done*12 - sort_lower_bound, độ rộng thử [1,3,8,20,50,120] dừng sau 2 lần thắng, độ sâu tối đa 160; ghi chú: `is_doomed`/`has_any_move` để cắt trạng thái chết.
Ngân sách tính toán đã dùng: ~14 phút (solver_metrics, 4 core) + ~5 phút (variants) + ~11 phút (greedy_ext) + test.

### Phụ lục A: solver_metrics.gd
```gdscript
extends SceneTree
# Usage: -- in.json out.json shard nshards [mode]
# in.json: [{uid, raw}]  -> out.json: [{uid, ...metrics}]
const R = preload("res://scripts/gameplay/juice_sort/core/juice_rules.gd")
const S = preload("res://scripts/gameplay/juice_sort/core/juice_solver.gd")

func hidden_count(st: Dictionary) -> int:
	var c := 0
	for col: Array in st["cols"]:
		for v: int in col:
			if JuiceLevel.is_hidden(v):
				c += 1
	return c

func hidden_pos(st: Dictionary) -> Dictionary:
	# depth = number of flowers between hidden flower and tail (0 = tail)
	var n := 0
	var dsum := 0.0
	var runs := 0
	var cols_h := 0
	var under := 0   # hidden flowers lying under a non-hidden flower of a different type than pot
	for col: Array in st["cols"]:
		var prev_h := false
		var any := false
		for i in col.size():
			var v: int = col[i]
			var h: bool = JuiceLevel.is_hidden(v)
			if h:
				n += 1; any = true
				dsum += float(col.size() - 1 - i)
				if not prev_h:
					runs += 1
			prev_h = h
		if any:
			cols_h += 1
	return {"n": n, "mean_depth": (dsum / n) if n > 0 else 0.0, "runs": runs, "cols": cols_h}

func hidden_burden(st: Dictionary) -> int:
	var b := 0
	for col: Array in st["cols"]:
		for i in col.size():
			if JuiceLevel.is_hidden(int(col[i])):
				b += col.size() - i
	return b

func locks_active(st: Dictionary) -> int:
	var c := 0
	for l: Dictionary in R._locks_for(st):
		if not l.is_empty():
			c += 1
	return c

func is_dead_state(st: Dictionary, lv: JuiceLevel) -> bool:
	return R.is_doomed(st, lv) or not R.has_any_move(st)

# random / greedy playout. policy: 0 random, 1 eps-greedy(move_score)
func play(lv: JuiceLevel, rng: RandomNumberGenerator, policy: int, eps: float, max_steps: int) -> Dictionary:
	var st: Dictionary = R.make_state(lv)
	var steps := 0
	var bsum := 0.0
	var bn := 0
	var doomed_at := -1
	var res := "cap"
	while steps < max_steps:
		if R.is_win(st, lv):
			res = "win"; break
		if doomed_at < 0 and R.is_doomed(st, lv):
			doomed_at = steps
		var ms: Array = R.useful_moves(st)
		if ms.is_empty():
			res = "stuck"; break
		bsum += ms.size(); bn += 1
		var mv: Dictionary
		if policy == 1 and rng.randf() >= eps:
			var best := -1e9
			var cands: Array = []
			for m: Dictionary in ms:
				var sc: float = S.move_score(st, m)
				if sc > best + 1e-6:
					best = sc; cands = [m]
				elif absf(sc - best) <= 1e-6:
					cands.append(m)
			mv = cands[rng.randi_range(0, cands.size() - 1)]
		else:
			mv = ms[rng.randi_range(0, ms.size() - 1)]
		if R.apply_move(st, lv, int(mv.src), int(mv.j), int(mv.dst)).is_empty():
			res = "invalid"; break
		steps += 1
	return {"res": res, "steps": steps, "done": int(st["done"]), "b": bsum / maxi(1, bn), "doomed_at": doomed_at}

func summarize(plays: Array, total: int) -> Dictionary:
	var w := 0
	var stuck := 0
	var done_sum := 0.0
	var b := 0.0
	var wsteps := 0.0
	var doomed := 0
	var doomed_at := 0.0
	for p: Dictionary in plays:
		if p.res == "win":
			w += 1; wsteps += p.steps
		if p.res == "stuck":
			stuck += 1
		done_sum += float(p.done) / total
		b += p.b
		if p.doomed_at >= 0:
			doomed += 1; doomed_at += p.doomed_at
	var n := float(plays.size())
	return {"win": w / n, "stuck": stuck / n, "done_frac": done_sum / n, "branch": b / n,
		"win_steps": (wsteps / w) if w > 0 else -1.0, "doomed_frac": doomed / n,
		"doomed_at": (doomed_at / doomed) if doomed > 0 else -1.0}

# Beam search. returns {win, depth, path, stats}
func beam(lv: JuiceLevel, width: int, max_depth: int) -> Dictionary:
	var root: Dictionary = R.make_state(lv)
	var total: int = lv.groups_total
	var nodes: Array = [{"st": root, "p": -1, "mv": {}}]   # all nodes (for path)
	var layer: Array = [0]
	var seen: Dictionary = {R.state_key(root): true}
	var expanded := 0
	var bsum := 0.0
	var children_total := 0
	var children_dead := 0
	var layer_sizes: Array = []
	for depth in range(1, max_depth + 1):
		var cand: Array = []
		for ni: int in layer:
			var st: Dictionary = nodes[ni]["st"]
			var ms: Array = R.useful_moves(st)
			expanded += 1
			bsum += ms.size()
			for mv: Dictionary in ms:
				var nx: Dictionary = R.clone_state(st)
				if R.apply_move(nx, lv, int(mv.src), int(mv.j), int(mv.dst)).is_empty():
					continue
				children_total += 1
				if R.is_win(nx, lv):
					nodes.append({"st": nx, "p": ni, "mv": mv})
					return _beam_result(true, depth, nodes, nodes.size() - 1, expanded, bsum, children_total, children_dead, layer_sizes)
				if is_dead_state(nx, lv):
					children_dead += 1
					continue
				var key: String = R.state_key(nx)
				if seen.has(key):
					continue
				seen[key] = true
				var h: float = float(int(nx["done"])) * 12.0 - float(S.sort_lower_bound(nx))
				cand.append({"h": h, "st": nx, "p": ni, "mv": mv})
		if cand.is_empty():
			return _beam_result(false, depth, nodes, -1, expanded, bsum, children_total, children_dead, layer_sizes)
		cand.sort_custom(func(a, b): return a.h > b.h)
		if cand.size() > width:
			cand.resize(width)
		layer = []
		for c: Dictionary in cand:
			nodes.append({"st": c.st, "p": c.p, "mv": c.mv})
			layer.append(nodes.size() - 1)
		layer_sizes.append(layer.size())
	return _beam_result(false, max_depth, nodes, -1, expanded, bsum, children_total, children_dead, layer_sizes)

func _beam_result(win: bool, depth: int, nodes: Array, last: int, expanded: int, bsum: float, ct: int, cd: int, ls: Array) -> Dictionary:
	var path: Array = []
	var i := last
	while win and i > 0:
		path.append({"mv": nodes[i]["mv"], "pi": nodes[i]["p"]})
		i = nodes[i]["p"]
	path.reverse()
	var states: Array = []
	if win:
		for e: Dictionary in path:
			states.append(nodes[e.pi]["st"])
	return {"win": win, "depth": depth, "path": path, "states": states, "expanded": expanded,
		"branch": bsum / maxi(1, expanded), "dead_child": float(cd) / maxi(1, ct)}

func path_stats(lv: JuiceLevel, b: Dictionary) -> Dictionary:
	var path: Array = b["path"]
	var states: Array = b["states"]
	var nonmono := 0
	var low := 0
	var rank_sum := 0.0
	var reveal := 0
	var lock_steps := 0
	var wide := 0
	var brs := 0.0
	var forced := 0
	var hburden := 0.0
	for i in path.size():
		var st: Dictionary = states[i]
		var mv: Dictionary = path[i]["mv"]
		var ms: Array = R.useful_moves(st)
		brs += ms.size()
		if ms.size() <= 2:
			forced += 1
		var sc: float = S.move_score(st, mv)
		var better := 0
		for m: Dictionary in ms:
			if S.move_score(st, m) > sc + 1e-6:
				better += 1
		rank_sum += float(better) / maxi(1, ms.size() - 1)
		if sc <= 0.0:
			low += 1
		var col: Array = st["cols"][int(mv.src)]
		var mono := true
		for q in range(int(mv.j) + 1, col.size()):
			if col[q] != col[int(mv.j)]:
				mono = false
		if not mono:
			nonmono += 1
		if int(mv.k) > 1:
			wide += 1
		if locks_active(st) > 0:
			lock_steps += 1
		var hb: int = hidden_count(st)
		hburden += float(hidden_burden(st))
		if i + 1 < states.size() and hidden_count(states[i + 1]) < hb:
			reveal += 1
	var n: float = maxf(1.0, path.size())
	return {"nonmono": nonmono / n, "lowscore": low / n, "rank": rank_sum / n, "reveal": reveal / n,
		"lock_steps": lock_steps / n, "wide": wide / n, "path_branch": brs / n, "forced": forced / n, "hburden": hburden / n, "reveal_n": reveal}

func label(st: Dictionary, lv: JuiceLevel, cap: int) -> int:
	# 1 winnable, 2 unwinnable, 0 unknown
	var s: Dictionary = S.begin_full_search(st, lv)
	return S.advance_full_search(s, lv, {"node_cap": cap, "state_cap": 6 * cap})

func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	var arr: Array = JSON.parse_string(FileAccess.get_file_as_string(args[0]))
	var shard := int(args[2])
	var nsh := int(args[3])
	var out: Array = []
	var seeds := [12345, 777, 4242]
	for idx in arr.size():
		if idx % nsh != shard:
			continue
		var item: Dictionary = arr[idx]
		var lv := JuiceLevel.from_dict(item["raw"])
		if not lv.validate().is_empty():
			continue
		var o: Dictionary = {"uid": item["uid"]}
		var t0 := Time.get_ticks_msec()
		var total: int = lv.groups_total
		o["total"] = total
		var st0: Dictionary = R.make_state(lv)
		o["hidden0"] = hidden_count(st0)
		o["locks0"] = locks_active(st0)
		o["hpos"] = hidden_pos(st0)
		# 1. random play: 3 seeds x 40
		var rng := RandomNumberGenerator.new()
		var rs: Array = []
		for sd in seeds:
			rng.seed = sd
			var pl: Array = []
			for p in 40:
				pl.append(play(lv, rng, 0, 0.0, 300))
			rs.append(summarize(pl, total))
		o["rand_seeds"] = rs
		var tr := Time.get_ticks_msec()
		o["t_rand"] = tr - t0
		# 2. greedy eps 0.15 / eps 0.35 (2 seeds x 20)
		var gs: Array = []
		for eps in [0.0, 0.15, 0.35]:
			rng.seed = 999
			var pl: Array = []
			for p in (1 if eps == 0.0 else 30):
				pl.append(play(lv, rng, 1, eps, 300))
			gs.append(summarize(pl, total))
		o["greedy"] = gs
		var tg := Time.get_ticks_msec()
		o["t_greedy"] = tg - tr
		# 3. DFS solver (as in first pass) keep_path
		var srch: Dictionary = S.begin_full_search(R.make_state(lv), lv, false, true)
		var res: int = S.advance_full_search(srch, lv, {"node_cap": 4000, "state_cap": 20000})
		o["dfs_res"] = res
		o["dfs_expanded"] = int(srch["expanded"])
		o["dfs_states"] = (srch["seen"] as Dictionary).size()
		o["dfs_path"] = (srch["path"] as Array).size()
		var td := Time.get_ticks_msec()
		o["t_dfs"] = td - tg
		# 4. beam widths
		var bw: Array = []
		var best: Dictionary = {}
		var wins_seen := 0
		for w in [1, 3, 8, 20, 50, 120]:
			var b: Dictionary = beam(lv, w, 160)
			bw.append({"w": w, "win": b.win, "depth": b.depth, "dead_child": b.dead_child, "branch": b.branch, "exp": b.expanded})
			if b.win:
				wins_seen += 1
				if best.is_empty() or b.depth < best.depth:
					best = b
				if wins_seen >= 2:
					break
		o["beam"] = bw
		var tb := Time.get_ticks_msec()
		o["t_beam"] = tb - td
		if not best.is_empty():
			o["path"] = path_stats(lv, best)
			o["opt_len"] = best.depth
		if not (args.size() > 4 and args[4] == "full"):
			o["t_total"] = Time.get_ticks_msec() - t0
			out.append(o)
			continue
		# 5. root moves labelled
		var root_ms: Array = R.useful_moves(st0)
		var lw := 0
		var lu := 0
		var lk := 0
		for m: Dictionary in root_ms:
			var nx: Dictionary = R.clone_state(st0)
			if R.apply_move(nx, lv, int(m.src), int(m.j), int(m.dst)).is_empty():
				continue
			var l: int = 2 if is_dead_state(nx, lv) else label(nx, lv, 300)
			if l == 1: lw += 1
			elif l == 2: lu += 1
			else: lk += 1
		o["root"] = {"n": root_ms.size(), "win": lw, "lost": lu, "unk": lk}
		var tl := Time.get_ticks_msec()
		o["t_root"] = tl - tb
		# 6. random trajectories labelled at checkpoints
		rng.seed = 2024
		var tw := 0
		var tu := 0
		var tk := 0
		var trap_steps: Array = []
		var trap_plays := 0
		for p in 6:
			var st: Dictionary = R.make_state(lv)
			var step := 0
			var trapped := false
			while step < 120 and not R.is_win(st, lv):
				if step % 8 == 0:
					var l: int = 2 if is_dead_state(st, lv) else label(st, lv, 150)
					if l == 1: tw += 1
					elif l == 2:
						tu += 1; trapped = true; trap_steps.append(step); break
					else: tk += 1
				var ms: Array = R.useful_moves(st)
				if ms.is_empty():
					break
				var mv: Dictionary = ms[rng.randi_range(0, ms.size() - 1)]
				if R.apply_move(st, lv, int(mv.src), int(mv.j), int(mv.dst)).is_empty():
					break
				step += 1
			if trapped:
				trap_plays += 1
		o["traj"] = {"w": tw, "u": tu, "k": tk, "trap_plays": trap_plays, "trap_steps": trap_steps}
		o["t_traj"] = Time.get_ticks_msec() - tl
		o["t_total"] = Time.get_ticks_msec() - t0
		out.append(o)
		print("L %d %s t=%d" % [idx, item["uid"].substr(0, 6), o["t_total"]])
	var f := FileAccess.open(args[1], FileAccess.WRITE)
	f.store_string(JSON.stringify(out)); f.close()
	quit()

```

### Phụ lục B: greedy_ext.gd
```gdscript
extends SceneTree
# Usage: -- in.json out.json shard nshards
const R = preload("res://scripts/gameplay/juice_sort/core/juice_rules.gd")
const S = preload("res://scripts/gameplay/juice_sort/core/juice_solver.gd")

# policy 0: eps-greedy on S.move_score; policy 1: softmax(move_score / T) with T=eps
func play(lv: JuiceLevel, rng: RandomNumberGenerator, policy: int, eps: float, max_steps: int) -> Dictionary:
	var st: Dictionary = R.make_state(lv)
	var steps := 0
	var res := "cap"
	while steps < max_steps:
		if R.is_win(st, lv):
			res = "win"; break
		var ms: Array = R.useful_moves(st)
		if ms.is_empty():
			res = "stuck"; break
		var mv: Dictionary
		if policy == 0:
			if rng.randf() >= eps:
				var best := -1e9
				var cands: Array = []
				for m: Dictionary in ms:
					var sc: float = S.move_score(st, m)
					if sc > best + 1e-6:
						best = sc; cands = [m]
					elif absf(sc - best) <= 1e-6:
						cands.append(m)
				mv = cands[rng.randi_range(0, cands.size() - 1)]
			else:
				mv = ms[rng.randi_range(0, ms.size() - 1)]
		else:
			var ws: Array = []
			var mx := -1e9
			for m: Dictionary in ms:
				var sc2: float = S.move_score(st, m)
				ws.append(sc2); mx = maxf(mx, sc2)
			var tot := 0.0
			for i in ws.size():
				ws[i] = exp((ws[i] - mx) / eps); tot += ws[i]
			var r := rng.randf() * tot
			var k := 0
			while k < ws.size() - 1 and r > ws[k]:
				r -= ws[k]; k += 1
			mv = ms[k]
		if R.apply_move(st, lv, int(mv.src), int(mv.j), int(mv.dst)).is_empty():
			res = "invalid"; break
		steps += 1
	return {"res": res, "steps": steps, "done": int(st["done"])}

func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	var arr: Array = JSON.parse_string(FileAccess.get_file_as_string(args[0]))
	var shard := int(args[2])
	var nsh := int(args[3])
	var out: Array = []
	var configs := [[0, 0.3], [0, 0.45], [0, 0.6], [1, 4.0]]
	for idx in arr.size():
		if idx % nsh != shard:
			continue
		var item: Dictionary = arr[idx]
		var lv := JuiceLevel.from_dict(item["raw"])
		if not lv.validate().is_empty():
			continue
		var t0 := Time.get_ticks_msec()
		var total: int = lv.groups_total
		var o: Dictionary = {"uid": item["uid"], "cfg": []}
		for c in configs:
			var per: Array = []
			for sd in [11, 22]:
				var rng := RandomNumberGenerator.new()
				rng.seed = sd
				var w := 0
				var dn := 0.0
				var wsteps := 0.0
				for p in 30:
					var r: Dictionary = play(lv, rng, c[0], c[1], 300)
					if r.res == "win":
						w += 1; wsteps += r.steps
					dn += float(r.done) / total
				per.append({"win": w / 30.0, "done": dn / 30.0, "wsteps": (wsteps / w) if w > 0 else -1.0})
			o["cfg"].append({"policy": c[0], "param": c[1], "seeds": per})
		o["t"] = Time.get_ticks_msec() - t0
		out.append(o)
	var f := FileAccess.open(args[1], FileAccess.WRITE)
	f.store_string(JSON.stringify(out)); f.close()
	quit()

```

### Phụ lục: build.py
```python
import json,glob,numpy as np,pandas as pd
def load(pat):
    o=[]
    for f in sorted(glob.glob(pat)): o+=json.load(open(f))
    return o
def row(x):
    r={'uid':x['uid'],'total':x['total'],'hidden0':x['hidden0'],'locks0':x['locks0']}
    rs=x['rand_seeds']
    for i,s in enumerate(rs):
        r[f'rw{i}']=s['win']; r[f'rd{i}']=s['done_frac']
    r['rand_win']=np.mean([s['win'] for s in rs]); r['rand_done']=np.mean([s['done_frac'] for s in rs])
    r['rand_stuck']=np.mean([s['stuck'] for s in rs]); r['rand_doomed']=np.mean([s['doomed_frac'] for s in rs])
    da=[s['doomed_at'] for s in rs if s['doomed_at']>=0]; r['rand_doomed_at']=np.mean(da) if da else np.nan
    r['rand_branch']=np.mean([s['branch'] for s in rs])
    ws=[s['win_steps'] for s in rs if s['win_steps']>=0]; r['rand_win_steps']=np.mean(ws) if ws else np.nan
    g=x['greedy']
    r['g0_win']=g[0]['win']; r['g0_done']=g[0]['done_frac']
    r['g15_win']=g[1]['win']; r['g15_done']=g[1]['done_frac']
    r['g35_win']=g[2]['win']; r['g35_done']=g[2]['done_frac']; r['g35_stuck']=g[2]['stuck']
    r['dfs_res']=x['dfs_res']; r['dfs_exp']=x['dfs_expanded']; r['dfs_states']=x['dfs_states']; r['dfs_path']=x['dfs_path']
    bw=x['beam']; wins=[b for b in bw if b['win']]
    r['beam_w']=wins[0]['w'] if wins else 999
    r['beam_fail1']=int(not bw[0]['win'])
    r['opt_len']=x.get('opt_len',np.nan)
    r['beam_dead']=np.mean([b['dead_child'] for b in bw]); r['beam_branch']=np.mean([b['branch'] for b in bw])
    p=x.get('path',{})
    for k in ['nonmono','lowscore','rank','reveal','lock_steps','wide','path_branch','forced','hburden','reveal_n']: r['p_'+k]=p.get(k,np.nan)
    h=x['hpos']
    r['h_n']=h['n']; r['h_depth']=h['mean_depth']; r['h_runs']=h['runs']; r['h_cols']=h['cols']
    r['t_total']=x['t_total']
    return r
if __name__=='__main__':
    df=pd.DataFrame([row(x) for x in load('out_*.json')])
    m=pd.DataFrame(json.load(open('/tmp/claude-0/metrics.json'))).rename(columns={'win_rate':'old_win','branch':'old_branch','expanded':'old_exp','avg_moves':'old_moves','solved':'old_solved'})
    df=df.merge(m,on='uid')
    c=json.load(open('/home/user/GodotProject/assets/builtin/chapter_default_1_5.json'))['data']
    rows=[]
    for ch in c:
        for l in ch['levels']: rows.append(dict(uid=l['levelUniqueId'],ch=ch['chapterIndex'],slot=l['levelIndex'],dtype=l['difficultyType'],tier=int(l['difficulty']),score=float(l['summaryScore'])))
    sc=pd.DataFrame(rows); sc.to_csv('slots.csv',index=False)
    first=sc.drop_duplicates('uid')
    df=df.merge(first,on='uid')
    # static
    u={x['uid']:x['raw'] for x in json.load(open('/tmp/claude-0/uniq.json'))}
    df['cap']=[u[i]['capacity'] for i in df.uid]; df['ncols']=[len(u[i]['initial']) for i in df.uid]
    df.to_csv('features.csv',index=False); print(df.shape)

```

### Phụ lục: models.py
```python
import pandas as pd,numpy as np,sys,warnings
warnings.filterwarnings('ignore')
from sklearn.model_selection import KFold,GroupKFold,cross_val_predict
from sklearn.linear_model import RidgeCV
from sklearn.ensemble import GradientBoostingRegressor
from sklearn.pipeline import make_pipeline
from sklearn.preprocessing import StandardScaler
from sklearn.metrics import r2_score,mean_absolute_error
df=pd.read_csv('features.csv')
try:
    g=pd.read_csv('greedy_feat.csv'); df=df.merge(g,on='uid')
except Exception as e: print('no greedy ext')
df['log_dfs']=np.log1p(df.dfs_exp); df['log_opt']=np.log(df.opt_len.fillna(df.opt_len.max()))
df['beam_logw']=np.log(df.beam_w.clip(upper=200))
df['opt_len']=df.opt_len.fillna(df.opt_len.median()); 
for c in df.columns:
    if pd.api.types.is_numeric_dtype(df[c]): df[c]=df[c].fillna(df[c].median())
sets={
 'old3 (win,branch,logexp)':['old_win','old_branch','log_dfs'],
 'rand_win':['rand_win'],
 'g35_win':['g35_win'],
 'greedy(g15,g35 win+done)':['g15_win','g15_done','g35_win','g35_done'],
 'greedy+rand':['g15_win','g35_win','g35_done','rand_win','rand_done'],
 'greedy+rand+beam':['g15_win','g35_win','g35_done','rand_win','rand_done','beam_logw','opt_len','beam_dead','log_dfs'],
 'all solver':[c for c in ['g0_win','g0_done','g15_win','g15_done','g35_win','g35_done','g35_stuck','rand_win','rand_done','rand_stuck','rand_doomed','rand_branch','beam_logw','opt_len','beam_dead','beam_branch','log_dfs','p_nonmono','p_wide','p_path_branch','p_forced','p_reveal','p_hburden','p_lock_steps','h_n','h_depth','h_runs','h_cols','hidden0','locks0']],
 'static only':['cap','ncols','total','hidden0','locks0','h_depth'],
}
extra=[c for c in df.columns if c.startswith('ge_')]
if extra:
    sets['greedy_ext']=extra
    sets['greedy_ext+rand']=extra+['rand_win','rand_done']
    sets['greedy_ext+all']=extra+sets['all solver']
y=df.score.values
kf=KFold(5,shuffle=True,random_state=0)
# group by uid is already unique; also leave-slot-out
grp=(df.ch.astype(str)+'_'+df.slot.astype(str)).values
gk=GroupKFold(5)
out=[]
for name,cols in sets.items():
    X=df[cols].values
    for mn,mk in [('ridge',lambda:make_pipeline(StandardScaler(),RidgeCV(alphas=np.logspace(-2,3,20)))),('gbr',lambda:GradientBoostingRegressor(n_estimators=150,max_depth=2,learning_rate=0.05,subsample=0.8,random_state=0))]:
        r2s=[];maes=[]
        for rep in range(5):
            kf=KFold(5,shuffle=True,random_state=rep)
            p=cross_val_predict(mk(),X,y,cv=kf); r2s.append(r2_score(y,p)); maes.append(mean_absolute_error(y,p))
        p=cross_val_predict(mk(),X,y,cv=gk,groups=grp)
        out.append((name,mn,len(cols),np.mean(r2s),np.std(r2s),np.mean(maes),r2_score(y,p),mean_absolute_error(y,p)))
print("%-28s %-6s %3s %7s %6s %6s | %7s %6s"%('set','model','k','R2cv','sd','MAE','R2slot','MAEslot'))
for o in out: print("%-28s %-6s %3d %7.3f %6.3f %6.2f | %7.3f %6.2f"%o)
print('baseline MAE (median):',np.mean(np.abs(y-np.median(y))))

```

### Phụ lục: final.py
```python
import pandas as pd,numpy as np,warnings,itertools
warnings.filterwarnings('ignore')
from scipy.stats import spearmanr,kendalltau
from sklearn.model_selection import KFold,cross_val_predict
from sklearn.linear_model import LinearRegression,RidgeCV
from sklearn.pipeline import make_pipeline
from sklearn.preprocessing import StandardScaler
from sklearn.metrics import r2_score,mean_absolute_error
df=pd.read_csv('features.csv').merge(pd.read_csv('greedy_feat.csv'),on='uid')
df['opt_len']=df.opt_len.fillna(df.opt_len.median()); df['beam_logw']=np.log(df.beam_w.clip(upper=200)); df['log_dfs']=np.log1p(df.dfs_exp)
df['lw']=df[['ge_e30_win','ge_e45_win','ge_e60_win','ge_sm4_win']].mean(axis=1)
df['ld']=df[['ge_e30_done','ge_e45_done','ge_e60_done','ge_sm4_done']].mean(axis=1)
print('composite greedy win mean-of-4 rho',spearmanr(df.lw,df.score)[0], 'done',spearmanr(df.ld,df.score)[0])
y=df.score.values
def cv(cols,model=None,reps=10):
    X=df[cols].values; r2=[];ma=[];P=np.zeros(len(y))
    for r in range(reps):
        p=cross_val_predict(model or LinearRegression(),X,y,cv=KFold(5,shuffle=True,random_state=r)); r2.append(r2_score(y,p)); ma.append(mean_absolute_error(y,p)); P+=p/reps
    return np.mean(r2),np.mean(ma),P
cands={'lw':['lw'],'lw+ld':['lw','ld'],'lw+beam_logw':['lw','beam_logw'],'lw+opt_len':['lw','opt_len'],'lw+ld+rand_win+beam_logw+opt_len':['lw','ld','rand_win','beam_logw','opt_len'],
 'lw+ld+rand_win+beam_logw+opt_len+log_dfs+p_nonmono+cap':['lw','ld','rand_win','beam_logw','opt_len','log_dfs','p_nonmono','cap']}
for k,c in cands.items():
    r2,ma,P=cv(c); print('%-62s R2=%.3f MAE=%.2f'%(k,r2,ma))
c=cands['lw+ld+rand_win+beam_logw+opt_len']
lr=LinearRegression().fit(df[c],y); print(dict(zip(c,lr.coef_.round(3))),lr.intercept_.round(2))
r2,ma,P=cv(c)
res=y-P; print('residual sd',res.std(), '90% abs err',np.quantile(np.abs(res),0.9),'80%',np.quantile(np.abs(res),0.8),'50%',np.median(np.abs(res)))
bins=pd.cut(df.score,[-1,10,20,30,40,55,70,95]); print(pd.DataFrame({'bin':bins,'ae':np.abs(res),'res':res}).groupby('bin').agg(n=('ae','size'),mae=('ae','mean'),bias=('res','mean')).round(2))
# static baseline & joint
for extra in (['cap','ncols','total','hidden0','locks0','h_depth'],):
    r2,ma,_=cv(c+extra); print('solver+static',r2,ma)
# noise ceiling: tier
print('tier vs score rho',spearmanr(df.tier,df.score)[0])
# within-slot analysis
sc=pd.read_csv('slots.csv').drop_duplicates('uid')
d=df.copy(); d['pred']=P; d['slot_id']=d.ch.astype(str)+'_'+d.slot.astype(str)
g=d.groupby('slot_id')
d['score_c']=d.score-g.score.transform('mean')
for m in ['lw','ld','rand_win','opt_len','beam_logw','log_dfs','pred','cap','total','hidden0']:
    d[m+'_c']=d[m]-g[m].transform('mean')
n=g.size(); ok=d[d.slot_id.map(n)>=2]
print('slots with >=2 variants',(n>=2).sum(),'levels',len(ok))
for m in ['lw','ld','rand_win','opt_len','beam_logw','log_dfs','pred','cap','total','hidden0']:
    print('within-slot rho %-10s %.3f  pearson %.3f'%(m,spearmanr(ok[m+'_c'],ok.score_c)[0],np.corrcoef(ok[m+'_c'],ok.score_c)[0,1]))
# pairwise ordering accuracy within slot
def pairacc(col,sign=1):
    tot=0;good=0
    for s,gg in ok.groupby('slot_id'):
        for a,b in itertools.combinations(gg.index,2):
            ds=gg.score[a]-gg.score[b]
            if abs(ds)<5: continue
            dm=gg[col][a]-gg[col][b]
            if dm==0: continue
            tot+=1; good+= (np.sign(ds)==np.sign(dm)*sign)
    return good/tot,tot
print('pair acc (score gap>=5): pred',pairacc('pred'),'lw',pairacc('lw',-1),'opt_len',pairacc('opt_len'),'rand_win',pairacc('rand_win',-1),'cap',pairacc('cap'))
print('within-slot score sd',ok.score_c.std(),'between-slot sd of slot mean',g.score.mean().std())
# variance partition: how much of score explained by slot (ch,slot) mean
print('R2 of slot means on score',1-((d.score-g.score.transform('mean'))**2).sum()/((d.score-d.score.mean())**2).sum())
# residual vs position
d['res']=res; print('res vs ch',spearmanr(d.ch,d.res)[0],'res vs slot',spearmanr(d.slot,d.res)[0],'res vs hard',d.groupby('dtype').res.mean().to_dict(),'res vs total',spearmanr(d.total,d.res)[0],'cap',spearmanr(d.cap,d.res)[0],'hidden',spearmanr(d.hidden0,d.res)[0],'locks',spearmanr(d.locks0,d.res)[0])
print(d.groupby('ch').score.agg(['mean','std','size']).round(1)); print(d.groupby('tier').score.agg(['mean','std','min','max','size']).round(1))
d.to_csv('final_table.csv',index=False)
# spearman table of top metrics, with CI by bootstrap
rng=np.random.default_rng(0)
tops=['ge_sm4_win','ge_e45_win','lw','ge_sm4_done','g35_win','g15_win','rand_win','rand_done','beam_logw','opt_len','log_dfs','old_win','cap','hidden0','h_depth','p_hburden','p_nonmono','beam_dead']
print('metric, rho, 95% CI')
for m in tops:
    bs=[spearmanr(df[m].values[i],y[i])[0] for i in [rng.integers(0,len(y),len(y)) for _ in range(300)]]
    print('%-14s %.3f [%.3f,%.3f]'%(m,spearmanr(df[m],y)[0],*np.quantile(bs,[.025,.975])))

```

### Phụ lục: mkvariants.py
```python
import json,copy,random
u=json.load(open('/tmp/claude-0/uniq.json'))
random.seed(5)
def cols(raw):
    for key in ('initial','incoming'):
        for c in raw[key]:
            yield c
def variant(raw,mode):
    r=copy.deepcopy(raw)
    for c in cols(r):
        pot,fl=c['column'].split('|')
        if not fl: continue
        f=[x.lstrip('?') for x in fl.split(',')]
        h=sum(1 for x in fl.split(',') if x.startswith('?'))
        n=len(f)
        if h==0: continue
        if mode=='deep': pos=list(range(0,h))
        elif mode=='shallow': pos=list(range(n-1-h,n-1))
        elif mode=='alt': pos=[n-2-2*i for i in range(h)]
        if mode=='alt' and min(pos)<0: return None
        if max(pos)>=n-1 or min(pos)<0: return None
        g=[('?'+x if i in pos else x) for i,x in enumerate(f)]
        c['column']=pot+'|'+','.join(g)
    return r
sel=[]
for x in u:
    raw=x['raw']
    hs=[sum(1 for t in c['column'].split('|')[1].split(',') if t.startswith('?')) for c in cols(raw) if c['column'].split('|')[1]]
    if max(hs+[0])>=2 and sum(hs)<=8: sel.append(x)
print(len(sel))
random.shuffle(sel); sel=sel[:48]
out=[]
for x in sel:
    for m in ('orig','deep','shallow','alt'):
        r=x['raw'] if m=='orig' else variant(x['raw'],m)
        if r is None: continue
        out.append({'uid':x['uid']+'#'+m,'raw':r})
print(len(out))
json.dump(out,open('variants.json','w'))

```

### Phụ lục: mkge.py
```python
import json,glob,pandas as pd,numpy as np
o=[]
for f in sorted(glob.glob('ge_*.json')): o+=json.load(open(f))
rows=[]
names=['e30','e45','e60','sm4']
for x in o:
    r={'uid':x['uid'],'t_ge':x['t']}
    for n,c in zip(names,x['cfg']):
        s=c['seeds']
        r[f'ge_{n}_win']=np.mean([q['win'] for q in s]); r[f'ge_{n}_done']=np.mean([q['done'] for q in s])
        r[f'gs_{n}_a']=s[0]['win']; r[f'gs_{n}_b']=s[1]['win']
    rows.append(r)
pd.DataFrame(rows).to_csv('greedy_feat.csv',index=False)
print(len(o), np.mean([x['t'] for x in o])/1000)

```
