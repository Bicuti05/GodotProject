# Godot Endless và Combo

Bổ sung 19 PNG theo manifest, gồm 12 texture Endless và 7 texture Combo. Nguồn tương ứng nằm trong `source/`.

- **Endless** dùng đồng hồ vàng với hai cụm lá, xu dập hình táo và icon thưởng táo. Chuông, hai kim và nắp trục là các lớp riêng. Ảnh ráp đồng hồ dùng vị trí tĩnh của Sprite2D trong `timed_challenge_clock.tscn`.
- **Combo** dùng trái cây Sweet Rope, mảnh giấy màu và dải sáng. Giữ lưới shader 10 × 8 cho các mảnh giấy, lưới 4 × 3 cho ruy băng và lưới 2 × 1 cho Combo 10. Ô cuối của atlas ruy băng vẫn trong suốt. Atlas `flowers_atlas.png` giữ ba ô hàng ngang theo layout texture tham chiếu. Đã kiểm nội dung nằm trong từng ô và có khoảng trống tại mép.
- Checker ghi 19 OK, 0 WARN, 0 FAIL. Godot 4.7.2 headless đọc và tạo texture được cho 19 PNG trong project kiểm riêng. Chuyển động của rig, mesh ruy băng và shader full-screen vẫn chưa được xác minh trong scene.

[Contact sheet nền tối](contact_sheets/godot_endless_combo_dark.png) · [Nền sáng](contact_sheets/godot_endless_combo_light.png) · [Ảnh ráp đồng hồ](contact_sheets/godot_endless_clock_assembly.png) · [Báo cáo](report_godot_endless_combo.csv)
