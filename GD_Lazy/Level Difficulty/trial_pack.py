"""Kiểm và đóng gói bàn do trial_gen.py sinh: luật C# của game, luật của Level Designer, chấm lại bằng seed mới,
rồi ghi thư mục Levels (bản chép của game, chỉ thay pack_001), file zip và bảng báo cáo.

  python -X utf8 trial_pack.py <đường dẫn core.js của Level Designer>"""
import glob, json, os, shutil, subprocess, sys, tempfile, zipfile
from multiprocessing import Pool
import openpyxl
from openpyxl.styles import Font, PatternFill, Alignment, Border, Side
import trial_gen as G
from gen_level import pack, HARNESS

SRV = r'E:\AssetRipper\ClaudeWorkPlace\SortStreak\out\server_levels.json'
LEVELS_OUT = os.path.join(G.OUT, 'Levels')
ZIP = os.path.join(G.OUT, 'SweetRope_Levels_1-200.zip')
REPORT = os.path.join(G.OUT, 'SR_Level_1-200.xlsx')
CHALLENGE = lambda n: n >= 17 and (n - 17) % 10 == 0
BONUS = lambda n: n >= 13 and (n - 13) % 10 == 0       # fixed gold-pig Bonus (GD 2026-11-26)
ENDLESS = lambda n: n >= 30 and (n - 30) % 10 == 0
ICE = {(o['stage'] - 1) * 25 + o['levelIndex'] for o in json.load(open(os.path.join(G.GAME, 'Variants', 'ice_01.json'), encoding='utf8'))['overrides']}
label = lambda s: 1 if s < 20.5 else 2 if s < 37 else 3          # score bands of the Sort Streak default labels


def gold(lv):
    """colours with exactly one Container in the level, shown on the opening board (candidates for the gold colour)"""
    first = [r['container']['type'] for r in lv['ropes'] if r.get('container')]
    every = first + [e['container']['type'] for e in lv.get('reserveQueue', []) if e.get('container')]
    return sorted(t for t in set(first) if every.count(t) == 1)


def game_check(rows, core):
    """rows of {level, path} -> list of (ok by the game's C#, ok by the designer tool, errors)"""
    with tempfile.TemporaryDirectory() as d:
        p, m, j = (os.path.join(d, n) for n in ('pack.json', 'moves.json', 'rows.json'))
        json.dump(pack([G.copy(r['level']) for r in rows]), open(p, 'w', encoding='utf8'))
        json.dump([r['path'] for r in rows], open(m, 'w'))
        json.dump(rows, open(j, 'w', encoding='utf8'))
        cs = subprocess.run(['dotnet', HARNESS, p, '60000', m], capture_output=True, text=True, encoding='utf-8', timeout=1800, check=True)
        js = subprocess.run(['node', os.path.join(G.HERE, 'check_core.js'), core, j], capture_output=True, text=True, encoding='utf-8', timeout=1800, check=True)
    c = [line.split('|') for line in cs.stdout.splitlines()]; t = json.loads(js.stdout)
    assert len(c) == len(t) == len(rows), (len(c), len(t), len(rows))
    return [(not x[1] and x[2] in ('Solved', 'Replayed'), y['win'], x[1] or '; '.join(y['errors'])) for x, y in zip(c, t)]


def rescore(job):
    import sr_score
    n, level = job
    r = [sr_score.full(G.to_layout(level), salt) for salt in (11, 12)]
    return n, {k: (r[0][k] + r[1][k]) / 2 for k in r[0]}


def canonical(L):
    """same game: opening Rope order does not matter, type numbers are only names"""
    names = {}
    name = lambda t: names.setdefault(t, str(len(names)))

    def col(c):
        head, _, body = c['column'].partition('|')
        h = name(head) if head.isdigit() else head
        items = [('?' if x[0] == '?' else '') + name(x.lstrip('?')) for x in body.split(',') if x]
        info = c.get('columnInfo') or {}
        lock = (info.get('condition'), name(str(info['typeId'])) if info.get('condition') == 'collect_type' else '', info.get('count')) if c.get('columnType') == 'unlock' else ''
        return f'{h}|{",".join(items)}|{lock}'
    inc = [col(c) for c in L['incoming']]
    raw = sorted(L['initial'], key=lambda c: (c['column'].count(','), c.get('columnType'), c['column'].partition('|')[0] != '-', c['column']))
    return json.dumps([L['capacity'], L['targetCups'], sorted(col(c) for c in raw), inc])


# ---------- report (MSCS layout) ----------
F = Font(name='Times New Roman', size=14); FB = Font(name='Times New Roman', size=14, bold=True); FT = Font(name='Times New Roman', size=18, bold=True)
HEAD = PatternFill('solid', fgColor='CFE2F3'); thin = Side(style='thin', color='000000'); BOX = Border(left=thin, right=thin, top=thin, bottom=thin)


def sheet(wb, name, title, header, rows, widths):
    ws = wb.create_sheet(name); ws['A1'] = title; ws['A1'].font = FT
    ws.merge_cells(start_row=1, start_column=1, end_row=1, end_column=len(header))
    for r, row in enumerate([header] + rows, 3):
        for c, v in enumerate(row, 1):
            x = ws.cell(r, c, v); x.border = BOX; x.font = FB if r == 3 else F
            x.alignment = Alignment(vertical='center', wrap_text=True, horizontal='left' if isinstance(v, str) and len(v) > 18 else 'center')
            if r == 3: x.fill = HEAD
    for i, w in enumerate(widths): ws.column_dimensions[openpyxl.utils.get_column_letter(i + 1)].width = w
    ws.freeze_panes = 'B4'
    return ws


def main(core):
    from sim3 import lowprio
    base, target = G.base_levels(), G.targets()
    R = {}
    for line in open(G.RESULTS, encoding='utf8'):
        r = json.loads(line); R[r['n']] = r
    # levels not generated yet (or with no solvable board) keep the default board and are listed in the report
    G.LEVELS = [n for n in G.LEVELS if n in R and R[n]['best']]
    curve = dict(target); target.update({n: R[n]['target'] for n in G.LEVELS})      # aims on the Điểm SR scale
    known = {canonical(e['layout']) for e in json.load(open(SRV, encoding='utf8'))}
    flat = [(n, i, b) for n in G.LEVELS for i, b in enumerate(R[n]['best'])]
    checks = game_check([dict(level=b['level'], path=b['path']) for _, _, b in flat], core)
    chosen, used, rejected = {}, set(), []
    for (n, i, b), (cs, js, err) in zip(flat, checks):
        if n in chosen: continue
        key = canonical(G.to_layout(b['level']))
        if cs and js and key not in known and key not in used: chosen[n] = b; used.add(key)
        else: rejected.append((n, i, cs, js, key in known, err))
    G.LEVELS = [n for n in G.LEVELS if n in chosen]
    if QUICK:      # the generator still uses the 6 allowed workers, so no rescoring with fresh seeds here
        again = {n: {k: chosen[n][k] for k in ('score', 'bot_win', 'player_win')} for n in G.LEVELS}
    else:
        with Pool(6, initializer=lowprio) as p:
            again = dict(p.map(rescore, [(n, chosen[n]['level']) for n in G.LEVELS], chunksize=1))

    # Levels folder: a copy of the game's level data with only the generated levels replaced
    if os.path.isdir(LEVELS_OUT): shutil.rmtree(LEVELS_OUT)
    shutil.copytree(G.GAME, LEVELS_OUT, ignore=shutil.ignore_patterns('*.meta'))
    out = {}
    for f in G.PACKS:
        path = os.path.join(LEVELS_OUT, f); d = json.load(open(path, encoding='utf8'))
        for s in d['stages']:
            for k, lv in enumerate(s['levels']):
                n = (s['stage'] - 1) * 25 + lv['levelIndex']
                if n in chosen:
                    new = G.copy(chosen[n]['level']); new['difficulty'] = label((chosen[n]['score'] + again[n]['score']) / 2)
                    s['levels'][k] = new
                out[n] = s['levels'][k]
        json.dump(d, open(path, 'w', encoding='utf8'), ensure_ascii=False, separators=(',', ':'))
    assert sorted(n for n in out if out[n] != base[n]) == list(G.LEVELS), 'only the generated levels may differ from the game'
    LAST = 200
    final = [dict(level=out[n], path=chosen[n]['path'] if n in chosen else []) for n in range(1, LAST + 1)]
    verdict = game_check(final, core)
    bad = [(n + 1, v) for n, v in enumerate(verdict) if not (v[0] and v[1])]
    bad += [(n, 'Bonus không có màu 1 chậu') for n in range(13, LAST + 1, 10) if not gold(out[n])]
    with zipfile.ZipFile(ZIP, 'w', zipfile.ZIP_DEFLATED) as z:
        for f in glob.glob(os.path.join(LEVELS_OUT, '**', '*.json'), recursive=True):
            z.write(f, os.path.relpath(f, G.OUT).replace(os.sep, '/'))

    rows = []
    for n in range(1, LAST + 1):
        lv = out[n]; items = G.slots(lv); t = target[n]
        notes = [x for x, on in (('Giữ nguyên bàn hướng dẫn', n == 1), ('Challenge thay lúc chạy', CHALLENGE(n)), ('Endless thay lúc chạy', ENDLESS(n)), ('Bonus: ' + (f'màu vàng {gold(lv)}' if gold(lv) else 'KHÔNG CÓ MÀU 1 CHẬU'), BONUS(n)),
                                 ('ice_01 ghi đè', n in ICE)) if on]
        locks = sum(r['kind'] == 'Locked' for r in lv['ropes']); hid = sum(i.get('state') == 'Hidden' for i in items)
        if n in chosen:
            c, a = chosen[n], again[n]; changed = sum(x['type'] != y['type'] for x, y in zip(items, G.slots(base[n]))) / len(items)
            if abs(a['score'] - t) > 5: notes.append('Lệch hơn 5 điểm')
            rows.append([n, (n - 1) // 25 + 1, lv['difficultyType'], round(curve[n], 1), round(t, 1), round(c['score'], 1), round(a['score'], 1), round(a['score'] - t, 1),
                         lv['difficulty'], round(100 * a['bot_win']), round(100 * a['player_win']), len(c['path']), lv['orderCount'], hid, locks, round(100 * changed), ', '.join(notes)])
        else:
            if n != 1: notes.append('GIỮ BÀN DEFAULT: chưa sinh xong hoặc không có bàn giải được')
            rows.append([n, (n - 1) // 25 + 1, lv['difficultyType'], round(curve[n], 1), round(t, 1), None, None, None, lv['difficulty'], None, None, None, lv['orderCount'], hid, locks, 0, ', '.join(notes)])
    errs = [again[n]['score'] - target[n] for n in G.LEVELS]; sel = [chosen[n]['score'] - target[n] for n in G.LEVELS]
    share = lambda e, k: round(100 * sum(abs(x) <= k for x in e) / len(e))
    over = [n for n in G.LEVELS if n % 5 and (n - 1) // 5 * 5 + 5 in again and again[n]['score'] > again[(n - 1) // 5 * 5 + 5]['score']]
    summary = dict(levels=len(chosen), passed_game=sum(v[0] for v in verdict), passed_tool=sum(v[1] for v in verdict), failed=bad,
                   select_mae=round(sum(map(abs, sel)) / len(sel), 2), select_within231=share(sel, 2.31), select_within5=share(sel, 5),
                   again_mae=round(sum(map(abs, errs)) / len(errs), 2), again_bias=round(sum(errs) / len(errs), 2),
                   again_within231=share(errs, 2.31), again_within5=share(errs, 5),
                   off_by_more_than_5=[(n, round(target[n], 1), round(again[n]['score'], 1)) for n in G.LEVELS if abs(again[n]['score'] - target[n]) > 5],
                   normal_above_its_hard=over, rejected_candidates=len(rejected))
    wb = openpyxl.Workbook(); wb.remove(wb.active)
    sheet(wb, 'Tổng quan', 'Sweet Rope – level thử 1–200', ['Mục', 'Kết quả', 'Trạng thái'], [
        ['Level sinh mới', f'{len(chosen)} trong level 2–{LAST}; level 1 giữ nguyên', 'Implemented'],
        ['Level còn giữ bàn default', ', '.join(str(n) for n in range(2, LAST + 1) if n not in chosen) or 'không', 'Chưa xong' if QUICK else 'Implemented'],
        ['Qua luật C# của game (kiểm lỗi và chạy lại lời giải, không dùng Helper)', f"{summary['passed_game']}/{LAST}", 'Implemented'],
        ['Qua luật của Level Designer', f"{summary['passed_tool']}/{LAST}", 'Implemented'],
        ['Điểm SR lúc chọn: sai TB so với điểm đích', f"{summary['select_mae']} (trong ±2,31: {summary['select_within231']}%, trong ±5: {summary['select_within5']}%)", 'Lạc quan vì chọn theo chính số này'],
        ['Điểm SR chấm lại bằng seed mới' + (' (BẢN NHANH: chưa chấm lại, dùng điểm lúc chọn)' if QUICK else ''), f"{summary['again_mae']} (trong ±2,31: {summary['again_within231']}%, trong ±5: {summary['again_within5']}%)", 'Dùng số này'],
        ['Level Normal khó hơn Hard cùng nhóm 5 (chấm lại)', str(len(over)), 'Unverified'],
        ['Độ khó với người chơi thật', 'Chưa đo', 'Unverified']], [62, 62, 36])
    sheet(wb, 'Level', 'Từng level', ['Level', 'Stage', 'difficultyType', 'Điểm đích (đường C)', 'Điểm đích quy về Điểm SR', 'Điểm SR lúc chọn', 'Điểm SR chấm lại', 'Lệch đích', 'difficulty',
                                      'Bot đơn giản thắng %', 'Người chơi máy thắng %', 'Số bước lời giải', 'Số Order', 'Hidden', 'Locked Rope', 'Item đổi chỗ %', 'Ghi chú'],
          rows, [9, 8, 17, 12, 14, 13, 13, 11, 11, 13, 14, 12, 10, 9, 10, 12, 46])
    sheet(wb, 'Cần xác nhận', 'Cần xác nhận', ['Mã', 'Câu hỏi', 'Trạng thái', 'Đề xuất'], [
        ['CX-01', 'ice_01 ghi đè 32 level trong khoảng 42–200 bằng bàn cũ. GD đã bỏ qua Ice: giữ bàn Ice cũ hay tắt?', 'Chờ GD', 'Giữ trong lúc chơi thử.'],
        ['CX-02', '22 bộ A/B level ghi đè nhiều level trong khoảng 2–100 bằng bàn cũ.', 'Chờ Dev', 'Tắt A/B khi chơi thử (GameConfig).'],
        ['CX-03', 'Level 17, 27, 37… (Challenge) và 30, 40, 50… (Endless) bị thay lúc chạy nên bàn mới không được chơi.', 'Chờ GD', 'Giữ như hiện tại.'],
        ['CX-04', 'Điểm SR học từ bàn default của Sort Streak, chưa kiểm bằng người chơi.', 'Unverified', 'Chơi thử, ghi lại level thấy lệch.'],
        ['CX-05', 'Khung mỗi level (Rope, khoá, số Order, số Item mỗi màu, số Hidden) lấy theo level default cùng số; chỉ chỗ đặt Item và thứ tự Container chờ được đổi.', 'Chờ GD', 'Giữ cho bản thử; muốn khác bản gốc hơn thì đổi cả khung.'],
    ], [10, 90, 14, 48])
    wb.save(REPORT)
    json.dump(summary, open(os.path.join(G.OUT, 'summary.json'), 'w', encoding='utf8'), ensure_ascii=False, indent=1)
    print(json.dumps(summary, ensure_ascii=False))


QUICK = False

if __name__ == '__main__':
    sys.stdout.reconfigure(encoding='utf-8')
    QUICK = '--quick' in sys.argv
    main(os.path.abspath(sys.argv[1]))
