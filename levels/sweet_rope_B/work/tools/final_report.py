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
thay = [x for x in ref if x['thay'] == 'True']
e0 = [abs(float(x['lech_cu'])) for x in ref]
e1 = [abs(float(x['lech_moi'])) if x['thay'] == 'True' else abs(float(x['lech_cu'])) for x in ref]
L = [f'# Báo cáo Sweet Rope: bản A và bản B ({datetime.date.today():%d/%m/%Y})', '',
     'Báo cáo chung duy nhất cho toàn bộ level đã sinh. Bản A: 200 màn, một bộ cho mọi người chơi, mục tiêu theo đường độ khó riêng. '
     'Bản B: 5 bộ (`default`, `lv2`–`lv5`) × 199 màn (màn 1 dùng level hướng dẫn), mục tiêu bằng `summaryScore` của Sort Streak cùng màn cùng bộ; '
     'các bộ có cùng điểm ở cùng màn dùng chung một level (680 level).', '',
     '**Cách đo:** điểm "thực tế" là điểm bot (`tools/score.py`, cột `diem_lw`), sai số khoảng ±9 mỗi level; màn trên 70 điểm bị chấm thấp khoảng 18.', '',
     '## 0. Tóm tắt', '',
     f'- Tất cả level đúng sức chứa của Sort Streak cùng màn cùng bộ (bản A theo bộ `default`), ≤ 14 cốc, ≤ 7 dây, giải được (solver Godot hoặc bot thắng).',
     f'- Đã sửa các màn lệch > 10 điểm: {len(ref)} mục ({sum(x["ban"] == "A" for x in ref)} màn A, {sum(x["ban"] == "B" for x in ref)} nhóm B); '
     f'thay {len(thay)}; sai số TB của nhóm này {sum(e0) / len(e0):.1f} → {sum(e1) / len(e1):.1f}; còn {sum(v > 10 for v in e1)} mục lệch > 10.',
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
      '## 8. Sửa các màn lệch > 10 điểm', '',
      'Mỗi màn sinh 32 ứng viên quanh mức `mix` hiệu chỉnh theo sức chứa, chấm nhanh 20 bản (2 bot × 30 ván), chấm đầy đủ 4 bản gần nhất, '
      'chỉ thay khi bản mới gần mục tiêu hơn.', '',
      '| Bản | Số mục | Được thay | Sai số TB trước | Sai số TB sau | Còn > 10 |', '|---|---|---|---|---|---|']
for b in ['A', 'B']:
    X = [x for x in ref if x['ban'] == b]
    if not X: continue
    a0 = [abs(float(x['lech_cu'])) for x in X]
    a1 = [abs(float(x['lech_moi'])) if x['thay'] == 'True' else abs(float(x['lech_cu'])) for x in X]
    L.append(f'| {b} | {len(X)} | {sum(x["thay"] == "True" for x in X)} | {sum(a0) / len(a0):.1f} | {sum(a1) / len(a1):.1f} | {sum(v > 10 for v in a1)} |')
cb = list(csv.DictReader(open('levels/sweet_rope_B/reports/choi_bua_man_2-10.csv')))
L += ['', '## 8b. Chơi bừa ở màn đầu (bot chọn nước ngẫu nhiên, 120 ván mỗi màn)', '',
      'Yêu cầu cho bản A: màn 2–5 chơi bừa thắng 100%; màn 6–9 chỉ thua 1–2 lần và thua lúc gần cuối; từ màn 10 giữ nguyên. '
      'Bản B: áp cùng yêu cầu cho màn 2–5 (cả 5 bộ) và màn 6–9 bộ `default` (điểm vẫn sát mục tiêu thấp). Màn 6–9 của lv2–lv5 giữ độ khó mục tiêu Sort Streak (15–37 điểm) nên chơi bừa thua nhiều hơn; chi tiết `sua_man_2-9_choi_bua.csv`. Màn 10 giữ nguyên.', '',
      '| Bản | Màn | Nhóm | Thắng khi chơi bừa | % cốc đã xong khi thua |', '|---|---|---|---|---|']
L += [f"| {x['ban']} | {x['man']} | {x['nhom']} | {x['thang_choi_bua_pct']}% | {x['pct_coc_xong_khi_thua'] + '%' if x['pct_coc_xong_khi_thua'] else '–'} |" for x in cb]
L += ['', '## 9. Biểu đồ theo màn (không làm trơn)', '',
      'Mỗi bộ một hình: độ khó mục tiêu (cam, nét đứt) và đo thực tế (xanh); tỉ lệ thắng TB của 4 bot; playtime ước lượng (số bước TB khi thắng × 3 giây).']
for b in ['A', 'default', 'lv2', 'lv3', 'lv4', 'lv5']:
    L += ['', f'### {"Bản A" if b == "A" else "Bản B – " + b}', '', f'![{b}](sweet_rope_B/reports/bieu_do/{b}.png)']
L += ['', '## 10. Gói Unity', '',
      '- `SweetRope_A/Levels/pack_001.json` (màn 1–125), `pack_002.json` (126–200); `SweetRope_B/<bộ>/Levels/pack_001.json`, `pack_002.json`.',
      '- `difficultyType` Hard ở màn 5, 10, …; `difficulty` 1–6 suy từ điểm mục tiêu theo ngưỡng của Sort Streak (< 20,5 → 1; < 38 → 2; < 55 → 3; < 70 → 4; < 85 → 5; còn lại 6).',
      '- Màn 1 bản B là chỗ giữ (màn 1 bản A); dev thay bằng level hướng dẫn. `pack_002` chỉ tới màn 200: khi nhập giữ màn 201–250 cũ.',
      '- Bonus, Challenge, Endless không ghi vào file level (theo luật đã chốt); Challenge và Endless hiện là level thường.', '',
      '## Phụ lục: file số liệu', '',
      f'- Chi tiết từng màn: `{os.path.basename(P)}_chi_tiet.csv`; bonus tiềm năng: `{os.path.basename(P)}_bonus_tiem_nang.csv`; '
      'chơi bừa: `choi_bua_man_2-10.csv`; trùng lặp: `kiem_trung_lap.csv`; sửa màn lệch: `sua_man_lech.csv` (cùng thư mục `levels/sweet_rope_B/reports/`).']
open('levels/BAO_CAO_SweetRope_AB.md', 'w').write('\n'.join(L) + '\n')
print('wrote levels/BAO_CAO_SweetRope_AB.md')
