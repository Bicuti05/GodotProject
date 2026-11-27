# Tác động của từng cơ chế và knob đầu vào lên độ khó level (thí nghiệm nhiễu loạn có đối chứng trên 392 level builtin Sort Streak)

Phạm vi (theo cập nhật của người dùng): chỉ dùng các level builtin có `summaryScore` (392 level, `/tmp/claude-0/uniq.json`). Các bank khác (sunlight, special challenge, fallback) chỉ được đọc để hiểu cú pháp, không dùng để thống kê hay kết luận. Mọi con số dưới đây do engine của repo (JuiceLevel/JuiceRules/JuiceSolver, Godot 4.6.1 headless) tính ra. Nguồn của mọi "Cited Findings" là các file kết quả cục bộ liệt kê ở mục "Tệp dữ liệu" cuối ghi chú.

Cảnh báo quan trọng: các chỉ số đo là chỉ số của solver/bot, không phải của người chơi. Chúng phản ánh hạn chế cơ học (nước đi bị cấm, số nhánh, kích thước không gian trạng thái). Chúng không phản ánh gánh nặng trí nhớ hay bất định mà hoa ẩn gây ra cho người chơi thật. Kết luận về hoa ẩn phải đọc theo cảnh báo này.

---

## Câu hỏi 0. Thiết kế thí nghiệm, recipe, cỡ mẫu và nhiễu

### Takeaway
Mỗi level "gốc sạch" (clean base) bị sửa đúng một đầu vào, rồi so sánh theo cặp (paired) với chính nó, cùng seed bot. Mẫu là 15 level gốc (cặp có đủ dữ liệu 9-17 level cho từng biến thể) trải đều summaryScore 3-79. Mẫu nhỏ, nên chỉ nên tin hiệu ứng có |Δ| lớn hơn khoảng 2 lần SE và nhất quán dấu.

### Cited Findings
- Chọn base: từ 392 level, lọc `solved==1` (WINNABLE ở lượt đầu), `expanded<2500`, 6-7 dây, `capacity>=4`; chia 8 khoảng summaryScore ([0,10), [10,20), [20,30), [30,42), [42,54), [54,66), [66,78), [78,100)), mỗi khoảng 8 ứng viên (64). Chạy engine trên bản "sạch": 62/64 bản sạch vẫn WINNABLE. Lấy 4 level/khoảng = 32 base, xếp ngẫu nhiên. Do giới hạn tính toán (~65 phút tổng, 4 lõi), chỉ xử lý xong 17 base (15 base có đủ mọi biến thể, summaryScore: 3, 7, 8, 19, 21, 32, 34, 41, 46, 61, 63, 64, 72, 75, 79). Tổng 1098 lần đánh giá, 0 level invalid (`validate()` luôn qua) — `var_out*.jsonl`, `done1.jsonl`, `done2.jsonl`, `var3_out*.jsonl`.
- "Gốc sạch" (clean) = level gốc đã bỏ mọi `?` (hoa ẩn) và mọi dây khóa (columnType về default). Mọi biến thể đều dựng từ bản sạch này (không từ bản gốc), nên các hiệu ứng của hoa ẩn/khóa đo trên nền không có sẵn hai cơ chế đó. So với bản sạch, bản gốc có sẵn hoa ẩn + khóa tự nhiên chỉ lệch cf -0.031±0.011 và lexp +0.03±0.14 (n=15).
- Chỉ số mỗi level (3 seed, mỗi seed 20 lần chơi ngẫu nhiên trong `useful_moves`, tối đa 250 nước, seed 1000+7919k):
  - `cf` (cups_frac): trung bình done/targetCups khi kết thúc lần chơi. Đây là chỉ số liên tục, nhạy nhất. Bản sạch: cf=0.221 (stuck_share 0.50, nghĩa là một nửa số lần chơi ngẫu nhiên bị kẹt hẳn).
  - `wr`: tỉ lệ thắng của bot ngẫu nhiên. Bản sạch: 0.041 (rất thấp nên kém nhạy). Seed-to-seed SD trong cùng một level: 0.012 (trung bình wr toàn tập 0.025).
  - `br`: số nước hợp lệ trung bình mỗi lượt. Bản sạch: 5.72.
  - `lexp`: trung bình ln(expanded+1) của 2 lần chạy DFS của solver (`begin_full_search`/`advance_full_search`, node_cap 3000, state_cap 40000): một lần với thứ tự dây gốc, một lần với thứ tự dây hoán vị ngẫu nhiên. Bản sạch: 6.78 (tương đương khoảng 880 nút).
  - `unres`: tỉ lệ trong 2 lần DFS không trả WINNABLE (UNKNOWN do chạm node_cap, hoặc UNWINNABLE). `unsat_any`: có ít nhất 1 lần trả UNWINNABLE (solver duyệt cạn nên đây là bằng chứng "không giải được"). Bản sạch: unres=0.
- Nhiễu đo được: (i) |lexp(thứ tự A) − lexp(thứ tự B)| trung bình 0.78 trên 15 bản sạch, nghĩa là `expanded` của DFS rất nhạy với thứ tự dây (rộng hơn hầu hết hiệu ứng "hoa ẩn"); (ii) SD seed của wr 0.012. Với cf không có ước lượng seed riêng; dùng SE của chênh lệch theo cặp (thường 0.004-0.015 cho biến thể nhẹ, 0.02-0.04 cho biến thể nặng).
- Hiệu chỉnh tính hợp lệ của cf: trên 15 base sạch, tương quan cf với summaryScore gốc là r = -0.52 (cf cao tương ứng level dễ), còn lexp là r = +0.24 (yếu). cf theo tercile summaryScore (thấp/giữa/cao): 0.330 / 0.182 / 0.151; wr: 0.103 / 0.017 / 0.003. Xác nhận lại nhận xét của README: expanded chỉ giải thích một phần nhỏ.
- Hai chỉ số đã thử và bỏ: (a) "tỉ lệ nước đi dẫn tới trạng thái doomed" luôn bằng 0 (`JuiceRules.is_doomed` dùng cận `max_groups_left` quá lỏng, không bao giờ kích hoạt trong lúc chơi ngẫu nhiên); (b) bot "safe-random" (chỉ chọn nước không dẫn tới doomed) có win_rate 0.083 so với 0.088 của bot ngẫu nhiên trên 62 level sạch, tức là không có thêm thông tin.
- Công thức ước lượng `est = 9.9 + 8.33 ln(expanded+1) − 6.01 branch − 35.65 win_rate` của README không dùng được để đo perturbation: số hạng branch áp đảo (thêm 1 dây trống làm br +5.8, est giảm khoảng 37 điểm, vô nghĩa với hướng của độ khó khi chỉ số duy nhất đổi là số chỗ để). Do đó bảng dưới đây dùng cf/wr/br/lexp/unres rời nhau.
- Quy ước đọc dấu: Δcf âm = khó hơn (bot hoàn thành ít cốc hơn); Δlexp và Δunres dương = khó hơn cho solver (DFS tốn nhiều nút hơn hoặc không tìm ra nghiệm trong 3000 nút); Δbr dương = dễ hơn theo nghĩa nhiều lựa chọn hơn (nhưng có thể làm không gian trạng thái phình ra, nên unres/lexp cũng tăng). Cột "nhất quán" = % level có Δ dương / % level có Δ âm.

### Recipe chính xác của từng nhiễu loạn (code Python `lvl.py`, `gen.py`, `gen2.py`)
Mọi lựa chọn ngẫu nhiên dùng `random.Random(f'{uid}-{tag}')` để các biến thể cùng họ chọn cùng dây.

| Họ / biến thể | Công thức |
|---|---|
| Hoa ẩn, liều (hid_dose H10/H20/H30) | Ẩn 10/20/30% tổng số hoa, vị trí ngẫu nhiên, trừ đuôi dây, cả initial và incoming |
| Hoa ẩn n=3, ở initial (hid_pos3) | `bottom_*`: vị trí idx = len-2 (sát đuôi, ngay trên đuôi); `top_*`: idx = 0 (sát chậu); `rand_*`: ngẫu nhiên không đuôi. `*_spread`: mỗi hoa một dây khác nhau (3 dây); `*_conc`: cả 3 hoa trong cùng một dây (bottom: idx len-2, len-3, len-4; top: idx 0,1,2). Dây phải có len≥n+1 và không phải chậu trắng |
| Hoa ẩn n=3 ở incoming (hid_pos3_inc) | Như trên nhưng chọn dây trong `incoming` |
| Hoa ẩn n=4 conc (hid_pos4), n=5 spread (hid_pos5, hid_pos5_inc) | Cùng quy tắc, tăng n |
| Liền vs xen kẽ (hid_adj2, n=2, dây len≥5) | `adjacent_bottom`: idx len-2, len-3; `interleaved_bottom`: len-2, len-4; `adjacent_top`: 0, 1; `interleaved_top`: 0, 2; `spread_bottom`: 2 dây khác nhau, mỗi dây ẩn idx len-2. Cùng một dây cho 4 biến thể đầu |
| Khóa theo count (lock_count) | 1 dây colored initial (không phải dây 0) bị `columnType:"unlock"`, `collect_count` với count=1,2,3,4 |
| Khóa theo số dây (lock_n) | 2 hoặc 3 dây ngẫu nhiên, count=2 (và 2 dây count=1) |
| Khóa theo dây cần sớm/muộn (lock_which) | Điểm cần = số hoa của dây có type trùng một chậu đang ở initial. `early_needed`: khóa dây điểm cao nhất; `late_needed`: dây điểm thấp nhất; count=2 |
| Khóa collect_type (lock_type) | 1 dây, count=1, `typeId` = loại của một chậu ở initial (`early`) hoặc loại của chậu colored cuối cùng ở incoming (`late`) |
| Đỗ xe (park) | `add_empty_ini`: thêm 1 dây `-|` rỗng vào initial (chỉ khi ≤6 dây). `fill_white_ini`: dồn hoa từ đuôi các dây khác vào dây trắng initial tới 60% capacity. `white_cap2`: columnCaps đặt capacity dây trắng = 2 (chỉ áp dụng được khi dây trắng có ≤2 hoa; chỉ 3 level, bỏ). `white_inc_early/late`: lấy 2 hoa cuối của mục incoming thứ 2 (early) hoặc mục colored cuối (late), đưa vào một chậu trắng mới chèn vào đúng vị trí đó; xóa một `x|` cuối để giữ độ dài |
| Capacity ±1 (cap) | cap-1: bỏ đúng p_t hoa loại t cho mỗi chậu loại t (p_t = số chậu loại đó), ưu tiên lấy từ dây đang đầy; cap+1: thêm p_t hoa loại t vào vị trí ngẫu nhiên không đuôi của dây còn chỗ. Cân bằng hoa được giữ nguyên |
| Sức chứa riêng (colcap-1_x2) | 2 dây colored initial ngắn, đặt `columnCaps` = capacity-1; bỏ 1 hoa cùng loại chậu để vẫn cân bằng |
| Số loại hoa (types) | `merge1/2`: gán nhãn loại A thành loại B (hoa và chậu) 1 hoặc 2 lần, số loại giảm 1/2, số cốc giữ nguyên; `split1`: chọn loại có ≥2 chậu, đổi một chậu và `capacity` hoa ngẫu nhiên của loại đó sang loại mới chưa dùng (số loại +1) |
| targetCups ±1 (cups) | cups+1: thêm một chậu loại ngẫu nhiên vào incoming sau chậu colored cuối, thêm `capacity` hoa loại đó vào chỗ trống ngẫu nhiên (dư thì cho vào chính dây mới). cups-1: bỏ chậu colored cuối của incoming, bỏ tương ứng `capacity` hoa loại đó, phân phối lại các hoa khác của dây bị bỏ vào chỗ trống |
| Trộn (mix) | `shuffle_least1/2`: xáo hoàn toàn 1 hoặc 2 dây ít phân mảnh nhất (ít cặp kề khác loại nhất); `shuffle_rand1`: 1 dây ngẫu nhiên; `cross_swap3/6`: đổi chỗ 3 hoặc 6 cặp hoa khác loại giữa các dây initial; `bury3`: cho ≤3 dây colored, đổi hoa cùng loại chậu gần đuôi nhất với hoa khác loại xa đuôi nhất (đẩy hoa "cần" lên gần chậu); `unbury3`: ngược lại (đưa hoa cần xuống gần đuôi) |
| Thứ tự incoming (inc_order) | `shuffle`: hoán vị ngẫu nhiên cả mục (chậu+hoa) colored; `reverse`: đảo; `pots_perm`: hoán vị loại chậu giữa các mục nhưng giữ nguyên hoa trong từng mục |
| Băng (ice) | Chọn loại ánh nắng `sunlight.typeId` = loại một chậu ở initial (`early`) hoặc loại chậu colored cuối của incoming (`late`); đóng băng k hoa (k=3 hoặc 6) loại khác ở vị trí không phải đuôi trong initial; `iceMode` mặc định hoặc `blockConnection`; `fpot1`: thêm 1 `frozenPots` |
| Tương tác (inter) | `H`: ẩn 15% ngẫu nhiên; `L`: khóa 2 dây count=2; `P`: thêm dây trống; ghép `HL`, `HP`, `LP`, `HLP` trên cùng lựa chọn ngẫu nhiên |

Không thử được: bố cục 2 hàng (`layoutRows:2` yêu cầu capacity=4, 8-10 dây có màu, nên không thể suy ra từ level builtin 6-7 dây mà không thay đổi đồng thời hàng chục thuộc tính); không tách riêng được tác động "xóa dây trắng ban đầu" (mọi level builtin đều có đúng 1 dây trắng initial, rỗng hoặc có 1 hoa; xóa nó làm lệch cân bằng hoa).

### Inferences
- Vì DFS của solver nhạy với thứ tự dây (|Δlexp| 0.78) và 15-17 base là mẫu nhỏ, `lexp` chỉ dùng làm tín hiệu phụ. `cf` và `unres`/`unsat_any` đáng tin hơn cho xếp hạng.
- Khi `unres` đạt 0.8-1.0 (DFS không tìm ra nghiệm trong 3000 nút) thì `lexp` bị bão hòa ở ln(3001)=8.0 và không còn so sánh được (censored); cần đọc `unres` thay `lexp`.

### Gaps
- Chưa có phép thử nhiễu (null) kiểu "chạy lại cùng level với seed khác" cho cf; SE theo cặp là proxy duy nhất.
- 15 base chứ không phải 32: hiệu ứng nhỏ (|Δcf|<0.02) không phân biệt được với nhiễu.
- Chưa kiểm hoa ẩn theo tác động lên người chơi thật (cần dữ liệu người chơi).

---

## Câu hỏi 1. Knob nào làm tăng độ khó mạnh nhất, knob nào gần như không đổi hoặc làm dễ hơn?

### Takeaway
Mạnh nhất và nhất quán nhất: thêm một cốc hoặc một hoa/chậu mỗi loại (cups+1, capacity+1), thêm bất kỳ dây khóa nào, thêm loại hoa (split), băng+ánh nắng và đổi thứ tự incoming. Hoa ẩn chỉ làm khó nhẹ (cf khoảng -0.02, tương đương khoảng 10% cf nền), gần như vô hiệu so với khóa. Làm dễ rõ nhất: thêm dây trống (đỗ xe, +0.156 cf, 100% level) và gộp loại hoa (merge).

### Cited Findings
Bảng xếp hạng theo Δcf (so với bản sạch, cf nền 0.221, wr nền 0.041, br nền 5.72, lexp nền 6.78). Δ = trung bình ± SE theo cặp. "Nhất quán" = %level Δcf dương / %level Δcf âm.

| Knob (biến thể) | n cặp | Δcf | Nhất quán cf (+/−) | Δwr | Δbr | Δlexp | Δunres | Chia sẻ UNWINNABLE (≥1 lần) |
|---|---|---|---|---|---|---|---|---|
| cups+1 (thêm 1 cốc, +capacity hoa) | 14 | -0.203±0.038 | 0/100 | -0.044 | -3.52 | +1.06±0.11 | +0.79 | 0.00 |
| capacity+1 | 15 | -0.198±0.038 | 0/100 | -0.041 | -2.70 | +0.84±0.34 | +0.90 | 0.06 |
| khóa 1 dây, count=4 | 14 | -0.192±0.036 | 0/100 | -0.039 | -2.45 | +0.94±0.19 | +0.82 | 0.06 |
| khóa 1 dây, count=3 | 15 | -0.182±0.031 | 0/100 | -0.030 | -2.48 | +0.85±0.20 | +0.80 | 0.06 |
| khóa 1 dây, count=2 | 15 | -0.175±0.031 | 0/100 | -0.026 | -2.42 | +0.83±0.21 | +0.77 | 0.06 |
| khóa 1 dây, count=1 | 14 | -0.175±0.034 | 0/100 | -0.035 | -2.33 | +0.39±0.24 | +0.43 | 0.00 |
| khóa 2 dây, count=2 | 14 | -0.172±0.016 | 0/100 | -0.025 | -2.31 | -0.62±0.66 (bão hòa) | +0.79 | 0.31 |
| khóa 2 dây, count=1 | 15 | -0.178±0.030 | 0/100 | -0.031 | -2.98 | -1.57±0.68 (bão hòa) | +0.80 | 0.53 |
| khóa 3 dây, count=2 | 15 | -0.221±0.037 | 0/100 | -0.041 | -2.84 | -2.20±0.83 (bão hòa) | +1.00 | 0.94 |
| collect_type, count=1, loại cốc muộn | 15 | -0.179±0.027 | 0/100 | -0.044 | -2.85 | +0.48±0.57 | +0.86 | 0.12 |
| collect_type, count=1, loại cốc sớm | 15 | -0.132±0.013 | 0/100 | -0.019 | -2.38 | +0.11±0.52 | +0.53 | 0.06 |
| split loại (+1 loại hoa) | 15 | -0.142±0.023 | 0/100 | -0.032 | -1.92 | +0.73±0.16 | +0.50 | 0.00 |
| băng, blockConnection, k=3, nắng sớm | 15 | -0.159±0.026 | 0/100 | -0.024 | -2.18 | +0.68±0.19 | +0.53 | 0.00 |
| cups-1 (bỏ 1 cốc) | 15 | -0.113±0.043 | 27/73 | -0.018 | -1.76 | +0.25±0.22 | +0.23 | 0.00 |
| thứ tự incoming đảo ngược | 14 | -0.090±0.041 | 29/71 | -0.037 | -0.52 | +0.81±0.20 | +0.64 | 0.00 |
| thứ tự incoming xáo ngẫu nhiên | 14 | -0.083±0.035 | 21/79 | -0.044 | -1.11 | +0.77±0.23 | +0.50 | 0.00 |
| băng, k=3, nắng muộn | 14 | -0.077±0.020 | 14/86 | -0.039 | +1.44 | +0.98±0.12 | +0.71 | 0.00 |
| băng, k=3, nắng sớm | 14 | -0.069±0.018 | 14/86 | -0.021 | +1.24 | +0.45±0.21 | +0.39 | 0.00 |
| băng, k=6, nắng sớm | 14 | -0.063±0.016 | 7/93 | -0.014 | +1.65 | +0.54±0.16 | +0.46 | 0.00 |
| frozenPots 1 chậu, nắng sớm | 15 | -0.056±0.014 | 27/73 | -0.014 | +0.64 | +0.64±0.16 | +0.50 | 0.00 |
| unbury3 (đưa hoa cần xuống gần đuôi) | 15 | -0.043±0.015 | 13/87 | -0.018 | +0.15 | +0.31±0.09 | 0.00 | 0.00 |
| cross_swap 6 cặp | 14 | -0.040±0.010 | 29/71 | -0.021 | +0.01 | -0.01±0.16 | +0.07 | 0.00 |
| cross_swap 3 cặp | 14 | -0.036±0.010 | 0/93 | -0.023 | -0.16 | +0.08±0.11 | +0.07 | 0.00 |
| shuffle 2 dây ít phân mảnh | 15 | -0.025±0.010 | 40/60 | -0.013 | -0.02 | +0.00±0.17 | +0.03 | 0.00 |
| hoa ẩn 20% (ngẫu nhiên) | 14 | -0.021±0.010 | 29/71 | -0.004 | -0.40 | +0.16±0.12 | 0.00 | 0.00 |
| hoa ẩn 30% (ngẫu nhiên) | 15 | -0.016±0.013 | 33/67 | -0.011 | -0.32 | +0.08±0.17 | +0.13 | 0.00 |
| hoa ẩn 10% (ngẫu nhiên) | 14 | -0.014±0.008 | 21/79 | -0.013 | -0.13 | +0.04±0.11 | +0.07 | 0.00 |
| shuffle 1 dây ít phân mảnh | 14 | -0.013±0.008 | 29/57 | -0.010 | -0.03 | +0.14±0.16 | +0.07 | 0.00 |
| sức chứa riêng (2 dây capacity-1) | 15 | -0.011±0.009 | 40/60 | -0.004 | -0.71 | -0.07±0.13 | 0.00 | 0.00 |
| thứ tự incoming: hoán vị loại chậu | 15 | -0.011±0.012 | 27/60 | -0.023 | +0.09 | +0.14±0.13 | +0.13 | 0.00 |
| dồn hoa vào dây trắng initial (60% capacity) | 14 | -0.000±0.000 | 7/7 | +0.001 | +0.05 | +0.06±0.10 | +0.04 | 0.00 |
| chậu trắng incoming, xuất hiện muộn | 15 | -0.008±0.007 | 7/33 | -0.028 | +0.16 | +0.42±0.08 | +0.17 | 0.00 |
| bury3 (đưa hoa cần lên gần chậu) | 14 | +0.026±0.009 | 86/14 | +0.006 | -0.37 | -0.17±0.11 | 0.00 | 0.00 |
| chậu trắng incoming, xuất hiện sớm | 14 | +0.038±0.014 | 79/21 | -0.018 | +1.38 | +0.67±0.12 | +0.32 | 0.00 |
| merge 1 loại (số loại -1) | 14 | +0.043±0.014 | 79/7 | +0.013 | +0.10 | -0.29±0.12 | 0.00 | 0.00 |
| merge 2 loại (số loại -2) | 14 | +0.114±0.027 | 93/7 | +0.081±0.033 | +0.68 | -0.41±0.15 | +0.04 | 0.00 |
| thêm 1 dây trống vào initial (parking) | 11 | +0.156±0.023 | 100/0 | +0.026 | +5.82 | +0.56±0.17 | +0.23 | 0.00 |

Thêm: số lần 3 dây khóa lập tức làm 94% level UNWINNABLE; 2 dây khóa làm 31% (count=2) đến 53% (count=1) level UNWINNABLE; 1 dây khóa làm 0-12% UNWINNABLE (xem câu hỏi 3).

Nhất quán theo mức độ khó gốc (cf Δ ở nhóm 5 level thấp / giữa / cao summaryScore):
- khóa 1 dây count=2: -0.246 / -0.160 / -0.120 (mạnh hơn ở level dễ)
- capacity+1: -0.305 / -0.141 / -0.147; cups+1: -0.342 / -0.164 / -0.130; xáo thứ tự incoming: -0.215 / -0.048 / -0.013; split: -0.196 / -0.131 / -0.100
- parking (thêm dây trống): +0.186 / +0.127 / +0.161 (ổn định); merge2: +0.097 / +0.095 / +0.147 (mạnh hơn ở level khó); hoa ẩn 20%: +0.003 / -0.028 / -0.033 (không có tác động ở level dễ)

### Inferences
- Xếp hạng "mạnh nhất trên một đơn vị thay đổi" (theo Δcf, nhất quán 100% và unres): cups+1 ≈ capacity+1 ≈ khóa (bất kỳ dây nào) > split loại ≈ băng blockConnection > đổi thứ tự incoming ≈ băng nắng muộn > hoán đổi/trộn hoa > hoa ẩn (nhẹ) > dồn dây trắng ≈ sức chứa riêng ≈ hoán loại chậu (≈0).
- Chiều dễ hơn: thêm dây trống (parking) là knob "dễ hơn" mạnh nhất, ổn định ở mọi mức; merge loại hoa là knob làm dễ thứ hai; chậu trắng incoming xuất hiện sớm làm dễ hơn chút (cf +0.038) nhưng vì phình không gian trạng thái nên solver DFS lại cần nhiều nút hơn (lexp +0.67, unres +0.32). Hai chỉ số cf và lexp ngược chiều nhau ở các knob thêm chỗ chứa: thêm chỗ chứa làm bot ngẫu nhiên tiến xa hơn, nhưng DFS khó cạn hơn.
- Khóa hầu như chỉ tác động bởi "có hay không có" khóa: Δcf không đổi nhiều khi count từ 1 lên 4 (-0.175 tới -0.192), nhưng DFS khó cạn hơn khi count lớn (unres 0.43 → 0.84). Tức count lớn làm khó cho người suy luận dài hơn là cho bot ngẫu nhiên.
- Kết quả cho cups-1 (cf -0.113, có vẻ ngược chiều trực giác) cần nghi ngờ phương pháp: khi bỏ một chậu và các hoa của dây bị bỏ phải nhét lại vào chỗ trống ngẫu nhiên, ta làm đầy các dây thêm (ít chỗ trống hơn) và dễ gây kẹt. Không nên diễn giải như "bớt một cốc làm khó hơn".
- Với bản gốc (tự nhiên) so với bản sạch, hoa ẩn + khóa chỉ làm cf -0.031, trong khi khóa chèn ngẫu nhiên vào level sạch làm -0.175 hoặc hơn. Nghĩa là khóa của nhà thiết kế gốc được đặt có chọn lọc (và đi cùng chỉnh sửa khác), không thể thay bằng khóa chèn ngẫu nhiên.

### Gaps
- Không có dữ liệu cho bố cục 2 hàng (xem Câu hỏi 0).
- Không xác định được "đơn vị" công bằng giữa các knob (1 cốc so với 1 dây khóa) — bảng xếp hạng chỉ ở đơn vị thay đổi tối thiểu có thể.
- Effect cups-1 chưa kiểm chứng bằng phương pháp thứ hai.

---

## Câu hỏi 2. Vị trí và cách phân bố có quan trọng hơn số lượng không (hoa ẩn, dây khóa, chậu trắng)?

### Takeaway
Với hoa ẩn, vị trí/phân bố gần như không có tác động đo được bằng bot và solver: mọi so sánh cùng số lượng (đáy so với đầu, dồn một dây so với rải, liền nhau so với xen kẽ, initial so với incoming) cho |Δcf| ≤ 0.03 và hầu hết không vượt 2 SE. Giả thuyết "hoa ẩn dồn ở đáy dễ hơn xen kẽ" không được chứng minh bằng bot (và solver cho dấu ngược lại một chút). Với dây khóa, "khóa muộn/count lớn", "type cốc muộn" và "khóa dây chứa hoa cần sớm" thay đổi unres/lexp và nguy cơ UNWINNABLE nhiều hơn là cf. Chậu trắng: initial (dây trống) làm dễ rõ nhất; chậu trắng incoming xuất hiện sớm dễ hơn xuất hiện muộn.

### Cited Findings

**Hoa ẩn, cùng số lượng (hid_pos*, n cặp 7-17; Δ so với bản sạch, n hoa ẩn ghi trong cột 1):**

| Biến thể (n hoa ẩn, vùng) | Δcf | Nhất quán cf | Δlexp | Δunres |
|---|---|---|---|---|
| n=3, đáy, rải 3 dây, initial | -0.014±0.007 | 33/67 | -0.23±0.14 | 0.00 |
| n=3, đầu, rải 3 dây, initial | +0.001±0.005 | 50/50 | -0.12±0.13 | +0.04 |
| n=3, ngẫu nhiên, rải, initial | -0.007±0.008 | 36/57 | -0.06±0.13 | +0.04 |
| n=3, đáy, dồn 1 dây, initial | -0.016±0.008 | 27/73 | -0.11±0.11 | 0.00 |
| n=3, đầu, dồn 1 dây, initial | -0.022±0.008 | 27/73 | -0.10±0.09 | 0.00 |
| n=3, ngẫu nhiên, dồn 1 dây, initial | -0.025±0.008 | 21/79 | -0.16±0.13 | +0.04 |
| n=3, đáy, rải, incoming | -0.010±0.004 | 21/64 | -0.04±0.08 | 0.00 |
| n=3, đầu, rải, incoming | +0.000±0.004 | 47/40 | -0.04±0.07 | 0.00 |
| n=3, đáy, dồn, incoming | +0.005±0.003 | 53/20 | -0.03±0.05 | 0.00 |
| n=4, đáy, dồn 1 dây, initial | -0.016±0.009 | 8/92 | +0.24±0.10 | +0.17 |
| n=4, đầu, dồn 1 dây, initial | -0.018±0.010 | 8/92 | +0.12±0.10 | +0.08 |
| n=5, đáy, rải, initial (n=6-7 cặp) | -0.028±0.016 | 17/67 | -0.20±0.19 | 0.00 |
| n=5, đầu, rải, initial (n=6-7 cặp) | -0.013±0.013 | 50/50 | +0.06±0.19 | 0.00 |
| n=5, đáy, rải, incoming | -0.010±0.003 | 20/80 | +0.03±0.08 | +0.03 |
| n=5, đầu, rải, incoming | -0.000±0.006 | 53/47 | +0.02±0.10 | +0.03 |
| n=2, liền nhau, đáy (1 dây) | -0.015±0.005 | 18/82 | +0.21±0.09 | +0.05 |
| n=2, xen kẽ, đáy (1 dây) | -0.011±0.004 | 18/73 | -0.03±0.13 | +0.05 |
| n=2, liền nhau, đầu | -0.005±0.008 | 42/58 | +0.17±0.12 | +0.12 |
| n=2, xen kẽ, đầu | -0.006±0.005 | 33/67 | +0.06±0.09 | 0.00 |
| n=2, rải 2 dây, đáy | -0.021±0.008 | 18/82 | -0.01±0.14 | +0.05 |

**Đối chiếu trực tiếp (hiệu theo cặp giữa hai biến thể, cùng base, cùng số hoa ẩn):**

| So sánh (A − B) | n | Δcf | Nhất quán | Δlexp | Δunres |
|---|---|---|---|---|---|
| n=3 dồn: đáy − đầu | 17 | +0.006±0.005 | 35/12 | -0.01±0.06 | 0.00 |
| n=3 rải: đáy − đầu | 16 | -0.024±0.008 | 19/81 | -0.13±0.09 | -0.03 |
| n=4 dồn: đáy − đầu | 14 | +0.002±0.002 | 14/14 | +0.10±0.05 | +0.07 |
| n=5 rải: đáy − đầu (initial) | 7 | -0.027±0.021 | 29/71 | -0.20±0.22 | 0.00 |
| n=5 rải: đáy − đầu (incoming) | 17 | -0.009±0.007 | 47/53 | -0.02±0.10 | 0.00 |
| n=3 đáy: dồn − rải | 17 | +0.002±0.008 | 47/53 | +0.08±0.10 | 0.00 |
| n=3 đầu: dồn − rải | 16 | -0.029±0.009 | 19/81 | -0.04±0.12 | -0.03 |
| n=2 đáy: liền nhau − xen kẽ | 13 | -0.004±0.005 | 46/54 | +0.24±0.09 | 0.00 |
| n=2 đầu: liền nhau − xen kẽ | 14 | +0.004±0.007 | 57/43 | +0.17±0.11 | +0.11 |
| n=2 liền nhau: đáy − đầu | 13 | -0.004±0.006 | 38/62 | -0.08±0.13 | -0.08 |
| n=2 xen kẽ: đáy − đầu | 13 | +0.002±0.005 | 46/54 | -0.16±0.11 | +0.04 |
| n=2 đáy: liền nhau (1 dây) − rải (2 dây) | 13 | +0.008±0.006 | 54/46 | +0.19±0.13 | 0.00 |
| n=3 đáy rải: incoming − initial | 16 | +0.009±0.005 | 69/31 | +0.17±0.12 | 0.00 |
| n=3 đầu rải: incoming − initial | 16 | -0.007±0.009 | 44/56 | +0.01±0.10 | -0.03 |
| n=5 đáy rải: incoming − initial | 7 | +0.023±0.011 | 71/29 | +0.20±0.23 | 0.00 |
| n=5 đầu rải: incoming − initial | 7 | +0.010±0.013 | 71/29 | +0.15±0.20 | +0.07 |
| số lượng: H20 − H10 (ngẫu nhiên) | 14 | -0.006±0.011 | 29/71 | +0.12±0.13 | -0.07 |
| số lượng: H30 − H20 (ngẫu nhiên) | 14 | -0.003±0.014 | 36/64 | -0.10±0.16 | +0.14 |

**Dây khóa, cùng "mức" khóa, khác vị trí/thời điểm:**

| So sánh | n | Δcf | Nhất quán | Δlexp | Δunres | Ghi chú |
|---|---|---|---|---|---|---|
| khóa dây chứa hoa cần sớm − dây chứa hoa cần muộn (count=2) | 16 | +0.021±0.030 | 25/56 | +0.63±0.31 | +0.19 | br +2.24; xác suất UNWINNABLE: early 0.00 so với late 0.24 |
| collect_type loại cốc muộn − loại cốc sớm (count=1) | 16 | -0.043±0.024 | 0/31 | +0.40±0.15 | +0.31 | UNWINNABLE: 0.12 so với 0.06 |
| 1 dây: count=4 − count=1 | 16 | -0.017±0.007 | 6/50 | +0.55±0.14 | +0.41 | UNWINNABLE 0.06 so với 0.00 |
| 1 dây: count=2 − count=1 | 16 | -0.004±0.006 | 19/38 | +0.43±0.14 | +0.34 | |
| 2 dây − 1 dây (count=2) | 16 | +0.004±0.019 | 12/56 | -1.23±0.65 (bão hòa) | +0.03 | UNWINNABLE: 0.31 so với 0.06 |
| 3 dây − 2 dây (count=2) | 16 | -0.047±0.026 | 6/31 | -1.41±0.84 (bão hòa) | +0.19 | UNWINNABLE: 0.94 so với 0.31 |
| 2 dây − 1 dây (count=1) | 16 | -0.007±0.034 | 12/50 | -2.13±0.71 (bão hòa) | +0.34 | UNWINNABLE: 0.53 so với 0.00 |

**Chậu trắng (parking):**

| So sánh | n | Δcf | Nhất quán | Δlexp | Δunres | Δbr |
|---|---|---|---|---|---|---|
| chậu trắng incoming muộn − sớm | 16 | -0.053±0.016 | 19/81 | -0.23±0.10 | -0.12 | -1.32±0.35 |
| dây trống initial − chậu trắng incoming sớm | 11 | +0.123±0.020 | 100/0 | -0.11±0.15 | -0.14 | +5.17±0.31 |
| dây trống initial (so với sạch) | 11 | +0.156±0.023 | 100/0 | +0.56±0.17 | +0.23 | +5.82 |
| chậu trắng incoming sớm (so với sạch) | 14 | +0.038±0.014 | 79/21 | +0.67±0.12 | +0.32 | +1.38 |
| chậu trắng incoming muộn (so với sạch) | 15 | -0.008±0.007 | 7/33 | +0.42±0.08 | +0.17 | +0.16 |

**Vị trí hoa của chính mình trong dây (burial):** `bury3` (đẩy hoa cần lên gần chậu) +0.026±0.009 cf (86/14, dễ hơn); `unbury3` (đưa hoa cần xuống gần đuôi) -0.043±0.015 (13/87, khó hơn); `unbury − bury` = -0.068±0.014 (6/94), lexp +0.43±0.13, br +0.50±0.18.

### Inferences
- Hoa ẩn: hiệu ứng lớn nhất trong nhóm vị trí là "rải rác khắp nhiều dây (spread) ở đáy làm khó hơn rải ở đầu" (Δcf -0.024±0.008, 81% level) và "dồn một dây ở đầu khó hơn rải ở đầu" (Δcf -0.029±0.009, 81%), cỡ 10-13% cf nền. Mọi so sánh còn lại xấp xỉ 0 trong sai số. Hướng của giả thuyết (ẩn ở đáy/dồn/liền nhau dễ hơn) không thể xác nhận: Δcf cho liền-so-với-xen-kẽ và đáy-so-với-đầu nằm trong ±0.004 quanh 0.
- Hoa ẩn liền nhau (adjacent) cho lexp cao hơn xen kẽ (+0.24±0.09 ở đáy, +0.17±0.11 ở đầu), nhưng cf không khác. Đây có thể là chênh lệch trong thứ tự duyệt DFS (nhiễu kiểu thứ tự dây 0.78), không phải khó thật; coi là không kết luận được.
- Hoa ẩn trong incoming gây hại ít hơn trong initial một chút ở dạng rải đáy (cf +0.009 đến +0.023, 69-71% level) nhưng cỡ bằng nhiễu.
- Liều: ẩn 10% → 30% không tăng độ khó theo hướng đơn điệu (cf -0.014, -0.021, -0.016; H20-H10 và H30-H20 đều trong nhiễu). Hoa ẩn bị "bão hòa" rất sớm theo các chỉ số này; số lượng cũng không quan trọng nhiều. Hiệu ứng khoảng -0.02 cf (-10% cf nền) ở level giữa/khó, không có ở level dễ (+0.003 ở nhóm summaryScore thấp).
- Dây khóa: vị trí quan trọng hơn count đối với cf. "Khóa dây chứa hoa cần sớm" (early-needed) cho unres cao hơn nhưng UNWINNABLE thấp hơn (0 so với 24%), còn khóa dây chứa hoa cần muộn làm giảm br mạnh (-3.63 so với -1.34) và hay chặn tiến trình (xem Câu hỏi 3). Đợi cốc loại muộn để mở khóa (collect_type late) khó hơn loại sớm (cf -0.043, 100% hướng khó).
- Chậu trắng: độ dễ lớn nhất đến từ dây trống ở initial (+0.156 cf) rồi chậu trắng incoming xuất hiện sớm (+0.038); chậu trắng incoming xuất hiện muộn gần như không có tác dụng (-0.008). Nhưng dây trắng initial vốn đã có (1 hoa) nên "dồn" hoa vào đó (fill_white_ini) không đổi cf (0.000), tức khoảng trống chứ không phải bản thân dây trắng mới là biến số.
- Vị trí hoa "cần" trong dây là biến số mạnh hơn hoa ẩn: Δcf giữa unbury và bury là -0.068 (94% level). Hướng này ngược trực giác "chôn sâu = khó": chôn hoa cần lên đầu (gần chậu) lại làm bot dễ hơn. Giả thuyết cơ chế (chưa kiểm): khi hoa cần ở gần đuôi và bị chặn bởi hoa lạ, bot ngẫu nhiên hay di chuyển nhầm hoa cần; khi hoa lạ ở đáy dễ bị chuyển đi hết.

### Gaps
- Không xác nhận được ảnh hưởng của hoa ẩn tới người chơi (bot không có trí nhớ/bất định; solver biết trạng thái thật, chỉ không được cắt từ hoa ẩn).
- Các so sánh n=5 spread ở initial chỉ có 6-7 cặp (đòi hỏi 5 dây đủ dài).
- "Khóa sớm/muộn" mới được thử qua count (1 so với 4) và qua loại cốc (collect_type) chứ chưa thử cùng một dây ở các vị trí khác nhau trong initial.

---

## Câu hỏi 3. Knob nào an toàn để generator tinh chỉnh độ khó (giữ hợp lệ và giải được)?

### Takeaway
Tất cả 1098 biến thể đều qua `validate()` (0 lỗi), nên "hợp lệ" không phải rủi ro. Rủi ro là không giải được và DFS không tìm ra nghiệm. Hoa ẩn, trộn hoa, hoán loại chậu incoming, sức chứa riêng và dây trống an toàn (UNWINNABLE 0%, unres thấp). Khóa là rủi ro nhất: ≥2 dây khóa thường UNWINNABLE.

### Cited Findings
Tỉ lệ biến thể bị UNWINNABLE ít nhất một lần (solver duyệt cạn) và trung bình `unres` (DFS không giải trong 3000 nút), trên 9-17 level:

| Knob | UNWINNABLE ≥1 lần | unres trung bình |
|---|---|---|
| hoa ẩn (mọi cấu hình đã thử, n=2-5, 10-30%) | 0.00 | 0.00-0.17 |
| trộn hoa (shuffle, cross_swap, bury, unbury) | 0.00 | 0.00-0.09 |
| hoán loại chậu incoming (pots_perm) | 0.00 | 0.12 |
| sức chứa riêng của 2 dây (columnCaps) | 0.00 | 0.00 |
| dồn dây trắng initial | 0.00 | 0.06 |
| merge loại hoa 1-2 | 0.00 | 0.00-0.03 |
| thêm dây trống | 0.00 | 0.29 (DFS phải duyệt thêm) |
| chậu trắng incoming (sớm, muộn) | 0.00 | 0.34, 0.21 |
| băng + nắng (mọi chế độ đã thử) | 0.00 | 0.47-0.75 (DFS khó giải) |
| thứ tự incoming xáo ngẫu nhiên / đảo | 0.00 | 0.50 / 0.66 |
| capacity+1 | 0.06 | 0.91 |
| cups+1 / cups-1 | 0.00 / 0.00 | 0.75 / 0.21 |
| split loại | 0.00 | 0.44 |
| khóa 1 dây (count 1/2/3/4) | 0.00 / 0.06 / 0.06 / 0.06 | 0.44 / 0.79 / 0.82 / 0.84 |
| collect_type, loại sớm / muộn | 0.06 / 0.12 | 0.59 / 0.88 |
| khóa dây chứa hoa cần sớm / muộn (count 2) | 0.00 / 0.24 | 0.75 / 0.59 |
| khóa 2 dây (count 2 / count 1) | 0.31 / 0.53 | 0.81 / 0.79 |
| khóa 3 dây (count 2) | 0.94 | 1.00 |
| hoa ẩn + khóa 2 dây (HL) | 0.27 | 0.87 |
| khóa + dây trống (LP) | 0.00 | 1.00 |
| ẩn + khóa + dây trống (HLP) | 0.00 | 1.00 |

### Inferences
- Knob "an toàn" cho generator (không rủi ro mất nghiệm, đổi cf dưới 0.05): hoa ẩn, trộn hoa (cross_swap, shuffle), hoán loại chậu incoming, sức chứa riêng, dồn dây trắng. Nhưng các knob này gần như chỉ dịch cf trong khoảng ±0.04 nên "tầm với" độ khó nhỏ.
- Knob làm dịch độ khó nhiều nhưng vẫn giải được: capacity ±1, cups ±1, split/merge loại hoa, băng+nắng, dây trống. Những knob này cần kiểm tra bằng solver sau khi thay đổi vì unres tăng mạnh (DFS 3000 nút không đủ; cần node_cap lớn hơn hoặc solver tốt hơn).
- Khóa: chỉ 1 dây, count ≤ 3, và đã kiểm solver; 2-3 dây khóa nên bị loại bỏ trừ khi đã chứng minh WINNABLE. Với khóa 2 dây count=2, 31% level mất nghiệm, và vì level gốc của nhà thiết kế có ít khóa hơn nhiều so với kết quả này, khóa nên được dựng đồng thời với bố trí hoa (đặt hoa "cần để mở khóa" ở dây không khóa).
- Khi `unres` ≥ 0.8, người dùng generator không thể dựa vào DFS 3000 nút để xác nhận giải được; cần node_cap cao hơn hoặc solver khác (ví dụ A* của `hint_win_path`).

### Gaps
- Ngưỡng node_cap đủ để phân biệt "khó" và "không giải được" cho level có khóa/băng chưa được xác định.
- Chưa thử chính xác độ nhạy của UNWINNABLE theo số lượng hoa cần mở khóa ở các dây còn lại (mới thử count ≤ 4).

---

## Câu hỏi 4. Tương tác không cộng tính (non-additive)

### Takeaway
Các cặp tương tác đều dưới-cộng-tính (sub-additive): ghép hai knob làm khó cho kết quả nhỏ hơn tổng. Nổi bật nhất: dây khóa triệt tiêu lợi ích của dây trống; hoa ẩn không cộng thêm gì khi đã có khóa hoặc dây trống.

### Cited Findings
Δ so với bản sạch, 9-15 level (H = ẩn 15% ngẫu nhiên, L = khóa 2 dây count=2, P = thêm 1 dây trống):

| Tổ hợp | Δcf | Nhất quán | Δbr | Δunres | UNWINNABLE |
|---|---|---|---|---|---|
| H | -0.030±0.010 | 15/77 | -0.20 | 0.00 | 0.00 |
| L | -0.216±0.039 | 0/100 | -3.25 | +0.93 | 0.25 |
| P | +0.150±0.025 | 100/0 | +5.86 | +0.25 | 0.00 |
| HL | -0.225±0.041 | 0/100 | -3.01 | +0.92 | 0.27 |
| HP | +0.150±0.032 | 89/11 | +6.03 | +0.28 | 0.00 |
| LP | -0.174±0.012 | 0/100 | +0.52 | +1.00 | 0.00 |
| HLP | -0.164±0.015 | 0/100 | -0.18 | +1.00 | 0.00 |

Phần dư tương tác (Δ_kết hợp − ΔA − ΔB, trung bình ± SE theo cặp):

| Tương tác | n | Δcf dư | Δlexp dư | Δunres dư |
|---|---|---|---|---|
| HL − H − L | 13 | +0.030±0.010 | -0.61±0.55 | 0.00 |
| HP − H − P | 9 | +0.041±0.016 | -0.25±0.12 | 0.00 |
| LP − L − P | 9 | -0.144±0.027 | +0.83±0.87 | -0.28±0.12 |
| (H|L) − L | 15 | -0.002±0.003 | -0.42±0.44 | 0.00 |
| (H|P) − P | 10 | +0.003±0.011 | -0.01±0.06 | 0.00 |

### Inferences
- Hoa ẩn bị "nuốt" bởi các knob khác: khi đã có khóa (hoặc dây trống), thêm hoa ẩn không làm đổi cf (-0.002±0.003 và +0.003±0.011). Hiệu ứng riêng của hoa ẩn (-0.030) nằm trong dao động của hiệu ứng khóa.
- Khóa và dây trống dùng chung một nguồn "lợi ích": dây trống cho +0.150 cf, nhưng khi có khóa, phần cộng thêm chỉ còn +0.042 (LP − L = -0.174 − (-0.216)), tức mất khoảng 72% lợi ích. Đồng thời LP làm DFS không tìm ra nghiệm ở 100% level (unres 1.00): khóa + thêm dây trống phình không gian trạng thái.
- Khóa làm tăng tỉ lệ UNWINNABLE khi cộng với hoa ẩn (HL 0.27 so với L 0.25: không khác), nhưng dây trống cứu level: LP/HLP có UNWINNABLE 0.00 thay vì 0.25 (đây là hiệu ứng "dây trống bù lại độ cứng của khóa" trên khả năng giải).
- Nên dùng solver kiểm trực tiếp từng tổ hợp thay vì cộng độ khó từ thành phần.

### Gaps
- Chưa thử đủ 2×2 cho băng × khóa và băng × hoa ẩn.
- Mẫu tương tác (n=9-15) quá nhỏ cho kết luận chắc chắn về dấu của phần dư lexp.

---

## Câu hỏi 5. Thiết kế của chính các bank gốc (sunlight tier 1-5, special challenge)

### Takeaway
Phần này nằm ngoài phạm vi sau cập nhật: người dùng yêu cầu chỉ dùng level builtin có summaryScore, không dùng sunlight bank/special challenge/fallback để thống kê hay kết luận. Tôi chỉ đọc chúng để hiểu cú pháp của băng, sức chứa riêng và 2 hàng.

### Cited Findings
- Cú pháp được dùng để dựng perturbation băng/columnCaps: `assets/game/juice_sunlight_levels.json` có `sunlight:{typeId}`, `iceMode`, hoa `iN`, schema `juice-level/3`; `special_challenge_levels_v2.json` dùng `columnCaps:{initial:[...],incoming:[...]}` (ví dụ dây trắng 2 đầu capacity 4, dây colored capacity 6). `JuiceLevel.validate` yêu cầu 2 hàng: capacity=4, 4+4/5+4/5+5 dây có màu, tối đa 2 dây độc lập rỗng (`juice_level.gd` dòng 630-636).

### Inferences
- Không có.

### Gaps
- Không phân tích các tier 1-5 hay level_user_tags (đúng theo chỉ đạo phạm vi).

---

## Phụ lục. Mã chính

### Phụ lục A: Mã Godot đo chỉ số (`/home/user/GodotProject/.godot/mech_metrics.gd`, rút gọn)
```gdscript
extends SceneTree
# args: in.json out.json shard nshards [seeds] [plays]
func _dfs(raw: Dictionary, cap: int) -> Array:
	var lv := JuiceLevel.from_dict(raw)
	var search := JuiceSolver.begin_full_search(JuiceRules.make_state(lv), lv)
	var res: int = JuiceSolver.advance_full_search(search, lv, {"node_cap": cap, "state_cap": 40000})
	return [res, int(search["expanded"])]   # res: 0 UNKNOWN, 1 WINNABLE, 2 UNWINNABLE

func _perm_raw(raw, rng):  # hoán vị thứ tự dây initial (và columnCaps.initial) để đo độ nhạy DFS
	...
func _initialize() -> void:
	...
	for sd in seeds:                      # 3 seed x 20 lượt chơi ngẫu nhiên
		rng.seed = 1000 + sd * 7919
		for p in plays:
			var st := JuiceRules.make_state(lv)
			for step in 250:
				if JuiceRules.is_win(st, lv): wins += 1; break
				var ms: Array = JuiceRules.useful_moves(st)
				if ms.is_empty(): stuck = true; break
				br += ms.size(); brn += 1
				var mv: Dictionary = ms[rng.randi_range(0, ms.size() - 1)]
				JuiceRules.apply_move(st, lv, int(mv.src), int(mv.j), int(mv.dst))
			cups_frac += float(int(st["done"])) / float(lv.groups_total)
	var d0 := _dfs(raw, 3000)                       # thứ tự dây gốc
	var d1 := _dfs(_perm_raw(raw, rng), 3000)       # thứ tự dây hoán vị
	out["expanded"] = [d0[1], d1[1]]; out["res"] = [d0[0], d1[0]]
	out["cups_frac"] = cups_frac / nplays; out["win_rate"] = wr; out["branch"] = br / brn
```
Chạy: `cd /home/user/GodotProject && godot --headless --path . -s res://.godot/mech_metrics.gd -- in.json out.jsonl <shard> 4 3 20` (4 shard song song).

### Phụ lục B: Mã Python dựng nhiễu loạn (`lvl.py`, rút gọn)
```python
def clean(l):                       # bản sạch: bỏ ? và i, khóa về default
    for r in l.allropes():
        r['fl'] = [x.lstrip('?i') for x in r['fl']]
        r['type'] = 'default'; r['info'] = {}
def hide_positions(l, spec, rng):   # spec=(vùng,n,mode)
    # bottom_spread: idx=len-2 trên n dây khác nhau; top_spread: idx=0
    # bottom_conc: idx=len-2-k, k<n trong 1 dây; top_conc: idx=0..n-1; inter_conc: idx=len-2-2k
def lock_rope(l, idxs, counts, ctype=None):
    r['type']='unlock'; r['info']={'condition':'collect_count','count':c}   # hoặc collect_type + typeId
def inc_white(l, where):            # lấy 2 hoa cuối của mục incoming p, đưa vào chậu '-' chèn tại p, xóa 1 'x|'
def cap_change(l, delta, rng):      # thêm/bớt p_t hoa loại t cho mỗi chậu loại t -> cân bằng
def merge_types(l, k, rng): relabel(l, a, b)            # số loại -k
def bury(l, m, rng, 'bury'|'unbury'): # đổi hoa cần gần đuôi nhất với hoa lạ xa đuôi nhất (và ngược lại)
def ice(l, k, rng, sun, mode, fpots): # sunlight.typeId=loại chậu initial/incoming; k hoa 'iN' không phải đuôi
```
So sánh theo cặp: `analyze2.py` (Δ = biến thể − bản sạch cùng base; trung bình ± SE = SD/√n; nhất quán = %Δ>0 / %Δ<0).

### Tệp dữ liệu (nguồn của mọi con số)
Thư mục `/tmp/claude-0/-home-user-GodotProject/789c606f-fe6b-525e-85bc-e2eb0b400faa/scratchpad/research_work/mechanics/`:
- `lvl.py`, `gen.py`, `gen2.py`, `pick.py`, `analyze2.py`: mã dựng và phân tích
- `variants.json`, `variants2.json`, `variants3f.json`: toàn bộ biến thể (raw JSON level)
- `done1.jsonl`, `done2.jsonl`, `var3_out*.jsonl`: kết quả đo từng biến thể (1098 dòng); `clean_out*.jsonl`: 64 bản sạch ban đầu (62 WINNABLE)
- Script Godot: `/home/user/GodotProject/.godot/mech_metrics.gd` (thư mục git-ignored, không sửa file được git theo dõi; `git status --short` rỗng)
