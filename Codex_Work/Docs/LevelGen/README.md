# Sweet Rope – Hướng dẫn sinh level

Tài liệu này dành cho AI (hoặc người) bắt đầu sinh màn chơi cho Sweet Rope. Đọc hết một lượt trước khi tạo màn đầu tiên.

**Nhiệm vụ:** sinh **200 màn** cho Sweet Rope, một bản duy nhất cho mọi người chơi. Mỗi màn phải:
1. đúng định dạng level của engine (mục 2), qua được hàm kiểm tra `JuiceLevel.validate()` (mục 3);
2. giải được, kiểm bằng solver của engine (mục 6);
3. có độ khó gần với **điểm mục tiêu** của màn đó (mục 5 và mục 7);
4. ra mắt cơ chế mới đúng màn đã định (mục 7).

**Không** sao chép level của Sort Streak. Repo này có bản Sort Streak 1.0.10 khôi phục lại để **tham khảo** cách engine chạy và thống kê độ khó (xem `Codex_Work/INDEX.md`). Level của Sweet Rope phải được sinh mới.

---

## 0. Bối cảnh trong repo

| Đường dẫn | Nội dung |
|---|---|
| `scripts/gameplay/juice_sort/core/juice_level.gd` | Đọc JSON level (`from_dict`) và kiểm tra (`validate`). **Nguồn sự thật cho định dạng.** |
| `scripts/gameplay/juice_sort/core/juice_rules.gd` | Luật chơi: nước đi, thu hoa vào chậu, khóa, hoa ẩn, thắng thua. |
| `scripts/gameplay/juice_sort/core/juice_solver.gd` | Solver: `full_reachability` trả về WINNABLE / UNWINNABLE / UNKNOWN. |
| `assets/builtin/chapter_default_1_5.json` | Level Sort Streak chapter 1–5. Trường `initialLayout` bị mã hóa AES; giải bằng `AESDecryptor.decrypt()` trong `scripts/data/level_data/aes_decryptor.gd`. Chỉ để tham khảo. |
| `assets/game/juice_fallback_levels.json` | 93 level Sort Streak không mã hóa, xem nhanh định dạng. |
| `assets/game/juice_sunlight_levels.json` | 426 level mẫu có **băng + ánh nắng**, xem cách viết cơ chế này. |
| `assets/game/special_challenge_levels_v2.json` | Level mẫu có **sức chứa khác nhau** (`columnCaps`). |
| `Game Design/` | Tài liệu thiết kế của team (Excel). |

Bản sao các script đo và kiểm tra nằm trong repo ở `Codex_Work/Docs/LevelGen/tools/` (`validate_level.gd`, `greedy_ext.gd`; cùng nội dung với mục 6 và Phụ lục A). Khi chạy, sao chép chúng vào `.godot/`.

Engine: Godot **4.6.1** (bản chính thức chạy được phần logic level; phần Spine/SQLite báo lỗi khi chạy headless nhưng không ảnh hưởng việc kiểm tra level).

---

## 1. Luật chơi (theo engine)

- Màn chơi có một hàng **chậu** (pot). Dưới mỗi chậu treo một **dây** (rope) xâu các **bông hoa**. Mỗi bông có một **loại** (số nguyên 0–9, tối đa 10 loại).
- Trong JSON, hoa của một dây được liệt kê **từ trên (sát chậu) xuống dưới**. Phần tử **cuối** là **đuôi dây**, nơi người chơi tương tác.
- **Nước đi:** chọn một vị trí `j` trên dây nguồn, cắt đoạn từ `j` xuống hết đuôi, rồi nối vào **đuôi** của dây đích. Hợp lệ khi:
  - dây đích rỗng, **hoặc** bông ở đầu đoạn cắt cùng loại với bông ở đuôi dây đích;
  - tổng số hoa sau khi nối không vượt **sức chứa** của dây đích;
  - cả hai dây không bị khóa.
- **Thu hoa:** chậu có loại `t` hoàn thành một **cốc** khi dây của nó **đầy đúng sức chứa** và **mọi bông đều là loại `t`**. Khi đó dây được làm trống và lấy mục kế tiếp trong `incoming` (chậu mới + hoa mới). Hoa dư nếu không vừa sẽ rải sang các dây còn chỗ.
- **Chậu trắng** (`-`): không thu hoa. Đây là dây đệm để người chơi xếp tạm.
- **Thắng:** hoàn thành đủ `targetCups` cốc. **Thua:** không còn nước đi hợp lệ (có vật phẩm hỗ trợ cứu, ngoài phạm vi tài liệu này).
- **Hoa ẩn** (`?`): hiện dấu hỏi, không thể làm đầu đoạn cắt. Bông lộ ra khi nó thành đuôi dây.
- **Dây khóa** (`columnType: "unlock"`): không di chuyển hoa vào hay ra cho đến khi đạt điều kiện, ví dụ hoàn thành đủ N cốc.
- **Băng + ánh nắng**: hoa đóng băng (`i`) chỉ nằm trong `initial`; cần một chậu thu "ánh nắng" (`sunlight.typeId`) để làm tan. Xem mẫu trong `assets/game/juice_sunlight_levels.json`.

---

## 2. Định dạng JSON của một level

```json
{
  "id": 1,
  "capacity": 4,
  "targetCups": 5,
  "initial": [
    {"column": "-|7,1,6,4", "columnType": "default", "columnInfo": {}},
    {"column": "6|",        "columnType": "default", "columnInfo": {}},
    {"column": "1|4,6,1,8", "columnType": "default", "columnInfo": {}}
  ],
  "incoming": [
    {"column": "4|1,4,4,1", "columnType": "default", "columnInfo": {}},
    {"column": "x|",        "columnType": "default", "columnInfo": {}}
  ]
}
```
(Ví dụ chỉ minh họa cú pháp, không cân bằng số hoa.)

| Trường | Bắt buộc | Ý nghĩa |
|---|---|---|
| `id` | không | Số nguyên ≥ 1. Dùng số màn. |
| `capacity` | có | Sức chứa mỗi dây (số hoa để thành 1 cốc). Số nguyên ≥ 2. Khi dùng `columnCaps`, đây là sức chứa **lớn nhất**. |
| `targetCups` | có | Tổng số cốc cần hoàn thành = tổng số chậu có màu (trong `initial` + `incoming`). |
| `initial` | có | Các dây lúc bắt đầu, tối thiểu 3. Bố cục 1 hàng tối đa **7** dây. |
| `incoming` | có | Danh sách lần lượt thay thế các dây vừa hoàn thành. Engine tự thêm `x|` cho đủ **`targetCups − 1`** mục. |
| `columnCaps` | không | `{"initial": [...], "incoming": [...]}`: sức chứa riêng từng dây (cơ chế "sức chứa khác nhau"). Độ dài phải bằng số mục tương ứng; mỗi giá trị ≤ `capacity`. |
| `layoutRows`, `layoutColumns` | không | Bố cục 2 hàng: `layoutRows: 2`, `layoutColumns` 4 hoặc 5, `capacity` bắt buộc = 4, số dây có màu = 4+4, 5+4 hoặc 5+5, thêm tối đa 2 dây trắng. |
| `sunlight` | không | `{"typeId": t}`: loại hoa đóng vai ánh nắng (cơ chế băng). |
| `iceMode` | không | `"blockCollection"` (mặc định) hoặc `"blockConnection"`. |
| `frozenPots` | không | Danh sách chỉ số dây `initial` có chậu bị đóng băng. |
| `note`, `seed` | không | Ghi chú tự do, seed. |

**Chuỗi `column`** có dạng `"<chậu>|<hoa>,<hoa>,..."`:
- `<chậu>`: số loại (`0`–`9`) là chậu thu loại đó; `-` là chậu trắng; trong `incoming`, `x|` (hoặc `x`) nghĩa là dây bị bỏ khỏi màn chơi.
- `<hoa>`: số loại; thêm `?` phía trước là hoa ẩn (`?3`); thêm `i` phía trước là hoa đóng băng (`i3`, chỉ dùng trong `initial`).
- Dây rỗng viết `"6|"` hoặc `"-|"`.

**Dây khóa:**
```json
{"column": "4|4,0,3,1", "columnType": "unlock", "columnInfo": {"condition": "collect_count", "count": 2}}
```
- `collect_count`: mở khi đã hoàn thành `count` cốc bất kỳ.
- `collect_type`: thêm `"typeId": t`, mở khi đã hoàn thành `count` cốc loại `t`.
- Dây thường bắt buộc `"columnType": "default", "columnInfo": {}`.

---

## 3. Ràng buộc bắt buộc (`JuiceLevel.validate()`)

Màn nào vi phạm, engine sẽ bỏ và thay bằng màn dự phòng. Các luật chính:
1. **Cân bằng hoa:** với mỗi loại `t`, tổng số hoa loại `t` (cả `initial` và `incoming`) **bằng** tổng sức chứa của các chậu loại `t`. Tổng số hoa = tổng sức chứa các chậu có màu.
2. **Số chậu:** số chậu có màu trong `initial` + `incoming` = `targetCups`.
3. `incoming` có đúng `targetCups − 1` mục (thiếu thì engine tự thêm `x|`); mục `x|` không được chứa hoa.
4. Mỗi dây không chứa quá sức chứa của nó. Tổng hoa ban đầu ≤ tổng sức chứa các dây ban đầu.
5. **Đuôi dây không được là hoa ẩn** (`?`), cả trong `initial` lẫn mục cuối của mỗi mục `incoming`.
6. Loại hoa và loại chậu trong khoảng 0–9. Chậu không được ẩn.
7. Số chậu trắng ban đầu ≤ số dây − 2; số dây khóa ban đầu ≤ số dây − 2; số chậu trắng trong `incoming` tối đa 4.
8. Hoa đóng băng chỉ có trong `initial`, phải có `sunlight`, và hoa ánh nắng không được đóng băng.
9. Bố cục 1 hàng: tối đa 7 dây ban đầu (chừa 1 chỗ cho vật phẩm thêm dây).

Qua `validate()` **chưa** có nghĩa là giải được. Luôn chạy solver (mục 6).

---

## 4. Quy ước thiết kế rút từ Sort Streak

Thống kê 392 level gốc (chapter 1–5):

| Thông số | Giá trị thường gặp |
|---|---|
| `capacity` | 5 (66%), 4 (17%), 6 (16%) |
| Số dây ban đầu | 6 (55%) hoặc 7 (44%) |
| Số loại hoa | 9 (84%), 8 (15%) |
| `targetCups` | 10–12 |
| Chậu trắng | 1 chậu trắng ở `initial` (dây đầu tiên), khoảng 1 chậu trắng trong `incoming` |
| Hoa ẩn | có ở khoảng 70% số màn, chiếm khoảng 12% số hoa |
| Dây khóa | có ở khoảng 40% số màn, thường `collect_count` với `count` 1–3 |

**10 màn đầu của Sort Streak** dễ dần lên theo cách sau (gợi ý cho giai đoạn làm quen):
- Màn 1: `capacity` 3, 3 cốc, 4 dây, 3 loại hoa.
- Màn 2: `capacity` 4, 5 cốc, 6 dây, 5 loại.
- Màn 3–5: `capacity` 4–5, 10–12 cốc, 6–7 dây, 9 loại; chưa có hoa ẩn hay khóa.

**Quan trọng:** trung vị các thông số cấu trúc trên gần như không đổi qua các khoảng điểm (luôn 6–7 dây, `capacity` 5, 11–12 cốc, 9 loại), nên **không** thể chọn độ khó chỉ bằng cách đổi các con số này. Có vài thông số ảnh hưởng thật nhưng yếu (số hoa lúc đầu, `targetCups`, `count` của dây khóa; xem mục 5b), còn phần lớn độ khó nằm ở **thứ tự hoa chi tiết**. Vì vậy phải đo độ khó bằng solver (mục 5).

---

## 5. Đo độ khó

Thang điểm là `summaryScore` của Sort Streak (0 là dễ nhất, khoảng 90 là khó nhất). Công thức gốc không có trong repo; không có dữ liệu người chơi thật. Bằng chứng cho thấy `summaryScore` bám sát **tỉ lệ thắng của một người chơi có heuristic nhưng mắc lỗi** (rho −0,84 với bot greedy có nhiễu), và bám yếu thước đo độ sâu tìm kiếm của solver (rho 0,34–0,44). Công thức ước lượng cũ (`win_rate` ngẫu nhiên, `branch`, `expanded`) chỉ giải thích R² ≈ 0,30 và đã **bị thay thế**. Số `branch` trong công thức cũ áp đảo kết quả (thêm một dây trống làm điểm ước lượng tụt khoảng 37), nên không dùng nữa.

### 5.1 Chỉ số khuyến nghị: bot greedy có nhiễu (`lw`)

Bot đi theo điểm nước đi `JuiceSolver.move_score`, nhưng đôi khi đi sai:
- **eps-greedy**: với xác suất `eps` chọn ngẫu nhiên trong `JuiceRules.useful_moves()`; ngược lại chọn nước có `move_score` cao nhất (hòa thì chọn ngẫu nhiên). Dùng `eps` = 0,3 / 0,45 / 0,6.
- **softmax**: chọn nước theo xác suất tỉ lệ `exp((move_score - max)/T)` với `T = 4`.
- Mỗi cấu hình chạy **2 seed (11 và 22) × 30 ván**, tối đa **300 nước** mỗi ván; ván thắng khi `JuiceRules.is_win`.
- `lw` = trung bình win-rate của 4 cấu hình (e30, e45, e60, sm4); `ld` = trung bình tỉ lệ cốc hoàn thành (`done / groups_total`) của cùng 4 cấu hình.

Script đầy đủ nằm ở **Phụ lục A** cuối README (lưu thành `.godot/greedy_ext.gd`). Chạy: `godot --headless --path . -s res://.godot/greedy_ext.gd -- in.json out.json <shard> <nshards>`, trong đó `in.json` là mảng `{"uid": ..., "raw": <level JSON>}`, `shard` từ 0 đến `nshards-1` để chia việc chạy song song. Kết quả `out.json` có, cho mỗi level, win-rate và tỉ lệ cốc hoàn thành của từng cấu hình và seed; `lw` là trung bình win-rate của 4 cấu hình. Chi phí khoảng **9,3 s/level** trên 1 core (4 cấu hình), hoặc **~2,3 s** nếu chỉ chạy một cấu hình (eps 0,45 hoặc softmax T=4, tương quan −0,81; ổn định giữa 2 seed 0,86–0,91).

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

### 5.2 Công thức 5 đặc trưng (tùy chọn)

Có thể gộp thêm 4 chỉ số từ một script solver nặng hơn (random-play 3 seed × 40 ván, beam search độ rộng 1–120, DFS `node_cap` 4000; khoảng 7,9 s/level) để được:

```
diem_uoc_luong = 32.83 - 53.67*lw - 24.49*ld + 32.32*rand_win + 4.13*ln(beam_w) + 0.602*opt_len
```

- R² kiểm chéo **0,70**, MAE **8,8**; chỉ dùng `lw` + bảng hiệu chuẩn cho R² 0,66 và MAE 9,45, kém không đáng kể. **Khuyến nghị dùng `lw` thôi**; script solver nặng này không đi kèm README.
- `ld` là trung bình tỉ lệ cốc hoàn thành của 4 cấu hình trong Phụ lục A; `rand_win` là win-rate random-play; `beam_w` là độ rộng beam nhỏ nhất tìm được lời giải; `opt_len` là độ dài đường thắng của beam. Hệ số `rand_win` dương chỉ vì cộng tuyến với `lw`.

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

---

## 6. Kiểm tra màn bằng engine

Lưu script dưới đây thành `.godot/validate_level.gd` (thư mục `.godot/` bị git bỏ qua), rồi chạy:

```bash
godot --headless --path . --import
godot --headless --path . -s res://.godot/validate_level.gd -- levels.json
```
`levels.json` là một mảng JSON các level. Lần `--import` đầu tiên có thể báo lỗi và tạo file `*.csv.import` trong `Codex_Work/`; xóa các file `.import` chưa được git theo dõi đó sau khi import.

```gdscript
extends SceneTree
# In mỗi màn: valid và solvable (kiểm tra hợp lệ + giải được). Không đo độ khó (xem mục 5).
func _initialize() -> void:
	var arr: Array = JSON.parse_string(FileAccess.get_file_as_string(OS.get_cmdline_user_args()[0]))
	for raw: Dictionary in arr:
		var lv := JuiceLevel.from_dict(raw)
		var errs: Array[String] = lv.validate()
		if not errs.is_empty():
			print("LEVEL id=%s valid=false errors=%s" % [raw.get("id", ""), " | ".join(errs)])
			continue
		var search := JuiceSolver.begin_full_search(JuiceRules.make_state(lv), lv)
		var res: int = JuiceSolver.advance_full_search(search, lv, {"node_cap": 4000, "state_cap": 20000})
		print("LEVEL id=%s valid=true solvable=%s expanded=%d" % [
			raw.get("id", ""), ["UNKNOWN", "WINNABLE", "UNWINNABLE"][res], int(search["expanded"])])
	quit()
```

- `solvable=WINNABLE` là bắt buộc. `UNKNOWN` nghĩa là solver chưa tìm ra trong giới hạn: tăng `node_cap` hoặc coi như không đạt.
- Với màn có dây khóa, băng hoặc dây trống, solver 4000 nút thường trả `UNKNOWN` dù màn vẫn giải được (xem 5b.4): tăng `node_cap` hoặc dùng `JuiceSolver.hint_win_path` để xác nhận trước khi loại màn.
- Script này chỉ kiểm tra hợp lệ và giải được. Độ khó đo bằng `greedy_ext.gd` (mục 5.1, Phụ lục A).
- Thông báo lỗi của `validate()` viết bằng tiếng Trung (code gốc). Nội dung tương ứng với các luật ở mục 3.

---

## 7. Đường độ khó mục tiêu

200 màn, 8 chapter × 25 màn (mỗi chapter là một bức tranh). Màn 5, 10, 15, … là **màn Hard**.

| Giai đoạn | Màn | Mục tiêu | Điểm TB |
|---|---|---|---|
| Làm quen | 1–10 | Cho người chơi thích game. Không cơ chế đặc biệt, không màn khó thật. | 5,6 |
| Học cơ chế | 11–25 | Ra mắt hoa ẩn và dây khóa. Màn 25 là cao trào đầu tiên. | 14,7 |
| Ổn định | 26–125 | Bám mức bộ default của Sort Streak; mỗi chapter thêm một cơ chế. | 21,0 |
| Đào sâu | 126–200 | Kết hợp cơ chế cũ, khó dần nhẹ. | 24,9 |

**Lịch ra mắt cơ chế.** Màn ra mắt phải là màn **dễ**, chỉ dạy đúng cơ chế đó, ít yếu tố gây nhiễu. Bốn màn sau dùng cơ chế với độ khó tăng dần. Không dùng một cơ chế trước màn ra mắt của nó.

| Màn | Cơ chế |
|---|---|
| 11 | Hoa ẩn (`?`) |
| 21 | Dây khóa (`columnType: "unlock"`) |
| 41 | Băng + ánh nắng (`sunlight`, `i`) |
| 61 | Dây sức chứa khác nhau (`columnCaps`) |
| 96 | Bố cục 2 hàng (`layoutRows: 2`) |
| 111 | Combo: hoa ẩn + băng |
| 146 | Combo: khóa + sức chứa khác nhau |
| 166 | Combo: 2 hàng + băng + khóa |

Tên cơ chế lấy theo engine Sort Streak. Nếu team đổi danh sách cơ chế cho Sweet Rope, giữ nguyên số màn ra mắt.

**Ghi chú trong bảng điểm:**
- `màn thở`: màn dễ hẳn chen giữa chapter để người chơi nghỉ.
- `bất ngờ`: màn khó hơn hẳn các màn xung quanh dù không phải màn Hard.
- Màn 25 của mỗi chapter là cao trào (ghép xong tranh); 5 màn đầu mỗi chapter nhẹ hơn.

### Bảng điểm mục tiêu từng màn

| Màn | Chapter | Màn trong chapter | Loại | Điểm mục tiêu | Giai đoạn | Cơ chế mới | Ghi chú |
|---|---|---|---|---|---|---|---|
| 1 | 1 | 1 | Normal | 0 | Làm quen |  |  |
| 2 | 1 | 2 | Normal | 2 | Làm quen |  |  |
| 3 | 1 | 3 | Normal | 3 | Làm quen |  |  |
| 4 | 1 | 4 | Normal | 4 | Làm quen |  |  |
| 5 | 1 | 5 | Hard | 6 | Làm quen |  |  |
| 6 | 1 | 6 | Normal | 5 | Làm quen |  |  |
| 7 | 1 | 7 | Normal | 7 | Làm quen |  |  |
| 8 | 1 | 8 | Normal | 8 | Làm quen |  |  |
| 9 | 1 | 9 | Normal | 9 | Làm quen |  |  |
| 10 | 1 | 10 | Hard | 12 | Làm quen |  |  |
| 11 | 1 | 11 | Normal | 5 | Học cơ chế | Hoa ẩn (?) |  |
| 12 | 1 | 12 | Normal | 9 | Học cơ chế |  |  |
| 13 | 1 | 13 | Normal | 11 | Học cơ chế |  |  |
| 14 | 1 | 14 | Normal | 13 | Học cơ chế |  |  |
| 15 | 1 | 15 | Hard | 14 | Học cơ chế |  |  |
| 16 | 1 | 16 | Normal | 7 | Học cơ chế |  |  |
| 17 | 1 | 17 | Normal | 16 | Học cơ chế |  |  |
| 18 | 1 | 18 | Normal | 12 | Học cơ chế |  |  |
| 19 | 1 | 19 | Normal | 20 | Học cơ chế |  |  |
| 20 | 1 | 20 | Hard | 25 | Học cơ chế |  |  |
| 21 | 1 | 21 | Normal | 12 | Học cơ chế | Dây khóa |  |
| 22 | 1 | 22 | Normal | 15 | Học cơ chế |  |  |
| 23 | 1 | 23 | Normal | 17 | Học cơ chế |  |  |
| 24 | 1 | 24 | Normal | 20 | Học cơ chế |  |  |
| 25 | 1 | 25 | Hard | 25 | Học cơ chế |  |  |
| 26 | 2 | 1 | Normal | 6 | Ổn định |  |  |
| 27 | 2 | 2 | Normal | 11 | Ổn định |  |  |
| 28 | 2 | 3 | Normal | 19 | Ổn định |  |  |
| 29 | 2 | 4 | Normal | 23 | Ổn định |  |  |
| 30 | 2 | 5 | Hard | 31 | Ổn định |  |  |
| 31 | 2 | 6 | Normal | 10 | Ổn định |  |  |
| 32 | 2 | 7 | Normal | 23 | Ổn định |  |  |
| 33 | 2 | 8 | Normal | 21 | Ổn định |  |  |
| 34 | 2 | 9 | Normal | 8 | Ổn định |  | màn thở |
| 35 | 2 | 10 | Hard | 34 | Ổn định |  |  |
| 36 | 2 | 11 | Normal | 8 | Ổn định |  |  |
| 37 | 2 | 12 | Normal | 28 | Ổn định |  | bất ngờ |
| 38 | 2 | 13 | Normal | 20 | Ổn định |  |  |
| 39 | 2 | 14 | Normal | 19 | Ổn định |  |  |
| 40 | 2 | 15 | Hard | 36 | Ổn định |  |  |
| 41 | 2 | 16 | Normal | 9 | Ổn định | Băng + ánh nắng |  |
| 42 | 2 | 17 | Normal | 15 | Ổn định |  |  |
| 43 | 2 | 18 | Normal | 19 | Ổn định |  |  |
| 44 | 2 | 19 | Normal | 22 | Ổn định |  |  |
| 45 | 2 | 20 | Hard | 24 | Ổn định |  |  |
| 46 | 2 | 21 | Normal | 13 | Ổn định |  |  |
| 47 | 2 | 22 | Normal | 25 | Ổn định |  |  |
| 48 | 2 | 23 | Normal | 24 | Ổn định |  |  |
| 49 | 2 | 24 | Normal | 11 | Ổn định |  |  |
| 50 | 2 | 25 | Hard | 39 | Ổn định |  |  |
| 51 | 3 | 1 | Normal | 10 | Ổn định |  |  |
| 52 | 3 | 2 | Normal | 20 | Ổn định |  |  |
| 53 | 3 | 3 | Normal | 18 | Ổn định |  |  |
| 54 | 3 | 4 | Normal | 22 | Ổn định |  |  |
| 55 | 3 | 5 | Hard | 30 | Ổn định |  |  |
| 56 | 3 | 6 | Normal | 10 | Ổn định |  |  |
| 57 | 3 | 7 | Normal | 29 | Ổn định |  | bất ngờ |
| 58 | 3 | 8 | Normal | 9 | Ổn định |  | màn thở |
| 59 | 3 | 9 | Normal | 23 | Ổn định |  |  |
| 60 | 3 | 10 | Hard | 33 | Ổn định |  |  |
| 61 | 3 | 11 | Normal | 10 | Ổn định | Dây sức chứa khác nhau |  |
| 62 | 3 | 12 | Normal | 14 | Ổn định |  |  |
| 63 | 3 | 13 | Normal | 17 | Ổn định |  |  |
| 64 | 3 | 14 | Normal | 22 | Ổn định |  |  |
| 65 | 3 | 15 | Hard | 23 | Ổn định |  |  |
| 66 | 3 | 16 | Normal | 9 | Ổn định |  |  |
| 67 | 3 | 17 | Normal | 24 | Ổn định |  |  |
| 68 | 3 | 18 | Normal | 15 | Ổn định |  |  |
| 69 | 3 | 19 | Normal | 28 | Ổn định |  |  |
| 70 | 3 | 20 | Hard | 24 | Ổn định |  |  |
| 71 | 3 | 21 | Normal | 12 | Ổn định |  |  |
| 72 | 3 | 22 | Normal | 19 | Ổn định |  |  |
| 73 | 3 | 23 | Normal | 29 | Ổn định |  |  |
| 74 | 3 | 24 | Normal | 18 | Ổn định |  |  |
| 75 | 3 | 25 | Hard | 37 | Ổn định |  |  |
| 76 | 4 | 1 | Normal | 8 | Ổn định |  |  |
| 77 | 4 | 2 | Normal | 28 | Ổn định |  |  |
| 78 | 4 | 3 | Normal | 16 | Ổn định |  |  |
| 79 | 4 | 4 | Normal | 16 | Ổn định |  |  |
| 80 | 4 | 5 | Hard | 31 | Ổn định |  |  |
| 81 | 4 | 6 | Normal | 13 | Ổn định |  |  |
| 82 | 4 | 7 | Normal | 21 | Ổn định |  |  |
| 83 | 4 | 8 | Normal | 10 | Ổn định |  | màn thở |
| 84 | 4 | 9 | Normal | 28 | Ổn định |  |  |
| 85 | 4 | 10 | Hard | 27 | Ổn định |  |  |
| 86 | 4 | 11 | Normal | 17 | Ổn định |  |  |
| 87 | 4 | 12 | Normal | 18 | Ổn định |  |  |
| 88 | 4 | 13 | Normal | 24 | Ổn định |  |  |
| 89 | 4 | 14 | Normal | 21 | Ổn định |  |  |
| 90 | 4 | 15 | Hard | 33 | Ổn định |  |  |
| 91 | 4 | 16 | Normal | 14 | Ổn định |  |  |
| 92 | 4 | 17 | Normal | 26 | Ổn định |  |  |
| 93 | 4 | 18 | Normal | 30 | Ổn định |  | bất ngờ |
| 94 | 4 | 19 | Normal | 17 | Ổn định |  |  |
| 95 | 4 | 20 | Hard | 34 | Ổn định |  |  |
| 96 | 4 | 21 | Normal | 13 | Ổn định | Bố cục 2 hàng |  |
| 97 | 4 | 22 | Normal | 19 | Ổn định |  |  |
| 98 | 4 | 23 | Normal | 21 | Ổn định |  |  |
| 99 | 4 | 24 | Normal | 25 | Ổn định |  |  |
| 100 | 4 | 25 | Hard | 33 | Ổn định |  |  |
| 101 | 5 | 1 | Normal | 16 | Ổn định |  |  |
| 102 | 5 | 2 | Normal | 16 | Ổn định |  |  |
| 103 | 5 | 3 | Normal | 17 | Ổn định |  |  |
| 104 | 5 | 4 | Normal | 16 | Ổn định |  |  |
| 105 | 5 | 5 | Hard | 29 | Ổn định |  |  |
| 106 | 5 | 6 | Normal | 10 | Ổn định |  |  |
| 107 | 5 | 7 | Normal | 31 | Ổn định |  | bất ngờ |
| 108 | 5 | 8 | Normal | 24 | Ổn định |  |  |
| 109 | 5 | 9 | Normal | 18 | Ổn định |  |  |
| 110 | 5 | 10 | Hard | 35 | Ổn định |  |  |
| 111 | 5 | 11 | Normal | 12 | Ổn định | Combo: hoa ẩn + băng |  |
| 112 | 5 | 12 | Normal | 19 | Ổn định |  |  |
| 113 | 5 | 13 | Normal | 21 | Ổn định |  |  |
| 114 | 5 | 14 | Normal | 24 | Ổn định |  |  |
| 115 | 5 | 15 | Hard | 30 | Ổn định |  |  |
| 116 | 5 | 16 | Normal | 11 | Ổn định |  |  |
| 117 | 5 | 17 | Normal | 25 | Ổn định |  |  |
| 118 | 5 | 18 | Normal | 11 | Ổn định |  | màn thở |
| 119 | 5 | 19 | Normal | 28 | Ổn định |  |  |
| 120 | 5 | 20 | Hard | 40 | Ổn định |  |  |
| 121 | 5 | 21 | Normal | 21 | Ổn định |  |  |
| 122 | 5 | 22 | Normal | 17 | Ổn định |  |  |
| 123 | 5 | 23 | Normal | 24 | Ổn định |  |  |
| 124 | 5 | 24 | Normal | 22 | Ổn định |  |  |
| 125 | 5 | 25 | Hard | 41 | Ổn định |  |  |
| 126 | 6 | 1 | Normal | 8 | Đào sâu |  |  |
| 127 | 6 | 2 | Normal | 18 | Đào sâu |  |  |
| 128 | 6 | 3 | Normal | 22 | Đào sâu |  |  |
| 129 | 6 | 4 | Normal | 25 | Đào sâu |  |  |
| 130 | 6 | 5 | Hard | 27 | Đào sâu |  |  |
| 131 | 6 | 6 | Normal | 12 | Đào sâu |  |  |
| 132 | 6 | 7 | Normal | 22 | Đào sâu |  |  |
| 133 | 6 | 8 | Normal | 32 | Đào sâu |  |  |
| 134 | 6 | 9 | Normal | 15 | Đào sâu |  |  |
| 135 | 6 | 10 | Hard | 31 | Đào sâu |  |  |
| 136 | 6 | 11 | Normal | 23 | Đào sâu |  |  |
| 137 | 6 | 12 | Normal | 18 | Đào sâu |  |  |
| 138 | 6 | 13 | Normal | 21 | Đào sâu |  |  |
| 139 | 6 | 14 | Normal | 19 | Đào sâu |  |  |
| 140 | 6 | 15 | Hard | 34 | Đào sâu |  |  |
| 141 | 6 | 16 | Normal | 33 | Đào sâu |  | bất ngờ |
| 142 | 6 | 17 | Normal | 21 | Đào sâu |  |  |
| 143 | 6 | 18 | Normal | 26 | Đào sâu |  |  |
| 144 | 6 | 19 | Normal | 13 | Đào sâu |  | màn thở |
| 145 | 6 | 20 | Hard | 31 | Đào sâu |  |  |
| 146 | 6 | 21 | Normal | 15 | Đào sâu | Combo: khóa + sức chứa khác nhau |  |
| 147 | 6 | 22 | Normal | 22 | Đào sâu |  |  |
| 148 | 6 | 23 | Normal | 23 | Đào sâu |  |  |
| 149 | 6 | 24 | Normal | 28 | Đào sâu |  |  |
| 150 | 6 | 25 | Hard | 35 | Đào sâu |  |  |
| 151 | 7 | 1 | Normal | 8 | Đào sâu |  |  |
| 152 | 7 | 2 | Normal | 24 | Đào sâu |  |  |
| 153 | 7 | 3 | Normal | 26 | Đào sâu |  |  |
| 154 | 7 | 4 | Normal | 15 | Đào sâu |  |  |
| 155 | 7 | 5 | Hard | 34 | Đào sâu |  |  |
| 156 | 7 | 6 | Normal | 14 | Đào sâu |  |  |
| 157 | 7 | 7 | Normal | 14 | Đào sâu |  | màn thở |
| 158 | 7 | 8 | Normal | 25 | Đào sâu |  |  |
| 159 | 7 | 9 | Normal | 33 | Đào sâu |  |  |
| 160 | 7 | 10 | Hard | 29 | Đào sâu |  |  |
| 161 | 7 | 11 | Normal | 21 | Đào sâu |  |  |
| 162 | 7 | 12 | Normal | 27 | Đào sâu |  |  |
| 163 | 7 | 13 | Normal | 34 | Đào sâu |  | bất ngờ |
| 164 | 7 | 14 | Normal | 32 | Đào sâu |  |  |
| 165 | 7 | 15 | Hard | 39 | Đào sâu |  |  |
| 166 | 7 | 16 | Normal | 15 | Đào sâu | Combo: 2 hàng + băng + khóa |  |
| 167 | 7 | 17 | Normal | 21 | Đào sâu |  |  |
| 168 | 7 | 18 | Normal | 22 | Đào sâu |  |  |
| 169 | 7 | 19 | Normal | 26 | Đào sâu |  |  |
| 170 | 7 | 20 | Hard | 33 | Đào sâu |  |  |
| 171 | 7 | 21 | Normal | 22 | Đào sâu |  |  |
| 172 | 7 | 22 | Normal | 31 | Đào sâu |  |  |
| 173 | 7 | 23 | Normal | 24 | Đào sâu |  |  |
| 174 | 7 | 24 | Normal | 18 | Đào sâu |  |  |
| 175 | 7 | 25 | Hard | 48 | Đào sâu |  |  |
| 176 | 8 | 1 | Normal | 10 | Đào sâu |  |  |
| 177 | 8 | 2 | Normal | 24 | Đào sâu |  |  |
| 178 | 8 | 3 | Normal | 20 | Đào sâu |  |  |
| 179 | 8 | 4 | Normal | 28 | Đào sâu |  |  |
| 180 | 8 | 5 | Hard | 35 | Đào sâu |  |  |
| 181 | 8 | 6 | Normal | 24 | Đào sâu |  |  |
| 182 | 8 | 7 | Normal | 21 | Đào sâu |  |  |
| 183 | 8 | 8 | Normal | 28 | Đào sâu |  |  |
| 184 | 8 | 9 | Normal | 15 | Đào sâu |  | màn thở |
| 185 | 8 | 10 | Hard | 38 | Đào sâu |  |  |
| 186 | 8 | 11 | Normal | 35 | Đào sâu |  | bất ngờ |
| 187 | 8 | 12 | Normal | 20 | Đào sâu |  |  |
| 188 | 8 | 13 | Normal | 24 | Đào sâu |  |  |
| 189 | 8 | 14 | Normal | 29 | Đào sâu |  |  |
| 190 | 8 | 15 | Hard | 34 | Đào sâu |  |  |
| 191 | 8 | 16 | Normal | 19 | Đào sâu |  |  |
| 192 | 8 | 17 | Normal | 29 | Đào sâu |  |  |
| 193 | 8 | 18 | Normal | 29 | Đào sâu |  |  |
| 194 | 8 | 19 | Normal | 22 | Đào sâu |  |  |
| 195 | 8 | 20 | Hard | 31 | Đào sâu |  |  |
| 196 | 8 | 21 | Normal | 16 | Đào sâu |  |  |
| 197 | 8 | 22 | Normal | 34 | Đào sâu |  |  |
| 198 | 8 | 23 | Normal | 25 | Đào sâu |  |  |
| 199 | 8 | 24 | Normal | 28 | Đào sâu |  |  |
| 200 | 8 | 25 | Hard | 43 | Đào sâu |  |  |

---

## 8. Quy trình làm việc đề xuất

1. Đọc `juice_level.gd` (hàm `from_dict`, `validate`) và `juice_rules.gd` (`move_info`, `deposit_ready`, `place_batch`) để chắc chắn hiểu luật.
2. Mở vài level mẫu trong `assets/game/` để làm quen cú pháp, nhất là các cơ chế băng, sức chứa khác nhau và 2 hàng.
3. Viết bộ sinh level: chọn số dây, `capacity`, số cốc, số loại theo mục 4, rồi chỉnh theo các núm ở mục 5b; xếp chậu và hoa sao cho cân bằng (mục 3); thêm cơ chế theo lịch ở mục 7.
4. Với mỗi màn: sinh nhiều ứng viên → kiểm tra hợp lệ/giải được bằng script mục 6 → đo `lw` bằng `greedy_ext.gd` (mục 5.1) → giữ ứng viên WINNABLE có điểm ước lượng gần mục tiêu nhất, và ghi sai số dự kiến theo mục 5.3 (không coi ±3 là đạt).
5. Lưu kết quả:
   - mỗi màn một file `levels/sweet_rope/level_###.json` (ví dụ `level_001.json`), nội dung là một object level với `id` = số màn;
   - một file `levels/sweet_rope/report.csv` gồm: `man, diem_muc_tieu, lw, diem_uoc_luong, lech, solvable, co_che`.
6. Làm theo từng chapter (25 màn) và gửi báo cáo sau mỗi chapter trước khi làm tiếp.

---

## 9. Những điều không được làm

- Không chép nguyên hoặc biến đổi nhẹ level của Sort Streak. Chỉ dùng chúng để học định dạng và thống kê.
- Không đưa asset (hình, âm thanh) của Sort Streak vào Sweet Rope.
- Không sửa code engine để màn qua kiểm tra. Nếu thấy luật kiểm tra sai, ghi lại và hỏi team.
- Không dùng cơ chế trước màn ra mắt của nó.

---

## Phụ lục A. Script `greedy_ext.gd` (đo `lw`)

Lưu thành `.godot/greedy_ext.gd` (thư mục `.godot/` bị git bỏ qua). Script chạy 4 cấu hình bot (eps-greedy 0,3 / 0,45 / 0,6 và softmax T=4) × 2 seed × 30 ván mỗi level, tối đa 300 nước mỗi ván.

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
