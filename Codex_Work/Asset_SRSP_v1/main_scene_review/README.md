# Main Scene · Level 27 theo ref mới

Mockup 1080 × 2340, dựng ngoài engine. Ref sếp đưa dùng để đối chiếu thứ tự và tỉ lệ cụm: Level/xu → IQ → Order (3 cây đã giao + 5 ô chờ) → ván và 6 dây → 4 Helper. Không đưa pixel ref vào output. Layer ngày chơi, xu, mốc IQ, tiến độ 3/8 và badge Helper giữ ở lớp chữ trong CSV.

## File mới

- `sprout.png`, `soil.png` và `canopy.png` là các lớp rời để ráp với Container. Mầm chỉ đặt trên chậu có loại, Free Rope dùng chậu trống.
- `delivered_tree_0…9.png` là 10 sprite cây đã Deliver, tái tạo theo mẫu được duyệt và xuất theo Type ID. Xem [sheet cây Order](delivered_trees_sheet.png). Ảnh Level 27 là bản dựng tham chiếu trước khi thay bộ cây. Chúng dành cho Order đã giao. Container đầy quả trong manifest vẫn là loại asset riêng.
- `assets.csv` và `layers.csv` lần lượt ghi kích thước nguồn/xuất và từng lớp dùng trong preview. Source PNG có cùng đường dẫn bên dưới `source/`.
- 7 PNG thuộc manifest chính: nút thắt Rope, 3 hạt Deliver đổi màu được, trail và glow cho Hint/đặt hợp lệ. Xem `../report_main_scene_ref.csv`.

Ref có quả vàng dáng chanh và quả tím dáng mận. Mock dùng chuối type 3 và mận type 0 theo bảng type đã chốt; chanh xanh vẫn là type 5. Dữ liệu board là mẫu để duyệt art và bố cục. Cần dev xác nhận kích thước slot mầm/cây, pivot, animation Deliver và dữ liệu Level 27 trong Unity trước khi đưa vào game.
