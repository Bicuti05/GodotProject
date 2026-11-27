# Bot greedy có nhiễu đo độ khó tốt nhất

**Kết luận chính:** độ khó `summaryScore` của Sort Streak được quyết định chủ yếu bởi **tải của level** (số hoa trên dây lúc đầu/độ đầy, số cốc `targetCups`, `capacity`) và **sự có mặt cùng độ lớn `count` của dây khóa**; hoa ẩn, dù ở vị trí nào, chỉ là núm tinh chỉnh ±1–3 điểm. Các đếm cấu trúc chỉ giải thích **32% (tuyến tính) đến 41–47% (cây)** phương sai (MAE 12–13,5 so với baseline 17), còn bot greedy có nhiễu (eps-greedy hoặc softmax trên `JuiceSolver.move_score`) đạt **rho = −0,84 (CI95 −0,87..−0,79), R² cv 0,66 chỉ với một đặc trưng, 0,70 với công thức 5 đặc trưng (MAE 8,8)**. Vì vậy `summaryScore` hành xử như một "người chơi mô phỏng có heuristic nhưng mắc lỗi", không như thước đo độ sâu tìm kiếm của solver (rho chỉ 0,34–0,44). Với Sweet Rope, nên chọn "núm" theo bảng hiệu ứng bên dưới rồi **đo bằng bot greedy-noisy**, không bằng công thức `expanded/branch/win_rate` cũ (R² 0,30). Dung sai ±3 của README **không đạt được cho từng level**: sai số dư sd 11,2 điểm, chỉ khoảng 1/5 ứng viên "ước lượng đúng mục tiêu" thật sự nằm trong ±3. Về hoa ẩn: không có bằng chứng nào, theo hướng nào, về cảm nhận của người chơi thật, vì mọi bot hiện có đều thấy loại hoa thật; cần bot "mù một phần" hoặc playtest. Các con số "sau khi kiểm soát nhãn bản" nên đọc thận trọng vì nhãn bản (tier) là một bin của chính `summaryScore`.

Phân loại bằng chứng dùng xuyên suốt: **[QS] quan sát** (tương quan trên 392 level, công thức `summaryScore` là hộp đen, không có dữ liệu người chơi thật); **[TN] thí nghiệm có đối chứng** (sửa đúng một đầu vào của level "sạch", đo bằng bot/solver, 9–17 cặp mỗi biến thể); **[VH] văn liệu** (đa số kinh nghiệm truyền miệng, chưa có chỉ số nào được xác nhận cho sort puzzle). Nhãn tin cậy: Cao / TB / Thấp.

## Cấu trúc giải thích 32–47% phương sai; tier giải thích 71% nhưng là phép tautology

Trên 392 level duy nhất (118 slot có ≥2 biến thể), mô hình cấu trúc với `GroupKFold` theo slot cho R² cv **0,32** (tuyến tính, 8 đặc trưng chính), **0,37–0,41** (Lasso/GB, 66 đặc trưng) và **0,47** (GB, thêm ~30 đặc trưng phân bố hoa ẩn/khóa/chậu), MAE 12,1–13,5 so với baseline 17,05 [CT]. Bão hòa quanh 0,41–0,43 dù tăng số đặc trưng. Các đặc trưng đơn biến mạnh nhất (Spearman, [CT]) là `runs_total` 0,41, `n_flowers` 0,40, `flowers_init` 0,37, độ sâu hoa ẩn từ đuôi 0,34, `capacity` 0,34; số loại hoa, số chậu trắng (hằng 1 ở 392/392), vị trí khóa, độ trộn kề nhau đều không tín hiệu.

Nhãn bản (default, lv2..lv5) một mình cho R² 0,71 (CV 0,708, MAE 8,7) và cùng gidx/hard là 0,82 [CT]. Con số này **không** nên đọc là "nhãn bản giải thích 71% độ khó". Ghi chú solver cho thấy tier là **bin của chính summaryScore** (tier 1: 0–20,4; tier 2: 20,5–35,4; tier 3: 35,5–50,4; tier 4: 50,5–69,4; tier 5: 70,5–85,4; tier 6: 86,7–89,7; Spearman tier–score 0,976) [SV]. Hệ quả: (i) 71% là cận tautology, không phải năng lực giải thích; (ii) mọi hệ số "sau khi kiểm soát tier" là hệ số **có điều kiện trên một phiên bản thô của biến kết quả**, nên co về 0 một cách cơ học; chúng là cận dưới bảo thủ, không phải ước lượng nhân quả sạch. Quan sát đi kèm: giữa các tier của cùng slot, các đếm cấu trúc gần như không đổi (`flowers_init` 22,6/23,6/23,4/23,7/23,4 trong khi điểm 20/33/44/59/67), tức phần lớn chênh lệch nằm ở **thứ tự hoa chi tiết**, thứ mà đếm không nắm được [CT].

Bot thì nắm được. Bot greedy có nhiễu đạt R² cv 0,66 với một đặc trưng (`lw`, trung bình win-rate 4 cấu hình) và 0,70–0,75 khi gộp thêm chỉ số khác, MAE 8–9,45 so với baseline 16,9 [SV]. Hai ghi chú không mâu thuẫn mà đo cái khác nhau: cấu trúc tĩnh trong ghi chú solver chỉ cho R² 0,17–0,19 với 6 đặc trưng (nhẹ hơn tập 66 đặc trưng của ghi chú cấu trúc), còn bot mô phỏng chính thứ tự hoa. Phép kiểm tra rò rỉ cũng sạch: `GroupKFold` theo slot lệch < 0,01 R² so với KFold thường [SV]. Công thức cũ của README (`expanded`, `branch`, random `win_rate`) chỉ R² 0,28–0,33, MAE 13,4–14,4 [SV], đúng với R² 0,30 README tự nêu.

| Mô hình/đại lượng | R² cv | MAE | Loại bằng chứng | Tin cậy |
|---|---|---|---|---|
| Baseline (đoán trung vị/trung bình) | 0 | 16,9–17,05 | QS | Cao |
| Cấu trúc tuyến tính (flowers_init, targetCups, locks, hidden…) | 0,32–0,34 | 13,4–13,8 | QS | Cao |
| Cấu trúc GB + đặc trưng phân bố, không tier | 0,47 | 12,1 | QS | TB |
| Công thức README cũ (random win_rate, branch, expanded) | 0,28–0,33 | 13,4–14,4 | QS | Cao |
| Random bot `rand_win` đơn lẻ | 0,11–0,21 | 15,2–16,1 | QS | Cao |
| `g35_win` (eps 0,35, 1 seed) | 0,55 | 11,0 | QS | Cao |
| `lw` (TB 4 bot greedy-noisy) | 0,66 | 9,45 | QS | Cao |
| Công thức 5 đặc trưng (lw, ld, rand_win, beam, opt_len) | 0,70 | 8,76 | QS | Cao (trong mẫu 392; chưa kiểm ngoài mẫu) |
| 38 đặc trưng GBR | 0,75 | 7,99 | QS | Thấp (nguy cơ quá khớp, khó dùng) |
| Tier (bin của score) | 0,71 | 8,7 | tautology | Không dùng |

## Núm điều chỉnh: tải, cốc và khóa mạnh; hoa ẩn yếu; các nguồn bằng chứng khớp ở đâu và lệch ở đâu

Ba nguồn độc lập (hồi quy quan sát, so cặp trong slot, thí nghiệm nhiễu loạn) **khớp** ở các điểm sau. Tăng tải (thêm hoa trên dây đầu, thêm `targetCups` ở cùng `capacity`) là núm mạnh nhất: [QS] +5,0 đến +6,5 điểm mỗi hoa đầu (+2,2 mỗi +1% độ đầy) và +5,6 đến +8,8 mỗi cốc ở cùng capacity, còn +1,4 mỗi cốc và +1,6 mỗi hoa sau kiểm soát tier; [TN] thêm một cốc (kèm `capacity` hoa) làm cups_frac của bot ngẫu nhiên giảm **−0,203±0,038, 100% level khó hơn**, nền 0,221 [CC]. `capacity`+1 (cân bằng hoa giữ nguyên) cho −0,198±0,038 [CC]; quan sát cho +5,8 (p=0,08) đến +10–12 (đơn biến) nhưng chỉ có 3/118 slot đổi capacity nên [QS] không tách được hiệu ứng thuần [CT]. Dây trống thêm vào (đỗ xe) là núm **làm dễ** mạnh nhất: +0,156±0,023 cf, 100% level; ở [QS], hệ số `n_init` âm (−5,4 sau tier, −16,6 trước tier) trước đây bị gọi là "dấu âm giả do cộng tuyến", nhưng thí nghiệm đối chứng cho thấy ít nhất một phần là thật (thêm dây trống thì dễ). Phần này là suy luận tổng hợp của báo cáo, hai ghi chú không tự nói như vậy.

| Núm (+1 đơn vị) | [QS] không tier / có tier (điểm) | [TN] Δcf bot ngẫu nhiên (n cặp) | Rủi ro UNWINNABLE | Tin cậy hướng / độ lớn |
|---|---|---|---|---|
| `flowers_init` +1 hoa (hoặc +1% độ đầy) | +5,0..6,5 / +1,6 (+2,2 / +0,47 mỗi 1%) | chưa kiểm riêng | thấp (chưa đo) | Cao / TB |
| `targetCups` +1 (cùng capacity) | +5,6..8,8 / +1,4 | −0,203±0,038 (14) | 0% (unres 0,75) | Cao / TB |
| `capacity` +1 (cân hoa) | +5,8..12 / +3,7 (không tách được) | −0,198±0,038 (15) | 6% (unres 0,90) | Cao hướng / Thấp độ lớn |
| Dây khóa, có/không, 1 dây | −2,9..+4,8 (p=0,15, không ý nghĩa) | −0,175±0,034 (14) | 0–6% | **Mâu thuẫn QS/TN** (xem dưới) |
| `count` khóa (tổng +1 / dây nặng nhất +1) | +3,3..4,1 / +1,3; +8,7 / +4,3 | count 1→4: −0,175 → −0,192 (gần phẳng); unres 0,43→0,84 | tăng theo count | TB |
| Số dây khóa 2 / 3 | n_lock_init: +5,5 / +0,5 (p=0,64) | −0,172..−0,221 | **31–53% / 94% UNWINNABLE** | Cao rủi ro |
| Số đoạn đổi loại (`runs_total_init`) +1 | +2,3 / +1,5..1,9 | shuffle/cross-swap: −0,013..−0,040 | 0% | TB |
| Dây đơn sắc ban đầu (`mono_init`) +1 | −3,7..−4,7 / −0,8 (p=0,32) | chưa kiểm | không | Thấp |
| Thêm 1 dây trống | `n_init` +1: −16,6 / −5,4 (cộng tuyến, có thật một phần) | **+0,156±0,023 (11, 100% dễ)** | 0% | Cao |
| Số loại hoa +1 / −1 / −2 | n_types: không tín hiệu (rho 0,07; 329/392 level có đúng 9 loại) | split −0,142±0,023; merge1 +0,043; merge2 +0,114±0,027 | 0% | TB (TN) / Thấp (QS, thiếu phương sai) |
| Hoa ẩn +1 hoa (ngẫu nhiên) | +0,77..0,82 / +0,29..0,35 | 10/20/30%: −0,014/−0,021/−0,016 (không đơn điệu) | 0% | Cao nhỏ / Cao yếu |
| Băng + nắng (blockConnection, k=3) | không có trong 392 level builtin | −0,159±0,026 (15); k=3 thường −0,07..−0,08 | 0% (unres 0,47–0,75) | Thấp (chỉ TN, 1 họ bot) |
| Thứ tự `incoming` xáo/đảo | không đo | −0,083±0,035 / −0,090±0,041 (14) | 0% | Thấp-TB |
| "Hoa cần" xuống gần đuôi (`unbury3`) / lên gần chậu (`bury3`) | không đo trực tiếp | −0,043±0,015 (13/87) / +0,026±0,009 (86/14) | 0% | TB, nhỏ |
| Màn Hard | +9,0 / +12,2 | — | — | Cao (không phải núm cấu trúc) |

**Chỗ lệch 1: khóa.** [QS] nói "có khóa hay không" không có hiệu ứng riêng (−8,2 thô, +4,8 p=0,145 sau kiểm soát, −2,9 p=0,15 có tier) và độ lớn `count` mới có ý nghĩa (+2 đến +7 mỗi đơn vị, p<0,01); [TN] nói ngược lại: **sự có mặt** của khóa là toàn bộ hiệu ứng (−0,175 ở count=1, chỉ thêm −0,017 từ count 1 lên 4) nhưng DFS cạn khó dần theo count [CC]. Lý do hợp lý: bot ngẫu nhiên không "suy luận dài", nên count lớn chủ yếu làm khó cho người suy luận, không cho bot ngẫu nhiên; trong khi `summaryScore` (gần với bot greedy hơn) có thể nhạy hơn với count. Ngoài ra khóa do nhà thiết kế đặt có chọn lọc và đi kèm chỉnh sửa khác (bản gốc có sẵn hoa ẩn + khóa chỉ lệch cf −0,031 so với bản sạch, còn khóa chèn ngẫu nhiên −0,175), nên hệ số quan sát phản ánh thiết kế bù trừ, không phản ánh "chèn khóa vào level bất kỳ". Quan trọng hơn, [TN] dùng bot ngẫu nhiên (rho với score chỉ −0,52, r = −0,52 trên 15 base sạch), một thước đo kém hơn nhiều so với `lw` (−0,84). **Xếp hạng núm của [TN] cần chạy lại bằng `lw`** trước khi tin các chênh lệch giữa núm; hiện chỉ nên tin hướng và nhóm bậc (mạnh/nhẹ/≈0).

**Chỗ lệch 2: công thức README cũ.** [TN] chỉ ra số hạng `branch` áp đảo công thức (thêm một dây trống làm branch +5,8, ước lượng giảm khoảng 37 điểm), nên dùng nó để đo nhiễu loạn không có nghĩa [CC]. Điều này khớp với R² 0,30 của nó ở [SV]. Công thức đó đã bị thay thế (mục "Bản bổ sung").

**Chỗ lệch 3: số loại hoa và capacity.** [QS] không thấy n_types (không phương sai: 8–9 loại), [TN] thấy `split`/`merge` có tác dụng rõ. Hai điều không mâu thuẫn: dữ liệu không cho phép đo, thí nghiệm đo được nhưng bằng bot ngẫu nhiên. Với capacity, [QS] cảnh báo không đọc "capacity lớn làm dễ" (hệ số âm là cộng tuyến), và [TN] xác nhận capacity+1 làm khó.

**Tương tác (sub-additive, [TN], n=9–15).** Khóa 2 dây làm mất khoảng 72% lợi ích của dây trống (LP−L = +0,042 so với +0,150 riêng), hoa ẩn không cộng thêm gì khi đã có khóa hoặc dây trống (phần dư −0,002±0,003, +0,003±0,011); khóa + dây trống làm DFS 3000 nút không giải được ở 100% level (unres 1,00) dù UNWINNABLE 0%. Không cộng độ khó từ thành phần; kiểm lại từng tổ hợp bằng solver.

## Vị trí và phân bố hoa ẩn: quan sát nói gần đuôi dễ hơn một chút, bot không phân biệt được, người chơi chưa ai đo

**Quy ước dùng thống nhất (và chỗ ghi chú cấu trúc mâu thuẫn).** "Sâu từ đuôi" (`depth_tail`) = số hoa nằm giữa hoa ẩn và đuôi dây, 0 = đuôi; đuôi là đầu lấy hoa ra, chậu ở đầu kia, nên **sâu từ đuôi lớn = gần chậu = lộ ra muộn nhất**. "Độ sâu từ chậu" (`depth_pot`) = chỉ số, 0 = sát chậu, nên `depth_pot` lớn = gần đuôi. Hai biến đối xứng (TB 2,27 + 1,39 ≈ độ dài dây − 1), và bảng hệ số của ghi chú cấu trúc nhất quán: `depth_tail` +6,7 và `depth_pot` −6,8 đều nói "hoa ẩn gần chậu thì điểm cao hơn". Chỗ **không nhất quán là nhãn chữ** trong bảng phân tầng: hàng "Gần chậu hơn (h_all_depth_pot cao) 1,70 vs 1,16: −4,1" gán nhãn sai; `depth_pot` cao nghĩa là **gần đuôi**, và −4,1 chỉ cùng hướng với "gần đuôi dễ hơn". Dòng "Inferences" của ghi chú cũng nói hướng này "ngược trực giác" trong khi nhận là khớp dấu [CT]. Quy ước một nghĩa cho báo cáo này: **"đáy/gần đuôi" (shallow) = hoa ẩn sát đuôi, lộ sớm; "sâu/gần chậu" (deep) = lộ muộn.** Đây cũng là quy ước của [TN] (bottom = idx len−2; top = idx 0) và của thí nghiệm hoán vị ở [SV] (deep = index 0..h−1). Mơ hồ còn lại: chữ "bottom/đáy" trong câu hỏi của người dùng ("2 hoa ẩn ở đáy") có thể hiểu là sát đuôi hoặc sát chậu tùy cách vẽ dây trên màn hình; cần xác nhận với người dùng. Báo cáo này giả định "đáy" = sát đuôi, trùng quy ước của README.

**Quan sát [QS], 283 level có hoa ẩn.** Kiểm soát số hoa ẩn, capacity, gidx, hard: độ sâu từ đuôi +6,7 mỗi bậc (p=0,013; **+2,9 điểm mỗi SD**), độ rải (số dây/số hoa ẩn) +38,5 (p<0,001), hoa ẩn liền nhau −28,4 (p=0,002; −3,2 mỗi SD), số hoa ẩn ngay dưới đuôi −1,8 mỗi hoa (p=0,02). Phân tầng cùng số hoa và capacity: dồn vào ít dây (HHI cao) −7,1, nhiều ở nửa đáy dây −4,7, nhiều hoa sâu ≥3 +4,6, rải nhiều dây +3,9 [CT]. Chiều ghép lại: **hoa ẩn gần đuôi, dồn, liền nhau thì điểm thấp hơn vài điểm; sâu và rải thì cao hơn vài điểm**, ±2–5 điểm mỗi SD so với MAE mô hình 12. Sau kiểm soát tier hầu hết biến mất (p=0,14–1,0); chỉ còn độ sâu của hoa ẩn ở `incoming` (+2,7 mỗi bậc, p=0,023). Lưu ý rằng "biến mất sau tier" bị chi phối một phần bởi việc tier là bin của score (đã nói ở trên), nên không phải bằng chứng hiệu ứng bằng 0. Các đặc trưng phân bố tương quan mạnh nhau, hiệu ứng "độ sâu" và "hoa ẩn ở initial" (+0,36, p=0,85) không nhất quán giữa initial và incoming, và nhiều biến đo cùng một khái niệm "độ rải", nên không tách được thưởng/phạt riêng từng kiểu.

**Thí nghiệm bot [TN], cùng số hoa ẩn, đổi vị trí.** [CC]: n=3 dồn một dây, đáy − đầu Δcf +0,006±0,005; n=3 rải, đáy − đầu −0,024±0,008 (81% level); n=2 liền nhau − xen kẽ ở đáy −0,004±0,005, ở đầu +0,004±0,007; ẩn 10/20/30% không đơn điệu. [SV] (48 level, hoán vị `?` giữ nguyên loại hoa, deep/alt/shallow): mọi win-rate (random, greedy), `opt_len` và `rand_win` **không đổi** (|Δ| ≤ 0,02, p>0,15); chỉ `beam_w` (deep − shallow +1,28, p=0,011) và các đại lượng đo trực tiếp vị trí (`h_depth`, `p_hburden`) phân biệt; alt ≈ shallow trên mọi chỉ số. Hướng của [TN] (rải ở đáy hơi khó hơn ở đầu) **ngược dấu** với [QS] (gần đuôi dễ hơn), nhưng độ lớn nhỏ (10–13% cf nền) và giữa hai thí nghiệm khác nhau bot (ngẫu nhiên so với greedy). Kết luận trung thực là cả ba nguồn đều **gần 0 về mặt thực chất**.

**Điều có thể và không thể kết luận về cảm nhận người chơi.** Có thể kết luận: (a) `summaryScore` nhạy rất yếu với vị trí hoa ẩn (≤ ±5 điểm mỗi SD, và không kiểm chứng được sau tier); (b) bot hiện tại không đo được gì về vị trí: `JuiceSolver._hint_type` trả `JuiceLevel.true_type`, nên bot và solver thấy loại thật của hoa ẩn, chỉ bị chặn việc dùng hoa ẩn làm đầu đoạn cắt [SV]. Không thể kết luận: câu hỏi "2 hoa ẩn ở đáy dễ hơn 2 hoa ẩn xen kẽ với người chơi" hoàn toàn chưa được trả lời, vì chi phí thông tin (bất định, trí nhớ về hoa chưa lộ) không có trong bot nào. Một dấu hiệu gián tiếp: phần dư của mô hình bot tương quan **+0,20** với số hoa ẩn ban đầu và màn Hard dư +3,8 điểm so với −1,1 của Normal [SV], hơi gợi ý score gốc phạt hoa ẩn nhiều hơn bot omniscient dự đoán, nhưng đây chỉ là tương quan.

Thí nghiệm giải quyết: (1) **bot mù một phần**: trong một bản sao riêng của solver, `_hint_type`/`move_score` coi hoa ẩn là loại chưa biết cho tới khi lộ (belief đều trên các loại còn thiếu theo cân bằng hoa), chạy trên bộ biến thể hoán vị của [SV] (`mkvariants.py`, deep/alt/shallow) với ≥150 level gốc để tăng mẫu; (2) playtest/telemetry thật: cùng một level với hai cách xếp 2 hoa ẩn (sát đuôi so với xen kẽ), đo tỉ lệ thắng, số lần thử, thời gian; để phát hiện chênh lệch 5 điểm phần trăm win-rate quanh 50% cần ước chừng ~1.500 lượt chơi mỗi nhánh (80% power, tính trực tiếp từ công thức hai tỉ lệ; con số này là của báo cáo, không có trong ghi chú).

## Bot greedy có nhiễu là chỉ số đáng tin nhất, nhưng sai số mỗi level vẫn khoảng ±9

**Thứ tự chỉ số theo độ bám score ([SV], n=392, CI bootstrap 300 lần).**

| Chỉ số | rho | Ổn định giữa 2 seed | Chi phí/level | Ghi chú |
|---|---|---|---|---|
| `lw` = TB win-rate 4 cấu hình greedy-noisy (e30, e45, e60, sm4) | **−0,839** (−0,871..−0,793) | n/a (đã trung bình) | ~9,3 s | khuyến nghị |
| softmax T=4 (`ge_sm4_win`) | −0,805 | 0,905 | ~2,3 s | một cấu hình, ổn định nhất |
| eps 0,45 (`ge_e45_win`) | −0,809 | 0,864 | ~2,3 s | một cấu hình, tương quan nhất |
| eps 0,3 / 0,6 | −0,771 / −0,799 | 0,884 / 0,836 | | |
| `g35_win` (eps 0,35, 30 ván, 1 seed) | −0,750 | | ~0,6 s | |
| greedy tất định (1 ván) | −0,335 | | rất rẻ | nên tránh |
| random win-rate (3 seed × 40) | −0,506 | 0,71–0,74 | ~3,5 s | quá mù |
| `beam_logw` (độ rộng beam tối thiểu thắng) | +0,436 | tất định | ~0,9 s | bổ trợ |
| `opt_len` | +0,397 | tất định | | bổ trợ |
| `log(1+expanded)` DFS (node_cap 4000) | +0,341 | tất định nhưng phụ thuộc thứ tự dây (|Δlexp| 0,78) | ~1,5 s | chỉ làm tín hiệu phụ |

Cách đọc: random quá mù (win-rate gần 0 ở level khó), solver/beam quá mạnh (hầu hết level giải được bằng beam rộng 1–8), bot greedy-noisy nằm đúng vùng giữa nên phân giải tốt khắp thang và không có sàn. Trong cùng slot, `lw` xếp đúng thứ tự **90,4% cặp (n=457) có chênh score ≥5**, `rand_win` 75,8%, `opt_len` 62,2% [SV]. Dư không tương quan với chapter (0,03), slot (0,07), tổng cốc (0,03), số khóa (0,03): mô hình bot xử lý khóa và tải ổn, ngoại trừ dư dương với hoa ẩn (+0,20). Khẳng định "summaryScore là điểm do bot mô phỏng" là **suy luận**, không chứng minh: bằng chứng chỉ là bot greedy khớp xếp thứ tự cặp rất tốt, solver mạnh khớp yếu. Từ dữ liệu này không phân biệt được "score do bot mô phỏng" với "score từ dữ liệu người chơi thật đã hiệu chỉnh".

**Sai số thực.** Công thức 5 đặc trưng `score_hat = 32,83 − 53,67·lw − 24,49·ld + 32,32·rand_win + 4,13·ln(beam_w) + 0,602·opt_len` có R² cv 0,70, MAE 8,76, sd dư 11,2, sai số tuyệt đối trung vị 7,4, phân vị 80% = 13,9, 90% = 17,8 [SV]. Lệch theo vùng điểm: MAE 9,6/8,8/9,9/8,1/6,3/7,3/14,2 cho các khoảng 0–10/10–20/20–30/30–40/40–55/55–70/70–95, bias (thực − dự đoán) −6,0/−1,8/−7,2/−4,5/+1,2/+5,9/+14,1: nghĩa là **co về trung bình**, level rất khó bị đánh giá thấp ~14 điểm. Tính từ sd 11,2 (giả định chuẩn): xác suất sai số thật ≤ ±3 chỉ khoảng 21%. Chọn ứng viên có ước lượng gần mục tiêu nhất trong 20 ứng viên **không giảm** sai số thật của ứng viên được chọn, vì sai số của chỉ số là sai số hệ thống của chính chỉ số. Vì vậy dung sai ±3 (±5 màn Hard) của README không đạt per-level; thực tế phân biệt đáng tin được các level cách nhau **≥ ~15 điểm** (hai độ lệch chuẩn dư 22 thì gần như chắc chắn, 15 điểm khoảng 1,3 sd), và phân biệt tốt hơn nhiều trong cùng một slot. Dùng để (a) xếp hạng tương đối giữa biến thể cùng khung, (b) loại ứng viên lệch xa (>15–20), (c) kiểm đường cong độ khó trung bình qua nhiều level (trung bình nhiều level giảm sai số ngẫu nhiên nhưng không giảm bias co-về-giữa).

**Điểm đặc biệt cho Sweet Rope.** Đường độ khó mục tiêu của README nằm ở vùng thấp (trung bình 5,6; 14,7; 21,0; 24,9). Đây đúng là vùng MAE ~9–10 và bias −6..−7 lớn so với biên độ mục tiêu: 20–30 là vùng sai số tệ nhất ngoài đuôi trên. Bảng hiệu chuẩn `lw` → score (TB; sd 7–16): lw (0,001–0,05] 69,5; (0,05–0,15] 58,3; (0,15–0,3] 44,2; (0,3–0,5] 30,6; (0,5–0,7] 20,0; (0,7–1] 10,2 [SV]. Vùng mục tiêu < 10 nằm trong ô lw > 0,7, nên mọi level ≥ 0,7 trông giống nhau với chỉ số này; cần thêm ván (hoặc tăng số seed) để nhìn rõ lw ở đuôi cao.

**Văn liệu cho thấy gì.** Ball Sort/Water Sort NP-complete và tìm lời giải ngắn nhất cũng NP-hard ([Ito et al., FUN 2022](https://arxiv.org/abs/2202.09495); [LIPIcs](https://drops.dagstuhl.de/entities/document/10.4230/LIPIcs.FUN.2022.16)); số ống rỗng đảm bảo giải được tăng theo n và dung lượng h (có instance cần k ≥ floor(19/64·min{n,h}); hằng số chưa đối chiếu bản cuối), phù hợp với việc `capacity`+1 làm khó và dây trống làm dễ [TN]. Với độ khó đo bằng solver, bằng chứng mạnh nhất nằm ở game khác: ở Sokoban/Rush Hour, độ dài lời giải ngắn nhất tương quan yếu với độ khó người chơi (Spearman ~0,47 hoặc r=0,30 tùy nguồn, hai số không khớp) trong khi chỉ số mô hình hóa quá trình tìm kiếm của người (xung đột, phân rã bài toán) tốt hơn (~0,69) ([Jarušek & Pelánek, FIMU-RS-2010-01](https://www.fi.muni.cz/reports/2010/abstract/FIMU-RS-2010-01.html); [STAIRS 2010](https://www.fi.muni.cz/~xpelanek/publications/stairs2010-final.pdf)); với Sudoku chỉ số đơn giản đạt Pearson 0,88, kết hợp 0,95 ([Pelánek, arXiv 1403.7373](https://arxiv.org/pdf/1403.7373)); với Nonogram, chỉ số SAT-solver không dự đoán độ khó cảm nhận ([arXiv 2608.23300](https://arxiv.org/pdf/2608.23300)). Kết quả của [SV] khớp mẫu hình này: `opt_len`, beam, DFS (thước đo độ sâu tìm kiếm) yếu (|rho| 0,3–0,44), mô phỏng người chơi có lỗi mạnh (−0,84). Chưa có nghiên cứu validate nào cho sort puzzle (cả hai phía), và **không tìm được xếp hạng định lượng của hidden/lock/frozen** [TL]. Con số win rate mục tiêu 70–80% (case Taxi Run; dưới 50% quá khó với hyper-casual) và benchmark retention là kinh nghiệm blog, không phải chuẩn ([PocketGamer.biz](https://www.pocketgamer.biz/how-saygames-uses-game-analytics-to-balance-difficulty-in-hybrid-puzzles-so-players-dont-leave--but-stay-and-pay), [SayGames](https://blog.say.games/posts/how-to-work-with-difficulty-in-hybrid-puzzles-so-players-dont-leave--but-stay-and-pay)); Columbia working paper cho thấy giảm độ khó thay thế IAP ngắn hạn nhưng tăng retention dài hạn ([PDF](https://business.columbia.edu/sites/default/files-efs/citation_file_upload/Personalized_games.pdf)). Toàn bộ văn liệu chỉ đọc qua snippet/tóm tắt tìm kiếm, **chưa đọc full text** vì WebFetch bị chặn [TL].

## Khuyến nghị cho bộ sinh level Sweet Rope

**Bối cảnh sử dụng.** Sweet Rope cùng engine, một bản duy nhất, mục tiêu theo thang `summaryScore`. Mọi hệ số ở trên là từ Sort Streak; hãy xem chúng là **giá trị khởi đầu** và kiểm bằng bot.

**Xếp hạng núm (tải/độ khó đổi nhiều nhất trước):**

| Hạng | Núm | Hướng và độ lớn (khoảng ±10 điểm cần…) | Tin cậy | Rủi ro giải được |
|---|---|---|---|---|
| 1 | Tải: hoa trên dây đầu / độ đầy; `targetCups` ở cùng capacity | Tăng = khó. ~+10 điểm: +1,5 hoa hoặc +1,6–1,8 cốc (QS thô, cận trên); nếu hiểu theo ước lượng co-về-tier: +6 hoa hoặc +7 cốc. TN: +1 cốc = nhóm hiệu ứng mạnh nhất | Cao hướng, TB độ lớn | thấp (0% UNWINNABLE), nhưng DFS 3000 nút không đủ xác nhận giải được (unres 0,75) |
| 2 | Dây trống thêm (đỗ xe), tức giảm độ đầy | Dễ rõ nhất, ổn định mọi mức (+0,156 cf, 100% level) | Cao | 0% |
| 3 | `capacity` ±1 (cân bằng hoa) | Tăng = khó; đặt theo chapter, không tinh chỉnh từng màn | Cao hướng, Thấp độ lớn | 6% (unres 0,9) |
| 4 | Dây khóa: có/không, rồi `count` | Có khóa = khó (TN −0,175 cf); `count` thêm +1,3..4,1/đơn vị (QS, nhưng mâu thuẫn TN). **Giới hạn: tối đa 1 dây khóa, count ≤ 3**, đặt hoa mở khóa ở dây không khóa | TB | **cao nếu ≥2 dây (31–53%), 3 dây 94% UNWINNABLE**; khóa + dây trống làm DFS bó tay |
| 5 | Số đoạn đổi loại / độ trộn dây đầu; "hoa cần" gần đuôi hay gần chậu | +1,5..2,3 điểm/đoạn (QS); unbury −0,043 cf, bury +0,026 cf (TN) | TB | 0% |
| 6 | Số loại hoa (merge/split) | merge2 +0,114 cf (dễ), split −0,142 cf (khó) (TN, bot ngẫu nhiên); QS không đo được | Thấp-TB | 0% |
| 7 | Băng + ánh nắng, thứ tự `incoming` | Khó hơn (−0,06..−0,16 cf, −0,08..−0,09 cf) | Thấp | 0% UNWINNABLE nhưng unres 0,47–0,75 |
| 8 | Hoa ẩn: **số lượng** | +0,3..0,8 điểm/hoa; cần ~12 hoa cho +10; Δcf ≈ −0,02, không đơn điệu theo liều; chỉ tinh chỉnh ±1–3 | Cao nhỏ | 0% |
| 9 | Hoa ẩn: **vị trí/phân bố** | Không dùng làm núm. Nếu buộc chọn: gần đuôi/dồn/liền = hơi dễ (QS, ±2–5/SD); TN không đồng thuận | **Rất thấp**; không biết cảm nhận người chơi | 0% |
| — | Không dùng: vị trí dây khóa, vị trí chậu trắng, chậu trắng trên dây đầu, `columnCaps` hai dây, hoán loại chậu `incoming` | ≈ 0 | TB (thiếu phương sai ở QS) | — |

**Quy trình đo.** (1) Chọn khung (cốc, độ đầy, capacity, số dây) theo mục 7 README; (2) sinh nhiều ứng viên, lọc `validate()` và solver (WINNABLE), nhớ rằng DFS trả UNKNOWN khi node_cap thấp; (3) lọc thô bằng một cấu hình greedy (eps 0,45, 30 ván, ~1–2 s); (4) tính `lw` (4 cấu hình × 2 seed × 30 ván, ~9,3 s/level) và hiệu chuẩn bằng bảng lw → score hoặc công thức 5 đặc trưng; (5) chọn ứng viên theo lw/điểm ước lượng, nhưng **báo cáo khoảng sai số ±9 (MAE) / ±14 (80%) / ±18 (90%)** cho từng level, không coi ±3 là đạt; (6) với level mục tiêu > 55, nhớ ước lượng bị đánh giá thấp thêm tới ~6–14 điểm. Chi phí: 200 màn × 20 ứng viên = 4000 level ≈ 16 giờ-core cho `greedy_ext` (~4 giờ trên 4 core), nên lọc thô trước.

**Chỉ số nên tin theo mục đích.** Xếp hạng/đường cong/loại ngoại lai: `lw`. Kiểm giải được: solver DFS/beam (không dùng `expanded` làm độ khó). Độ khó người chơi thật: chưa có chỉ số nào; không dùng bot omniscient cho hoa ẩn.

**Cần xác nhận khi có dữ liệu người chơi thật:** (a) hiệu chỉnh `lw` → tỉ lệ thắng/số lần thử thật, và kiểm xem "bot-like" giả thuyết có đúng; (b) A/B vị trí hoa ẩn (sát đuôi so với xen kẽ) theo cỡ mẫu ở trên; (c) hiệu ứng `count` khóa, vì [QS] và [TN] lệch; (d) win-rate mục tiêu theo loại màn (70–80% chỉ là giá trị khởi điểm); (e) đường cong tổng, màn Hard (+9..+12), màn ra mắt cơ chế; (f) kiểm tra các level có khóa ≥2 hay combo (khóa + băng) có thật sự giải được và người chơi thắng được.

## Giới hạn và việc cần làm tiếp

**Cỡ mẫu nhỏ/kết quả mỏng:**

| Kết quả | Cỡ mẫu | Vì sao mong manh |
|---|---|---|
| Toàn bộ thí nghiệm nhiễu loạn [TN] | 15 base (9–17 cặp mỗi biến thể); kế hoạch 32 base, chỉ xong 17 | hiệu ứng \|Δcf\| < 0,02 không phân biệt được nhiễu; SE theo cặp là proxy nhiễu duy nhất |
| So sánh vị trí hoa ẩn n=5 rải ở initial | 6–7 cặp | cần 5 dây đủ dài |
| Tương tác H/L/P | 9–15 level | dấu phần dư lexp chưa chắc |
| Thí nghiệm hoán vị hoa ẩn [SV] | 47–48 level | chỉ đổi dấu `?`, không đổi thứ tự loại hoa; level có thể mất giải được (dfs_res 0,92–0,98); không có score thật cho biến thể |
| Phân tầng hoa ẩn [QS] | 9–10 tầng, ~5–30 level mỗi nửa | hiệu ứng phân bố phụ thuộc cách chia |
| Khóa count ≥4 [QS] | 6 + 5 + 7 level | hệ số count phần đuôi gần như từ 18 level; Lasso còn đổi dấu giữa `lock_flowers` và `lock_count_sum` |
| `n_init` thuần, `capacity` thuần | 5/118 và 3/118 slot đổi | không có thực nghiệm tự nhiên |
| Level > 70 điểm | 44 | bias +14 của công thức |
| Level có `lw` rất cao (> 0,7, điểm < 10) | 24 level < 10 | phân giải thấp ở vùng mục tiêu của Sweet Rope |
| `cups-1` (−0,113) | 15 | nghi vấn phương pháp (nhét lại hoa làm dây đầy hơn), không dùng |

**Giới hạn khác.** (i) `summaryScore` là hộp đen, công thức/seed bot gốc không biết; mọi hệ số là tương quan. (ii) Không có dữ liệu người chơi thật. (iii) Tier là bin của score (sự kiểm soát bằng tier làm teo hệ số cơ học). (iv) Bot dùng trong [TN] là random (rho −0,52), kém hơn `lw`. (v) Phạm vi dữ liệu: capacity 4–6, 6–7 dây, 8–9 loại hoa, 10–14 cốc, count khóa ≤ 6; ngoài đó là ngoại suy (README mục 7 có màn 1 capacity 3, bố cục 2 hàng chưa thử được). (vi) Chưa chạy bot mù một phần; chưa chạy lại [TN] bằng `lw`; chưa thử MCTS hoặc policy khác, chưa tối ưu eps/T theo score (rho phẳng 0,77–0,81); chưa kiểm công thức ngoài mẫu 392. (vii) Hai ước tính "Hoa ẩn thật sự dễ hơn khi gần đuôi" giữa [QS] và [TN] trái dấu và chưa dung hòa.

**Việc nên làm tiếp (theo thứ tự lợi ích/chi phí):** (1) chạy lại 1098 biến thể [TN] với `greedy_ext` để có Δlw (ước tính ~11–15 phút mỗi lượt 4 core theo ghi chú); (2) hoàn thành 32 base và thêm null-test (cùng level, seed khác) cho cf/lw; (3) bot mù một phần cho hoa ẩn; (4) hiệu chuẩn phi tuyến (isotonic) lw → score cho đuôi trên và thêm hạng tử hoa ẩn/Hard cho phần dư; (5) kiểm chéo công thức 5 đặc trưng bằng giữ lại ngoài mẫu (ví dụ ra chapter 5 làm test); (6) khi có telemetry: hiệu chỉnh lại và A/B.

## Nguồn

Nội bộ (ghi chú nghiên cứu): [CT] `/tmp/claude-0/-home-user-GodotProject/789c606f-fe6b-525e-85bc-e2eb0b400faa/scratchpad/research_notes/Input quyết định độ khó level/cau_truc_level.md`; [SV] `.../chi_so_solver_bot.md`; [CC] `.../co_che_va_thi_nghiem.md`; [TL] `.../tai_lieu_ben_ngoai.md`. Dữ liệu và script: `/tmp/claude-0/-home-user-GodotProject/789c606f-fe6b-525e-85bc-e2eb0b400faa/scratchpad/research_work/{structure,solver,mechanics}/`; script Godot `/home/user/GodotProject/.godot/{solver_metrics,greedy_ext,mech_metrics}.gd`; dữ liệu level `/home/user/GodotProject/assets/builtin/chapter_default_1_5.json`, `.godot/builtin_dump.json`.

Văn liệu ngoài (chỉ đọc snippet/tóm tắt tìm kiếm; **WebFetch bị chặn nên chưa đọc full text**, các con số cần kiểm lại với bản gốc): [Ito et al., Sorting Balls and Water (arXiv 2202.09495)](https://arxiv.org/abs/2202.09495); [LIPIcs FUN 2022](https://drops.dagstuhl.de/entities/document/10.4230/LIPIcs.FUN.2022.16); [ScienceDirect (TCS)](https://www.sciencedirect.com/science/article/abs/pii/S0304397523004711); [Althaus et al., Sorting Colored Balls in Colored Tubes (SoCS)](https://ojs.aaai.org/index.php/SOCS/article/view/35971); [Jarušek & Pelánek, Difficulty Rating of Sokoban Puzzle](https://www.fi.muni.cz/reports/2010/abstract/FIMU-RS-2010-01.html) và [STAIRS 2010 PDF](https://www.fi.muni.cz/~xpelanek/publications/stairs2010-final.pdf); [What Determines Difficulty of Transport Puzzles? (FLAIRS 2011)](https://aitopics.org/doc/conferences:77F145E4); [Pelánek, Difficulty Rating of Sudoku Puzzles](https://arxiv.org/pdf/1403.7373); [arXiv 2608.15958](https://arxiv.org/pdf/2608.15958); [arXiv 2608.23300 (SAT metrics, Nonogram)](https://arxiv.org/pdf/2608.23300); [Automated Puzzle Difficulty Estimation (CIG 2015)](https://ics-websites.science.uu.nl/docs/vakken/mscip/assignments/CIG2015-AutomatedPuzzleDifficultyEstimation.pdf); [Elimination (evolutionary generator)](https://webcf.waybackmachine.org/web/20210827172554/http://akhalifa.com/documents/Elimination.pdf); [SayGames](https://blog.say.games/posts/how-to-work-with-difficulty-in-hybrid-puzzles-so-players-dont-leave--but-stay-and-pay); [PocketGamer.biz](https://www.pocketgamer.biz/how-saygames-uses-game-analytics-to-balance-difficulty-in-hybrid-puzzle-games/); [Columbia, Personalized games](https://business.columbia.edu/sites/default/files-efs/citation_file_upload/Personalized_games.pdf); [Adjust](https://www.adjust.com/blog/askblu-data-science-mobile-games-difficulty-tuning); [Gamezebo strategy guide](https://www.gamezebo.com/walkthroughs/water-sort-puzzle-strategy-guide-top-5-hints-tips-and-cheats/); [level 74 is impossible](https://filipre.github.io/posts/level-74-is-impossible/); [cemasma solver](https://github.com/cemasma/water-sort-puzzle-solver).

## Kết luận

Hai điều thay đổi cách nhìn: thứ quyết định `summaryScore` không phải một núm cấu trúc nào đơn lẻ mà là **xác suất một người chơi có heuristic nhưng sai sót thất bại**, và đây là thứ chỉ bot mô phỏng đo được; còn con số "tier giải thích 71%" chỉ là phép bin chính nó. Hệ quả cho Sweet Rope là đổi thứ tự công việc: chọn tải/cốc/khóa để vào vùng điểm, đo bằng `lw`, chấp nhận sai số ±9 mỗi level, và dùng hoa ẩn như phụ gia, không như công cụ chỉnh độ khó.

Điều chưa biết lớn nhất chính là điều người dùng quan tâm nhất, tức hoa ẩn dưới góc nhìn người chơi thật. Mọi chỉ số hiện có mù với chi phí thông tin; bot mù một phần và một A/B với ~1.500 lượt mỗi nhánh là cách rẻ nhất để biết, và nên làm trước khi sinh hàng loạt level dựa vào bất kỳ "quy tắc vị trí hoa ẩn" nào.

---

<!-- ===================== BẮT ĐẦU: BẢN BỔ SUNG CHO README SINH LEVEL ===================== -->

# Bản bổ sung cho README sinh level

*Thay thế toàn bộ mục `## 5. Đo độ khó` và `## 5b. Các yếu tố đầu vào ảnh hưởng độ khó` của README. Các mục khác giữ nguyên. Dán từ dòng `## 5.` đến hết `### 5b.6`.*

````markdown
## 5. Đo độ khó

Thang điểm là `summaryScore` của Sort Streak (0 là dễ nhất, khoảng 90 là khó nhất). Công thức gốc không có trong repo; không có dữ liệu người chơi thật. Bằng chứng cho thấy `summaryScore` bám sát **tỉ lệ thắng của một người chơi có heuristic nhưng mắc lỗi** (rho −0,84 với bot greedy có nhiễu), và bám yếu thước đo độ sâu tìm kiếm của solver (rho 0,34–0,44). Công thức ước lượng cũ (`win_rate` ngẫu nhiên, `branch`, `expanded`) chỉ giải thích R² ≈ 0,30 và đã **bị thay thế**. Số `branch` trong công thức cũ áp đảo kết quả (thêm một dây trống làm điểm ước lượng tụt khoảng 37), nên không dùng nữa.

### 5.1 Chỉ số khuyến nghị: bot greedy có nhiễu (`lw`)

Bot đi theo điểm nước đi `JuiceSolver.move_score`, nhưng đôi khi đi sai:
- **eps-greedy**: với xác suất `eps` chọn ngẫu nhiên trong `JuiceRules.useful_moves()`; ngược lại chọn nước có `move_score` cao nhất (hòa thì chọn ngẫu nhiên). Dùng `eps` = 0,3 / 0,45 / 0,6.
- **softmax**: chọn nước theo xác suất tỉ lệ `exp((move_score - max)/T)` với `T = 4`.
- Mỗi cấu hình chạy **2 seed (11 và 22) × 30 ván**, tối đa **300 nước** mỗi ván; ván thắng khi `JuiceRules.is_win`.
- `lw` = trung bình win-rate của 4 cấu hình (e30, e45, e60, sm4); `ld` = trung bình tỉ lệ cốc hoàn thành (`done / groups_total`) của cùng 4 cấu hình.

Script: `.godot/greedy_ext.gd` (nguồn đầy đủ trong phụ lục B của ghi chú `chi_so_solver_bot.md`; có thể sao chép từ `/home/user/GodotProject/.godot/greedy_ext.gd`). Chạy: `godot --headless --path . -s res://.godot/greedy_ext.gd -- in.json out.json <shard> <nshards>` (`in.json` là mảng `{uid, raw}`). Chi phí khoảng **9,3 s/level** trên 1 core (4 cấu hình), hoặc **~2,3 s** nếu chỉ chạy một cấu hình (eps 0,45 hoặc softmax T=4, tương quan −0,81; ổn định giữa 2 seed 0,86–0,91).

Bảng hiệu chuẩn `lw` → điểm (trung bình, độ lệch chuẩn trong mỗi ô 7–16 điểm), dùng khi chỉ chạy `greedy_ext`:

| `lw` | Điểm TB tương ứng |
|---|---|
| 0,001–0,05 | 69,5 |
| 0,05–0,15 | 58,3 |
| 0,15–0,3 | 44,2 |
| 0,3–0,5 | 30,6 |
| 0,5–0,7 | 20,0 |
| 0,7–1 | 10,2 |

Tương quan: `lw` có Spearman **−0,839** (CI95 −0,871..−0,793) với `summaryScore` trên 392 level; R² kiểm chéo **0,66**, MAE **9,45**.

### 5.2 Công thức 5 đặc trưng (khi cần tốt hơn một chút)

Chạy thêm `.godot/solver_metrics.gd` (~7,9 s/level; ngẫu nhiên 3 seed × 40 ván tối đa 300 nước, beam độ rộng 1/3/8/20/50/120 dừng sau 2 lần thắng, DFS `node_cap` 4000):

```
diem_uoc_luong = 32.83 - 53.67*lw - 24.49*ld + 32.32*rand_win + 4.13*ln(beam_w) + 0.602*opt_len
```

- `rand_win`: win-rate trung bình của random-play (seed 12345/777/4242 × 40 ván).
- `beam_w`: độ rộng beam nhỏ nhất tìm được lời giải (không tìm được thì đặt 200 cho `ln`); `opt_len`: độ dài đường thắng của beam (thiếu thì lấy trung vị).
- Hệ số `rand_win` dương chỉ vì cộng tuyến với `lw`; không đọc riêng lẻ.
- R² kiểm chéo **0,70**, MAE **8,8**. Công thức đơn giản (chỉ `lw`) chỉ kém chút (R² 0,66, MAE 9,45), nên khi tiết kiệm thời gian cứ dùng `lw` + bảng hiệu chuẩn.
- Code tái lập: `research_work/solver/{build.py, mkge.py, models.py, final.py}` trong thư mục scratchpad của phiên nghiên cứu; chạy theo thứ tự `solver_metrics.gd` (4 shard), `greedy_ext.gd` (4 shard), `build.py`, `mkge.py`, `final.py`.

### 5.3 Sai số thật: không đạt ±3 cho từng màn

| Đại lượng | Giá trị |
|---|---|
| Độ lệch chuẩn của sai số (cv) | 11,2 điểm |
| Sai số tuyệt đối trung vị | 7,4 |
| 80% màn lệch dưới | ~14 |
| 90% màn lệch dưới | ~17,8 |
| Xác suất sai số thật ≤ ±3 | ≈ 21% (tính từ sd 11,2, giả định chuẩn) |

Sai số theo vùng điểm gốc (MAE / bias = thực − dự đoán): 0–10: 9,6 / −6,0; 10–20: 8,8 / −1,8; 20–30: 9,9 / −7,2; 30–40: 8,1 / −4,5; 40–55: 6,3 / +1,2; 55–70: 7,3 / +5,9; 70–95: 14,2 / +14,1. Ước lượng **co về trung bình**: màn rất khó bị đánh giá thấp ~14 điểm, màn dễ-vừa bị đánh giá cao hơn thực vài điểm.

Hệ quả:
- **Dung sai ±3 (±5 màn Hard) không đạt được cho từng màn.** Chọn ứng viên có ước lượng gần mục tiêu nhất không làm sai số thật nhỏ hơn.
- Chỉ phân biệt tin cậy được các màn cách nhau **≥ ~15 điểm**. Trong cùng một khung (cùng chapter/slot) phân biệt tốt hơn: `lw` xếp đúng thứ tự 90% cặp chênh ≥5 điểm.
- Dùng cho: (a) xếp hạng tương đối giữa các ứng viên, (b) loại ứng viên lệch xa (> 15–20 điểm), (c) kiểm đường cong độ khó trung bình qua nhiều màn. Báo cáo độ lệch ước lượng với khoảng ±9 (trung bình) / ±14 (80%) / ±18 (90%) thay vì tuyên bố "đạt mục tiêu".
- Màn dễ (mục tiêu < 10) rơi vào ô `lw` > 0,7; chỉ số ít phân giải ở đó, nên tăng số ván hoặc số seed.

### 5.4 Quy trình chọn màn

1. Sinh ứng viên theo khung của giai đoạn (mục 7), rồi chỉnh theo bảng núm (5b.2).
2. Loại ứng viên không qua `validate()` hoặc không `WINNABLE` (DFS `UNKNOWN` cần node_cap lớn hơn; với màn có khóa/băng/dây trống, DFS 3000–4000 nút thường không đủ, xem 5b.4).
3. Lọc thô bằng một cấu hình greedy (eps 0,45 hoặc softmax T=4, 30 ván).
4. Tính `lw` đầy đủ (và công thức 5 đặc trưng nếu muốn) cho các ứng viên còn lại; chọn ứng viên gần điểm mục tiêu nhất.
5. Ghi lại độ lệch dự kiến và sai số theo 5.3 trong báo cáo cho từng màn.

Ngân sách: 200 màn × 20 ứng viên ≈ 4000 level ≈ 16 giờ-core cho `greedy_ext` (~4 giờ trên 4 core); lọc thô bằng 1 cấu hình để giảm còn ~1/4.

### 5.5 Những gì chỉ số này không đo

- Đây là chỉ số **bot**, không phải của người chơi. Bot nhìn được **loại thật của hoa ẩn** (`JuiceSolver._hint_type` trả `JuiceLevel.true_type`), nên không đo được chi phí thông tin/trí nhớ của hoa ẩn.
- Các chỉ số "solver mạnh" (`expanded`, `opt_len`, beam) chỉ khớp yếu (|rho| 0,3–0,44); văn liệu về Sokoban/Rush Hour cho kết quả tương tự (độ dài lời giải ngắn nhất yếu, mô hình hóa quá trình tìm kiếm của người tốt hơn), và **chưa có chỉ số nào được xác nhận với người chơi cho sort puzzle**.
- Khi Sweet Rope có dữ liệu chơi thật (tỉ lệ thắng, số lần thử), hiệu chỉnh lại `lw` → điểm. Win-rate mục tiêu 70–80% mà blog ngành hay nêu chỉ là kinh nghiệm, không phải kết quả nghiên cứu.

---

## 5b. Các yếu tố đầu vào ảnh hưởng độ khó

Nguồn: (a) phân tích quan sát 392 level khác nhau của Sort Streak chapter 1–5 (`summaryScore`; công thức hộp đen; không có dữ liệu người chơi); (b) thí nghiệm nhiễu loạn có đối chứng (sửa đúng một đầu vào của level "sạch", đo bằng bot ngẫu nhiên và solver; 9–17 cặp mỗi biến thể trên 15 level gốc); (c) tài liệu ngoài (chỉ kinh nghiệm truyền miệng). Hệ số quan sát **không phải quan hệ nhân quả**. Nhãn bản (default, lv2…lv5) thực chất là bin của `summaryScore`, nên cột "sau kiểm soát nhãn bản" là cận dưới bảo thủ, không phải ước lượng nhân quả sạch.

### 5b.1 Mức giải thích

- Các thông số cấu trúc (đếm số lượng, vị trí) giải thích **32%** (tuyến tính) đến **41–47%** (cây) phương sai, MAE 12–13,5 (đoán trung bình: 17).
- Bot greedy có nhiễu giải thích **66–70%** (MAE 8,8–9,5): phần độ khó còn lại nằm ở **thứ tự hoa chi tiết**, thứ mà bot mô phỏng được.
- Nhãn bản giải thích 71% nhưng chỉ vì là bin của chính điểm; không dùng.
- Dùng bảng 5b.2 để **chọn thông số khởi đầu**, rồi **đo bằng bot (mục 5)**; đừng cộng hệ số.

### 5b.2 Núm điều chỉnh (xếp theo mức dùng)

Ký hiệu: QS = quan sát (cột "thô" là cận trên, cột "sau tier" là cận dưới); TN = thí nghiệm đối chứng, Δcf là thay đổi tỉ lệ cốc bot ngẫu nhiên hoàn thành (nền 0,221; âm = khó hơn); tin cậy Cao/TB/Thấp.

| Núm | QS: thô / sau tier (điểm cho +1 đơn vị) | TN: Δcf | Rủi ro không giải được | Tin cậy |
|---|---|---|---|---|
| Số hoa trên dây đầu / độ đầy (+1 hoa; +1% độ đầy) | +5,0..6,5 / +1,6; (+2,2 / +0,47 mỗi 1%) | chưa kiểm riêng | thấp | Cao hướng, TB độ lớn |
| `targetCups` +1 ở cùng `capacity` | +5,6..8,8 / +1,4 | −0,203 ±0,038 (cả 14 level khó hơn) | 0% UNWINNABLE; DFS khó cạn | Cao hướng, TB độ lớn |
| `capacity` +1 (giữ cân bằng hoa) | không tách được (+5,8..12 / +3,7) | −0,198 ±0,038 | ~6% | Cao hướng, Thấp độ lớn; đặt theo chapter |
| Thêm 1 dây trống vào `initial` | (`n_init` +1: −16,6 / −5,4, một phần là thật) | **+0,156 ±0,023 (dễ hơn ở 100% level)** | 0% | Cao |
| Dây khóa (có/không, 1 dây) | không ý nghĩa (−2,9..+4,8) | −0,175 ±0,034 | 0–6% | **TB; QS và TN không khớp** |
| `count` dây khóa (tổng +1 / dây nặng nhất +1) | +3,3..4,1 / +1,3; +8,7 / +4,3 | count 1→4: −0,175 → −0,192 (gần phẳng) | tăng theo count | TB |
| 2 hoặc 3 dây khóa | không có ý nghĩa riêng | −0,17..−0,22 | **31–53% / 94% UNWINNABLE** | Cao rủi ro: **tránh** |
| Số đoạn đổi loại hoa trên dây đầu | +2,3 / +1,5..1,9 | trộn/hoán hoa: −0,01..−0,04 | 0% | TB |
| Số loại hoa (+1 / −1 / −2) | không đo được (8–9 loại) | −0,142 / +0,043 / +0,114 | 0% | Thấp-TB |
| Băng + ánh nắng (blockConnection, k=3) | không có trong dữ liệu | −0,16 (nắng sớm); −0,07..−0,08 (k=3 thường) | 0% UNWINNABLE; DFS khó | Thấp |
| Thứ tự `incoming` (xáo hoặc đảo) | không đo | −0,083 / −0,090 | 0% | Thấp-TB |
| Hoa "cần" xuống gần đuôi / lên gần chậu | không đo | −0,043 / +0,026 | 0% | TB, nhỏ |
| Số dây đơn sắc ban đầu | −3,7..−4,7 / −0,8 (không ý nghĩa) | chưa kiểm | không | Thấp |
| Số hoa ẩn (+1 hoa, ngẫu nhiên) | +0,8 / +0,3 | 10/20/30% hoa ẩn: −0,014/−0,021/−0,016 (không tăng theo liều) | 0% | Cao nhưng yếu |
| Màn Hard | +9,0 / +12,2 | không áp dụng | không áp dụng | Cao |

Chuyển đổi gần đúng +10 điểm (QS thô, cận trên; nếu giữ nhãn bản thì chỉ 20–35% giá trị đó): +1,5 hoa dây đầu, hoặc +1,6–1,8 cốc ở cùng `capacity`, hoặc +2,5–3 tổng `count` khóa, hoặc +1,2 ở `count` khóa nặng nhất. Hoa ẩn cần ~12 hoa cho +10: **chỉ dùng để tinh chỉnh ±1–3 điểm**.

Nhớ: sai số đo mỗi màn cỡ ±9–14 (mục 5.3), nên mọi con số trên là kỳ vọng trung bình cho nhiều màn, không đảm bảo cho từng màn. Hệ số của TN dùng bot ngẫu nhiên (rho −0,52 với điểm) nên chỉ tin hướng và bậc độ lớn; cần đo lại bằng `lw`.

### 5b.3 Vị trí và phân bố hoa ẩn

**Quy ước:** *sâu từ đuôi* = số hoa nằm giữa hoa ẩn và đuôi dây (0 = đuôi); sâu = gần chậu, lộ ra muộn. *Đáy / gần đuôi* = hoa ẩn sát đuôi, lộ sớm. (Hoa ẩn luôn nằm trên đuôi: đuôi dây không được là hoa ẩn.)

| Cách xếp (cùng số hoa ẩn, cùng `capacity`) | QS: tác động lên điểm | Hướng QS |
|---|---|---|
| Nhiều hoa ẩn ở nửa gần đuôi | −4,7 | dễ hơn |
| Hoa ẩn dồn vào ít dây | −7,1 | dễ hơn |
| Hoa ẩn liền nhau | −2,0 | dễ hơn |
| Hoa ẩn rải trên nhiều dây | +2,9 | khó hơn |
| Hoa ẩn sâu ≥ 3 bậc từ đuôi | +4,6 | khó hơn |

- Độ lớn chỉ **±2–5 điểm mỗi độ lệch chuẩn**, nhỏ so với sai số ±12; sau kiểm soát nhãn bản hầu như biến mất, chỉ còn độ sâu của hoa ẩn trong dây `incoming` (+2,7 mỗi bậc). Hoa ẩn trong `initial` không có hiệu ứng phân bố.
- **Thí nghiệm bot không xác nhận hướng này**: với cùng số hoa ẩn, đổi sát đuôi/sát chậu, dồn/rải, liền/xen kẽ cho |Δcf| ≤ 0,03, phần lớn trong nhiễu; một so sánh (rải ở đáy so với ở đầu) còn trái dấu QS (−0,024). Hoán vị vị trí `?` (48 level) không đổi win-rate của bot nào (random hay greedy), chỉ `beam_w` và `hburden` đổi.
- **Lý do:** bot nhìn thấy loại thật của hoa ẩn. Vì vậy hoàn toàn **chưa biết** việc 2 hoa ẩn ở đáy so với xen kẽ có làm người chơi thật dễ/khó hơn hay không. Đừng dùng vị trí hoa ẩn làm núm chỉnh độ khó; chỉ dùng số lượng. Nếu cần xác định: bot mù một phần hoặc A/B với người chơi thật (~1.500 lượt mỗi nhánh để thấy chênh 5 điểm phần trăm).

### 5b.4 An toàn giải được

`validate()` luôn qua với mọi nhiễu loạn đã thử; rủi ro là **không giải được** và DFS không xác nhận được.

| Núm | UNWINNABLE (≥1 lần, solver cạn) | DFS 3000 nút không xác nhận (unres) |
|---|---|---|
| Hoa ẩn (mọi cách xếp thử), trộn hoa, hoán loại chậu `incoming`, `columnCaps` hai dây | 0% | 0–0,17 |
| Thêm dây trống, chậu trắng `incoming` | 0% | 0,2–0,3 |
| `targetCups` ±1, tách loại hoa | 0% | 0,2–0,75 |
| Băng + nắng, thứ tự `incoming` | 0% | 0,5–0,75 |
| `capacity` +1 | 6% | 0,9 |
| 1 dây khóa (`count` 1/2/3/4) | 0% / 6% / 6% / 6% | 0,44–0,84 |
| 2 dây khóa (count 2 / count 1) | 31% / 53% | ~0,8 |
| 3 dây khóa (count 2) | 94% | 1,0 |
| Khóa + dây trống | 0% | 1,0 |

- Giới hạn khuyến nghị cho khóa: **tối đa 1 dây khóa, `count` ≤ 3**, đặt hoa mở khóa ở dây không khóa. 2–3 dây khóa chỉ dùng khi đã chứng minh `WINNABLE` bằng solver.
- Khi `unres` ≥ 0,8, DFS 4000 nút không xác nhận được giải được: tăng `node_cap` hoặc dùng solver khác (ví dụ `hint_win_path`).
- Các tổ hợp **không cộng**: khóa nuốt ~72% lợi ích của dây trống; hoa ẩn không đổi gì khi đã có khóa hoặc dây trống. Đo lại từng tổ hợp.

### 5b.5 Yếu tố không thấy tác động (hoặc không đo được)

- **Số loại hoa** trong dữ liệu gốc: không tương quan (0,07), gần như không đổi (8–9). Thí nghiệm đối chứng cho thấy gộp/tách loại có đổi độ khó; đừng bỏ qua khi thiết kế.
- **Chậu trắng**: `initial` luôn 1 (hằng số). Vị trí chậu trắng `incoming`: muộn gần như không tác dụng; sớm hơi dễ hơn (+0,038). Dồn hoa vào dây trắng không đổi gì.
- **Vị trí dây khóa**, dây khóa là chậu trắng: không tác động đo được. Chỉ `count`, và sự có mặt của khóa.
- **Số dây và `capacity` đứng riêng**: không phải núm độc lập; chúng cùng quyết định độ đầy. Đừng hiểu "tăng `capacity` làm dễ hơn" (hệ số âm trong mô hình nhiều biến chỉ là cộng tuyến).
- Một yếu tố "không tác động" có thể chỉ vì gần như không đổi trong dữ liệu. Dữ liệu chỉ phủ `capacity` 4–6, 6–7 dây, 8–9 loại, 10–14 cốc, `count` khóa ≤ 6. Ngoài khoảng này (ví dụ màn 1–10 với `capacity` 3, bố cục 2 hàng) là ngoại suy: đo lại bằng bot.

### 5b.6 Gợi ý thứ tự điều chỉnh khi sinh một màn

1. Chọn khung theo giai đoạn (mục 7): số cốc, độ đầy các dây đầu lúc đầu, số dây ban đầu, `capacity`.
2. Chỉnh **tải**: tăng/giảm `targetCups` và số hoa ở dây đầu, thêm hoặc bớt dây trống, để vào đúng khoảng điểm.
3. Chỉnh **cơ chế** (chỉ khi màn đã ra mắt cơ chế): 0–1 dây khóa với `count` ≤ 3; băng + nắng nếu có.
4. Chỉnh **tinh**: số đoạn đổi loại hoa trên dây đầu, số dây đơn sắc ban đầu, hoa "cần" gần đuôi hay gần chậu, số hoa ẩn (±1–3 điểm).
5. Chạy `validate()` và solver (`WINNABLE`), đo `lw` (mục 5.1), giữ ứng viên gần mục tiêu nhất, và ghi sai số dự kiến (mục 5.3).
````

<!-- ===================== KẾT THÚC: BẢN BỔ SUNG CHO README SINH LEVEL ===================== -->
