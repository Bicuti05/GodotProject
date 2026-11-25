# START_HERE · Đối chiếu 81 trạng thái và art bổ sung

| Nhóm trong START_HERE | Đã bổ sung trong manifest Unity | Còn phải xác minh hoặc tạo |
|---|---|---|
| Board, Locked, Hidden, Sunlight | 10 Container màu, Free Rope, Container đầy, Order, Sunlight collector/item và hai lớp băng. Mock dùng túi vải và mật ong của Phase 0S | Pose túi mở, mật chảy và băng tan theo thời điểm, Rope/Godot drop-in đầy đủ |
| HUD và Helper | IQ track/groove/fill/badge, mặt nút và icon theo trạng thái, CTA, dấu thả | Hand guide, các lớp hoạt ảnh và trạng thái runtime |
| Startup và Home | Nút Play và UI, track/fill loading, mock Home với nền Sweet Rope | Logo PNG đã chốt, stage chính thức và các layer nền Home tách riêng |
| Settings, Finish, Bonus, Endless, Special | Panel và icon chung, timer, heo đất/xu, rương đóng/mở, các khung kết quả | Hiệu ứng phát thưởng, hoạt ảnh heo/vỡ rương và bố cục kiểm trong Unity |
| Rank, Profile, Streak, Meta | Ảnh duyệt có lớp minh họa từ bộ Sweet Rope cũ, thành phần mới dùng chung | File Unity redraw theo từng màn, cúp mèo đủ bậc, atlas đúng vùng |
| Theme Flower và Winter | Phạm vi mockup dùng Fruit | Chờ chốt tên hoa và motif bánh quy; chưa xuất asset theme thay thế |

Có đủ 81 mockup duyệt bố cục. Tất cả dựng ngoài engine. Content của mỗi mock là minh họa từ ảnh ref và data mẫu. Không coi một mockup là bằng chứng đã đủ asset của scene runtime. Danh sách mọi dòng manifest còn thiếu nằm ở `remaining_scene_assets.csv`.

- `GODOT / draw`: 669 mục còn thiếu.
- `GODOT / layers`: 46 mục còn thiếu.
- `UNITY_NEW / draw`: 126 mục còn thiếu.
- `UNITY_REDRAW / atlas`: 4 mục còn thiếu.
- `UNITY_REDRAW / draw`: 80 mục còn thiếu.

Các dòng action skip được loại khỏi thống kê. Asset tạo trong lượt này giữ nguyên canvas nguồn hoặc thu nhỏ đúng tỷ lệ. Source tại source/. Checker chạy theo danh sách file mới, sau đó đối chiếu alpha và kích thước master.

## Bổ sung Gameplay drop-in

Giao thêm 90 PNG. Xem [ghi chú](gameplay_dropin_notes.md) và [checker](report_gameplay_dropin.csv). Còn 835 dòng trong manifest.

## Ref main scene mới

Đã xuất [Level 27](main_scene_review/Gameplay_Level_27_Ref.png), 13 lớp art bổ sung ngoài manifest và 7 mục theo manifest. Xem [ghi chú](main_scene_review/README.md) và [checker](report_main_scene_ref.csv).

## Đối chiếu số lượng

Bổ sung 96 dòng HUD/FX. Xem [kiểm kê](asset_count_audit.md) và [checker](report_hud_fx_parity.csv). Còn 732 dòng cần giao.

## Rank và Profile

Bổ sung 70 asset và 2 mockup theo art mới. Còn 662 mục trong manifest. [Ghi chú](rank_profile_review/README.md) · [checker](report_rank_profile.csv).

## Streak và Win

Bổ sung 24 PNG Unity redraw và 2 mockup theo theme mèo nông dân. Còn 638 mục. [Ghi chú](streak_win_review/README.md) · [checker](report_streak_win.csv).
