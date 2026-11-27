# Tài liệu bên ngoài: input quyết định độ khó của sort puzzle (Ball/Water/Color Sort) và cách đo/tinh chỉnh

LƯU Ý PHƯƠNG PHÁP: WebFetch bị chặn trong phiên (arxiv.org, ojs.aaai.org, gamedeveloper.com, blog.say.games ... không resolve được; cần cho phép các domain này nếu muốn đọc full text). Mọi thông tin dưới đây lấy từ WebSearch snippet/tóm tắt, KHÔNG phải đọc bản đầy đủ. Mức tin cậy: [Cao] = tóm tắt nhất quán nhiều nguồn/abstract bài báo; [Trung bình] = chỉ có snippet thứ cấp; [Thấp/Folk] = blog/ý kiến. Con số cụ thể cần kiểm lại với bản gốc trước khi dùng làm chuẩn.

## 1. Kết quả hình thức & độ phức tạp của sort puzzle; tham số nào làm khó?

### Takeaway
Ball Sort và Water Sort là NP-complete (Ito et al., FUN 2022), tương đương nhau về khả năng giải; tìm lời giải NGẮN NHẤT cũng NP-hard ngay cả ở ca "tầm thường". Số ống rỗng cần để đảm bảo giải được phụ thuộc số ống đầy n và dung lượng h; không tìm thấy nghiên cứu thực nghiệm định lượng "phase transition" theo số ống rỗng.

### Cited Findings
- "Sorting Balls and Water: Equivalence and Computational Complexity" (Ito và 9 đồng tác giả, FUN 2022; bản journal Theoretical Computer Science): Ball Sort và Water Sort NP-complete; mọi yes-instance có lời giải độ dài đa thức (nên thuộc NP). [Cao] — [arXiv 2202.09495](https://arxiv.org/abs/2202.09495), [LIPIcs FUN 2022](https://drops.dagstuhl.de/entities/document/10.4230/LIPIcs.FUN.2022.16), [ScienceDirect](https://www.sciencedirect.com/science/article/abs/pii/S0304397523004711)
- Hai bản (bóng / nước) giải được khi và chỉ khi nhau (tương đương về solvability). [Cao] — [arXiv 2202.09495](https://arxiv.org/abs/2202.09495)
- Tìm chuỗi sắp xếp ngắn nhất là NP-complete ngay cả với instance water sort "tầm thường". [Trung bình, qua tóm tắt tìm kiếm] — [arXiv 2202.09495](https://arxiv.org/pdf/2202.09495)
- Trường hợp đa thức: dung lượng ống = 2 và số màu = số ống đầy. [Trung bình] — [arXiv 2202.09495](https://arxiv.org/pdf/2202.09495)
- Mô hình: n ống đầy (h đơn vị), k ống rỗng, màu thuộc tập C; bài báo cho cận trên/dưới số ống rỗng đảm bảo giải được theo n và h. Có instance cần k >= floor((19/64)*min{n,h}); với k = ceil(((h-1)/h)*n) thì luôn làm được j = floor(n/h) ống đơn sắc. Hằng số chưa đối chiếu với bản cuối. [Trung bình] — [arXiv 2202.09495 (html)](https://arxiv.org/html/2202.09495.pdf)
- "Sorting Colored Balls in Colored Tubes" (Althaus et al., SoCS/AAAI): biến thể tube có màu, tối thiểu hóa số bước là NP-hard bằng rút gọn từ Feedback Arc Set. [Trung bình, chỉ snippet] — [AAAI SOCS](https://ojs.aaai.org/index.php/SOCS/article/view/35971)
- Hướng dẫn hobbyist: ống rỗng là "working memory"; thêm ống và màu làm tăng entropy/độ khó; dùng ống rỗng sớm cho nước đi ngắn hạn dễ dẫn tới soft-lock. [Folk] — [strategy guide](https://www.gamezebo.com/walkthroughs/water-sort-puzzle-strategy-guide-top-5-hints-tips-and-cheats/)
- Solver mã nguồn mở (DFS/BFS trên đồ thị trạng thái) tồn tại để tham khảo: [cemasma](https://github.com/cemasma/water-sort-puzzle-solver), [ColinGJohnson](https://github.com/ColinGJohnson/watersort-solver), [blog solving water sort](https://kpendolino.github.io/KendraCreates/2022/04/18/solving_water_sort), [level 74 is impossible](https://filipre.github.io/posts/level-74-is-impossible/) (ví dụ level sinh ra không giải được). Không có số liệu độ khó theo số ống rỗng. [Folk]

### Inferences
- Vì bài toán NP-complete và độ dài lời giải đa thức, solver có thể dùng như oracle "giải được/không" cho level nhỏ; kích thước nhỏ của game mobile (vài ống) làm brute-force/BFS khả thi.
- Dung lượng ống h và số ống rỗng k tương tác: k tỷ lệ thuận với n và (h-1)/h để đảm bảo giải được; nghĩa là tăng capacity mà không tăng ống rỗng làm tăng nguy cơ không giải được/khó. (Suy luận từ cận lý thuyết, không phải đo trải nghiệm người chơi.)
- Cơ chế phụ của game (hidden "?", lock, frozen, queue) không có kết quả hình thức công bố tìm thấy.

### Gaps
- Không tìm được nghiên cứu thực nghiệm phase transition (xác suất giải được vs. số ống rỗng ngẫu nhiên) cho sort puzzle.
- Không đọc được full text Ito et al. và Althaus et al. (fetch bị chặn).
- Không có kết quả hình thức cho hidden/locked/frozen items.

## 2. Đo độ khó bằng solver/bot; metric nào đã validate với người chơi?

### Takeaway
Bằng chứng validate mạnh nhất nằm ở Sokoban/Rush Hour/Sudoku: độ dài lời giải ngắn nhất tương quan yếu-vừa với độ khó người chơi, trong khi metric mô hình hóa quá trình tìm kiếm của người (đếm nước phản trực giác, phân rã bài toán) tốt hơn. Với Nonogram, metric SAT-solver không dự đoán được độ khó cảm nhận. Chưa tìm thấy validate nào cho sort puzzle.

### Cited Findings
- Jarušek & Pelánek (STAIRS 2010 "Difficulty Rating of Sokoban Puzzle"; FLAIRS 2011 "What Determines Difficulty of Transport Puzzles?"): dữ liệu ~2000 bài đã giải, ~780 giờ chơi online; độ khó giữa các bài rất chênh lệch (có cặp gần giống nhau chênh >10 lần); độ dài lời giải ngắn nhất tương quan yếu với thời gian giải (Spearman ~0.47 theo một báo cáo; r=0.30 theo bài trích dẫn khác — hai con số không khớp, cần kiểm bản gốc); metric "số nước phản trực giác"/conflict và "problem decomposition" tốt hơn (Spearman 0.69 cho conflict-based theo bài trích dẫn). Mô hình được thử trên Sokoban, Rush Hour, Replacement puzzle, metric hoạt động khác nhau giữa các trò. [Trung bình, thứ cấp] — [FIMU-RS-2010-01](https://www.fi.muni.cz/reports/2010/abstract/FIMU-RS-2010-01.html), [STAIRS 2010](https://www.fi.muni.cz/~xpelanek/publications/stairs2010-final.pdf), [FLAIRS 2011 aitopics](https://aitopics.org/doc/conferences:77F145E4), [AAAI PDF](https://cdn.aaai.org/ocs/2518/2518-11200-1-PB.pdf)
- Bài arXiv 2608.15958 (2026, diffusion Sokoban) trích: kích thước push-space gần như không tương quan với độ khó người; decomposition đạt Spearman 0.82. [Trung bình, thứ cấp] — [arXiv 2608.15958](https://arxiv.org/pdf/2608.15958)
- Sudoku: tổng quan "Difficulty Rating of Sudoku Puzzles: An Overview and Evaluation" (Pelánek): metric đơn giản Pearson 0.88, kết hợp lên 0.95 với dữ liệu người chơi từ web; phê phán nhiều nghiên cứu cũ so với nhãn độ khó của báo thay vì hiệu năng người thật. [Trung bình] — [arXiv 1403.7373](https://arxiv.org/pdf/1403.7373), [FLAIRS Sudoku](https://www.fi.muni.cz/~xpelanek/publications/flairs-sudoku.pdf)
- Rush Hour: phân tích mạng của không gian trạng thái (Bockholt). [Thấp-Trung bình] — [Bockholt summary](https://aalab.cs.rptu.de/gruppe/Former%20Members/bockholt/PDFs/Bockholt_Summary.pdf)
- "Automated Puzzle Difficulty Estimation" (CIG 2015, Univ. Utrecht): hướng ước lượng độ khó tự động bằng agent; chưa đọc nội dung/ số liệu. [Thấp] — [PDF](https://ics-websites.science.uu.nl/docs/vakken/mscip/assignments/CIG2015-AutomatedPuzzleDifficultyEstimation.pdf)
- Nonogram: "Evaluating SAT Solver Metrics as Predictors of Human-Perceived Nonogram Difficulty": metric SAT không dự đoán độ khó cảm nhận (solver-hard khác human-hard). [Trung bình] — [arXiv 2608.23300](https://arxiv.org/pdf/2608.23300)
- Elimination (word puzzle): generator tiến hóa có ràng buộc cho đường cong răng cưa đúng như thiết kế, kiểm chứng trên playtrace ~1000 người. [Trung bình] — [Elimination.pdf](https://webcf.waybackmachine.org/web/20210827172554/http://akhalifa.com/documents/Elimination.pdf)
- Không tìm thấy kết quả riêng cho Flow Free, Match-3, hay talk GDC của King/Playrix/Zynga/Voodoo/Lion về metric solver.

### Inferences
- Với sort puzzle, "độ dài lời giải ngắn nhất" nên chỉ là một đặc trưng; nên bổ sung: số nước sai/dead-end mà bot ngẫu nhiên/greedy gặp, tỉ lệ thắng của bot ngẫu nhiên (Monte-Carlo), số nước phản trực giác (nước phải đặt vào ống không cùng màu, dùng ống rỗng/đỗ tạm), cần lùi bước. Đây là suy luận từ Jarušek–Pelánek, chưa được kiểm chứng cho sort.
- Cần calibrate bằng dữ liệu người thật (tỉ lệ thắng, số lần thử) thay vì tin tuyệt đối vào solver.

### Gaps
- Không có validate người-vs-solver cho Ball/Water Sort.
- Không đọc full text; số Spearman giữa các nguồn không khớp.
- Không tìm được tài liệu chính thức về Flow/Match-3 metric.

## 3. Tham số input nào quan trọng nhất trong thực tế?

### Takeaway
Nguồn tin cậy thấp (hobbyist) và lý thuyết cùng chỉ về: số màu, số ống, số ống rỗng (đệm), dung lượng ống, mức xáo trộn. Không tìm được nguồn định lượng thứ hạng tầm quan trọng; các cơ chế phụ (hidden, lock, undo, move limit) chỉ có kiến thức chung.

### Cited Findings
- Ống rỗng = bộ nhớ làm việc; thêm màu/ống tăng độ khó. [Folk] — [Gamezebo guide](https://www.gamezebo.com/walkthroughs/water-sort-puzzle-strategy-guide-top-5-hints-tips-and-cheats/)
- Lý thuyết: số ống rỗng tối thiểu để đảm bảo giải được tăng theo n và h (xem mục 1). [Cao] — [arXiv 2202.09495](https://arxiv.org/abs/2202.09495)
- Level sinh ngẫu nhiên có thể không giải được, cần solver kiểm tra. [Folk] — [level 74 is impossible](https://filipre.github.io/posts/level-74-is-impossible/)
- Nghiên cứu Sokoban cho thấy các biến thể gần giống có thể chênh độ khó >10 lần, tức tham số thô (kích thước) không đủ dự đoán. [Trung bình] — [FIMU-RS-2010-01](https://www.fi.muni.cz/reports/2010/abstract/FIMU-RS-2010-01.html)

### Inferences
- Gợi ý cho generator: tham số thô (màu, ống, ống rỗng, capacity) + "độ xáo trộn" (ví dụ số lần đảo ngược từ trạng thái giải) + các cơ chế phụ; đo độ khó sau sinh bằng solver/bot thay vì đoán từ tham số.
- Hidden, lock, frozen, queue: tác động chưa có nguồn; nên đo bằng playtest/telemetry.

### Gaps
- Không tìm thấy bài/talk nêu thứ hạng tham số hoặc cách designer tune hidden items/locks/undo/move limit.

## 4. Độ khó vs retention/churn; win-rate mục tiêu

### Takeaway
Chỉ có số liệu từ blog/ngành, không peer-reviewed: một case study chọn win rate ~70–80%; <50% bị coi quá khó cho hyper-casual. Nghiên cứu Columbia (DDA) là nguồn học thuật gần nhất, cho thấy giảm độ khó thay thế một phần IAP ngắn hạn nhưng tăng engagement/retention và monetization dài hạn.

### Cited Findings
- Taxi Run: win rate 90% làm mất thử thách, người chơi bỏ; sau thử nghiệm chọn ~70–80%; dưới 50% là quá hardcore cho hyper-casual. [Folk, case đơn lẻ] — [PocketGamer.biz tổng hợp](https://www.pocketgamer.biz/how-saygames-uses-game-analytics-to-balance-difficulty-in-hybrid-puzzle-games/)
- SayGames: fail rate 50% = trung bình 2 lần thử/level; 80% = 5 lần; trung bình ~2 lần bắt đầu mỗi level nhưng một số người cần 10–20 lần; người retry nhiều ít nhưng thường trung thành; "churn" đôi khi chỉ là tạm dừng. [Folk/industry] — [SayGames blog](https://blog.say.games/posts/how-to-work-with-difficulty-in-hybrid-puzzles-so-players-dont-leave--but-stay-and-pay), [PocketGamer.biz](https://www.pocketgamer.biz/how-saygames-uses-game-analytics-to-balance-difficulty-in-hybrid-puzzle-games/)
- Retention giảm sau một level cụ thể là dấu hiệu level quá khó (cần loại trừ crash/quảng cáo trước) — Unity/Supersonic. [Folk] — [PocketGamer.biz difficulty curves](https://www.pocketgamer.biz/difficulty-curves-find-the-right-balance-and-boost-retention-and-revenue)
- Benchmark retention (GameAnalytics qua Adjust): D1 35% (hyper-casual 50%), D7 11%, D28 4%. [Folk] — [Adjust](https://www.adjust.com/blog/askblu-data-science-mobile-games-difficulty-tuning)
- Columbia Business School, "Personalized games" (DDA trong puzzle game freemium): giảm độ khó thay thế IAP ngắn hạn, nhưng tăng engagement/retention và doanh thu dài hạn. [Trung bình-Cao, working paper/nghiên cứu học thuật; chi tiết chưa đọc] — [PDF](https://business.columbia.edu/sites/default/files-efs/citation_file_upload/Personalized_games.pdf)
- Quy trình: soft-launch/A-B test theo nhóm nhỏ, theo dõi fail rate, churn, số lần thử, thời lượng level. [Folk] — [PocketGamer.biz](https://www.pocketgamer.biz/how-saygames-uses-game-analytics-to-balance-difficulty-in-hybrid-puzzle-games/)

### Inferences
- Có thể dùng làm giá trị khởi điểm: level thường ~70–80% win rate, level khó thấp hơn, nhưng đây chưa phải chuẩn ngành; cần tự hiệu chỉnh bằng telemetry.

### Gaps
- Không tìm được dải win rate cụ thể "easy/medium/hard" từ King/Playrix/Zynga/Voodoo/Lion hay GDC; các số trên là của case đơn lẻ.

## 5. Đường cong độ khó 10 level đầu & đo bằng bot

### Takeaway
Thực hành phổ biến: đường cong răng cưa (sawtooth): sau level khó cho level dễ để người chơi thấy tiến bộ; kiểm chứng bằng completion funnel. Không có công thức chuẩn cho 10 level đầu trong nguồn tìm được.

### Cited Findings
- Sawtooth: hạ độ khó theo chu kỳ trong xu hướng tăng; Puzzledorf: level dễ sau level rất khó giúp người chơi "thấy mình giỏi lên". [Folk] — [Game Developer: Puzzledorf](https://www.gamedeveloper.com/game-platforms/reflections-on-difficulty-pacing-in-i-puzzledorf-i-), [Rising Difficulty Curve](https://abagames.github.io/joys-of-small-game-development-en/difficulty/curve.html)
- Elimination: generator tạo đường cong sawtooth được xác nhận bằng playtrace ~1000 người. [Trung bình] — [Elimination.pdf](https://webcf.waybackmachine.org/web/20210827172554/http://akhalifa.com/documents/Elimination.pdf)
- Đo completion funnel theo level để so đường cong thực với thiết kế; sửa spike bằng chỉnh/đổi thứ tự. [Folk] — [bugnet.io](https://bugnet.io/blog/difficulty-curves-how-to-get-them-right)

### Inferences
- Đề xuất (không có nguồn trực tiếp): 10 level đầu dạy từng cơ chế một, mỗi cơ chế mới đi kèm level dễ; dùng bot (random/greedy/MCTS) để đo tỉ lệ thắng và độ dài lời giải, rồi hiệu chỉnh bằng dữ liệu người thật.

### Gaps
- Không tìm được nguồn có con số cụ thể cho 10 level đầu hoặc dải win-rate theo loại level; không có tài liệu về bot Monte-Carlo cho sort puzzle.

## Danh sách nguồn chính
- https://arxiv.org/abs/2202.09495 (Ito et al., FUN 2022)
- https://drops.dagstuhl.de/entities/document/10.4230/LIPIcs.FUN.2022.16
- https://www.sciencedirect.com/science/article/abs/pii/S0304397523004711
- https://ojs.aaai.org/index.php/SOCS/article/view/35971
- https://www.fi.muni.cz/reports/2010/abstract/FIMU-RS-2010-01.html ; https://www.fi.muni.cz/~xpelanek/publications/stairs2010-final.pdf ; https://aitopics.org/doc/conferences:77F145E4
- https://arxiv.org/pdf/1403.7373 ; https://arxiv.org/pdf/2608.15958 ; https://arxiv.org/pdf/2608.23300
- https://ics-websites.science.uu.nl/docs/vakken/mscip/assignments/CIG2015-AutomatedPuzzleDifficultyEstimation.pdf
- https://blog.say.games/posts/how-to-work-with-difficulty-in-hybrid-puzzles-so-players-dont-leave--but-stay-and-pay
- https://www.pocketgamer.biz/how-saygames-uses-game-analytics-to-balance-difficulty-in-hybrid-puzzle-games/
- https://business.columbia.edu/sites/default/files-efs/citation_file_upload/Personalized_games.pdf
- https://www.adjust.com/blog/askblu-data-science-mobile-games-difficulty-tuning
- https://webcf.waybackmachine.org/web/20210827172554/http://akhalifa.com/documents/Elimination.pdf
- https://www.gamedeveloper.com/game-platforms/reflections-on-difficulty-pacing-in-i-puzzledorf-i-
- https://github.com/cemasma/water-sort-puzzle-solver ; https://github.com/ColinGJohnson/watersort-solver ; https://filipre.github.io/posts/level-74-is-impossible/
