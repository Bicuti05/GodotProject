# Sort Streak – Godot project (khôi phục từ com.oakever.sortparade 1.0.10)

Mở bằng: `E:\AssetRipper\ClaudeWorkPlace\tools_godot\spine\godot-4.2-4.6.1-stable.exe --path . --editor`
(Godot 4.6.1 + module Spine 4.2 chính thức của Esoteric, giống engine custom mà game dùng.)
Chạy thử: `... --path .` (vào launcher, logo, flow khởi động).

## Đã khôi phục
- 627 script `.gd`, 215 scene `.tscn`, asset (PNG, mp3, spine, shader, font) đã chuyển lại từ dạng import.
- `project.godot` (autoload, display, plugin), addon fly_trail, unikit, godot_package_manager, ios_*, godot-sqlite (+DLL Windows v4.7), godot_vpx.

## Đã vá so với bản GDRE xuất ra
- Bỏ 3 autoload `MCP*` và 4 plugin dev (`android_build_helper`, `auto_texture_compress`, `common_build_helper`, `godot_mcp`): chỉ có trong bản dev, không có trong gói phát hành.
- godot-sqlite: thêm `libgdsqlite.windows.*.dll` (v4.7); dùng lại `gdsqlite.gdextension` gốc của game.

## Còn thiếu / sai khác
- `godot_vpx` (phát video VP8/9) không có DLL Windows → báo lỗi nạp extension lúc khởi động, không ảnh hưởng chạy.
- Bản dịch: GDRE chỉ khôi phục được 492/667 khóa (`translations.csv`, nằm ở `.assets/assets/localization/`); file `.translation` gốc vẫn dùng được trong `assets/localization/`.
- Plugin native (Android/iOS: UniKit, quảng cáo, thanh toán) không chạy trên desktop (`UniKitPlugin not available`).
- Comment, tên biến cục bộ và định dạng code có thể khác bản gốc (GDScript đã biên dịch thành token).
- Game cần mạng tới `jigsaw-api.dailyinnovation.biz` để lấy level; không có export preset nên chưa build APK.
