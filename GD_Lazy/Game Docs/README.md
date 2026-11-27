# GDD SortStreak (bản nháp 0.2, chờ GD check)

Game: Sort Streak: Color Puzzle (Oakever) 1.0.10, Godot 4.6.1. Nguồn: script `.gd` khôi phục tại `SortStreak/out/project/scripts`, dữ liệu level giải mã, báo cáo phân tích có sẵn. Chỉ lấy FORMAT từ GDD mẫu MSCS; không dùng nội dung mẫu.

Quy ước:
- Mỗi file có sheet `v1` (nội dung) và sheet `Cần xác nhận` (điểm chưa rõ).
- Cột **Trạng thái**: `Implemented` (có bằng chứng trong mã), `Implemented (data)` (có trong dữ liệu level/báo cáo), `Unverified` (ô tô vàng, chưa đủ bằng chứng).
- Sheet `Cần xác nhận`: dòng `Đã đối chiếu` là điểm đã tra mã và chốt (kèm câu trả lời); dòng `Cần xác nhận` còn mở.
- Cột **Nguồn**: file/hàm trong mã. Giá trị là mặc định trong mã; server/A/B có thể ghi đè.

| Nhóm | File |
|---|---|
| Main Game | Core Gameplay, Special Object, Helper, Level Data, Level Unlock, Tutorial, Game Result, Control, Game Feel |
| Monet | Economy, IAA (không có IAP: không tìm thấy sản phẩm) |
| Meta Game | Daily First-Win Check-in, Rank, Home Screen (+Settings), Challenge Modes |
| Overview | Version Control, AB Config, Event Tracking |

Không có trong SortStreak (mẫu MSCS có): Lives, Online Reward, Kitty Bank, Collection, Profile, Shop/IAP.

Chưa làm: hình REF/Figma, bản dịch chuỗi, thông số thời gian của Game Feel, nội dung JSON của move_tiles_info/target_tiles_info, danh sách mốc GRT.

Thay đổi 0.2 (2026-11-23): Event Tracking viết lại theo từng event (trigger, tham số, common/round params); đối chiếu mã để chốt neo Special Challenge, roll thưởng, Timed Endless, thời điểm cộng xu thắng, interstitial từ level 11, Rank toàn bot, Fill Pot chọn dây tự động, dead toast. Chi tiết ở SS_Version Control.xlsx.
