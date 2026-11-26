# Sweet Rope Round 3b

## B — Sửa theo fix_list2.csv

- Đã sửa 137 dòng, tương ứng 119 file đích duy nhất. Các file này có 105 OK, 14 WARN và 0 FAIL.
- B2 có 13 nền và icon. B1/B1g cập nhật vùng alpha và độ phủ. B4 cập nhật 33 đoạn trong 11 bộ dây, thân x=25–35 theo ngưỡng alpha >128. B5 cập nhật 53 ảnh nguồn và bản xuất. B6 cập nhật hai mũi tên Rank và hạt sáng.
- Đã mở contact sheet của nền, UI, dây lặp và ảnh nguồn. Cần kiểm pivot, 9-slice và độ phủ trong cảnh khi tích hợp.

## C — Asset còn thiếu

- Giao thêm 127 dòng từ 294 dòng chưa làm và 5 dòng chờ logo đầu đợt. Có nền Home, Rank, Daily Check-in, ảnh Store, sprite UI, hiệu ứng, bộ PNG tách lớp và atlas.
- Còn **172 dòng chưa làm** trong manifest.
  - P1, ảnh hoặc vector — 119.
  - P2, ảnh hoặc vector — 22.
  - P2, bộ lớp và motion — 31.
- Đã bàn giao 5 mục logo, gồm 4 ảnh xuất và 36 lớp PNG cho hiệu ứng.

## D — Mockup

- Đã dựng lại 81 màn tĩnh và 4 ảnh MOCK_* ở 1080 × 2340. Thay cúp mèo và giỏ giao trái cây, thêm nền Daily, căn lại IQ, nút Super Hard và hai màn Home.
- Đã rà bảng hình thu nhỏ và mở riêng các màn đại diện. 19 màn có vị trí logo dùng PNG Sweet Rope đã chốt. Chưa xác thực giao diện trong Unity hoặc chụp cảnh Godot chạy thật.

## E — Checker

- Toàn manifest có **895 OK, 45 WARN, 172 FAIL**. Có 172 FAIL ở dòng chưa có asset.
- report_all.csv giữ nguyên kết quả của checker. warn_disposition.csv ghi từng cảnh báo cùng cách xử lý hoặc điểm cần kiểm tra.

## Rà soát hình ảnh sau khi nhận logo

- Đối chiếu hình minh họa đã chốt với manifest, khung alpha và vai trò của texture trong scene.
- Đã sửa 6 asset. Khung chọn avatar có tâm trong suốt, panel xác nhận phục hồi viền xanh và ba huy chương dùng mặt kim loại đặc. Icon ứng dụng dùng quả và dây với chất liệu bám bộ Fruit đã chốt.
- Checker riêng cho 6 asset ghi 6 OK, 0 WARN và 0 FAIL. Xem cặp trước/sau trong contact_sheets/round3_style_corrections.jpg. Chưa xác nhận phong cách của toàn bộ gói hoặc kiểm thử trực tiếp trong game.
