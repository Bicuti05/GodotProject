#!/usr/bin/env python3
"""Đóng gói bản A và bản B sang định dạng Unity sweetrope.levelpack/1 (giống thư mục Levels của LevelDesigner).
Kết quả: levels/package/SweetRope_A/Levels/pack_001.json (màn 1-125), pack_002.json (126-200)
         levels/package/SweetRope_B/<bộ>/Levels/pack_001.json, pack_002.json  (bộ: default, lv2..lv5)
Màn 1 bản B: dùng màn 1 của bản A làm chỗ giữ (dev thay bằng level hướng dẫn cố định).
Kiểm lại toàn bộ bằng LevelDesigner (core.js validateLevel) rồi nén zip."""
import json, csv, os, sys, subprocess, shutil, zipfile
sys.path.insert(0, os.path.dirname(__file__))
import juice_to_unity as J
OUT = 'levels/package'
for d in ('SweetRope_A', 'SweetRope_B'): shutil.rmtree(f'{OUT}/{d}', ignore_errors=True)
ta = {int(r['man']): float(r['diem_muc_tieu']) for r in csv.DictReader(open('levels/sweet_rope_A/report.csv', encoding='utf-8-sig'))}
tb = {}
for r in csv.DictReader(open('levels/sweet_rope_B/docs/targets_B.csv', encoding='utf-8-sig')):
    for b in r['group'].split('+'): tb[(b, int(r['slot']))] = r
check = []


def write(levels, d):
    os.makedirs(d, exist_ok=True)
    for pno, p in J.build_packs(levels).items():
        json.dump(p, open(f'{d}/pack_{pno:03d}.json', 'w'), ensure_ascii=False, separators=(',', ':'))


A = {}
for n in range(1, 201):
    A[n] = J.convert(json.load(open(f'levels/sweet_rope_A/level_{n:03d}.json')), (n - 1) % 25 + 1, 'Hard' if n % 5 == 0 else 'Normal', ta[n])
    check.append({'uid': f'A|{n}', 'level': A[n]})
write(A, f'{OUT}/SweetRope_A/Levels')
for b in ['default', 'lv2', 'lv3', 'lv4', 'lv5']:
    L = {1: A[1]}
    for n in range(2, 201):
        r = tb[(b, n)]
        L[n] = J.convert(json.load(open(f'levels/sweet_rope_B/final/{b}/level_{n:03d}.json')), (n - 1) % 25 + 1, r['loai'], r['muc_tieu'])
        check.append({'uid': f'{b}|{n}', 'level': L[n]})
    write(L, f'{OUT}/SweetRope_B/{b}/Levels')
json.dump(check, open(os.path.join(os.environ.get('TMPDIR', '/tmp'), '_pkg_check.json'), 'w'))
res = subprocess.run(['node', 'levels/sweet_rope_B/work/tools/designer/check_unity.js', os.path.join(os.environ.get('TMPDIR', '/tmp'), '_pkg_check.json'), os.path.join(os.environ.get('TMPDIR', '/tmp'), '_pkg_out.json'), '0'], capture_output=True, text=True)
print('LevelDesigner validate:', res.stdout.strip(), res.stderr[-300:])
bad = [x for x in json.load(open(os.path.join(os.environ.get('TMPDIR', '/tmp'), '_pkg_out.json'))) if x['errors'] or x['warnings']]
print('loi/canh bao:', len(bad), bad[:5])
for v in ['A', 'B']:
    z = f'{OUT}/SweetRope_{v}.zip'
    with zipfile.ZipFile(z, 'w', zipfile.ZIP_DEFLATED) as f:
        for root, _, files in os.walk(f'{OUT}/SweetRope_{v}'):
            for fn in files: f.write(os.path.join(root, fn), os.path.relpath(os.path.join(root, fn), OUT))
    print(z, os.path.getsize(z))
