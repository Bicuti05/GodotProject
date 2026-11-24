# Rule verification

Godot 4.7.2 headless chạy bản sao nguyên file của các rules GDScript trong một project nhỏ. Bảy assertion đạt.

- Hidden vào dây trống đúng capacity.
- Mystery reveal sau khi hoa cuối bị di chuyển.
- Undo phục hồi trạng thái ban đầu với memory tắt.
- Lock trên nguồn trả reject Locked.
- Coin Bonus cadence và daily cap.
- Daily check-in cùng ngày và bỏ ngày.
- Difficulty ladder lên bậc và reset streak.

Các phép thử này chỉ chạy rules. Chưa kiểm thử launcher, UI tương tác, save/restore SQLite, quảng cáo và analytics native. Bản Godot 4.6.1 có Spine cần cho full build trước đây bị proxy trả 403. Art Reference Board hiện có ảnh layout và component xem trước.
