# Nhiệm vụ: vẽ bộ asset hoàn toàn mới cho Sweet Rope: Sorting Puzzle

Bạn đang làm trên repo `Bicuti05/GodotProject` (`/workspace/GodotProject`). Đọc hết file này trước khi tạo bất kỳ ảnh nào. Trả lời và ghi chú bằng tiếng Việt.

## 0. Năm điều không được sai

1. **Pixel.** Mỗi file xuất ra phải đúng `width` × `height` trong `asset_manifest.csv`, đúng tên, đúng đường dẫn, đúng định dạng. Không cắt sát (trim), không đổi khung, không phóng to ảnh nhỏ.
2. **Ảnh mới hoàn toàn.** Không tô lại, đổi màu, vẽ đè, can nét, hay đưa ảnh Sort Streak vào công cụ sinh ảnh (kể cả làm ảnh mẫu cho img2img). Ảnh gốc chỉ để biết chức năng, kích thước và vị trí.
3. **Một style.** Theo ảnh trong `style_ref/`.
4. **Dừng ở mỗi đợt** để người giao việc duyệt. Không làm đợt sau khi đợt trước chưa được duyệt.
5. **Không đoán.** Chỗ nào chưa rõ thì ghi vào `questions.md` và hỏi.

## 1. Bối cảnh

- Game đích là **Sweet Rope**, project **Unity** 2022.3 (bạn không có project này). **Sort Streak** (project Godot trong repo) là game tham chiếu kỹ thuật.
- Cần asset tương đương cho mọi chức năng của Sort Streak, theo thiết kế khác để không trùng bản quyền. Trừ skin Cat và Bird.
- Unity chưa có nhiều màn của Sort Streak (`sr_scene_parity.csv`: 20 màn đã có, 25 có một phần, 36 chưa có). Bạn vẫn vẽ asset cho cả 81 màn.
- Thuật ngữ Sweet Rope: Rope (dây), Item (quả), Container (chậu/giỏ), Order, Deliver, Free Rope, Locked Rope, Hidden Item. Không đặt tên mới theo tên của game gốc, trừ các file trong `godot_dropin/` (phải giữ đúng tên để thay đè).

## 2. Gói bàn giao

| File / thư mục | Dùng để |
|---|---|
| `asset_manifest.csv` | **Nguồn chuẩn** về file cần giao: đường dẫn, px, định dạng, nền trong suốt, vùng hình của bản cũ, 9-slice, lưới sprite sheet, đợt, mô tả. |
| `atlas_regions.json` | Tên và kích thước từng vùng của mỗi atlas Spine. |
| `check_assets.py` | Script bắt buộc chạy trước khi nộp mỗi đợt. |
| `SR_Art Task.xlsx` | Mô tả theo từng màn, ảnh ref, bảng màu, việc dev phải làm, câu chờ xác nhận. |
| `style_ref/` | 3 ảnh đã chốt: 10 quả, logo, cúp mèo Bronze. |
| `unity_current/` | Art hiện có của Sweet Rope cần vẽ lại (Rank, Profile, Streak, Win). Đây là art của team. |
| `SortStreak_Scenes_INDEX.md` | Danh sách 81 màn và cách mở từng màn. Ảnh nằm trên `origin/main` (commit `9e2995a`), nhánh cloud đang ở `e906108`: hãy fetch trước. |
| `sr_scene_parity.csv` | Màn nào Unity đã có. |
| `capture_reference/` | Script đã dùng để chụp 81 màn (viết cho Windows, sửa đường dẫn trước khi dùng). |

Đọc thêm trong repo: `Codex_Work/REF_Scene/START_HERE.html`, `Codex_Work/Docs/SRSP_*.xlsx`, `Codex_Work/Assets/assets/`. Nếu tài liệu cũ trái với mục 4 dưới đây thì **mục 4 đúng**. Cụ thể, bản `Level21_Review` cũ (token xám "?", cửa gỗ) đã bị thay.

## 3. Style

- Khối 3D mềm, bóng bẩy, bo tròn, màu tươi bão hòa. Sáng từ trên bên trái, đốm bóng rõ, bóng tối cùng họ màu. Item và vật trên bàn **không viền**.
- Logo đã chốt (`SR_Logo chot`): dùng đúng thiết kế này. Viền trắng kiểu sticker chỉ dành cho logo.
- Cúp: mèo nông dân đội nón lá, cầm táo, trên bục có nhánh lá như ảnh Bronze. Các bậc còn lại (silver, gold, platinum, amethyst, diamond, glory) cùng họ nhân vật, khác chất liệu và một chi tiết nhỏ.
- UI: bám art đang có trong `unity_current/` (nền kem, viền cam, nút bóng xanh lá và cam).
- Logo và ảnh quả bạn nhận bị dính nền (đen, sọc). Hãy vẽ lại thành ảnh nền trong suốt giống mẫu. Nếu người giao việc gửi file gốc trong suốt thì dùng file gốc.
- Không tạo lại logo Oakever, linh vật hoa của Sort Streak, hay bất kỳ nhân vật, biểu tượng nhận diện nào của game gốc.

## 4. Quyết định đã chốt

### 4.1 Mười loại quả

| type | Quả | Màu chủ đạo | Slot tên màu trong Godot |
|---|---|---|---|
| 0 | Mận | đỏ mận | `lavender` |
| 1 | Táo đỏ | đỏ | `red` |
| 2 | Cam | cam | `orange` |
| 3 | Chuối | vàng | `yellow` |
| 4 | Lê | xanh non | `teal` |
| 5 | Chanh xanh | xanh lá | `green` |
| 6 | Việt quất | xanh dương | `blue` |
| 7 | Nho | tím | `purple` |
| 8 | Thanh long | hồng đậm | `pink` |
| 9 | Đào | hồng phấn | `cyan` |

- Cột cuối chỉ là chỗ đặt file: ví dụ `rope_cyan_*`, `pot_cyan`, `flower_cyan` đều phải vẽ theo **đào**, màu hồng phấn.
- Quả lê trong ảnh mẫu ngả vàng: chỉnh xanh hơn để không lẫn với chuối. Mận phải tách rõ khỏi táo.
- Kiểm 10 quả ở cỡ 125 px và ở ảnh xám: nhận ra được chỉ bằng hình dáng.
- Hex đề xuất đo từ ảnh mẫu nằm ở sheet `01_Quy chuẩn Art`.

### 4.2 Hidden Item: túi vải buộc dây

- Một túi vải bố màu be đậm, nơ dây thừng, dùng chung cho mọi type. Che cả dáng lẫn màu.
- Không chữ, không dấu "?".
- Lộ: nơ bung, miệng túi mở, quả hiện **tại chỗ**. **Quả không nảy, không phóng to.**

### 4.3 Locked Rope: mật ong

- Mật đục màu hổ phách phủ kín cả dây, không thấy item bên dưới. Phải khác rõ chuối và cam.
- Unity: ba lớp `OBJ_HONEY_TOP`, `OBJ_HONEY_BODY` (lặp dọc, mép trên khớp mép dưới), `OBJ_HONEY_BOTTOM`. Sức chứa dây từ 3 đến 8 nên thân phải kéo dài được.
- Giữa lớp mật là dấu sáp; game đặt số lần Deliver hoặc hình quả lên trên.
- Mở khóa: dấu sáp nứt, mật chảy từ trên xuống, nhỏ giọt, item lộ dần. Undo chạy ngược.
- `godot_dropin/.../wood_door/`: dùng đúng các khung file cũ, sao cho trạng thái đóng ghép lại thành lớp mật che kín dây. File không cần hình thì để trong suốt cả file, giữ nguyên px. Cửa gỗ trong Godot mở sang hai bên: không cần sửa code, chỉ cần trạng thái đóng đúng cho mockup.

### 4.4 Theme

- **Fruit**: làm đầy đủ, ưu tiên cao nhất.
- **Flower** và **Winter**: bộ bàn chơi. Winter dùng **bánh quy tròn Noel**, phân biệt bằng hoa văn nổi chứ không chỉ bằng màu. Tên hoa và hoa văn bánh trong file là đề xuất, xin duyệt trước.
- **Bonus Level**: đồng xu tròn và heo đất thiết kế mới.

### 4.5 Rank, Streak, Win, Profile

Vẽ lại, giữ art style, giữ chủ thể (mèo, cá) và chữ tiếng Anh in sẵn đúng vị trí.

### 4.6 Animation

Giao ảnh tách lớp kèm mô tả chuyển động. **Không** dùng lại skeleton hay dữ liệu animation của Sort Streak.

## 5. Phạm vi (theo manifest)

| `set` | `action` | Số dòng | Giao gì | Đặt ở |
|---|---|---|---|---|
| GODOT | draw | 690 | Ảnh thay đè, đúng tên và px | `godot_dropin/assets/...` |
| GODOT | layers | 46 | Mỗi atlas: một PNG cho từng vùng (1.106 vùng) + `motion.md` | `motion/...` |
| UNITY_REDRAW | draw | 80 | Vẽ lại art đang có, đúng tên và px | `unity/Assets/_IEC/Image/...` |
| UNITY_REDRAW | atlas | 4 | Vẽ lại atlas Spine của team, đúng từng ô | như trên |
| UNITY_NEW | draw | 292 | Asset mới cho Unity | `unity/Assets/_IEC/Image/...` |
| bất kỳ | skip | 147 | Không làm (Cat/Bird, tiêu đề ngôn ngữ khác, logo hãng gốc) | – |

Thư mục gốc đầu ra: `Codex_Work/SweetRope_Delivery/Assets_v1/`. **Không sửa** `assets/` gốc của project.

Âm thanh, font, shader không thuộc phạm vi.

## 6. Quy tắc xuất ảnh

- PNG 8-bit RGBA, sRGB, alpha thẳng (không premultiplied). `webp` giữ `webp`. Dòng `svg` giao SVG vector thật có cùng `width`/`height`.
- Cột `alpha = yes`: nền trong suốt sạch, không viền trắng hay đen quanh hình. `alpha = no`: nền đặc.
- Sinh ảnh ở độ phân giải lớn rồi thu về đúng px (Lanczos). Không bao giờ kéo giãn lệch tỉ lệ: nếu hình không vừa khung thì vẽ lại.
- **Vị trí trong khung quan trọng như px.** `content_bbox` (x0 y0 x1 y1) là vùng có hình của bản cũ. Giữ tâm và độ phủ gần bản đó; điểm chạm (miệng chậu, đầu dây, đáy bục) phải ở đúng chỗ, nếu không hình sẽ lệch trong game dù đúng px.
- `nine_slice` (L T R B, px): bốn góc giữ trong lề, phần giữa phải kéo giãn được, không có hoa văn bị méo.
- `sheet_regions` (x,y,w,h): hình của mỗi vùng nằm trọn trong vùng đó. Sprite sheet giữ nguyên số khung và lưới.
- `same_pixels_as`: file trùng nội dung; vẽ một lần, chép sang.
- Chữ trong ảnh: chỉ khi bản cũ có chữ hoặc là file `TEXT_*`. Dựng chữ bằng font (Nunito Black, SN Pro Black), không để công cụ sinh ảnh tự viết. Chỉ tiếng Anh, kiểm chính tả.
- Vật xuất hiện ở cả Godot và Unity (quả, chậu, túi, xu...): một bản vẽ gốc cho cả hai. Khác biệt duy nhất: **Unity** dùng dây trắng/xám sáng để game tô màu; **Godot** cần dây tô sẵn theo từng quả. Item và Container luôn vẽ màu sẵn.
- Giữ file nguồn độ phân giải lớn trong `source/` với cùng tên.

## 7. Kiểm tra bắt buộc

Chạy trước (một lần):

```bash
python check_assets.py --selftest
```

Sau mỗi đợt (ví dụ đợt 0):

```bash
python check_assets.py --out <thư mục đầu ra> --source /workspace/GodotProject --batch 0 --report report_batch0.csv
```

- Không còn `FAIL`. Mỗi `WARN` phải xem bằng mắt và ghi lý do giữ lại hoặc sửa.
- Script không chấm được thẩm mỹ, chính tả, hay độ giống về thiết kế. Với mỗi đợt, tự dựng contact sheet (ảnh mới đặt trên nền sáng và nền tối, ở cỡ chơi thật) và soát từng ảnh: viền bẩn, lệch sáng, lệch style, chữ sai, quá giống bản gốc.
- Ngưỡng trong script là đề xuất; nếu đổi thì ghi rõ.

## 8. Thứ tự làm

| Đợt (`batch`) | Nội dung | Dừng lại khi |
|---|---|---|
| 0 | Chốt style: 10 quả, túi, mật ong, chậu, ván, dây, nền, 1 nút, mock bàn chơi và mock UI | Nộp contact sheet + mockup, chờ duyệt |
| 1 | P0 | Nộp + mockup các màn liên quan |
| 2 | P1 và art vẽ lại | Nộp |
| 3 | P2, atlas, lớp animation | Nộp + đủ 81 mockup |

Trong mỗi đợt, làm theo `SR_Art Task.xlsx` từng màn để đồ trong cùng một màn khớp nhau.

Sau đợt 0, báo thẳng: công cụ sinh ảnh của bạn có làm được nền trong suốt, đúng px và đồng nhất style qua hàng trăm file không. Nếu không, nêu nhóm file nào cần artist, đừng nộp ảnh kém.

## 9. Demo 81 màn (mockup)

- Mục tiêu: đủ 81 ảnh 1080 × 2340, tên trùng `SortStreak_Scenes_INDEX.md`, dùng asset mới.
- Cách ưu tiên: **sao chép** project Godot sang thư mục tạm, chép đè `godot_dropin/` lên bản sao, mở từng màn theo INDEX (debug API cổng 8090) và chụp. Chạy khi **đã chặn mạng**: game gốc tự kết nối server của hãng. Cần Godot có Spine; hiệu ứng Spine dùng atlas cũ phải được tắt hoặc thay bằng lớp ảnh mới.
- Nếu không chạy được: ghép ảnh tĩnh từ lớp asset mới theo bố cục ảnh ref.
- Mỗi ảnh có nhãn `MOCKUP` ở góc và một dòng trong `mockups/INDEX.md` ghi cách dựng. Không được còn asset Sort Streak, tên "Sort Streak" hay logo Oakever trong ảnh nào. Chữ tên game là Sweet Rope.
- Mockup không phải ảnh chụp game Sweet Rope. Ảnh thật sẽ thay sau khi dev Unity làm xong màn.

## 10. Mỗi lần nộp

1. Asset của đợt đó và `report_batch<N>.csv`.
2. Bản `asset_manifest.csv` đã cập nhật cột `status` (`xong`, `chờ sửa`, `không làm được` + lý do).
3. Contact sheet và mockup.
4. `questions.md`.
5. Danh sách việc dev cần làm mà bạn phát hiện thêm.

Chỉ commit khi được yêu cầu. Trước khi đẩy bất cứ gì lên GitHub, hỏi lại: repo đang chứa asset của game khác nên phải ở chế độ riêng tư.

## 11. Câu chưa chốt (hỏi nếu đợt đang làm cần đến)

Xem sheet `06_Cần xác nhận`. Quan trọng nhất: số tranh Stage ở Home (CX-05), in chữ vào ảnh (CX-06), luật Bonus Level (CX-07), kích thước canvas 1920 hay 2340 (CX-09), quyền dùng skeleton Spine cũ của team (CX-13), có đổi chủ thể cá và mèo không (CX-14).

Kích thước có ghi `Px: đề xuất` trong cột `note` là số do người giao việc đề xuất, chưa được dev xác nhận.
