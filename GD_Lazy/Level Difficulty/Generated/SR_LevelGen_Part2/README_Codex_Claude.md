# Codex sinh level, Claude duyệt

Luồng này dùng bộ sinh và bộ kiểm Sweet Rope của dự án. Codex tạo hai pack ứng viên, chạy kiểm tra và gửi kết quả cùng dữ liệu của từng level cho Claude Code. Claude trả phản hồi để Codex sửa và gửi lại. Mỗi lần chuẩn bị tạo một thư mục duyệt riêng.

## Chạy từ Codex

Yêu cầu ví dụ trong chat Codex ở dự án `GD_Lazy`.

> Sinh level Sweet Rope 2–6 theo README_LevelGen.md. Dùng cầu nối Codex–Claude để duyệt. Sửa theo các lỗi có bằng chứng, kiểm lại và báo kết quả từng level.

Codex làm theo [hướng dẫn sinh level](README_LevelGen.md) và đặt `pack_001.json`, `pack_002.json` trong thư mục riêng, ví dụ `Level Difficulty/Generated/TenDot/Levels`. Khi ở thư mục `GD_Lazy`, gọi cầu nối bằng PowerShell. `--levels` nhận một số hoặc một khoảng trong phạm vi 1–200. Nên gửi từng nhóm nhỏ (ví dụ 5 level) để Claude có thể đọc kỹ từng bàn.

```powershell
python -X utf8 '.\Level Difficulty\Handoff_LevelGen\review_with_claude.py' run '.\Level Difficulty\Generated\TenDot\Levels' --levels 2-6
```

Nếu đã có lời giải, thêm `--solutions <đường dẫn solutions.json>`. Cầu nối phát lại lời giải đã có bằng Level Designer để xác nhận.

Kết quả nằm trong `Level Difficulty/Generated/ClaudeReviews/review-…/`. Thư mục duyệt kế thừa quyền của `Generated` để Claude có thể đọc hồ sơ và ghi phản hồi, kể cả khi ứng viên được tạo trong thư mục tạm của Codex.

- `evidence.json` lưu bàn ứng viên và bàn default, kết quả kiểm khung, lời giải tìm được, kết quả replay theo luật Level Designer và điểm độ khó. Với điểm chậm, Claude so mức thay đổi giữa hai bàn với mức thay đổi yêu cầu so với bàn default.
- `request.md` là hồ sơ chuyển sang Claude.
- `feedback.md` là phản hồi của Claude. Codex đọc file này trước khi sửa và chuẩn bị hồ sơ mới cho bản sửa.

Lệnh `run` gửi `request.md` trực tiếp qua stdin cho `claude -p`, chờ Claude trả lời, rồi in phản hồi cho Codex và lưu vào `feedback.md`. Codex có thể sửa và gửi lại trong cùng lượt. Lượt duyệt dùng đăng nhập Claude Code trên máy và chạy riêng với chat Claude đang mở. Bạn có thể yêu cầu Codex sinh level như bình thường, vì `AGENTS.md` đã ghi luồng duyệt tự động.

## Gửi qua phiên Claude đang mở hoặc chạy lại

Dùng `prepare` thay cho `run` để chỉ chuẩn bị hồ sơ. Nếu gọi Claude lỗi sau khi lệnh in đường dẫn `request.md`, hồ sơ đã sẵn sàng.

Trong phiên Claude đang mở ở GD_Lazy, gửi một câu như sau với đường dẫn mà script in ra.

> Đọc file request.md ở đường dẫn sau và duyệt theo hướng dẫn trong đó. Báo kết quả ngay trong chat này và lưu cùng phản hồi vào feedback.md trong thư mục chứa request.md. [Dán đường dẫn tuyệt đối tới request.md]

Trong Codex, yêu cầu đọc `feedback.md` của đúng thư mục duyệt và tiếp tục vòng sửa.

Nếu sandbox của Codex báo OAuth 401, Codex dùng lệnh sau để thử gửi lại hồ sơ dưới tài khoản Windows có đăng nhập Claude Code. Codex có thể yêu cầu bạn duyệt quyền chạy lệnh. Nếu chính Claude Code dưới tài khoản Windows báo hết hạn, dùng `claude auth login` rồi gửi lại cùng hồ sơ.

```powershell
python -X utf8 '.\Level Difficulty\Handoff_LevelGen\review_with_claude.py' review '<đường dẫn thư mục review-…>'
```
