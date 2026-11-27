# Phân tích đường độ khó Sort Streak cho Sweet Rope

Sweet Rope là game xếp quả lên dây (Unity), chép lối chơi từ Sort Streak (SS). Bộ này có **mọi level của SS có `summaryScore`**: 5 bộ level, 25.605 dòng. Việc của bạn: phân tích đường độ khó của cả 5 bộ, rồi góp ý hoặc đề xuất đường độ khó cho Sweet Rope.

## 1. Thư mục

```
data/ss_levels.csv        mỗi dòng = 1 level của 1 bộ: điểm + đặc trưng bàn
data/ss_layouts.jsonl     bàn gốc từng dòng (cùng khoá set + level)
data/SS_Difficulty Curve.xlsx   phân tích trước: điểm theo Stage, theo vị trí trong Stage, luật lên/xuống bậc
sweet_rope/SR_Difficulty Curve.xlsx    đường C (đang dùng để sinh level)
sweet_rope/SR_Difficulty Curve_D.xlsx  đường D (đề xuất mới, chưa chốt) + curve_d.py, curve_d_1-200.png
  (curve_d.py đọc đường dẫn máy gốc; chỉ để xem công thức, muốn chạy thì đổi SRV sang data/ss_layouts.jsonl)
sweet_rope/pack_001.json, pack_002.json   level 1-250 hiện tại của Sweet Rope (đang chép từ default SS)
sweet_rope/Note_Dev_Bonus_Level.md       luật level Bonus đã chốt
```

## 2. Dữ liệu SS

- **Bộ:** `default` (level 1-5125), `lv2`…`lv5` (level 6-5125). Level 1-5 chỉ có `default`. Mục ghi nhiều tag (vd. `lv3,lv4,lv5`) đã tách ra từng bộ.
- **Số level:** `level = (stage − 1) × 25 + level_in_stage`.
- **Nhịp:** mọi bộ lặp 4 Normal + 1 Hard (`difficultyType`).
- **`difficulty`:** nhãn 1-3 của SS. Các dải điểm xấp xỉ: dưới 20,5 là 1, dưới 37 là 2, còn lại là 3.
- **`summaryScore`:** điểm độ khó của SS, khoảng 0-100. Không hoàn toàn từ bot: GD cho biết SS còn tăng giảm trọng số các yếu tố. Bàn giống hệt nhau có cùng điểm ở mọi bộ, nên 5 bộ dùng chung một thang.
- **`board_id`:** hash của bàn. Nhiều level dùng lại cùng bàn: `default` có 5.125 level nhưng chỉ 1.623 bàn khác nhau. Khi đo độ khớp của mô hình, hãy chia train/test theo `board_id`, đừng chia theo level.
- **Người chơi đổi bộ (đọc từ code, chưa kiểm trong game):**
  - Qua level 5, người chơi vào `lv2`.
  - Lên bậc khi thắng sạch liên tiếp: lv1 cần 2 ván, lv2 cần 2, lv3 cần 3, lv4 cần 5.
  - Xuống bậc khi quá nửa các ván gần nhất không sạch.
  - Thắng không sạch là thắng sau khi Restart, hết nước, hoặc dùng Helper khác Undo/Hint.
  - `lv1` không có bộ riêng mà lùi về `default`.

### Cột đặc trưng bàn

"Lúc mở" nghĩa là bàn khi bắt đầu level. "Hàng chờ" là `incoming` (ReserveQueue), nơi các Rope và quả mới đến dần sau mỗi lần giao.

| Cột | Ý nghĩa |
|---|---|
| `cap` | Sức chứa mỗi Rope |
| `tgt` | Số Order cần giao để thắng |
| `cols` | Số Rope lúc mở |
| `types_init` | Số màu lúc mở |
| `types_all` | Số màu cả level |
| `hidden` | Số quả ẩn lúc mở |
| `inc_hidden` | Số quả ẩn trong hàng chờ |
| `hidden_depth` | Tổng số quả nằm trên các quả ẩn |
| `locks` | Số Rope khoá |
| `lk_type` | Số Rope khoá theo màu |
| `lk_count` | Số Rope khoá theo số lần giao |
| `parks` | Số Free Rope lúc mở |
| `inc_park` | Số Free Rope trong hàng chờ |
| `inc_retire` | Số mục Remove trong hàng chờ |
| `free_ratio` | Tỉ lệ ô trống lúc mở |
| `wrong_ratio` | Tỉ lệ quả nằm sai màu Container |
| `changes_per_col` | Số lần đổi màu liền kề, trung bình mỗi Rope |
| `frozen` | Số quả Ice. Bộ default không có Ice |

### Định dạng bàn (`layout`)

- `initial`: các Rope lúc mở; `incoming`: hàng chờ.
- Mỗi Rope là chuỗi `"chậu|quả,quả"`, quả ghi **từ đáy lên đỉnh**:
  - `chậu`: số màu của Container; `-` là Free Rope; `x` là Remove.
  - Quả: `?3` là quả ẩn màu 3; `i3` là quả Ice màu 3.
- `columnType = unlock` là Rope khoá. `columnInfo.condition = collect_type` nghĩa là khoá theo màu.

## 3. Sweet Rope

- **Level 1-250** hiện chép từ `default` SS.
- **Mở cơ chế:**

  | Level | Mở |
  |---|---|
  | 2 | Undo |
  | 3 | Hint |
  | 5 | Extra Rope |
  | 6 | Hidden |
  | 7 | Fill |
  | 11 | Khoá theo màu |
  | 21 | Khoá theo số lần |

- **Level thay thế khi chơi:**
  - Level 1 là hướng dẫn cố định.
  - Challenge (17, 27…) và Endless (30, 40…) thay level lúc chơi.
  - 32 level Ice thay level thường trong khoảng 42-200 (hiện bỏ qua Ice).
- **Bonus cố định** ở 13, 23, 33…: một màu chỉ có 1 chậu thành đồng vàng.
- **Không có bậc lv2-lv5:** chỉ một bộ level cho mọi người chơi, nên đường cong phải tự tạo độ khó tăng dần.
- **Đường C (đang dùng):** sóng theo chương dài 3-7 Stage; leo từ gần `default` lên ngang `lv2` ở khoảng Stage 152.
- **Đường D (đề xuất, chưa chốt):** chia pha Learn → Practice → Combine → Challenge → Recover/Renew.
  - Nhóm 5 level: Recover, Practice, Practice, Combine, Hard.
  - Chương 50 level, đỉnh ở x45.
  - Chi tiết ở sheet Tổng quan của `SR_Difficulty Curve_D.xlsx`.

## 4. Những gì đã đo (để bạn kiểm lại, đừng chép)

- **Nhịp nhóm 5 của `default`** (trung vị):
  - Level 26-250: 13,9 / 21,8 / 20,4 / 17,9 / 30,1.
  - Level 251+: 12,8 / 13,3 / 13,3 / 16,2 / 29,6.
  - Level ngay sau Hard luôn có sức chứa 4 và có Hidden + khoá. Hard gần như luôn sức chứa 6.
- **Tầm dài của `default`:**
  - Stage 2-8 khó hơn hẳn; Stage 9 hạ khoảng 8 điểm.
  - Từ Stage 10 gần như phẳng (trung bình 16-16,8), sóng chỉ khoảng 0,8 điểm.
  - Chưa phân tích kỹ bộ `lv2`-`lv5`.

## 5. Yêu cầu

1. **Cả 5 bộ:** đo đường độ khó ở 3 tầm (nhóm 5 level, Stage 25 level, nhiều Stage). Xác định các pha **learn → practice → combine → challenge → recover/renew**: pha nào có thật trong dữ liệu, dài bao nhiêu, cao bao nhiêu.
2. **Đỉnh và hồi phục:**
   - Đỉnh khó ở đâu, theo level và theo Stage.
   - Sau đỉnh hồi phục ở đâu, hạ bao nhiêu điểm, kéo dài mấy level.
   - Đỉnh có lặp theo chu kỳ không.
3. **Điểm thay đổi theo đặc trưng bàn:**
   - Điểm thay đổi theo đặc trưng nào (sức chứa, Hidden, khoá, số Order, số màu…).
   - Các bộ `lv2`-`lv5` tăng độ khó bằng đặc trưng nào so với `default`.
4. **Người chơi thật thấy đường nào:** mô phỏng luật lên/xuống bậc (tự giả định xác suất thắng sạch theo điểm, ghi rõ giả định) để ước lượng đường độ khó người chơi thực sự gặp.
5. **Sweet Rope:**
   - Đánh giá đường C và đường D dựa trên các kết quả trên.
   - Đề xuất chỉnh, có số cụ thể theo level 1-500.
   - Lưu ý level thay thế, level Bonus, mốc mở cơ chế.

## 6. Luật trình bày

- Viết **tiếng Việt**.
- Không bịa số. Đánh dấu mỗi kết luận là **Đo được** / **Suy luận** / **Giả định**.
- Kèm script đã dùng để người khác chạy lại được.
- **Giao lại:**
  - `REPORT.md`: kết luận ngắn trước, bảng sau.
  - `curve_proposal.csv`: cột `level, phase, target, low, high, note`, level 1-500.
  - Hình đường cong (png) và các script.
