# Input cấu trúc của level quyết định `summaryScore` (Sort Streak chapter 1-5)

Nguồn dữ liệu duy nhất: file trong repo (không có nguồn web). Ký hiệu nguồn: [BD] = `/home/user/GodotProject/.godot/builtin_dump.json` (587 record, 392 uid duy nhất), [CH] = `/home/user/GodotProject/assets/builtin/chapter_default_1_5.json` (`summaryScore`, join theo uid).
Script và output nằm ở `/tmp/claude-0/-home-user-GodotProject/789c606f-fe6b-525e-85bc-e2eb0b400faa/scratchpad/research_work/structure/`: `feat.py` (đặc trưng cơ bản), `feat2.py` (đặc trưng phân bố), `analyze.py`/`analyze_out.txt`, `paired.py`/`paired_out.txt`, `compact.py`/`compact_out.txt`, `dist.py`/`dist_out.txt`, `final.py`, `final2.py`, CSV: `features_unique2.csv`, `univariate.csv`, `paired_univariate.csv`, `hidden_dist.csv`, `perm_importance_gb.csv`.

## Phương pháp (để tái lập)

- Đơn vị phân tích: 392 uid duy nhất [BD]+[CH]. Các tag lv của cùng slot hay dùng chung uid, nên đếm theo uid để không nhân đôi. Slot = (chapter 1-5, level 1-25), 118 slot có >=2 biến thể (53 slot có 3, 36 có 4, 21 có 2, 8 có 5, 7 chỉ có 1). `gidx = (chapter-1)*25 + level` là proxy vị trí tiến trình.
- 66 đặc trưng cơ bản (feat.py) cộng ~30 đặc trưng phân bố (feat2.py): số/độ sâu/độ rải/liền nhau của hoa ẩn, vị trí/giá trị dây khóa, chậu trắng, "lag" giữa lúc chậu xuất hiện và lúc hoa của nó xuất hiện. "Độ sâu từ đuôi" = (độ dài dây - 1 - chỉ số), 0 = đuôi; "độ sâu từ chậu" = chỉ số (0 = sát chậu).
- Thống kê: Spearman đơn biến, Spearman riêng phần (hạng, trừ ảnh hưởng gidx + hard), Spearman trong slot (trừ trung bình slot), OLS với sai số chuẩn cluster theo slot, Ridge/Lasso/GradientBoosting/RandomForest với GroupKFold(5) theo slot (không rò rỉ giữa biến thể cùng slot), permutation importance (20 lần, trên fold test), phân tích cặp trong slot (476 cặp), phân tầng so sánh cùng số lượng khác phân bố.
- Lưu ý: `summaryScore` là hộp đen, công thức không biết. Mọi hệ số là liên hệ thống kê, không chứng minh nhân quả. Tag người chơi (tier lv2..lv5) được dùng như biến kiểm soát ở một số mô hình, xem mục 2.

## 1. Input cấu trúc nào giải thích `summaryScore`, và bao nhiêu?

### Takeaway
Đặc trưng cấu trúc (không dùng tier) giải thích khoảng 32% (tuyến tính) đến 41-47% (GB với toàn bộ đặc trưng gồm phân bố) phương sai, MAE khoảng 12-13.5 điểm so với baseline 17.05. Các đòn bẩy mạnh nhất là TẢI ban đầu (số hoa trên dây lúc đầu / độ đầy của dây), số cốc (targetCups) ở cùng capacity, số lần đổi loại hoa ("runs"), tổng số unlock-count của dây khóa và số hoa ẩn. Phần lớn biến thiên điểm (đặc biệt giữa các tier của cùng slot) KHÔNG nằm ở các con số cấu trúc này.

### Cited Findings
Điểm tổng quan [CH]: n=392, trung bình 40.8, SD 20.5, min 0, max 89.7. MAE của baseline "luôn đoán trung bình" = 17.05 (analyze_out.txt).

Mô hình, GroupKFold 5 theo slot (analyze_out.txt, final.py, compact_out.txt):

| Mô hình | R² (CV) | MAE (CV) |
|---|---|---|
| Mean baseline | 0 | 17.05 |
| Ridge chỉ gidx+hard | 0.132 | 16.13 |
| Chỉ capacity (LR) | 0.126 | 16.22 |
| Chỉ targetCups / n_init / n_types (LR) | -0.014 / 0.015 / 0.004 | 17.14 / 16.71 / 16.98 |
| capacity+n_init+targetCups+n_types (LR) | 0.148 | 15.81 |
| ... + flowers_init (LR) | 0.265 | 14.29 |
| ... + lock_count_sum + hidden_total (LR) | 0.320 | 13.75 |
| ... + runs_total_init, mono_init, n_lock_init (LR / GB) | 0.343 / 0.412 | 13.35 / 12.68 |
| Ridge 66 đặc trưng | 0.194 | 13.54 |
| Lasso 66 đặc trưng | 0.374 | 13.09 |
| GB 66 đặc trưng | 0.414 | 12.51 |
| RF 66 đặc trưng | 0.401 | 12.74 |
| GB toàn bộ đặc trưng cấu trúc + phân bố, không tier | 0.471 | 12.07 |

Hạn chế: thêm gidx+hard vào mô hình không cải thiện thêm GB (0.414 vs 0.415 khi bỏ), tức vị trí/hard gần như dư thừa với đặc trưng cấu trúc.

Xếp hạng Spearman đơn biến (univariate.csv; rho toàn bộ / rho riêng phần sau khi trừ gidx+hard / rho trong slot):

| Đặc trưng | rho | rho riêng phần | rho trong slot | Độ dốc / đơn vị (toàn bộ) |
|---|---|---|---|---|
| runs_total (tổng số khúc cùng loại liên tiếp, cả initial+incoming) | 0.410 | 0.337 | 0.332 | +1.45 điểm / run |
| n_flowers (= capacity x targetCups) | 0.403 | 0.323 | 0.349 | +1.35 / hoa |
| flowers_init (hoa trên dây lúc đầu) | 0.370 | 0.251 | 0.326 | +2.59 / hoa (trong slot +5.0) |
| hidden_mean_depth_from_tail | 0.338 | 0.224 | 0.151 | +17.1 / 1 bậc sâu |
| capacity | 0.337 | 0.211 | 0.087 | +12.5 / 1 |
| runs_total_init | 0.313 | 0.173 | 0.183 | +2.4 / run |
| runs_per_rope | 0.303 | 0.201 | 0.055 | +14.4 |
| mean_types_per_rope | 0.275 | 0.200 | 0.126 | +17.6 / loại |
| fill_ratio (hoa đầu / tổng sức chứa các dây đầu) | 0.234 | 0.172 | 0.340 | +174 / 1.0 (tức +1.7 / 1%) |
| frac_pots_init (chậu ở initial / targetCups) | -0.202 | -0.254 | -0.345 | -69 |
| mono_init (số dây đã đơn sắc lúc đầu) | -0.160 | -0.150 | -0.146 | -6.2 / dây |
| has_lock | -0.201 | -0.091 | +0.121 | -8.2 |

Nhóm trung bình (compact_out.txt): capacity 4 / 5 / 6 có điểm TB 28.1 / 41.3 / 52.6; n_init 6 vs 7: 44.2 vs 36.7; flowers_init (18,21] 33.5, (21,24] 46.9, (24,27] 42.5, (27,30] 71.2 (n=21); n_flowers (45,50] 30.0, (55,60] 48.7, >65 61.2; hard 52.3 vs normal 37.3.

Hồi quy OLS gộp, SE cluster theo slot (compact_out.txt M4, final.py): với flowers_init, targetCups, capacity, n_init, lock_count_sum, hidden_total, runs_total_init, mono_init cùng mô hình, R² = 0.371. Hệ số: flowers_init +6.5, targetCups +6.4, lock_count_sum +3.3, hidden_total +0.79, runs_total_init +2.3, mono_init -4.7 (mỗi dây đơn sắc ban đầu), capacity -27.9 và n_init -44.3 (hệ số này mang dấu âm giả do cộng tuyến với flowers_init, xem Inferences). Phiên bản ít cộng tuyến hơn (final2.py, R² 0.383, SE cluster): fill_ratio +221.8 (tức +2.2 điểm cho mỗi +1% độ đầy), targetCups +5.6/cốc, n_init -16.6/dây, lock_count_sum +4.1, hidden_total +0.82, hard +9.0, gidx +0.086 / màn, mono_init -3.7, capacity +5.8 (p=0.08).

Permutation importance GB (tăng MAE khi xáo trộn, perm_importance_gb.csv): flowers_init 0.79, runs_total_init 0.46, flowers_inc 0.43, fill_ratio 0.41, lock_count_max 0.40, hidden_total 0.27, lock_count_sum 0.22, runs_total 0.21, free_space 0.18. Importance trải đều trên nhiều đặc trưng tương quan nên con số từng cái nhỏ. GB chỉ top-3 đặc trưng R² 0.27, top-8 0.40, top-12 0.41, top-20 0.43: bão hòa quanh 0.41-0.43.

Cụm dư thừa (tương quan Spearman, analyze_out.txt): runs_total ~ n_flowers 0.90 (cả hai ~ capacity x targetCups); runs_per_rope ~ runs_per_rope_init 0.86 ~ capacity 0.83 ~ init_pot_flower_depth_mean 0.82; entropy_rope_mean ~ mean_types_per_rope 0.97; flowers_init ~ runs_total_init 0.83. capacity kéo theo độ sâu dây và "runs" nên nhiều đặc trưng "trộn loại" thực chất chỉ là capacity.

Nhiễu / không có tín hiệu (|rho|<0.08 hoặc p>0.1, univariate.csv): n_types (rho 0.073, p=0.15), entropy_global, adj_mismatch_rate (0.03), pot_nearest_depth_mean/max, pot_matches_any_init/top_init, max_pot_mult, white_init_first, hidden_next_to_tail, tail_run_mean, free_space (-0.056 toàn bộ; nhưng -0.313 trong slot, xem mục 2), hidden_share (0.079).
Hằng số (không có thông tin): white_init = 1 ở cả 392 level; white_inc = 1 ở 389/392; frozen = 0; n_lock_inc = 0 (dây khóa chỉ nằm ở initial).

### Inferences
- Mức giải thích trần của input cấu trúc thuần túy là R² ~0.4-0.47 (MAE ~12), nên khoảng 55-60% phương sai còn lại đến từ thứ không thể hiện qua các đếm/độ sâu/độ rải này, nhiều khả năng là thứ tự cụ thể của hoa (khả năng giải của solver, số nước đi cần thiết, như README levelgen mục 5 cũng nói về chỉ số solver).
- capacity, n_init âm trong OLS nhiều biến là hiện tượng cộng tuyến: flowers_init = fill_ratio x capacity x n_init. Đừng đọc "tăng capacity làm dễ hơn". Dùng fill_ratio và số cốc làm trục chính thì capacity ~ +5 đến +10 điểm/đơn vị (dương hoặc ranh giới ý nghĩa).
- Số lượng hoa tổng (n_flowers/runs_total) quan trọng thật nhưng chủ yếu qua targetCups ở cùng capacity.

### Gaps
- Công thức `summaryScore` không biết nên không thể tách phần "thuần cấu trúc" khỏi phần tính từ solver/hành vi người chơi.
- Không có đặc trưng solver trong phạm vi nhiệm vụ này (nhà nghiên cứu khác lo).

## 2. Trong cùng slot, điều gì khác giữa biến thể điểm thấp và cao?

### Takeaway
Biến thể điểm cao hơn trong cùng slot chủ yếu có NHIỀU CỐC/HOA HƠN (targetCups, n_flowers, flowers_incoming), dây ban đầu ĐẦY hơn (flowers_init, fill_ratio), unlock-count dây khóa cao hơn và nhiều hoa ẩn hơn. Capacity, số dây, chậu trắng gần như đứng yên trong slot. Tuy vậy, chênh lệch cấu trúc nhỏ so với chênh lệch điểm: tier lv5 hơn default trung bình 46 điểm mà số hoa đầu chỉ hơn ~0.8.

### Cited Findings
- Phương sai giữa slot chỉ chiếm 32.6% tổng phương sai điểm (dùng slot làm biến giả: R² = 0.326, nhưng R² hiệu chỉnh 0.013 vì quá nhiều tham số). Phương sai trong slot = 283.8 so với tổng 421.3. Khoảng điểm trong slot (max-min) TB 38.4, trung vị 40.3 (paired_out.txt).
- Độ ổn định của đặc trưng trong slot (tỉ lệ slot nhiều biến thể mà giá trị đổi): capacity 3%, n_init 4%, white 0-1%, has_lock 8%, n_types 34%, lock_count_sum 34%; còn targetCups 77%, flowers_init 82%, hidden_total 77%, runs_total 97%. Số slot có capacity khác nhau giữa các biến thể = 3 / 118; n_init khác = 5 / 118; targetCups khác = 91 / 118 (compact_out.txt).
- 476 cặp trong slot (paired_univariate.csv; delta = biến thể điểm cao trừ điểm thấp): flowers_init cao hơn trong 206 cặp, thấp hơn 81 (Wilcoxon p<0.001, trung bình +0.49; độ dốc qua gốc +4.95 điểm/hoa); n_flowers 198 vs 84 (+1.82 hoa, +1.85 điểm/hoa); targetCups 191 vs 88 (+0.32 cốc, +8.8 điểm/cốc); lock_count_sum 89 vs 30 (+7.6/đơn vị); n_lock_init 75 vs 24 (+13.3/dây); hidden_total 185 vs 132 (+0.9 hoa, +1.27/hoa); runs_total 279 vs 158 (+1.87, +1.85/run); free_space 87 vs 195 (ít chỗ trống hơn ở biến thể khó, -6.7/hoa).
- Hồi quy hiệu ứng cố định theo slot, SE cluster (paired_out.txt): flowers_init +5.0 điểm/hoa (R² trong slot 0.081); + flowers_inc (+1.65/hoa): 0.192; + hidden_total (+1.0/hoa): 0.219; + lock_count_sum (+6.6/đơn vị): 0.292; thêm runs_total_init/n_init/capacity/mono_init: 0.385. Tức tập cấu trúc giải thích tối đa ~38% phương sai TRONG slot.
- Ví dụ slot lệch xa nhất (compact_out.txt), ch5 level 15: điểm 22.4 / 38.9 / 68.7 / 72.3 / 89.7 với targetCups 10/10/12/10/13, flowers_init 26/27/28/26/28, hidden_total 5/6/0/0/0, mono_init 0/0/1/1/1. Biến thể 72.3 có cấu trúc gần giống 22.4 (cùng 50 hoa, cùng 26 hoa đầu, ít hoa ẩn hơn) mà điểm cao hơn 50 điểm. ch3 level 7: điểm 4.5 / 28.5 / 51.9 / 71.0, chỉ khác targetCups 10/11/12/12 và flowers_init 21/21/21/22.
- Trung bình theo tier, mỗi tier ~ 51-125 uid (compact_out.txt, dist_out.txt): điểm default 20.1, lv2 33.1, lv3 43.6, lv4 59.2, lv5 66.5; trong khi flowers_init 22.6 / 23.6 / 23.4 / 23.7 / 23.4, n_flowers 53.9 / 55.5 / 56.2 / 57.0 / 58.4, lock_count_sum 0.67 / 0.71 / 0.85 / 1.01 / 0.98, hidden_total 6.3 / 6.9 / 7.0 / 7.9 / 7.7, runs_total_init 21.9 / 22.7 / 22.2 / 22.7 / 22.6. Tier một mình giải thích R² 0.713 (OLS trong mẫu), R² 0.708 / MAE 8.68 (CV); tier+gidx+hard CV R² 0.819 / MAE 6.84; tier + đặc trưng cấu trúc LR CV 0.802 / MAE 7.14 (không tốt hơn tier+gidx+hard); GB tier + tất cả đặc trưng CV 0.855 / MAE 6.22 (final.py).

### Inferences
- Tier là nhãn gắn với mức khó, nhưng nó đi kèm thay đổi cấu trúc rất nhỏ (các đếm trung bình gần như bằng nhau). Điều đó nghĩa là phần lớn khác biệt khó giữa tier nằm ở cách sắp xếp chi tiết, không ở số lượng. Đây là kết luận mạnh nhất về giới hạn của phân tích cấu trúc.
- Hệ số "trong slot" (không kiểm soát tier) phản ánh phần ảnh hưởng thật cộng với phần tương quan với tier (tier cao có thêm hoa, thêm khóa). Hệ số sau khi kiểm soát tier (mục 4) nhỏ hơn 3-5 lần, nên các hệ số "+5 điểm/hoa" là cận trên.

### Gaps
- Tag của cùng slot là mức người chơi, không biết nhà thiết kế điều chỉnh những gì giữa các tier ngoài cấu trúc; có thể bao gồm thứ tự hoa không được mô hình hóa ở đây.

## 3. Đòn bẩy thường giả định nào KHÔNG làm điểm dịch chuyển?

### Takeaway
Số loại hoa (n_types), số chậu trắng, số dây ở dạng đơn lẻ, và targetCups (khi so toàn bộ, không kiểm soát capacity) gần như không tương quan với điểm. Capacity đứng riêng có tương quan thật (khác với README levelgen mục 4 nói "gần như không tương quan") nhưng đó là hiệu ứng của "dây dài hơn nên có nhiều hoa và nhiều run", và không thể kiểm chứng thuần trong slot.

### Cited Findings
- n_types: rho 0.073 (p=0.15), nhóm 8 loại TB 38.8 vs 9 loại 41.3; CV LR R² 0.004 (chỉ n_types). Kiểm soát tier: hệ số -0.72 điểm/loại, p=0.68 (final.py). Trong slot n_types đổi ở 34% slot nhưng hệ số trong slot dương 12.8 (analyze), không ổn định theo spec. 329/392 level có đúng 9 loại nên thiếu phương sai.
- targetCups: rho 0.036 (p=0.47), CV R² -0.014; nhóm 10/11/12/13/14 cốc TB 40.3/39.7/43.3/39.7/26.6. Nhưng cùng capacity trong slot +8.8 điểm/cốc (paired) hoặc +5.6 (OLS gộp, kiểm soát capacity và fill), +1.4 sau khi kiểm soát tier (final2.py, p=0.003). targetCups bị che mờ vì tương quan -0.40 với capacity (cap lớn có ít cốc hơn).
- n_init (6 vs 7 dây): TB 44.2 vs 36.7, nhưng đó là hiệu ứng capacity (capacity 4 hầu như luôn đi với 7 dây: 67/68). Với capacity 5: n_init 6 -> 41.0, 7 -> 41.8 (compact_out.txt). Kiểm soát tier hệ số n_init = -4.65 (p=0.008) khi gộp mọi capacity; và -5.4 trong mô hình đầy đủ (p=0.001), nhưng cần cẩn thận vì chỉ 5/118 slot đổi n_init (không có thực nghiệm tự nhiên).
- Chậu trắng: white_init=1 ở 392/392, white_inc=1 ở 389/392; không có phương sai để đo. 2 level white_inc=0 có điểm TB 2.4 (tutorial); white_total hệ số +6.6 (p=0.48) sau khi kiểm soát tier (không có ý nghĩa).
- Dây khóa có hay không (has_lock): -8.2 điểm thô nhưng +4.8 (p=0.145) sau khi kiểm soát capacity, n_init, flowers, hidden, gidx, hard; -2.9 (p=0.15) khi kiểm soát thêm tier; độ lớn unlock count có ý nghĩa (xem mục 4).
- Các đặc trưng trộn kiểu "adj_mismatch_rate", entropy toàn cục, khoảng cách sâu của hoa cần cho chậu đầu (pot_nearest_depth_*): |rho| <0.04, p>0.5.
- Chỉ 0.4% phương sai (R² trong CV 0.004) giải thích bởi n_types và 1.5% bởi n_init riêng lẻ; capacity riêng lẻ 12.6%.

### Inferences
- Nếu nghĩ "thêm màu = khó hơn" thì dữ liệu này không ủng hộ; chỉ có 8 hoặc 9 loại, nên phạm vi quá hẹp để kết luận về 5 vs 12 màu.
- Số dây và capacity không nên được xem là núm vặn độc lập: chúng cùng quyết định độ đầy.

### Gaps
- Không đo được tác động của capacity thuần (hầu như không đổi trong slot: 3/118 slot) hay n_init thuần (5/118 slot): chỉ có bằng chứng quan sát chéo slot, dễ lẫn với "dòng thiết kế" của slot.

## 4. VỊ TRÍ và CÁCH PHÂN BỐ (hoa ẩn, dây khóa, chậu trắng, thứ tự incoming) tác động ra sao, đã kiểm soát số lượng?

### Takeaway
Số lượng hoa ẩn và độ lớn unlock-count của dây khóa có tác động nhỏ nhưng ổn định; còn VỊ TRÍ/PHÂN BỐ chỉ có tác động yếu hơn nhiều: hoa ẩn nằm sâu từ đuôi (ở dây incoming) cộng điểm một chút, hoa ẩn rải trên nhiều dây hơn cộng điểm, hoa ẩn dính liền nhau trừ điểm; sau khi kiểm soát tier hầu hết hiệu ứng phân bố mất ý nghĩa. Vị trí dây khóa và vị trí chậu trắng không có tác động đo được.

### Cited Findings
Mẫu: 283 level có hoa ẩn (hidden_total>0). Các hệ số dưới đây là điểm summaryScore trên 1 đơn vị đặc trưng, kiểm soát hidden_total, capacity, gidx, hard (cột `b_ctrl_count`), thêm tier (`b_ctrl+tier`), và hiệu ứng cố định theo slot (`b_slotFE`; kiểm soát hidden_total); nguồn hidden_dist.csv, dist_out.txt. "pts/SD" = điểm khi tăng 1 độ lệch chuẩn (cột b_ctrl_count).

| Đặc trưng hoa ẩn | mean (SD) | b kiểm soát số lượng (p) | pts/SD | b + tier (p) | b slotFE (p) |
|---|---|---|---|---|---|
| Độ sâu TB từ đuôi, tất cả (h_all_depth_tail) | 2.27 (0.44) | +6.7 (0.013) | +2.9 | +2.1 (0.14) | +9.8 (0.040) |
| Độ sâu TB từ chậu (h_all_depth_pot) | 1.39 (0.43) | -6.8 (0.006) | -2.9 | -1.9 (0.14) | -7.3 (0.088) |
| Độ sâu từ đuôi, hoa ẩn ở INCOMING | 2.37 (0.54) | +6.1 (0.001) | +3.3 | +2.7 (0.023) | +8.6 (0.009) |
| Độ sâu từ đuôi, hoa ẩn ở INITIAL | 2.12 (0.67) | +0.36 (0.85) | +0.2 | -0.4 (0.60) | +0.7 (0.81) |
| Số dây chứa hoa ẩn (h_n_ropes) | 7.2 (1.9) | +4.25 (<0.001) | +8.0 | +0.85 (0.16) | +4.9 (0.039) |
| Độ rải = số dây / số hoa ẩn (h_spread) | 0.76 (0.12) | +38.5 (<0.001) | +4.6 | +4.0 (0.43) | +42.3 (0.039) |
| HHI dồn vào ít dây (h_hhi) | 0.165 (0.049) | -54.9 (0.17) | -2.7 | -4.1 (0.80) | -80 (0.20) |
| Hoa ẩn liền nhau (h_adjacent_share) | 0.135 (0.111) | -28.4 (0.002) | -3.2 | 0.0 (1.0) | -41 (0.012) |
| Độ dài TB khúc ẩn liên tiếp | 1.18 (0.17) | -21.8 (<0.001) | -3.7 | -1.2 (0.69) | -31.8 (0.001) |
| Số hoa ẩn ngay dưới đuôi (độ sâu 1) | 3.0 (1.6) | -1.8/hoa (0.020) | -2.9 | -0.5 (0.22) | -2.0 (0.13) |
| Số hoa ẩn sâu >=3 từ đuôi | 3.9 (2.2) | +1.7/hoa (0.009) | +3.8 | +0.6 (0.12) | +2.5 (0.024) |
| Tỉ lệ hoa ẩn ở nửa đáy dây (nửa gần đuôi) | 0.29 (0.15) | -15.1 (0.017) | -2.2 | -5.4 (0.10) | -12.8 (0.24) |
| Tỉ lệ hoa ẩn nằm ở initial | 0.35 (0.16) | -2.0 (0.78) | -0.3 | -0.2 (0.93) | -6.4 (0.65) |

So sánh phân tầng cùng số lượng khác phân bố: chia theo (capacity) x (hidden_total in [1-6], [7-9], [10-12], >12), trong mỗi tầng tách theo trung vị của đặc trưng phân bố rồi lấy hiệu điểm "nhóm cao - nhóm thấp" có trọng số theo cỡ tầng (dist_out.txt, 9-10 tầng, count TB hai nhóm bằng nhau ~9.7-10.2):

| Đặc trưng phân bố (cùng số hoa ẩn, cùng capacity) | Nhóm cao vs thấp (giá trị TB) | Chênh điểm |
|---|---|---|
| Độ sâu từ đuôi lớn hơn | 2.54 vs 2.01 | +2.7 |
| Gần chậu hơn (h_all_depth_pot cao) | 1.70 vs 1.16 | -4.1 |
| Rải rộng hơn trên nhiều dây (h_spread) | 0.83 vs 0.69 | +2.9 |
| Liền nhau nhiều hơn | 0.23 vs 0.06 | -2.0 |
| Số dây chứa hoa ẩn nhiều hơn | 9.1 vs 7.3 | +3.9 (7 tầng) |
| Nhiều hoa ẩn ngay dưới đuôi (độ sâu 1) | 4.4 vs 2.2 | -3.8 |
| Nhiều hoa ẩn sâu >=3 | 5.5 vs 3.1 | +4.6 |
| Dồn vào ít dây (HHI cao) | 0.19 vs 0.15 | -7.1 |
| Tỉ lệ ở nửa đáy dây nhiều | 0.42 vs 0.20 | -4.7 |
| Tỉ lệ hoa ẩn ở initial cao | 0.49 vs 0.25 | -0.9 |

Số lượng hoa ẩn (kiểm soát capacity, n_init, targetCups, flowers_init, gidx, hard): có hoa ẩn so với không có +5.8 điểm (p=0.003). Mỗi hoa ẩn thêm +0.77-0.83 (p<0.001); sau khi kiểm soát tier còn +0.29 đến +0.35 (p<=0.007) (final.py, final2.py). Hoa ẩn ở INCOMING và INITIAL: mỗi hoa +1.5 (p=0.014, 0.015) sau khi kiểm soát hidden_total/capacity; khoảng +0.4-0.45 sau tier (p~0.07). Số hoa ẩn nằm trong dây khóa: không có ý nghĩa (-2.6, p=0.15).

Dây khóa (147 level có khóa; lock_count_sum: 1 -> 58 level, 2 -> 40, 3 -> 31, 4 -> 6, 5 -> 5, 6 -> 7; không có khóa trong incoming) (dist_out.txt, `b_ctrl` = kiểm soát capacity, gidx, hard; `b_ctrl+tier+load` thêm flowers_init, hidden_total, tier):

| Đặc trưng | b_ctrl (p) | b + tier + tải (p) | b slotFE (p) |
|---|---|---|---|
| lock_count_sum (tổng count mọi dây khóa) | +5.5 (<0.001) | +2.1 (0.007) | +7.0 (<0.001) |
| lock_count_max | +8.7 (<0.001) | +4.3 (<0.001) | +10.7 (0.003) |
| lock_count_mean | +12.8 (<0.001) | +6.9 (<0.001) | +16.7 (0.001) |
| lock_count_rel (tổng count / targetCups) | +64.6 (<0.001) | +26.4 (0.004) | +82.6 (<0.001) |
| n_lock_init (số dây khóa) | +5.5 (0.007) | +0.5 (0.64) | +13.0 (0.001) |
| lock_pos_mean (chỉ số dây khóa, 0 = trái) | -0.25 (0.88) | -0.8 (0.35) | -1.4 (0.58) |
| lock_needed_flower_share (tỉ lệ hoa của loại chậu mở sẵn nằm trong dây khóa, mean 0.20) | +12.6 (0.38) | +6.6 (0.50) | +0.4 (0.99) |
| lock_white (dây khóa là chậu trắng, 7.5%) | -1.7 (0.78) | +0.6 (0.77) | +2.0 (0.84) |

Điểm TB theo (n_lock_init, lock_count_sum): (0,0) 43.8 (n=245); (1,1) 25.7 (58); (1,2) 38.8 (26); (2,2) 35.1 (14); (2,3) 28 level 45.9; (2,5) 46.3 (5); (2,6) 68.2 (5); (3,6) 39.7 (2); (4,4) 43.1 (5) (compact_out.txt, dist_out.txt). Thang giá trị count đóng vai trò chính: count 1 = dễ (25.7), count 6 = khó (60.1 theo lock_count_sum). Có khóa nói chung không có hiệu ứng riêng (+4.8, p=0.145 không tier; -2.9, p=0.15 có tier).

Chậu trắng và thứ tự xuất hiện chậu/hoa (dist_out.txt, kiểm soát capacity, n_init, targetCups, flowers_init, gidx, hard; hệ số slotFE trong ngoặc):
- Vị trí chậu trắng ở initial (luôn ở dây đầu: 0.054 TB chỉ số, 98% ở vị trí 0): hệ số -0.9 (p=0.61), có tier -2.6 (p=0.053); không đủ phương sai để kết luận.
- Vị trí chậu trắng trong hàng chờ incoming (tương đối n_incoming): 0.85 +/- 0.023 (luôn gần cuối), b +24 (p=0.81); độ dài dây của chậu trắng incoming (white_inc_len, TB 3.86): rho -0.27, b -5.0 (p=0.007), b có tier -1.1 (p=0.35), slotFE -8.6 (p<0.001), tức dây trắng incoming ít hoa hơn gắn với điểm cao hơn trong slot, nhưng biến mất sau tier.
- "Lag" giữa chậu và hoa (feat2.py: so sánh lúc xuất hiện của chậu với lúc hoa cùng loại xuất hiện): pot_flower_late_share (tỉ lệ hoa của chậu đến muộn hơn chậu): b +54.6 (p=0.09), b có tier +16.4 (p=0.30), slotFE +1.8 (p=0.95), không rõ. pot_first_flower_lag_mean: rho -0.254, nhưng b ctrl -0.5 (p=0.90); slotFE -19.6 (p<0.001).
- Tỉ lệ loại chậu incoming có hoa ở initial (inc_pot_flower_in_init_share): rho 0.145, ctrl +1.3 (p=0.83), slotFE +21.9 (p=0.03).
- Chậu trùng loại trong initial (init_pot_dup): rho -0.194, ctrl +0.27 (p=0.89), slotFE -2.4 (p=0.45): vô tác dụng khi kiểm soát.
- Dây đơn sắc ban đầu (mono_init): -3.1 (p=0.067) đến -4.7 (p=0.004), nhưng sau tier -0.3 đến -0.8 (p>0.3).

### Inferences
- Dạng phân bố có thể mô tả được là "hoa ẩn nằm sâu hơn từ đuôi, rải ra nhiều dây, không liền nhau thì điểm cao hơn một chút". Chiều này NGƯỢC trực giác của đề bài (hoa ẩn dồn ở đáy dễ hơn hoa ẩn rải xen kẽ): về mặt dấu thì khớp ("dồn" dễ hơn: HHI cao -7.1; liền nhau -2.0 đến -3.2; nửa đáy -4.7), nhưng độ lớn nhỏ: ±2 đến ±5 điểm cho 1 SD, trong khi sai số mô hình MAE là 12.
- Hoa ẩn ở incoming, sâu hơn từ đuôi, là nhóm duy nhất vẫn có ý nghĩa sau khi kiểm soát tier (p=0.013-0.023), +2.7 điểm cho mỗi +1 bậc sâu từ đuôi (~ +1.4 điểm / SD). Hoa ẩn ở initial không cho thấy hiệu ứng phân bố nào.
- Không thể xác lập "phần thưởng/phạt" chính xác cho từng kiểu phân bố: các hiệu ứng phân bố tương quan mạnh với nhau (dưới 10 điểm khác biệt, nhiều biến cùng đo "độ rải"), SE rộng, và biến mất sau tier. Mức đáng tin cậy nhất: +0.3 đến +0.8 điểm/hoa ẩn; +2 đến +7 điểm mỗi đơn vị count của dây khóa (tổng) và mỗi đơn vị count lớn nhất (+4 đến +11); độ sâu từ đuôi +2 đến +7 / bậc; độ rải +4 / 0.1 đơn vị ... (ước tính thô, không nên dùng độc lập).

### Gaps
- Phân biệt hoa ẩn "dồn ở đáy rồi lộ ra ngay" và "rải xen kẽ" không thể tách hoàn toàn khỏi số lượng vì hai biến cùng đổi; cỡ mẫu mỗi tầng nhỏ (9-10 tầng, ~5-30 level mỗi nửa tầng).
- Không có đặc trưng đo lúc người chơi thực sự thấy hoa ẩn lộ ra (cần mô phỏng nước đi).
- Không đo được hiệu ứng "dây khóa chứa loại hoa cần sớm hay muộn" một cách trực tiếp: dùng xấp xỉ lock_needed_flower_share (không có ý nghĩa), chưa dùng thứ tự nước đi.

## 5. Núm vặn thực tế để tăng/giảm ~10 điểm

### Takeaway
Khoảng +10 điểm cần dịch chuyển nhiều núm cùng lúc: ~+2 hoa trên dây ban đầu (hoặc ~+4% độ đầy), hoặc +1-2 cốc ở cùng capacity, hoặc unlock-count tổng +2-3. Mọi ước tính là "không kiểm soát tier"; nếu giữ thiết kế tier nguyên (tức chỉ thay đổi cấu trúc trong cùng tier) thì hiệu ứng chỉ còn 20-35% giá trị đó, và để thay đổi 10 điểm bằng cấu trúc thuần là bất khả thi chỉ bằng một núm.

### Cited Findings
Ước tính hệ số cho +1 đơn vị (nguồn: final.py, final2.py, paired_out.txt, dist_out.txt; cột "có tier" là sau khi kiểm soát tier + hard + gidx và các biến cấu trúc khác):

| Núm | +1 đơn vị, không tier (OLS gộp, cluster) | Cùng slot FE | Có tier | Số đơn vị để ~ +10 điểm (không tier / có tier) |
|---|---|---|---|---|
| Độ đầy dây đầu +1% (fill_ratio +0.01) | +2.2 (p<0.001) | | +0.47 (p=0.009) | 4.5% / 21% |
| flowers_init +1 hoa (cùng cap, n_init) | +6.5 (p<0.001) (final.py) | +5.0 | +1.6 (p=0.007) | 1.5 hoa / 6 hoa |
| targetCups +1 cốc (cùng capacity; cũng thêm capacity hoa vào incoming) | +5.6 đến +6.4 | +8.8 (cặp) | +1.4 (p=0.003) | 1.6-1.8 cốc / 7 cốc |
| lock_count_sum +1 (tổng count của các dây khóa) | +3.3 đến +4.1 (p<0.001) | +7.0 | +1.3 (p=0.011) (cap 0.58 cho tier + nhiều biến, p=0.33) | 2.5-3 / 8 |
| lock_count_max +1 (dây khóa nặng nhất) | +8.7 (kiểm soát cap, gidx, hard) | +10.7 | +4.3 (p<0.001) | 1.2 / 2.3 |
| hidden_total +1 hoa ẩn | +0.77 đến +0.82 | +1.0 đến +1.3 | +0.29 đến +0.35 (p<=0.007) | 12-13 hoa ẩn / 30 |
| runs_total_init +1 (khúc đổi loại ở dây đầu) | +2.3 (p=0.001) | +1.6 | +1.5 đến +1.9 (p~0.001) | 4.5 / 5-7 |
| mono_init +1 dây đơn sắc ban đầu | -3.7 đến -4.7 | -5.1 | -0.8 (p=0.32, không ý nghĩa) | giảm 2-3 dây / không đáng tin |
| n_init +1 dây (cùng capacity, độ đầy) | -16.6 (final2.py) | không kiểm | -5.4 (p=0.001) | không dùng làm núm: 5/118 slot đổi |
| Chuyển Normal -> Hard | +9.0 (p=0.019) | 0 (hard không đổi trong slot) | +12.2 (p<0.001) | 1 |
| capacity +1 | +5.8 (p=0.08, final2.py), hoặc +10-12 (đơn biến) | không đủ thông tin | +3.7 (p=0.064); +10.3 (chỉ tier+capacity, p<0.001) | không dùng làm núm đơn lẻ |
| tier +1 bậc (lv) | | | +10.1 / +21.1 / +34.7 / +42.8 điểm so với default (lv2..lv5) | không phải input cấu trúc |

Độ không chắc: SE cluster của hệ số thường +/- 15-30% cho các núm chính; MAE mô hình 12-13 điểm, nên mỗi giá trị trên là kỳ vọng trung bình cho nhiều level, không bảo đảm cho từng level. Lasso giữ lại 28 đặc trưng, dấu không ổn định cho lock_flowers (-6.4) so với lock_count_sum (+11.1) cho thấy cặp này đa cộng tuyến.

### Inferences
- Núm an toàn để tăng độ khó đồng thời nhiều cách, theo thứ tự hiệu quả: (1) tăng độ đầy ban đầu (nhiều hoa hơn trên dây đầu, ít chỗ trống) và/hoặc thêm cốc cùng capacity; (2) tăng unlock-count của dây khóa (count 1 -> 3 là +4 đến +14 điểm); (3) tăng số run (xen loại hoa nhiều hơn trong dây đầu, tránh dây đơn sắc ban đầu); (4) thêm hoa ẩn (rẻ nhất về điểm: ~+0.3-0.8 mỗi cái, nên chỉ để tinh chỉnh ±1-3 điểm), đặt chúng ở incoming, sâu từ đuôi, rải nhiều dây; hạ độ khó thì ngược lại.
- Không nên dùng n_types, số chậu trắng, vị trí dây khóa làm núm chỉnh điểm.
- Cần bổ sung chỉ số solver (win_rate, branch, expanded) để dự đoán phần phương sai cấu trúc không giải thích được, như README levelgen mục 5.

### Gaps
- Không thể kiểm chứng nhân quả vì dữ liệu quan sát: các hệ số "cùng slot" lẫn với hiệu ứng tier.
- Không có dữ liệu cho miền ngoài quan sát (capacity <4 hoặc >6, n_types ngoài 8-9, targetCups ngoài 10-14, lock count >6).
