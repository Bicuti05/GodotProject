# Level Sweet Rope: bản A và bản B

Sweet Rope thử nghiệm A/B hai cách phát level. Mỗi bản có thư mục riêng.

| Bản | Thư mục giao cho dev | Nội dung |
|---|---|---|
| **A** – một bộ duy nhất | `sweet_rope_A/level_001.json` … `level_200.json` | Một bộ 200 màn cho mọi người chơi, theo đường độ khó mới chốt. Không có mức người chơi. |
| **B** – như Sort Streak | `sweet_rope_B/final/<bộ>/level_002.json` … `level_200.json`, với `<bộ>` là `default`, `lv2`, `lv3`, `lv4`, `lv5` | Năm bộ 200 màn bám năm đường độ khó của Sort Streak, chọn bộ theo mức người chơi (lên/xuống mức như Sort Streak). `default` dùng cho người chơi chưa có mức và mức 1. |

- Định dạng file level: object đọc được bằng `JuiceLevel.from_dict()` (Godot).
- **Màn 1 của bản B** không có trong thư mục: dev dùng level hướng dẫn cố định.
- **Bonus** cố định ở màn 13, 23, 33… (từ 13, cách 10): game chọn lúc chạy một màu chỉ có đúng 1 chậu để đổi skin vàng; không ghi vào file level.
- **Challenge** (17, 27…) và **Endless** (30, 40…): trong file vẫn là level thường, vì game chưa có cơ chế thay thế.
- Trong bản B, cùng một level có thể nằm ở cùng số màn của nhiều bộ (giống Sort Streak). Một level không được dùng lại ở hai số màn khác nhau.
- Thư mục `sweet_rope_B/work/` (AI sinh level) và `sweet_rope_B/reports/` (kết quả kiểm) là thư mục làm việc, **không** giao cho dev.
