# Sweet Rope B

Lô chuẩn bị có 27 ứng viên màn hướng dẫn 1, mỗi ứng viên ba loại và bốn dây. Tệp `candidates/L001_pending.json` giữ cặp `uid` và `raw` để chạy thẳng qua `greedy_ext.gd`. Đã tự chạy `validate_level.gd` và `greedy_ext.gd` từ nhánh tài liệu bằng Godot 4.6.1. Cả 27 ứng viên lưu lại đều WINNABLE, với chỉ số lw tự đo trong CSV đi kèm. Bên kiểm phụ trách kết quả độc lập.

Chờ `targets_B.csv` và xác nhận số loại cho màn hướng dẫn trước khi chốt lô 1–25. Xem [QUESTIONS.md](QUESTIONS.md). Lô này chưa có level chính thức, `assignment.csv` hay điểm mục tiêu.

Kiểm độ phủ CSV khi nhận được file.

    python3 levels/sweet_rope_b/tools/check_targets.py /path/to/targets_B.csv
