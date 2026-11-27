"""Đường độ khó D cho Sweet Rope: chia pha Learn -> Practice -> Combine -> Challenge -> Recover/Renew.
python -X utf8 curve_d.py   -> SR_Difficulty Curve_D.xlsx + curve_d_1-200.png
Số liệu Sort Streak lấy từ server_levels.json (bộ default). Mọi hằng số thiết kế ở khối THAM SỐ."""
import json, os, statistics as S, collections
import openpyxl
from openpyxl.styles import Font, PatternFill, Border, Side, Alignment
from openpyxl.chart import LineChart, Reference

HERE = os.path.dirname(os.path.abspath(__file__))
SRV = r'E:\AssetRipper\ClaudeWorkPlace\SortStreak\out\server_levels.json'
GAME = r'E:\AssetRipper\ClaudeWorkPlace\sweet-rope-sorting-puzzle\Assets\_IEC\Resources\LevelData'
LAST = 5125

# ---------------- THAM SỐ (Designed) ----------------
INTRO = {1: 0, 2: 4.9, 3: 6.6, 4: 8.0, 5: 6.6}          # level 1-5 lấy đúng default Sort Streak
BASE = [(6, 8.0), (25, 15.0), (200, 19.0), (1000, 22.0)]  # mức level Practice, nội suy thẳng, sau 1000 giữ nguyên
PHASE = {'Learn': -3.0, 'Practice': 0.0, 'Combine': 1.5, 'Recover': -6.0, 'Renew': -2.5, 'Bonus': -2.0}
SLOT = {1: -6.0, 2: -1.0, 3: 0.0, 4: 1.5}                # vị trí trong nhóm 5 (từ level 26), theo nhịp Sort Streak
CHAPTER = {'Renew': -2.5, 'Practice': 0.0, 'Combine': 1.5, 'Challenge': 3.0}   # tầm 50 level
HARD = [(10, 6.0), (15, 8.0), (20, 9.0), (25, 12.0), (26, 11.0), (200, 13.0), (1000, 14.0)]  # Hard cao hơn mức Practice bao nhiêu
PEAK_EXTRA = 4.0                                          # Hard đỉnh chương (x45) và level 25
TOL = 2.31
ONBOARD = {  # 6-25: từng level một (mechanic mở ở 6, 11, 21)
    6: ('Learn', 'Hidden'), 7: ('Learn', 'Hidden'), 8: ('Practice', 'Hidden'), 9: ('Practice', 'Hidden'), 10: ('Challenge', 'Hidden'),
    11: ('Learn', 'Khoá theo màu'), 12: ('Learn', 'Khoá theo màu'), 13: ('Bonus', 'Khoá theo màu'), 14: ('Practice', 'Khoá theo màu'), 15: ('Challenge', 'Khoá theo màu'),
    16: ('Recover', 'Hidden + khoá màu'), 17: ('Combine', 'Hidden + khoá màu'), 18: ('Combine', 'Hidden + khoá màu'), 19: ('Combine', 'Hidden + khoá màu'), 20: ('Challenge', 'Hidden + khoá màu'),
    21: ('Learn', 'Khoá theo số lần'), 22: ('Learn', 'Khoá theo số lần'), 23: ('Bonus', 'Khoá theo số lần'), 24: ('Practice', 'Khoá theo số lần'), 25: ('Challenge', 'Mọi cơ chế (đỉnh 1)'),
}
# ----------------------------------------------------

lerp = lambda pts, n: next((a[1] + (b[1] - a[1]) * (n - a[0]) / (b[0] - a[0]) for a, b in zip(pts, pts[1:]) if a[0] <= n <= b[0]), pts[0][1] if n < pts[0][0] else pts[-1][1])
is_bonus = lambda n: n >= 13 and (n - 13) % 10 == 0
CHALL = lambda n: n >= 17 and (n - 17) % 10 == 0
ENDLESS = lambda n: n >= 30 and (n - 30) % 10 == 0


def chapter_phase(n):
    p = (n - 1) % 50 + 1                       # vị trí trong chương 50 level (chương 1 = 1-50 nhưng 1-25 là nhập môn)
    return 'Renew' if p <= 10 else 'Practice' if p <= 25 else 'Combine' if p <= 40 else 'Challenge'


def target(n):
    """(điểm đích, pha chương, pha level, ghi chú)"""
    if n in INTRO:
        return INTRO[n], 'Nhập môn', ['Learn', 'Learn', 'Learn', 'Practice', 'Challenge'][n - 1], 'Luật cơ bản'
    b = lerp(BASE, n)
    if n <= 25:
        ph, mech = ONBOARD[n]
        if ph == 'Challenge':
            return b + lerp(HARD, n) + (PEAK_EXTRA if n == 25 else 0), 'Nhập môn', 'Challenge', mech
        return b + PHASE[ph], 'Nhập môn', ph, mech
    cp = chapter_phase(n); slot = (n - 1) % 5 + 1
    if slot == 5:
        peak = (n - 1) % 50 + 1 == 45
        return b + CHAPTER[cp] + lerp(HARD, n) + (PEAK_EXTRA if peak else 0), cp, 'Challenge (đỉnh chương)' if peak else 'Challenge', ''
    t = b + CHAPTER[cp] + SLOT[slot]
    ph = {1: 'Recover', 2: 'Practice', 3: 'Practice', 4: 'Combine'}[slot]
    if cp == 'Renew' and slot == 2: ph = 'Renew'      # level mở chương: đổi kiểu bàn (sức chứa, số màu, số Order)
    if is_bonus(n): t, ph = min(t, b + CHAPTER[cp] + PHASE['Bonus']), 'Bonus'
    return t, cp, ph, ''


def load_ss():
    rows = {}
    for e in json.load(open(SRV, encoding='utf8')):
        if e['levelUserTags'] == 'default':
            rows[(e['chapterIndex'] - 1) * 25 + e['levelIndex']] = (float(e['summaryScore']), e['difficultyType'])
    return rows


def ice_levels():
    p = os.path.join(GAME, 'Variants', 'ice_01.json')
    if not os.path.exists(p): return set()
    return {(o['stage'] - 1) * 25 + o['levelIndex'] for o in json.load(open(p, encoding='utf8'))['overrides']}


def curve_c():
    ws = openpyxl.load_workbook(os.path.join(HERE, 'SR_Difficulty Curve.xlsx'), read_only=True, data_only=True)['Đường Sweet Rope']
    return {r[0]: (r[4], r[8]) for r in ws.iter_rows(min_row=2, max_row=LAST + 1, values_only=True)}


def ss_analysis(ss):
    """bảng phân tích pha Sort Streak (cho sheet 'Sort Streak - pha')"""
    pos = lambda a, b, p: round(S.median(ss[n][0] for n in range(a, b + 1) if (n - 1) % 5 + 1 == p), 1)
    cad = [[p, pos(26, 250, p), pos(251, LAST, p)] for p in range(1, 6)]
    rec = []
    for a, b in [(6, 25), (26, 100), (101, 250), (251, LAST)]:
        after = [ss[n][0] for n in range(a, b + 1) if (n - 1) % 5 == 0]
        other = [ss[n][0] for n in range(a, b + 1) if ss[n][1] != 'Hard' and (n - 1) % 5]
        hard = [ss[n][0] for n in range(a, b + 1) if ss[n][1] == 'Hard']
        rec.append([f'{a}-{b}', round(S.mean(after), 1), round(S.mean(other), 1), round(S.mean(hard), 1)])
    stage = [S.mean(ss[n][0] for n in range((s - 1) * 25 + 1, s * 25 + 1)) for s in range(1, LAST // 25 + 1)]
    top = sorted(((ss[n][0], n) for n in range(1, 251) if ss[n][1] == 'Hard'), reverse=True)[:8]
    return cad, rec, stage, top


def check():
    t = {n: target(n) for n in range(1, 301)}
    for k in range(2, 61):                        # mỗi nhóm 5 (trừ 1-5 lấy default): Hard cao hơn mọi Normal cùng nhóm
        g = [t[n][0] for n in range(5 * k - 4, 5 * k + 1)]
        assert g[-1] > max(g[:-1]) + 1, (k, g)
    for n in range(26, 301):                      # level sau Hard luôn là level dễ nhất nhóm
        if (n - 1) % 5 == 0: assert t[n][0] <= min(t[n + j][0] for j in range(1, 4)), n
    assert t[95][0] > t[90][0] and t[45][0] > t[40][0], 'đỉnh chương x45 phải cao hơn x40'
    assert all(t[n][0] >= 0 for n in t)


if __name__ == '__main__':
    check()
    ss, C, ICE = load_ss(), curve_c(), ice_levels()
    cad, rec, stage, top = ss_analysis(ss)
    thin = Side(style='thin', color='999999'); B = Border(left=thin, right=thin, top=thin, bottom=thin)
    HEAD = PatternFill('solid', fgColor='D9E1F2'); F = Font(name='Times New Roman', size=14); FB = Font(name='Times New Roman', size=14, bold=True)
    COL = {'Learn': 'E2EFDA', 'Practice': 'FFFFFF', 'Combine': 'FFF2CC', 'Challenge': 'F8CBAD', 'Challenge (đỉnh chương)': 'FF9999',
           'Recover': 'DDEBF7', 'Renew': 'E4DFEC', 'Bonus': 'FFE699'}
    wb = openpyxl.Workbook()

    def sheet(title, rows, widths=None, head=1):
        ws = wb.create_sheet(title)
        for r in rows: ws.append(r)
        for row in ws.iter_rows():
            for c in row:
                c.font = FB if c.row <= head else F; c.border = B; c.alignment = Alignment(wrap_text=True, vertical='top')
                if c.row <= head: c.fill = HEAD
        for i, w in enumerate(widths or []): ws.column_dimensions[chr(65 + i)].width = w
        return ws

    wb.remove(wb.active)
    sheet('Tổng quan', [
        ['Mục', 'Sort Streak (đo từ bộ default)', 'Đường D cho Sweet Rope', 'Trạng thái'],
        ['Nhịp nhỏ: nhóm 5 level', f'Sau Hard là level dễ nhất (trung vị {cad[0][1]} ở level 26-250, {cad[0][2]} về sau). Level đó luôn có sức chứa 4, có Hidden và khoá. Hard (vị trí 5) {cad[4][2]}, gần như luôn sức chứa 6.',
         'Mỗi nhóm 5: Recover → Practice → Practice → Combine → Challenge (Hard).', 'Implemented (số đo) / Designed'],
        ['Nhập môn 1-25', 'Luật cơ bản 1-5, Hidden từ 6, khoá theo màu từ 11, khoá theo số lần từ 21. Mỗi cơ chế: 2-4 level học rồi 1 Hard. Đỉnh đầu tiên level 25 (31,7). Level 16 nghỉ sâu (5,7).',
         'Giữ đúng thứ tự mở cơ chế của game. Mỗi cơ chế: Learn (dễ hơn mức chung 3 điểm) → Practice → Challenge. Level 16 Recover. Level 25 là đỉnh 1.', 'Designed'],
        ['Tầm dài', f'Stage 2-8 (level 26-200) khó hơn hẳn về sau: Normal trung bình ~20 so với ~13,8. Từ Stage 10 phẳng: trung bình mỗi 10 Stage 16,0-16,8, sóng chỉ cao {0.77} điểm. Game gốc tăng độ khó bằng cách chuyển người chơi lên bậc lv2-lv5, không bằng đường cong.',
         'Sweet Rope chỉ có một bộ level, nên tự tạo sóng: chương 50 level = Renew (1-10) → Practice (11-25) → Combine (26-40) → Challenge (41-50). Mức chung leo 15 → 19 (level 200) → 22 (level 1000) rồi giữ.', 'Designed'],
        ['Đỉnh khó', 'Hard khó nhất trong level 1-250: ' + ', '.join(f'{n} ({s})' for s, n in top[:6]) + '. Có Normal vượt Hard (level 52: 46,9).',
         'Đỉnh ở level 25 và level x45 của mỗi chương (45, 95, 145, 195…): Hard cộng thêm 4 điểm. Level x30, x40… là Endless nên Hard thật chỉ còn ở x5.', 'Designed'],
        ['Hồi phục', 'Level ngay sau Hard dễ hơn các Normal khác 2-9 điểm. Stage 9 (level 201) cả Stage hạ ~8 điểm sau đoạn Stage 2-8.',
         'Level sau mỗi Hard thấp hơn mức chung 6 điểm. Đầu mỗi chương (x01-x10) hạ thêm 2,5 điểm và đổi kiểu bàn (Renew).', 'Designed'],
        ['Level đặc biệt', 'Bonus heo vàng 13, 23…; Challenge 17, 27…; Endless 30, 40…', 'Bonus thấp hơn mức chung 2 điểm (level thưởng). Challenge, Endless, Ice ghi "Màn thay thế", điểm không áp dụng.', 'Designed'],
        ['Dải cho phép', '', f'Điểm đích ± {TOL}', 'Designed'],
        ['Cách sửa', '', 'Đổi khối THAM SỐ trong curve_d.py rồi chạy lại: python -X utf8 curve_d.py', 'Implemented'],
    ], [22, 60, 60, 22])

    sheet('Sort Streak - pha', [['Vị trí trong nhóm 5', 'Trung vị level 26-250', 'Trung vị level 251-5125', 'Pha (đọc từ số)']] +
          [r + [['Recover', 'Practice', 'Practice', 'Combine (96% có Hidden)', 'Challenge (Hard)'][r[0] - 1]] for r in cad] +
          [[], ['Đoạn level', 'Level sau Hard (TB)', 'Normal khác (TB)', 'Hard (TB)']] + rec +
          [[], ['Hard khó nhất 1-250', 'Điểm', '', '']] + [[n, s, '', ''] for s, n in top] +
          [[], ['Stage', 'Điểm TB Stage', '', '']] + [[i + 1, round(v, 1), '', ''] for i, v in enumerate(stage)], [26, 24, 24, 30])

    rows = [['Level', 'Stage', 'Vị trí nhóm 5', 'difficultyType', 'Pha chương', 'Pha level', 'Cơ chế / ghi chú', 'Điểm đích D', 'Cận dưới', 'Cận trên',
             'Màn thay thế', 'Mở khoá', 'Đường C', 'D − C', 'Default Sort Streak', 'D − default']]
    for n in range(1, LAST + 1):
        t, cp, ph, note = target(n); t = round(t, 1)
        rep = 'Challenge' if CHALL(n) else 'Endless' if ENDLESS(n) else 'Ice' if n in ICE else ''
        c, unlock = C.get(n, (None, None)); s, dt = ss[n]
        rows.append([n, (n - 1) // 25 + 1, (n - 1) % 5 + 1, dt, cp, ph, note, t, round(max(0, t - TOL), 2), round(t + TOL, 2), rep, unlock or '',
                     round(c, 1) if c is not None else None, round(t - c, 1) if c is not None else None, s, round(t - s, 1)])
    ws = sheet('Đường D', rows, [8, 7, 8, 12, 14, 22, 24, 11, 10, 10, 13, 26, 10, 9, 12, 11])
    ws.freeze_panes = 'B2'
    for r in ws.iter_rows(min_row=2, max_row=301):
        r[5].fill = PatternFill('solid', fgColor=COL.get(r[5].value, 'FFFFFF'))
    ch = LineChart(); ch.title = 'Level 1-200: đường D, đường C, default Sort Streak'; ch.height, ch.width = 12, 34
    ch.y_axis.title = 'summaryScore'; ch.x_axis.title = 'Level'
    for col in (8, 13, 15): ch.add_data(Reference(ws, min_col=col, min_row=1, max_row=201), titles_from_data=True)
    ch.set_categories(Reference(ws, min_col=1, min_row=2, max_row=201))
    wsc = wb.create_sheet('Biểu đồ', 1); wsc.add_chart(ch, 'A1')

    sheet('Cần xác nhận', [['Mã', 'Câu hỏi', 'Trạng thái', 'Đề xuất'],
        ['CX-01', 'Mức chung leo 15 → 19 (level 200) → 22 (level 1000): nhanh hơn đường C (ngang lv2 ở Stage 152). Có chấp nhận?', 'Chờ GD', 'Giữ, vì Sweet Rope không có bậc lv2-lv5 để tăng độ khó.'],
        ['CX-02', 'Chương 50 level (2 Stage) có hợp với nhịp nội dung, quảng cáo, sự kiện của game?', 'Chờ GD', '50 level, đỉnh ở x45.'],
        ['CX-03', 'Renew hiện chỉ là đổi kiểu bàn (sức chứa, số màu, số Order) vì sau level 21 không còn cơ chế mới (Ice đang bỏ qua). Có cơ chế mới nào định mở sau này?', 'Chờ GD', 'Nếu có, đặt ở level x01 của một chương: Learn x01-x05, Practice x06-x10.'],
        ['CX-04', 'Level Recover thấp hơn mức chung 6 điểm. Nhiều level default khó hơn đích này nhiều; bộ sinh có thể không chạm được (xem cột D − default).', 'Unverified', 'Chấp nhận gần đích nhất, ghi trong báo cáo.'],
        ['CX-05', 'Chưa có số liệu người chơi thật. Mọi số pha là thiết kế, chỉ số Sort Streak là đo.', 'Unverified', 'Bật analytics theo level rồi chỉnh tham số.'],
    ], [10, 70, 14, 50])
    out = os.path.join(HERE, 'SR_Difficulty Curve_D.xlsx'); wb.save(out); print('saved', out)

    import matplotlib; matplotlib.use('Agg'); import matplotlib.pyplot as plt
    L = list(range(1, 201)); D = [target(n)[0] for n in L]
    fig, ax = plt.subplots(figsize=(16, 6), dpi=110)
    ax.plot(L, [ss[n][0] for n in L], color='#B0B0B0', lw=1, label='Default Sort Streak')
    ax.plot(L, [C[n][0] for n in L], color='#4C78A8', lw=1.2, ls='--', label='Đường C (cũ)')
    ax.plot(L, D, color='#D1495B', lw=2, label='Đường D (mới)')
    for a, b, name, col in [(1, 25, 'Nhập môn', '#E2EFDA')] + [(k, k + 9, 'Renew', '#E4DFEC') for k in range(51, 200, 50)] + \
            [(k + 40, k + 49, 'Challenge', '#FBE3D6') for k in range(0, 200, 50) if k + 40 > 25]:
        ax.axvspan(a - 0.5, b + 0.5, color=col, alpha=0.6, lw=0); ax.text((a + b) / 2, 52, name, ha='center', fontsize=9)
    for n in [25, 45, 95, 145, 195]: ax.annotate(f'đỉnh {n}', (n, target(n)[0]), (n, target(n)[0] + 4), ha='center', fontsize=9, arrowprops=dict(arrowstyle='-', lw=0.6))
    for n, lab in [(6, 'Hidden'), (11, 'Khoá màu'), (21, 'Khoá số lần')]: ax.axvline(n, color='#2E7D32', lw=0.8, ls=':'); ax.text(n + 0.3, 1, lab, fontsize=8, color='#2E7D32', rotation=90, va='bottom')
    ax.set_xlim(0.5, 200.5); ax.set_ylim(0, 55); ax.set_xlabel('Level'); ax.set_ylabel('summaryScore'); ax.grid(axis='y', color='#EEEEEE'); ax.legend(loc='upper left')
    ax.set_title('Sweet Rope level 1-200: đường D theo pha')
    fig.tight_layout(); fig.savefig(os.path.join(HERE, 'curve_d_1-200.png')); print('png ok')
