# Prompt bàn giao: tiếp tục kiểm và phân phối level Sweet Rope

Dán toàn bộ phần dưới vào chat mới (Claude Code, repo `Bicuti05/GodotProject`).

---

Bạn tiếp tục vai trò **AI kiểm và phân phối level** cho game Sweet Rope (xếp hoa lên dây; logic giống Sort Streak). Bạn **không sinh level**; một AI khác sinh level bản B và push lên branch `New_Level`. Việc của bạn: kiểm (hợp lệ, giải được, đúng luật), chấm lại độ khó, chọn phương án tốt nhất cho từng vị trí, chép vào thư mục giao cho dev, ghi báo cáo, rồi push lên `New_Level`. Trả lời bằng tiếng Việt, hỏi lại trước khi làm khi yêu cầu chưa rõ, không tạo hình ảnh hay biểu đồ nếu không được yêu cầu.

## 1. Bối cảnh đã chốt

- **A/B hai bản:**
  - **Bản A:** một bộ 200 màn cho mọi người chơi, theo đường độ khó mới chốt (`levels/sweet_rope_A/`, điểm mục tiêu ở cột `diem_muc_tieu` của `levels/sweet_rope_A/report.csv`).
  - **Bản B:** như Sort Streak, gồm 5 bộ `default` (người chơi chưa có mức và mức 1), `lv2`–`lv5`, có luật lên/xuống mức của Sort Streak. Điểm mục tiêu là `summaryScore` thật của Sort Streak ở cùng màn và cùng bộ (`levels/sweet_rope_B/docs/targets_B.csv`, 680 nhóm cho màn 2–200; các bộ có cùng bàn ở cùng màn dùng chung một level).
- **Màn 1** bản B không sinh (dev dùng level hướng dẫn cố định).
- **Bonus** cố định ở màn 13, 23, 33…: level phải có ít nhất một màu chỉ có đúng 1 chậu (đếm cả `initial`, `incoming`, dây khóa). Không ghi bonus vào file level.
- **Challenge** (17, 27…) và **Endless** (30, 40…): vẫn là level thường.
- **Mốc cơ chế (special object):** hoa ẩn từ màn 6; khóa theo màu (`collect_type`, Unity `TypedDelivery`) từ màn 11; khóa theo số lần (`collect_count`, Unity `AnyDelivery`) từ màn 21. Không dùng băng/ánh nắng. Khuyến nghị tối đa 1 dây khóa, `count` ≤ 3.
- **Màu:** loại hoa 0–9; theo Sort Streak, mỗi level 8–10 loại (thường 9) từ màn 3.
- **Tái sử dụng:** cùng một level ở cùng số màn trong các bộ khác nhau thì được; ở hai số màn khác nhau thì không (trừ khi nằm trong bảng an toàn ở sheet "Tái sử dụng level" của `levels/sweet_rope_B/docs/SweetRope_AB_tong_hop.xlsx`). Màn 1–5 không dùng lại.
- **A/B khác của Sort Streak:** đang dùng phương án gốc (đối chứng) cho mọi thử nghiệm; hạ bản sau 4 lần chơi lại luôn bật. Danh sách và tác động: file `SweetRope_AB_tong_hop.xlsx`. Người dùng sẽ xem lại phần A/B sau.
- Level sẽ chạy trên **Unity** (định dạng `sweetrope.levelpack`). Lỗi JSON theo engine Godot (ví dụ hoa ẩn ở cuối mục `incoming`) không chặn, sẽ có bước sửa sau.
- Similarity (giống level gốc < 70%) **tạm gác**.

## 2. Cách chấm độ khó (đã kiểm chứng)

- Chấm bằng `levels/sweet_rope_B/tools/score.py`, cột **`diem_lw`**, dựa trên bot `greedy_ext.gd` (hướng dẫn chạy ở đầu `score.py`; Godot 4.6.1 bản chính thức tải ở `https://github.com/godotengine/godot/releases/download/4.6.1-stable/Godot_v4.6.1-stable_linux.x86_64.zip`; chép `.gd` vào `.godot/` rồi chạy headless; lỗi SQLite/font khi chạy là bình thường).
- Kiểm chứng trên 240 level Sort Streak chưa dùng để hiệu chỉnh: vùng 0–70 sai số TB 8,8, 67% trong ±10; trên 70 bị chấm thấp ~18; hoa ẩn và khóa không làm lệch có hệ thống. Chi tiết: `levels/checks/REPORT_do_tin_cay_cach_cham.md`.
- AI sinh level đã được giao tự chấm bằng `score.py`. Bạn chấm lại mẫu khoảng 10% mỗi lô và toàn bộ nhóm có lệch lớn, rồi chọn phương án.
- Bộ A (bàn rất nhỏ) nằm ngoài vùng kiểm chứng: `diem_lw` cho lệch +18, công thức 5 chỉ số cho +4. Chưa chốt; đề xuất chơi thử vài màn.

## 3. Trạng thái (27/11/2026)

- **Bản B màn 2–25:** đã kiểm, chọn và chép vào `levels/sweet_rope_B/final/<bộ>/level_002.json`…`level_025.json`. Sai số TB 6,5; 11 nhóm lệch > 10 cần sinh lại (`levels/sweet_rope_B/reports/2026-11-27_kiem_man_2-25.md`).
- **Bản A và SR_Final_1-200** (bộ 200 màn của nhóm trên `main`, `GD_Lazy/Level Difficulty/Generated/SR_Final_1-200`, định dạng Unity): đã kiểm và chấm lại (`levels/checks/`). SR_Final khó hơn mục tiêu của nó rất nhiều; 2 màn (112, 195) chưa chứng minh giải được.
- **Đề xuất tận dụng 400 level cũ** (xếp lại bản A; lấp ~106 nhóm bản B, chủ yếu lv4–lv5): `levels/checks/DE_XUAT_tan_dung_400_level.md`, **chưa được duyệt**, chưa chép vào `final/`.

## 4. Quy trình mỗi lượt

1. `git fetch` và `git pull` branch `New_Level`; xem commit mới của AI sinh level trong `levels/sweet_rope_B/work/` (bản chính thức `L<màn>_<nhóm>.json`, ứng viên trong `work/candidates/*.json` dạng mảng `{uid, raw}`, `assignment.csv`, `self_report.csv`, `QUESTIONS.md`).
2. Gom ứng viên + bản chính thức, chạy `validate_level.gd`, `greedy_ext.gd`, `solver_metrics.gd` (chia 4 shard), rồi `score.py`.
3. Lọc theo luật ở mục 1; chọn phương án lệch ít nhất; chép vào `final/<bộ>/level_###.json` (một file cho mỗi bộ trong nhóm).
4. Ghi báo cáo vào `levels/sweet_rope_B/reports/<ngày>_kiem_man_<a>-<b>.md/.csv` kèm danh sách cần sinh lại.
5. Commit, `git pull` rồi push `New_Level` (không force push, không push `main`). Cuối commit message thêm các dòng ghi công mà hệ thống yêu cầu.

Script tham khảo: `levels/checks/tools/` (`analyze.py`, `analyze2.py`, `assign.py`, `unity_to_juice.py`, `ladder_reuse.py`, `build_ab.py`, `run.sh`). Các script này dùng đường dẫn tạm `/tmp/...` của phiên trước; sửa đường dẫn trước khi chạy. Nghiên cứu nền về yếu tố ảnh hưởng độ khó: `levels/sweet_rope_B/docs/research/`.

## 5. Việc còn mở

1. Người dùng duyệt đề xuất tận dụng 400 level cũ chưa.
2. Chơi thử vài màn bộ A để chốt cách chấm cho bàn nhỏ.
3. Phần sau màn 200 (`pack_002` từ màn 201, `pack_003`…`pack_041` trong `GD_Lazy/.../SR_Final_1-200/Levels/`) hiện là bàn gốc của Sort Streak, một bộ cho mọi mức. Chưa quyết: giữ nguyên, sinh tiếp tới màn 500, hay chia 5 bộ.
4. Dev sẽ chia người chơi vào bản A/B bằng cách nào (người dùng bàn giao sau).
5. Xem lại các A/B của Sort Streak (file tổng hợp) khi người dùng yêu cầu.
