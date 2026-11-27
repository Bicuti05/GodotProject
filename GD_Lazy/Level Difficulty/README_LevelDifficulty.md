# Công cụ chấm độ khó level (khớp với Sort Streak)

Bản 2 (2026-11-25): sửa lỗi Hidden Item gần như không đổi điểm.

## 1. Cách tính

`total = base + early + mid + end` (cắt trong khoảng 0 đến 100)

| Đầu điểm | Đo gì | Đầu vào |
|---|---|---|
| early | Những gì người chơi thấy lúc mở level (không thấy ReserveQueue) | `capacity`, số Order, số Rope, Free Rope, số Item và số màu, số nước đi và nước ghép ngay, ô trống, Locked Rope, Ice, độ xáo trộn, **số Hidden Item, tỉ lệ Hidden, số Hidden bị chôn** |
| mid | Nguy cơ stuck trong lúc chơi | Bot chơi 40 lượt: tỉ lệ stuck ở 1/3 đầu và 1/3 giữa, ô trống trung bình và thấp nhất, tiến độ, số nước mỗi Order; **độ sâu của Hidden** |
| end | Đoạn cuối | Tỉ lệ stuck 1/3 cuối, tỉ lệ thắng của bot, ô trống cuối, tổng Item, số màu, thành phần ReserveQueue (Remove, Free Rope, Locked, **Hidden**) |

**Luật của Hidden:** mọi đầu vào khác (kể cả bot) được đo như khi đã lộ hết Item. Hidden chỉ đi vào điểm qua các đầu vào in đậm, và mô hình bị buộc: thêm Hidden không bao giờ làm điểm giảm.

Mỗi đầu điểm là một cụm cây quyết định (boosted trees) trên đúng nhóm đầu vào của phase đó. Đây là **mô hình tính được**, không phải một công thức viết tay. Công thức tuyến tính thử trước đó chỉ đạt R² 0,60 (sai số 4,11 điểm trên `default`) nên bị loại.

`base` là hằng số của từng bộ. `early`, `mid`, `end` bắt đầu từ 0 ở level thấp nhất trong dữ liệu, nên `base` có thể âm.

## 2. Độ khớp với `summaryScore` của Sort Streak (kiểm chéo theo Stage)

> **Đính chính 2026-11-26: bảng dưới đây lạc quan hơn thực tế, đừng dùng.** Cùng một bàn xuất hiện ở nhiều Stage (`default` có 5.125 level nhưng chỉ 1.623 bàn khác nhau), nên chia kiểm theo Stage vẫn để bàn cần chấm lọt vào dữ liệu học.
>
> Đo lại, mỗi bàn một lần, trên 1.623 bàn `default`:
>
> | Đầu vào | R² | Sai số TB | Sai ≤ 2,31 | Sai ≤ 5 |
> |---|---|---|---|---|
> | Chỉ số trên bàn | 0,54 | 4,43 | 33% | 63% |
> | Thêm 5 người chơi máy (thử nghiệm, chưa đưa vào `level_score.py`) | 0,61 | 4,01 | 36% | 69% |
>
> Điểm thật 0–10 bị đoán cao khoảng 5,5; điểm thật từ 30 trở lên bị đoán thấp khoảng 5,9. Mô hình học từ `default` đoán thấp khoảng 33 điểm trên bàn chỉ có ở lv2–lv5: hai nhóm bàn gần giống nhau vẫn chênh điểm lớn (bàn chỉ khác vị trí Hidden: lệch trung bình +13, trong khi bot thắng ngang nhau), nên điểm của họ có phần trọng số không đọc được từ bàn.

| Bộ | Số level | R² | Sai số trung bình (điểm) | 90% level sai dưới | Sai ≤ 3 điểm | Khớp nhãn `difficulty` | Bản 1: R² / sai số |
|---|---|---|---|---|---|---|---|
| default | 5.125 | 0,815 | 2,31 | 5,51 | 76% | 95,0% | 0,835 / 2,15 |
| lv2 | 5.118 | 0,636 | 4,43 | 10,59 | 50% | 77,1% | 0,664 / 4,23 |
| lv3 | 5.114 | 0,651 | 5,00 | 11,52 | 44% | 74,5% | 0,688 / 4,62 |
| lv4 | 5.110 | 0,623 | 7,03 | 15,97 | 33% | 65,5% | 0,667 / 6,48 |
| lv5 | 5.110 | 0,556 | 7,11 | 15,83 | 31% | 65,4% | 0,581 / 6,73 |

Bản 2 khớp kém hơn bản 1 một chút ở mọi bộ. Đó là giá của việc buộc Hidden đi đúng chiều.

Chấm lại cùng một level với seed khác nhau: điểm lệch chuẩn trung bình 1,13, lớn nhất 3,11 (25 level, 6 seed).

**Sunlight (426 level):** không có `summaryScore`, chỉ có tier tác giả 1 đến 5. Tương quan hạng giữa điểm dự đoán và tier là 0,28 đến 0,46, tức là yếu. Điểm trung bình `default` theo tier 1 đến 5: 12,4 / 13,3 / 15,3 / 16,1 / 15,6.

## 3. Hidden Item ảnh hưởng bao nhiêu

**Trên dữ liệu server:** sau khi đã tính các đầu vào khác, `summaryScore` vẫn tăng theo độ sâu Hidden. Mỗi 10 đơn vị độ sâu: `default` +0,84 (±0,34), `lv3` +1,03 (±0,51), `lv5` +3,64 (±0,61).

**Trên công cụ:** lấy 300 level `default` có Hidden, so bản gốc với bản lộ hết Hidden, chấm bằng mô hình của từng bộ.

| Bộ | Hidden làm điểm cao hơn trung bình | Số level cao hơn | Số level thấp hơn |
|---|---|---|---|
| default | 1,79 | 79% | 0% |
| lv2 | 2,44 | 79% | 0% |
| lv3 | 2,87 | 79% | 0% |
| lv4 | 5,29 | 100% | 0% |
| lv5 | 7,60 | 100% | 0% |

Các level còn lại giữ nguyên điểm.

## 4. Nguyên nhân stuck (bot, bộ `default`)

Tỉ lệ trong các lượt bị stuck. Một lượt có thể có nhiều nguyên nhân cùng lúc, nên đây là dấu hiệu đi kèm, chưa chứng minh nguyên nhân. Bot chơi trên bàn đã lộ hết Item, nên không còn mã `hidden_left`.

| Mã | Ý nghĩa | Tỉ lệ |
|---|---|---|
| `no_empty_rope` | không còn Rope trống | 14,0% |
| `locked_left` | còn Locked Rope chưa mở | 14,2% |
| `root_blocked` | mọi Rope có Container đều bị Item sai chặn ở gốc | 0,9% |
| `ice_left` | còn Ice | 0% (bộ này không có Ice) |

## 5. Cách dùng

```powershell
python level_score.py level_example.json --set default
```

```powershell
python level_score.py --selftest
```

Cần Python có `numpy`, `scikit-learn` 1.9.0. Đầu vào là layout kiểu Sort Streak (`capacity`, `targetCups`, `initial`, `incoming`).

## 6. Cần xác nhận và giới hạn

| Trạng thái | Nội dung |
|---|---|
| Implemented | Chấm 4 đầu điểm cho 5 bộ `default`, `lv2` đến `lv5`. |
| Implemented | Thêm Hidden không làm giảm điểm (có kiểm trong `--selftest`). |
| Implemented | Mô phỏng hỗ trợ Locked Rope, Free Rope, Remove, Sunlight, Ice (chặn ghép và chặn Deliver), Container đóng băng. |
| Unverified | Độ lớn ảnh hưởng của Hidden chỉ học từ điểm server. Bot không mô phỏng việc người chơi thiếu thông tin. |
| Unverified | Điểm từng phase. Server chỉ có một điểm tổng, nên `early`, `mid`, `end` là phần chia do mô hình, không đối chiếu được. |
| Unverified | Level có Ice hoặc Sunlight. Dữ liệu khớp không có level nào như vậy, phần đầu vào tĩnh về Ice không có tác dụng, Ice chỉ ảnh hưởng qua kết quả bot. |
| Unverified | Thêm cơ chế mới ngoài danh sách trên: phải viết luật vào `sim.py` và nên khớp lại bằng dữ liệu có cơ chế đó. |
| Unverified | Bot yếu hơn người chơi nhiều (trung bình thắng 4,7%, tiến độ 16%), nên `mid` và `end` đo thô. |
| Unverified | Level nằm ngoài khoảng dữ liệu Sort Streak (ví dụ nhiều Rope hơn): mô hình cây không ngoại suy. |
| Implemented | Bộ sinh level Sweet Rope theo điểm đích (mục 7). |
| Chưa làm | Bộ sinh level chưa tạo Locked Rope, Ice, Sunlight; sức chứa là một số cho cả level. |


## 7. Sinh level Sweet Rope

```powershell
dotnet build harness -c Release
```

```powershell
python -X utf8 gen_level.py --orders 12 --colors 7 --free 4 --hidden 20 --hidden-ropes 13 --target 10.3 --out Generated/level.json
```

| Thông số | Ý nghĩa | Mặc định |
|---|---|---|
| `--target` | Điểm độ khó đích | bắt buộc |
| `--orders`, `--colors` | Số Order và số màu; công cụ tự xếp thứ tự | bắt buộc nếu không dùng `--order` |
| `--order` | Dãy `type` Container theo thứ tự xuất hiện, ví dụ `1,0,2,1` | |
| `--capacity` | Sức chứa mỗi Rope | 5; 6 khi đích từ 20 |
| `--free` | Tổng Free Rope (1 có sẵn lúc mở, còn lại đến từ ReserveQueue) | 2 |
| `--hidden`, `--hidden-ropes` | Số Hidden Item và số dây có Hidden | 0; khoảng 65% số Hidden |
| `--initial` | Số Rope lúc mở level | 7 khi đích dưới 10, còn lại 6 (tự tăng nếu nhiều Free Rope) |
| `--tol` | Sai lệch cho phép so với đích | 0,5 |

Ra 3 file: LevelPack `sweetrope.levelpack/1` (đưa vào game), `.report.json` (điểm, phần bù, kết quả bộ giải) và `.layout.json` (chấm lại bằng `level_score.py`).

**Cách bàn được dựng** (theo dữ liệu Sort Streak): luôn có 1 Free Rope lúc mở; ReserveQueue xếp Container, rồi Free, rồi Remove; Item mỗi `type` bằng đúng số Container loại đó nhân sức chứa; Hidden không nằm trên đỉnh dây lúc mở; không dây nào đầy một loại lúc mở. Level được nhận phải qua `LevelValidator` của Sweet Rope và được chứng minh giải được: bộ giải Python tìm một lời giải, rồi luật của chính game chơi lại từng nước (`BoardSolver.Replay`, ghi `Replayed`). Không tìm được thì dùng `BoardSolver.Solve` của game. Bộ giải của game một mình thường hết giới hạn tìm kiếm khi bàn có từ 10 Hidden Item.

## 8. Công thức bù cho thông số ngoài dữ liệu

`điểm = điểm mô hình + Σ hệ số × (số đơn vị vượt vùng dữ liệu)`; thiếu so với vùng thì số đơn vị âm. Trong vùng dữ liệu phần bù bằng 0.

| Thông số | Vùng dữ liệu (`default`) | Hệ số mỗi đơn vị | Cách ước lượng |
|---|---|---|---|
| Sức chứa | 4 đến 6 | +11,42 | hồi quy tuyến tính trên 5.125 level |
| Số Order | 10 đến 14 | +2,16 | hồi quy tuyến tính |
| Số màu | 8 đến 10 | +0,58 | sửa từng level: gộp 2 màu (sai số chuẩn 0,11) |
| Free Rope | 1 đến 3 | -0,05 | sửa từng level: thêm 1 Free Rope (sai số chuẩn 0,06, không khác 0 rõ ràng) |
| Hidden Item | 0 đến 20 | +0,23 | mô hình: lộ hết Hidden rồi so (sai số chuẩn 0,01) |

Phần bù là **Unverified**: không có level thật ngoài vùng để đối chiếu. Hệ số sức chứa và số Order lấy từ tương quan nên có thể lẫn ảnh hưởng khác. Hệ số đo trên bộ `default` và được dùng cho cả các bộ khác. Muốn đổi thì sửa `slope` trong `bonus.json`. Đo lại: `python -X utf8 fit_bonus.py`.
