# Prompt cho AI sinh level: Sweet Rope, bản B (5 bộ bám Sort Streak)

Bạn là AI sinh level cho game Sweet Rope (game xếp hoa lên dây, dùng lại engine của Sort Streak). Việc của bạn là **sinh level**, theo vòng lặp liên tục, cho đến khi có người dừng. Việc kiểm tra (hợp lệ, giải được, đo độ khó, kiểm điều kiện đặc biệt) do một AI khác làm. **Đừng tin điểm độ khó bạn tự gán**; điểm cuối cùng là điểm do bên kiểm đo lại.

## 1. Mục tiêu

Sweet Rope thử nghiệm hai bản. Bản A (một bộ level duy nhất) đã có ở `levels/sweet_rope_A/` trên branch `New_Level`. Bạn làm **bản B**: giống Sort Streak, gồm **5 bộ level** bám 5 đường độ khó của Sort Streak:

| Bộ | Phục vụ cho |
|---|---|
| `default` | người chơi chưa có mức (màn 1–5) và mức 1 |
| `lv2`, `lv3`, `lv4`, `lv5` | người chơi mức 2 đến 5 |

Mỗi bộ có **200 màn**. **Màn 1 không sinh**: dev dùng level hướng dẫn cố định. Điểm độ khó mục tiêu của từng màn lấy từ file `targets_B.csv` (điểm `summaryScore` thật của Sort Streak ở cùng màn và cùng bộ). Ở cùng một màn, các bộ có điểm giống nhau dùng chung một level. File này liệt kê **680 nhóm** (màn 2–200) `(màn, các bộ dùng chung)`; mỗi nhóm cần đúng **một** level. Ví dụ màn 13 có 3 nhóm: `default`, `lv2`, `lv3+lv4+lv5`.

Không chép hoặc biến đổi nhẹ level của Sort Streak. Chỉ dùng thông số "khung" trong file làm gợi ý.

## 2. Tài liệu và công cụ có sẵn

- `levels/sweet_rope_B/docs/README_LevelGen.md`: định dạng JSON của level, luật chơi, ràng buộc `validate()`, cách đo độ khó, các núm điều chỉnh. **Đọc hết trước khi làm.**
- `levels/sweet_rope_B/tools/validate_level.gd`: kiểm tra hợp lệ và giải được. `levels/sweet_rope_B/tools/greedy_ext.gd`: đo `lw`, chỉ số độ khó tốt nhất hiện có (rho −0,84 so với điểm thật; sai số mỗi level khoảng ±9).
- `levels/sweet_rope_A/`: bộ 200 level bản A và các script `generate.py`, `verify.py` của người làm trước, dùng làm tham khảo cách sinh.
- `levels/sweet_rope_B/docs/targets_B.csv`: danh sách 680 nhóm cần sinh (xem mục 3). `levels/sweet_rope_B/docs/SweetRope_AB_tong_hop.xlsx`: vị trí màn đặc biệt, bảng tái sử dụng, các phần A/B.

Tất cả nằm trên branch **`New_Level`**.

## 3. Cột của `targets_B.csv`

`slot`, `group` (các bộ dùng chung, nối bằng `+`), `loai` (Normal/Hard), `muc_tieu` (điểm độ khó mục tiêu), `dac_biet`, `bat_buoc_bonus_1_mau_1_chau`, `khung_sort_streak_*` (cap, tgt, cols, types_all, hidden, locks, parks, inc_len: thông số của level Sort Streak ở cùng chỗ, chỉ để gợi ý khung), `file` (tên file cần ghi).

## 4. Ràng buộc bắt buộc (không đạt là bị loại)

1. Đúng định dạng JSON và qua `JuiceLevel.validate()` (README mục 2, 3). Loại hoa và loại chậu chỉ từ **0 đến 9**.
2. **Giải được** (`WINNABLE` bằng solver trong README mục 6). Với màn có khóa, băng hoặc dây trống, solver 4000 nút hay trả `UNKNOWN`; hãy tăng giới hạn hoặc dùng `hint_win_path` để chứng minh.
3. **Màn bonus** (màn 13, 23, 33, … tức `slot ≥ 13` và `(slot − 13) % 10 == 0`): trong cả level phải có **ít nhất một màu chỉ có đúng 1 chậu**. Đếm chậu trên tất cả dây ở `initial` và `incoming` (kể cả dây đang khóa; không đếm chậu trắng `-` và mục `x`). Cột `bat_buoc_bonus_1_mau_1_chau` đánh dấu các nhóm này. Không ghi gì về bonus vào file level.
4. **Cơ chế mở theo màn:** hoa ẩn (`?`) chỉ từ màn **6**; dây khóa theo màu (`collect_type`) từ màn **11**; dây khóa theo số lần (`collect_count`) từ màn **21**. Không dùng băng và ánh nắng. Khuyến nghị tối đa **1 dây khóa** và `count` ≤ **3**: thí nghiệm cho thấy chèn 2 dây khóa làm 31–53% level không giải được. Chỉ dùng nhiều hơn khi `khung_locks` trong file yêu cầu và đã chứng minh giải được bằng solver.
5. **Màn đặc biệt:** màn 1 không sinh (dev dùng level hướng dẫn cố định). Màn Challenge (17, 27, …) và Endless (30, 40, …) bị thay lúc chơi, nhưng dev chưa có cơ chế đó, nên **vẫn sinh level thường**. Màn 2–5 giống nhau ở cả 5 bộ (đã gộp trong file).
6. **Màu sắc theo Sort Streak:** mỗi level dùng 8–10 loại hoa, thường là 9 (khoảng 84% level 9 loại, 13% 8 loại, 2% 10 loại). Thay đổi loại bị bỏ và cách gán chậu giữa các level để cả 10 màu xuất hiện đều; không để một màu vắng mặt liên tục. Thông số khác cũng bám Sort Streak: `capacity` 5 (khoảng 65%), 4 (19%), 6 (16%); 6 dây lúc mở (58%) hoặc 7 dây (42%).
7. **Không tái sử dụng** cùng một level ở hai màn khác nhau. Dùng chung một level cho nhiều bộ ở **cùng một màn** thì được (đó là nhóm trong file). Ngoại lệ hiếm: nếu thật sự cần dùng lại ở màn khác, chỉ khi chênh màn không vượt giá trị trong bảng dưới (số màn chênh tối đa; `x` hoặc `0` là không được) và ghi rõ lý do:

| Bộ ở màn nhỏ hơn \ bộ ở màn lớn hơn | default | lv2 | lv3 | lv4 | lv5 |
|---|---|---|---|---|---|
| default | x | x | 0 | 3 | 8 |
| lv2 | x | x | x | 0 | 5 |
| lv3 | 0 | x | x | x | 0 |
| lv4 | 2 | 0 | x | x | x |
| lv5 | 5 | 3 | 0 | x | x |

   Màn 1–5 không dùng lại ở bất kỳ màn nào khác. Bảng này tính theo luật lên/xuống mức gốc cộng cơ chế hạ bản sau 4 lần chơi lại.

## 5. Mục tiêu độ khó: sai càng thấp càng tốt

- Không có ngưỡng "đạt". Với mỗi nhóm, **sinh nhiều ứng viên** (khuyến nghị ít nhất 10), đo `lw` bằng `greedy_ext.gd`, chọn ứng viên có điểm ước lượng gần `muc_tieu` nhất làm bản chính thức, và **giữ lại các ứng viên còn lại** trong thư mục `work/candidates/` để bên kiểm có thể chọn lại.
- Dùng bảng núm trong README mục 5b để chỉnh: tải của level (số hoa ở dây đầu, độ đầy, số cốc), dây khóa, số đoạn đổi loại; hoa ẩn chỉ để tinh chỉnh vài điểm. Thêm dây trống để làm dễ.
- **Đừng tin điểm tự gán.** Công thức ước lượng chỉ giải thích khoảng 66–70% độ khó thật (sai số khoảng ±9 mỗi level, đánh giá thấp màn rất khó). Ghi trong báo cáo của bạn là "tự ước lượng".
- Màn 1–10 và các màn điểm rất thấp (dưới 10): bên kiểm đo kém chính xác ở vùng này; ưu tiên cấu trúc đơn giản đúng ý (ít màu, nhiều chỗ trống, không hoa ẩn trước màn 6).

## 6. Cách làm việc (vòng lặp liên tục)

1. Làm việc trên branch **`New_Level`**. **Không push lên `main`**, không force push. Trước mỗi lần push, `git pull` (merge) để lấy báo cáo mới của bên kiểm. Bạn chỉ ghi vào `levels/sweet_rope_B/work/`. Thư mục `levels/sweet_rope_B/final/` (bộ level giao cho dev) và `levels/sweet_rope_B/reports/` do bên kiểm ghi; không sửa hai thư mục này.
2. Ghi mỗi level chính thức thành `levels/sweet_rope_B/work/<file trong targets_B.csv>`, ví dụ `work/L013_lv3+lv4+lv5.json`. Ghi ứng viên vào `levels/sweet_rope_B/work/candidates/`. Ghi file `levels/sweet_rope_B/work/assignment.csv` với cột `bo, slot, file` (mỗi bộ trong nhóm một dòng).
3. Ghi `levels/sweet_rope_B/work/self_report.csv`: `slot, group, file, valid, solvable, lw, diem_tu_uoc_luong, muc_tieu, lech`. Đây là số tự ước lượng.
4. Commit và push sau mỗi lô (khoảng 25 màn). Commit nhỏ, thông điệp rõ.
5. Sau mỗi lần bên kiểm push báo cáo vào `levels/sweet_rope_B/reports/` (mỗi nhóm có: hợp lệ, giải được, `lw`, điểm ước lượng, sai số, điều kiện bonus), đọc báo cáo mới nhất, **sinh lại trước các nhóm bị loại hoặc sai số lớn**, rồi tiếp tục lô kế tiếp.
6. Thứ tự làm: màn 2–25, sau đó chapter 2 đến 8. Xong một lượt đủ 680 nhóm thì quay lại cải thiện các nhóm sai số lớn nhất, cho tới khi có người dừng.

## 7. Không được làm

- Không sửa engine, không sửa tài liệu hoặc file ngoài `levels/sweet_rope_B/work/`.
- Không chép level từ Sort Streak (`assets/builtin`, `assets/game`, `GD_Lazy`, các bộ level của người làm trước).
- Không tuyên bố một level "đạt" dựa trên điểm tự gán; không bịa kết quả kiểm.
- Không dùng loại hoa hoặc chậu ngoài 0–9, không dùng băng/ánh nắng; không dùng từ 2 dây khóa trở lên nếu chưa chứng minh giải được.
- Nếu một yêu cầu mâu thuẫn hoặc thiếu thông tin, ghi vào `levels/sweet_rope_B/work/QUESTIONS.md` và làm tiếp phần còn lại, không tự đoán.
