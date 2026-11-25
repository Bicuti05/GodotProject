# Gameplay · bổ sung sprite và lớp chuyển động

## Godot drop-in

- Chậu rỗng/đầy Fruit dùng cùng art Type ID với Unity. Chín nhóm dây màu và Free Rope có đủ đầu nút, thân và nút cuối, dùng lại hình dáng vân dây đỏ đã duyệt. `cyan` là đào hồng, `lavender` là mận.
- Các texture gỗ/hardware còn lại trong `wood_door/` được xuất trong suốt theo thông số manifest. Mật ong ở `frame.png` và sáp ở `body.png` vẫn là lớp đóng. Việc này giúp loại các mảng gỗ khỏi bản tham chiếu đóng. Logic mở/vỡ gỗ của Sort Streak chưa được thay thành chuyển động mật ong.
- Bổ sung mặt nút, icon, badge và một số texture Sunlight/băng cho bản tham chiếu. Bộ chưa được import hoặc xác minh trực quan trong Godot runtime.

## Unity · hướng dẫn lớp chuyển động

- Hidden Item: giữ nguyên vị trí/pivot. Dùng `OBJ_SACK_KNOT` cho nơ rời và `OBJ_SACK_OPEN` cho túi mở. Nơ tuột, túi hạ xuống rồi ẩn. Trong lúc đó lộ sprite thật theo Type ID **tại chỗ**, không bounce hoặc phóng lớn.
- Locked Rope: chuyển dấu sáp kín sang `OBJ_HONEY_SEAL_CRACK`. Dùng `EFF_HONEY_FLOW_1` → `4` theo thứ tự, neo phần mật còn lại về chân dây, để item lộ từ trên xuống. Drop và Puddle đặt dưới chân dây. Undo khôi phục theo thứ tự ngược và dùng điều kiện Deliver từ dữ liệu level.
- Thời lượng, easing, điểm cắt mask và trạng thái restored phải kiểm trong project Unity. Các PNG là lớp để dev dựng chuyển động, chưa phải animation chạy trong engine.

## Kiểm tra và WARN

- `sunlight_collector_body.png` giữ dáng collector bầu ngang đã dùng trong Unity. Vùng hình đạt 99% chiều ngang và 72% chiều cao tham chiếu; cần so lại điểm chạm với ván và glow trong runtime.
- `prop_btn_hint.png`, `prop_btn_rope.png`, `prop_btn_undo.png` giữ tỷ lệ icon Unity và chừa khoảng quanh glyph. Phần thị giác nhỏ hơn asset gốc; không kéo dài hình. Cần kiểm tra cỡ đọc ở nút thật và tâm vùng chạm.
- Các PNG gỗ hoàn toàn trong suốt là chủ ý của manifest. PNG khác giữ alpha thật, nguồn có ít nhất số px của file bàn giao.
