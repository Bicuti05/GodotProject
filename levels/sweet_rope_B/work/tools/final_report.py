#!/usr/bin/env python3
"""Ghép báo cáo chung duy nhất levels/BAO_CAO_SweetRope_AB.md.
final_report.py REPORT_PREFIX DUP_CSV DESIGNER_SUMMARY REFINE_CSV
  REPORT_PREFIX: tiền tố đầu ra của report.py (đã chạy), có .md, _chi_tiet.csv, _bonus_tiem_nang.csv
  DUP_CSV: kết quả dup_check.py cho toàn bộ level hiện tại; DESIGNER_SUMMARY: JSON {"total":..,"errors":..,"warnings":..}
  REFINE_CSV: apply.csv của refine.py"""
import csv, json, sys, os, datetime
P, DUP, DES, REF = sys.argv[1:5]
body = open(P + '.md').read()
dup = list(csv.DictReader(open(DUP)))
des = json.load(open(DES))
ref = list(csv.DictReader(open(REF)))
self1 = [x for x in dup if x['uid'].endswith('level_001') and x['nearest'] == 'A_cu/level_001']
dup = [x for x in dup if x not in self1]  # màn 1 bản A giữ nguyên từ bản cũ, chỉ trùng với chính nó
top = sorted(dup, key=lambda x: -float(x['sim_max']))
n80 = sum(float(x['sim_max']) > 0.8 for x in dup)
e1 = [abs(float(x['lech'])) for x in ref if x['lech'] != '']
pp = list(csv.DictReader(open('levels/sweet_rope_B/reports/phan_phoi_kho_level.csv')))
L = [f'# Báo cáo Sweet Rope: bản A và bản B ({datetime.date.today():%d/%m/%Y})', '',
     'Báo cáo chung duy nhất cho toàn bộ level đã sinh. Bản A: 200 màn, một bộ cho mọi người chơi, mục tiêu theo đường độ khó riêng. '
     'Bản B: 5 bộ (`default`, `lv2`–`lv5`) × 199 màn (màn 1 dùng level hướng dẫn), mục tiêu bằng `summaryScore` của Sort Streak cùng màn cùng bộ; '
     'các bộ có cùng điểm ở cùng màn dùng chung một level (680 level).', '',
     '**Cách đo:** điểm "thực tế" là điểm bot (`tools/score.py`, cột `diem_lw`), sai số khoảng ±9 mỗi level; màn trên 70 điểm bị chấm thấp khoảng 18.', '',
     '## 0. Tóm tắt', '',
     f'- Mọi level theo luật Sort Streak: không dây nào đầy sẵn đúng màu chậu (lúc mở và khi vào từ hàng chờ), tối đa 3 hoa thường cùng màu liền nhau (hoa ẩn không tính).',
     f'- Tất cả level đúng sức chứa của Sort Streak cùng màn cùng bộ (bản A theo bộ `default`), ≤ 14 cốc, ≤ 7 dây, giải được (solver Godot hoặc bot thắng).',
     f'- Sinh lại {len(ref)} level vi phạm luật Sort Streak ({sum(x["ban"] == "A" for x in ref)} màn A, {sum(x["ban"] == "B" for x in ref)} nhóm B); '
     f'các bản sinh lại này cùng mọi ứng viên đã chấm tạo thành kho level cho bước phân phối dưới đây.',
     f'- Phân phối kho level đã chấm (mỗi level dùng một lần) vào {len(pp)} ô màn 10–200 bản A và mọi nhóm bản B trừ màn đầu đã chốt dễ: '
     f'{sum(x["dat"] == "True" for x in pp)} ô đạt ±5 so với mục tiêu quy về thang bot, sai số TB {sum(abs(float(x["lech"])) for x in pp) / len(pp):.1f}.',
     f'- Trùng lặp với {des.get("originals", "")} level có sẵn trong project: {n80} level giống > 80% (giống nhất {top[0]["sim_max"]}).',
     f'- Luật LevelDesigner (`validateLevel`, bản port C#): {des["total"]} level, {des["errors"]} lỗi, {des["warnings"]} cảnh báo.',
     '- Gói Unity `sweetrope.levelpack/1`: `levels/package/SweetRope_A.zip`, `levels/package/SweetRope_B.zip`.', '']
L.append(body)
L += ['', '## 6. Kiểm trùng lặp', '',
      'So mỗi level mới với mọi level có sẵn: GD_Lazy (branch main), LevelDesigner/Levels (pack, variant, challenge), `assets/builtin`, `assets/game`, bản A cũ. '
      'Độ giống = tỉ lệ vị trí (chậu + hoa) trùng nhau sau khi đổi tên màu tối ưu. Level mới không so với nhau.', '',
      '- Màn 1 bản A (level hướng dẫn giữ nguyên từ bản cũ) không tính, vì chỉ trùng với chính nó; so với Sort Streak giống 0,39.', '',
      f'- Giống > 80%: **{n80}** level. Giống > 70%: {sum(float(x["sim_max"]) > 0.7 for x in dup)} level.', '',
      '| Level | Giống nhất | Level gần nhất |', '|---|---|---|']
L += [f'| {x["uid"]} | {x["sim_max"]} | {x["nearest"][:80]} |' for x in top[:5]]
L += ['', '## 7. Luật LevelDesigner và sửa cấu trúc', '',
      f'- Kiểm bằng `validateLevel` của LevelDesigner (`levels/sweet_rope_B/work/tools/designer/core.js`): {des["total"]} level, {des["errors"]} lỗi, {des["warnings"]} cảnh báo.',
      '- Đã sửa: 2 level có 15 cốc (Unity tối đa 14): bản A màn 86 và bản B màn 36 `lv2`, sinh lại; thêm luật ≤ 14 cốc vào bộ kiểm.',
      '- Không giải lại bằng `BoardSolver` của Unity (theo yêu cầu); tính giải được đã chứng minh khi sinh.', '',
      '## 8. Sinh lại theo luật Sort Streak', '',
      'Level cũ có dây đầy sẵn đúng màu chậu (giao cốc ngay khi vào màn) và chuỗi 4–6 hoa cùng màu liền nhau; Sort Streak không có màn nào như vậy. '
      'Mỗi level lỗi được sinh lại 16–48 ứng viên đúng luật (đổi hoa chỉ trong bàn chơi hoặc trong hàng chờ), chấm nhanh, chấm đầy đủ 3–4 bản gần mục tiêu nhất, chọn bản gần nhất mà bot thắng được.', '',
      '| Bản | Số level sinh lại | Sai số TB | Lệch ≤ 5 | Lệch > 10 |', '|---|---|---|---|---|']
for b in ['A', 'B']:
    X = [abs(float(x['lech'])) for x in ref if x['ban'] == b and x['lech'] != '']
    if X: L.append(f'| {b} | {len(X)} | {sum(X) / len(X):.1f} | {sum(v <= 5 for v in X)} | {sum(v > 10 for v in X)} |')
cb = list(csv.DictReader(open('levels/sweet_rope_B/reports/choi_bua_man_2-10.csv')))
L += ['', '## 8b. Chơi bừa ở màn đầu (bot chỉ nhìn một nước: đi nước có lợi nhất trước mắt, đôi khi đi bừa; 120 ván mỗi màn)', '',
      'Yêu cầu cho bản A: màn 2–5 chơi bừa thắng 100%; màn 6–9 chỉ thua 1–2 lần và thua lúc gần cuối; từ màn 10 giữ nguyên. '
      'Áp cho bản A màn 2–9, bản B màn 2–5 (cả 5 bộ) và màn 6–9 bộ `default`. Màn 6–9 của lv2–lv5 giữ độ khó mục tiêu Sort Streak. Từ màn 10 giữ nguyên.', '',
      '| Bản | Màn | Nhóm | Thắng khi chơi bừa | % cốc đã xong khi thua |', '|---|---|---|---|---|']
L += [f"| {x['ban']} | {x['man']} | {x['nhom']} | {x['thang_choi_bua_pct']}% | {x['pct_coc_xong_khi_thua'] + '%' if x['pct_coc_xong_khi_thua'] else '–'} |" for x in cb]
L += ['', '## 9. Biểu đồ theo màn (không làm trơn)', '',
      'Mỗi bộ một hình: độ khó mục tiêu (cam, nét đứt) và đo thực tế (xanh); tỉ lệ thắng TB của 4 bot; playtime ước lượng (số bước TB khi thắng × 3 giây).']
for b in ['A', 'default', 'lv2', 'lv3', 'lv4', 'lv5']:
    L += ['', f'### {"Bản A" if b == "A" else "Bản B – " + b}', '', f'![{b}](sweet_rope_B/reports/bieu_do/{b}.png)']
L += ['', '## 10. Gói Unity', '',
      '- `SweetRope_A/Levels/pack_001.json` (màn 1–125), `pack_002.json` (126–200); `SweetRope_B/<bộ>/Levels/pack_001.json`, `pack_002.json`.',
      '- `difficultyType` Hard ở màn 5, 10, …; `difficulty` 1–6 suy từ điểm mục tiêu theo ngưỡng của Sort Streak (< 20,5 → 1; < 38 → 2; < 55 → 3; < 70 → 4; < 85 → 5; còn lại 6).',
      '- Màn 1 của bản A và cả 5 bộ bản B là cùng một level hướng dẫn (sức chứa 3, 3 cốc, 4 dây). `pack_002` chỉ tới màn 200: khi nhập giữ màn 201–250 cũ.',
      '- Bonus, Challenge, Endless không ghi vào file level (theo luật đã chốt); Challenge và Endless hiện là level thường.', '',
      '## Phụ lục: file số liệu', '',
      f'- Chi tiết từng màn: `{os.path.basename(P)}_chi_tiet.csv`; bonus tiềm năng: `{os.path.basename(P)}_bonus_tiem_nang.csv`; '
      'phân phối kho level: `phan_phoi_kho_level.csv`; chơi bừa: `choi_bua_man_2-10.csv`; trùng lặp: `kiem_trung_lap.csv`; sinh lại theo luật: `sua_luat_chuoi_mau.csv` (cùng thư mục `levels/sweet_rope_B/reports/`).']
open('levels/BAO_CAO_SweetRope_AB.md', 'w').write('\n'.join(L) + '\n')
print('wrote levels/BAO_CAO_SweetRope_AB.md')
