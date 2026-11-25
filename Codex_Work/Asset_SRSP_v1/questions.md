# Câu hỏi duyệt đợt 0

1. Team có PNG RGBA gốc của logo `SR_Logo chot` không? Hai mock Home/Settings đang dùng chữ Sweet Rope minh họa. File WebP bàn giao có nền đen. Nếu không có bản gốc, cần duyệt lại bản phục dựng logo trước khi dùng trong mock chính thức.
2. Duyệt dáng lê xanh non của type 4 trên contact sheet ở 125 px. Hình lê thuôn để phân biệt chanh xanh ở ảnh xám. Checker cảnh báo vùng ngang của bản thay Godot nhỏ hơn vùng ảnh tham chiếu. Nếu runtime lấy hit area từ vùng alpha, cần đo lại trước khi chốt gameplay.
3. CX-09 vẫn cần xác nhận trong Unity. Kích thước file và mock được xuất đúng manifest 1080 × 2340. Dev xác nhận logical canvas 1920/2340 và cách xử lý import để ảnh cao 2340 không bị hạ độ phân giải ngoài ý muốn.

Các mục về Stage Home, luật Bonus, motif Flower/Winter và skeleton chưa cần quyết định để duyệt art đợt 0.

## Phase 0S

- Gói Phase 0S không kèm `SR_Art Task.xlsx`, `unity_current/`, `SortStreak_Scenes_INDEX.md`, `sr_scene_parity.csv` hoặc `capture_reference/` dưới thư mục handoff hiện tại. Đã bỏ qua các mục đó theo yêu cầu. `Codex_Work/INDEX.md` và art board trong repo dùng được khi cần tra bối cảnh.
- Logo trong mock Home/Settings tiếp tục là chữ minh họa theo README. Đường dẫn logo gốc trong suốt vẫn chờ team.
- Chậu các màu trong 2 mock Board có cùng kích thước, dùng biến thể màu chỉ cho mock. Phase Container chính thức vẫn khóa.
- Các nền mới được vẽ ở canvas 2160 × 4680. Ván và nút có source dựng trực tiếp ở 3×. Các file bàn giao thu về kích thước manifest; mẫu Home vẫn là mock tĩnh.
