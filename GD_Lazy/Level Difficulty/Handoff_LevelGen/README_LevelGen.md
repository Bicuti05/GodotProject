# Sinh level Sweet Rope 2–200 (bàn giao cho AI sinh level)

Bạn sinh lại **level 2–200** của game Sweet Rope cho đúng độ khó đích. Mỗi level xuất phát từ **bàn default cùng số**: giữ khung, chỉ xếp lại quả. Bạn tự kiểm bằng `kit/sr_levelkit.py` rồi giao kết quả. Một AI khác sẽ duyệt lại bằng luật C# của game, điểm chậm và so với dữ liệu gốc.

## 0. Đợt này: chỉ sinh các level còn lại

- `kit/start_levels/` là bản đã làm: 106 level đã sinh và đã duyệt. **Giữ nguyên các level này.**
- **Chỉ sinh 74 level trong `kit/todo_levels.txt`** (20, 105, 111…199). Level Challenge và Endless trong khoảng 105–200 để nguyên bàn default.
- Chép `start_levels/` thành thư mục làm việc của bạn (ví dụ `Levels/`), sửa đúng các level trong danh sách, rồi kiểm:
  `python -X utf8 sr_levelkit.py check default_levels Levels --only todo_levels.txt --workers 4`
- Level 20 đã thử nhiều lần mà chưa có bàn giải được. Nếu vẫn không được thì giữ bàn default và ghi vào `NOTES.md`.
- Điều tôi rút ra từ 106 level đã làm (`claude_report_done_levels.xlsx`): bàn sinh ra hay **khó hơn đích** (trung bình +4,9). Khi đích thấp hơn default thì ưu tiên các bước làm dễ ở mục 4: bớt Hidden, hạ `count` khoá, gom quả cùng màu. Đừng xáo nhiều hơn mức 25% bắt buộc.

Làm **một lần, không chia phase**. Hết thời gian thì giao phần đã đạt kèm báo cáo, đừng giao level chưa đạt mà không đánh dấu.

## 1. Thư mục

```
README_LevelGen.md        file này
kit/
  default_levels/          pack_001.json (level 1–125), pack_002.json (126–250): bàn default, KHÔNG sửa
  targets.csv              đích từng level: curve_c, real_default, notes
  sr_levelkit.py           bộ kiểm (lệnh ở mục 5)
  trial_gen.py             cách sinh mẫu của tôi (mutate, start), dùng lại thoải mái
  sim.py, sim3.py, dfeat*.py, players.py, sr_score.py, sr_train.npz   luật chơi bản Python và bộ chấm điểm
  core.js, check_core.js   luật của Level Designer (bản port từng dòng của C#), node để kiểm lại lời giải
```

Cần: Python 3.10+ có `numpy`, `scikit-learn`; Node 18+ (chỉ cho `check_core.js`). Chạy mọi lệnh **trong thư mục `kit/`**.

## 2. Định dạng level

Schema `sweetrope.levelpack/1`. Mảng `items` ghi **từ đáy lên đỉnh**: quả cuối mảng là quả người chơi lấy được.

```json
{ "levelIndex": 7, "difficultyType": "Normal", "difficulty": 1, "orderCount": 11,
  "ropes": [
    { "kind": "Free",   "capacity": 5, "items": [ {"type": 3}, {"type": 1, "state": "Hidden"}, {"type": 4} ] },
    { "kind": "Normal", "capacity": 5, "container": {"type": 2}, "items": [ ... ] },
    { "kind": "Locked", "capacity": 5, "container": {"type": 6}, "seal": {"rule": "TypedDelivery", "type": 1, "count": 1}, "items": [ ... ] } ],
  "reserveQueue": [
    { "mode": "Container", "capacity": 5, "container": {"type": 0}, "refill": [ ... ] },
    { "mode": "Free", "capacity": 5, "refill": [ ... ] },
    { "mode": "Remove" } ] }
```

- **Luật chơi:** kéo một quả cùng mọi quả phía trên nó sang Rope khác. Rope đích phải rỗng hoặc có quả trên cùng cùng màu, và phải còn đủ chỗ.
- **Giao (Deliver):** Rope có Container đầy `capacity` quả đúng màu thì tự giao. Sau đó `reserveQueue[k]` (với k là số lần đã giao trước đó) áp lên Rope vừa giao; các quả `refill` rơi vào Rope vừa giao trước, rồi tới các Rope khác theo thứ tự.
- **Hidden:** quả ẩn, chỉ lộ màu khi lên đỉnh Rope. Khi còn ẩn thì không ghép được với quả nào, chỉ đặt được vào Rope rỗng.
- **Locked:** Rope khoá không kéo vào hay ra được, cho tới khi đủ `count` lần giao (`AnyDelivery`), hoặc đủ `count` lần giao đúng màu `type` (`TypedDelivery`; không ghi `type` nghĩa là màu 0).
- **Thắng:** giao đủ `orderCount` lần. Không có giới hạn số bước. Lời giải **không được dùng Helper** (Undo, Extra Rope…).

## 3. Luật khung (bộ kiểm bắt lỗi hết các mục này)

| Giữ y như default | Được đổi |
|---|---|
| `orderCount`, `difficultyType` | Vị trí từng quả (đổi chỗ giữa các Rope và các `refill`) |
| Số Rope, thứ tự, `kind`, `capacity`, số quả mỗi Rope lúc mở | Quả nào Hidden, và **số Hidden** trong khoảng cho phép (`hidden_range` trong `trial_gen.py`). Default không có Hidden thì vẫn không có, có thì còn ít nhất 1 |
| Màu Container của Rope lúc mở | Thứ tự màu các Container trong `reserveQueue` (số Container mỗi màu vẫn giữ) |
| Rope nào khoá và **kiểu khoá** (`rule`) | **Điều kiện khoá:** `count` và `type`, miễn là còn đủ Container để mở |
| `reserveQueue`: số mục, `mode`, `capacity`, số quả `refill` mỗi mục | Số màu nhìn thấy lúc mở |
| Số quả mỗi màu trong cả level | `difficulty` (1–6) |

Luật thêm:
- **Phải đổi ít nhất 25% vị trí quả** so với default, để bàn khác bàn gốc.
- Không có quả Hidden ở đỉnh Rope lúc mở.
- Không có Rope nào đã đầy quả đúng màu ngay lúc mở.
- Không thêm Ice (`meltType`, quả `Ice`, chậu `frozen`).
- **Level 1 giữ nguyên** vì hướng dẫn gắn cứng với bàn đó.
- **Level Bonus** (13, 23, 33…): phải còn ít nhất một màu có **đúng 1 Container trong cả level** và Container đó có mặt lúc mở. Game sẽ đổi màu đó thành đồng vàng. Giữ đúng các luật khung trên thì màu này tự còn.
- **Level Challenge** (17, 27…) và **Endless** (30, 40…) bị thay lúc chơi, nên **để nguyên bàn default** cho đỡ tốn thời gian.
- **Level `ice_01_ghi_de`** vẫn sinh như level thường.

## 4. Độ khó

- `curve_c` là đích trên đường độ khó đã chốt. `real_default` là điểm thật (`summaryScore`) của bàn default.
- Bộ chấm nhanh (`sr_score.fast`, khoảng 0,5 giây mỗi bàn) bị lệch: chấm bàn dễ cao lên, bàn khó thấp xuống. Vì vậy **so tương đối với bàn default**:

  `đích_nhanh = fast(bàn default) + curve_c − real_default`

  `sr_levelkit.py` tự tính con số này. **Đạt khi `|fast(bàn mới) − đích_nhanh| ≤ 2,31`.**
- **Cách làm dễ hơn** (đích nhỏ hơn default): xếp quả cùng màu nằm liền nhau trong một Rope; đặt quả đúng màu vào Rope có Container màu đó; bớt Hidden; hạ `count` của khoá; cho quả `refill` sớm đúng màu Container sắp tới.
- **Cách làm khó hơn:** xen kẽ màu; chôn quả cần dùng sớm dưới quả khác; thêm Hidden, đặt Hidden sâu; tăng `count` khoá, hoặc khoá bằng màu xuất hiện muộn trong `reserveQueue`; dồn quả của màu giao sớm vào `refill` muộn.
- Một số level không thể chạm đích vì khung quá chặt. Ví dụ level 11 và 26: đường C muốn dễ hơn default 11–18 điểm. Gần đích nhất mà vẫn giải được là được, **ghi rõ trong báo cáo**.

## 5. Lệnh

```
python -X utf8 sr_levelkit.py selftest
python -X utf8 sr_levelkit.py check default_levels <Levels của bạn> --levels 2-200 --workers 4
```

- `check` ghi `kit_out/report.csv` (cột `ok`, `frame_errors`, `solvable`, `aim_fast`, `score_fast`, `off_by`) và `kit_out/solutions.json` (lời giải từng level, `[src, j, dst]` theo chỉ số Rope và vị trí quả).
- Dùng thẳng các hàm trong Python cho vòng lặp nhanh: `frame_errors(new, base, n)`, `find_path(level)`, `aim_fast(base, row)`, `sr_score.fast(to_layout(level))`.
- Kiểm lại lời giải bằng luật Level Designer: `node check_core.js ./core.js rows.json`, với `rows.json = [{"level": ..., "path": [...]}, ...]`.

## 6. Cách làm nhanh (đề xuất)

1. Với mỗi level: đọc bàn default, tính `đích_nhanh`, xác định cần dễ hơn hay khó hơn.
2. Sinh vài chục ứng viên bằng các bước ở mục 4 (hoặc `trial_gen.start` / `trial_gen.mutate` với `easy` = 0,85 khi cần dễ, 0,25 khi cần khó). Loại ngay bàn có `frame_errors`.
3. Chấm `fast` mọi ứng viên, chỉ chạy `find_path` (chậm hơn) cho những bàn gần đích nhất. Lấy bàn giải được và gần đích nhất. Lời giải dùng được khi `find_path` trả danh sách khác rỗng.
4. Mỗi level chạy độc lập, nên có thể chạy song song nhiều level cùng lúc.

Chỗ tốn thời gian trong bản của tôi là điểm chậm (`sr_score.full`, khoảng 5 giây) và tìm lời giải cho mọi ứng viên. **Bạn không cần chạy `full`**, người duyệt sẽ chạy.

## 7. Giao lại

Một zip gồm:
- `Levels/pack_001.json`, `Levels/pack_002.json`: lấy từ `start_levels/`, chỉ thay các level trong `todo_levels.txt`. Level 201–250 để nguyên.
- `kit_out/report.csv` và `kit_out/solutions.json` của lần `check` cuối.
- `NOTES.md`: level nào không đạt đích và vì sao, chỗ nào bạn làm khác hướng dẫn.

Đừng sửa `default_levels/`, `sr_score.py` hay `sr_train.npz`.
