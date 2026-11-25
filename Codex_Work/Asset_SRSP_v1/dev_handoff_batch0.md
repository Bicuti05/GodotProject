# Đợt 0 — ghi chú art và tích hợp

## Phạm vi

Asset mới theo `asset_manifest.csv`. Dùng style_ref và art Sweet Rope trong unity_current làm chuẩn. Sort Streak chỉ được đọc để lấy bố cục, vai trò và kích thước. Không dùng ảnh Sort Streak làm đầu vào sinh ảnh hay đưa pixel của game đó vào mockup. `source/` có art gốc PNG độ phân giải cao hoặc bản dựng gốc của từng output. PNG bàn giao giữ nguyên canvas và dùng sRGB/straight alpha.

Bốn mockup được ghép tĩnh ngoài engine. Board 4/7 Rope dùng Item mới, chậu đỏ đã xuất, các màu Container thử để đánh giá tương phản, và HUD/Helper minh họa. Hình minh họa và số liệu không phải fixture của game đích. Hai mock UI dùng chữ tiêu đề minh họa chờ logo PNG chuẩn. Đây là phạm vi duyệt style, chưa chạy một bản Unity.

## Checker và duyệt bằng mắt

- Chạy `python check_assets.py --selftest` và checker đợt 0 từ gói handoff gốc. Xem `report_batch0.csv`.
- `flower_teal.png` có vùng ngang 68% và cao 99% so với ảnh tham chiếu. Tâm và khung giữ nguyên. Giữ silhouette thuôn của lê để tránh lẫn chanh và táo ở ảnh xám. Không kéo ngang quả để bỏ cảnh báo. Hit area và tâm tiếp xúc cần thử trong game.
- Contact sheet màu sáng/tối và grayscale được xuất trong `contact_sheets/`. Hàng trái cây có cạnh dài hiển thị 125 px. Honey, nút và ván trong contact sheet được thu để xem cạnh nhau. Kiểm tra các cụm ở kích thước trong mock gameplay 4/7 Rope.
- Họa tiết mép nền được nối bằng sắc độ nền ở canvas lớn. Các phần có chi tiết của ảnh nguồn không bị phóng to. Ván/nút giữ hai đầu và ghép phần giữa co giãn.
- Các thông số cạnh đề xuất để thử Unity Sprite Editor, không phải dữ liệu đã đo trong editor: nút xanh L/T/R/B = 64/26/64/26 px; ván = 35/0/35/0 px (tách chiều ngang). Hai dòng này chưa có chỉ định 9-slice trong manifest nguồn.

## Việc dev cần làm

1. Ánh xạ Item/Container bằng Type ID. Godot dùng slot tên màu cố định, ví dụ `cyan` là đào hồng. Unity dùng dây trắng/xám để tint và có thể tắt tint trên Item và Container. Dùng tâm sprite theo slot và kiểm tra tiếp điểm miệng Container/ván, nhất là lê.
2. Ghép Honey Top, Body và Bottom theo cùng trục; tile Body theo sức chứa 3–8. Giữ sáp và nhãn điều kiện ở lớp riêng. Khi mở, tách nứt sáp và dòng mật để reveal từ trên xuống; Undo khôi phục theo hướng ngược. Các đoạn/mép ghép được kiểm tra pixel. Chuyển động chưa được kiểm trong Unity.
3. Chỉ 2 resource Wood Door trong manifest thuộc đợt 0 là `frame.png` và `body.png`. Muốn xem lớp mật đóng thay thế đầy đủ trong một bản sao Godot, cần đủ texture theo các đợt kế tiếp hoặc ẩn lớp gỗ cũ trên bản mock. Bản này chỉ đánh giá trạng thái đóng trên mock tĩnh. Không chép riêng hai file lên project gốc và coi là hoàn tất tích hợp.
4. Hidden Item dùng một túi kín. Khi reveal, đổi sang Item thật tại đúng tâm, không scale hoặc nảy. Rig/animator cần các pose mở nơ và miệng túi ở đợt animation.
5. Đo safe area và vùng banner thật trong Unity. Xác nhận Sprite Max Size và PPU, canvas 1920/2340. Soát viền 9-slice ở nhiều kích thước.
6. Giữ logo, 10 silhouette Item, hướng sáng và palette làm bộ đối chiếu duyệt trước khi mở rộng. Công cụ có thể tạo art alpha và script có thể xuất đúng px. Những nhóm nhiều ô chính xác hoặc nhiều frame liên tục như atlas/animation vẫn cần Artist kiểm tay và sửa chỗ lệch pose, hình hoặc viền. Kết quả đợt 0 chưa xác lập chất lượng đồng đều cho các đợt sau.
