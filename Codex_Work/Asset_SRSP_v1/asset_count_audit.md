# Kiểm kê asset Sort Streak và Sweet Rope

Phạm vi đếm là file Git theo dõi dưới `assets/` của project Sort Streak. Có **883 file hình 2D** gồm 870 PNG, 10 SVG, 3 WebP. Thư mục art tham chiếu có 870 PNG. Ngoài hình, project có 44 file atlas và 42 skeleton `.skel`. Cộng ba nhóm này ra 969 file, gần 960 nhưng gồm metadata và skeleton. Chưa có đường dẫn hoặc quy tắc đếm xác định con số 960. Bỏ `.import`, font, dữ liệu và âm thanh khỏi số hình.

Manifest Sweet Rope có 1.259 dòng, gồm 147 dòng `skip`. 1.112 dòng cần giao gồm ảnh Unity mới, Unity redraw, Godot drop-in và mục atlas/lớp. Một dòng layers có thể yêu cầu nhiều PNG. Số mockup, ảnh review và file nguồn được tính riêng.

| Nhóm | Dòng cần giao | Đã có | Còn thiếu |
|---|---:|---:|---:|
| `GODOT / draw` | 690 | 215 | 475 |
| `GODOT / layers` | 46 | 0 | 46 |
| `UNITY_NEW / draw` | 292 | 203 | 89 |
| `UNITY_REDRAW / atlas` | 4 | 0 | 4 |
| `UNITY_REDRAW / draw` | 80 | 80 | 0 |

Tổng còn thiếu **614 dòng**. 1106 vùng PNG dành cho 46 mục layers của Godot. Với rows layers, kiểm sự hiện diện của motion.md và toàn bộ file vùng. [Danh sách còn thiếu](remaining_scene_assets.csv) ghi từng tên và yêu cầu.

## Bổ sung lượt này

- Godot drop-in: HUD Level/Order/IQ/xu, nút chung cho dialog, dấu hợp lệ và hover thả, dải timer, coin/pig và nền Fruit. Một số glyph icon dùng bản Sweet Rope đã duyệt.
- FX: halo theo 10 Type ID, lớp sáng Sunlight, 12 bông tuyết nhỏ, ba pose tan băng Unity. Checker kiểm 96 dòng riêng, WebP lossless và IQ track SVG đúng định dạng.
- WARN có trong báo cáo. Các cảnh báo tương đồng do cùng chức năng/mặt nạ hình học tiêu chuẩn: bốn nền highlight dưới, bốn glow Sunlight, nền card Endless và thanh timer đỏ. Các ảnh được dựng mới theo gradient/hình học Sweet Rope; không dùng pixel gốc. Đã mở contact sheet để rà. Chưa kiểm runtime Godot/Unity.
- Các dòng chưa có gồm drop-in phụ, redraw Rank/Profile/Streak/Win, theme Flower/Winter, skeleton/atlas và motion. Cần xác nhận motif theme và quyền dùng skeleton của team theo handoff. Godot đóng vai trò tham chiếu, bản Unity Sweet Rope vẫn chưa có trong workspace.

- Lượt Rank/Profile: 70 mục, gồm 56 ảnh Unity redraw và 14 texture Rank Godot. Xem [mockup và ghi chú](rank_profile_review/README.md).

- Lượt Streak/Win: thêm 24 PNG Unity redraw. Hoàn tất các dòng redraw tĩnh. 4 atlas Unity đang chờ.

- Lượt Home/Loading/Shop: 24 mục, gồm nền và Stage, UI Shop, adaptive/store icon và lớp Loading Godot.
