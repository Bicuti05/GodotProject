#!/usr/bin/env python3
"""Vẽ biểu đồ đường (không làm trơn) cho từng bộ từ file chi tiết của report.py:
 (1) độ khó mục tiêu vs đo thực tế, (2) tỉ lệ thắng TB của bot, (3) playtime ước lượng (số bước × 3 giây).
charts.py chi_tiet.csv out_dir   -> out_dir/<bo>.png"""
import csv, sys, os
import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt

SRC, OUT = sys.argv[1], sys.argv[2]
os.makedirs(OUT, exist_ok=True)
BLUE, ORANGE, TEXT, TEXT2, GRID = '#257de0', '#f47230', '#191919', '#666666', '#e6e6e6'
CFG = ['eps0.3', 'eps0.45', 'eps0.6', 'softmaxT4']
rows = list(csv.DictReader(open(SRC)))
plt.rcParams.update({'font.size': 10, 'axes.edgecolor': GRID, 'axes.labelcolor': TEXT2, 'xtick.color': TEXT2, 'ytick.color': TEXT2,
                     'axes.titlecolor': TEXT, 'axes.spines.top': False, 'axes.spines.right': False})


def style(ax, ylabel):
    ax.grid(axis='y', color=GRID, linewidth=0.8); ax.set_axisbelow(True)
    ax.set_ylabel(ylabel); ax.set_xlim(0, 201)
    for s in ('left', 'bottom'): ax.spines[s].set_color(GRID)
    ax.tick_params(length=0)


for bo in ['A', 'default', 'lv2', 'lv3', 'lv4', 'lv5']:
    X = sorted([r for r in rows if r['bo'] == bo], key=lambda r: int(r['man']))
    m = [int(r['man']) for r in X]
    t = [float(r['muc_tieu']) for r in X]; d = [float(r['diem_do']) for r in X]
    w = [sum(float(r[f'win_{c}']) for c in CFG) / 4 * 100 for r in X]
    pt = []
    for r in X:
        s = [float(r[f'buoc_{c}']) for c in CFG if r[f'buoc_{c}']]
        pt.append(sum(s) / len(s) * 3 / 60 if s else float('nan'))
    fig, axs = plt.subplots(3, 1, figsize=(11, 9), sharex=True, gridspec_kw={'height_ratios': [1.4, 1, 1]})
    ten = 'Bản A' if bo == 'A' else f'Bản B – bộ {bo}'
    fig.suptitle(f'{ten}: độ khó, tỉ lệ thắng và playtime theo màn', x=0.06, ha='left', fontsize=13, color=TEXT, fontweight='bold')
    ax = axs[0]
    ax.plot(m, t, color=ORANGE, linewidth=2, linestyle=(0, (4, 2)), label='Mục tiêu (dự kiến)')
    ax.plot(m, d, color=BLUE, linewidth=2, label='Đo thực tế (bot, diem_lw)')
    ax.set_ylim(0, 100); style(ax, 'Điểm độ khó (0–100)')
    ax.legend(loc='upper left', frameon=False, ncol=2, labelcolor=TEXT)
    e = [abs(a - b) for a, b in zip(d, t)]
    ax.set_title(f'Độ khó: sai số TB {sum(e) / len(e):.1f} điểm, {sum(v > 10 for v in e)} màn lệch > 10', loc='left', fontsize=10, color=TEXT2)
    ax = axs[1]
    ax.plot(m, w, color=BLUE, linewidth=2); ax.set_ylim(0, 100); style(ax, 'Tỉ lệ thắng (%)')
    ax.set_title(f'Tỉ lệ thắng TB của 4 bot greedy (2 seed × 30 ván mỗi bot): trung bình {sum(w) / len(w):.0f}%', loc='left', fontsize=10, color=TEXT2)
    ax = axs[2]
    ax.plot(m, pt, color=BLUE, linewidth=2); ax.set_ylim(bottom=0); style(ax, 'Playtime (phút)')
    v = [x for x in pt if x == x]
    ax.set_title(f'Playtime ước lượng = số bước TB khi thắng × 3 giây: trung bình {sum(v) / len(v):.1f} phút (màn bot không thắng bị bỏ trống)',
                 loc='left', fontsize=10, color=TEXT2)
    ax.set_xlabel('Màn'); ax.set_xticks([1] + list(range(25, 201, 25)))
    fig.tight_layout(rect=(0, 0, 1, 0.96))
    fig.savefig(f'{OUT}/{bo}.png', dpi=110, facecolor='white'); plt.close(fig)
    print('wrote', f'{OUT}/{bo}.png')
