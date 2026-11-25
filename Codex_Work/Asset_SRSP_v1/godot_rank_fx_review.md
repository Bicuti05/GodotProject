# Godot Rank FX

Bổ sung 23 PNG cho hiệu ứng đổi hạng, vương miện, bục và điểm danh. Các lớp gồm mũi tên lên hạng, ruy băng, vòng sáng, tia, sao, đốm sáng và mặt nạ shader. Hai texture sao trong `rank_source` dùng art Sweet Rope đã có của Rank Trails ở đường dẫn tương ứng để các scene dùng cùng hình.

- `et_mask_702.png` và `et_line_700.png` giữ alpha đặc và tín hiệu ở kênh xám. `et_mask_015.png` dùng viền alpha với phần giữa trong suốt. Sprite sheet pháo sáng giữ bố cục 4 × 4 theo texture tham chiếu, mỗi ô có khoảng trong suốt ở mép.
- Checker ghi 20 OK, 3 WARN và 0 FAIL. Ba WARN thuộc glow có falloff hướng tâm tương tự tham chiếu. Các glow được dựng mới bằng hàm bán kính và góc.
- Godot 4.7.2 headless đọc và tạo texture cho cả 23 PNG trong project kiểm riêng. Chuyển động và shader ở scene Rank vẫn cần xác minh.

[Contact sheet nền tối](contact_sheets/godot_rank_fx_dark.png) · [Nền sáng](contact_sheets/godot_rank_fx_light.png) · [Báo cáo kiểm](report_godot_rank_fx.csv)
