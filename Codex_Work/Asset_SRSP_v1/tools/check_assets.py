"""Check delivered art against asset_manifest.csv.

  python check_assets.py --out OUT --source REPO_ROOT [--batch 0] [--report report.csv]
  python check_assets.py --selftest

OUT is the folder holding godot_dropin/, unity/, motion/. REPO_ROOT is the GodotProject root (for the copy check).
Needs Pillow. FAIL = must fix (exit code 1). WARN = look at it and explain."""
import argparse, csv, json, os, re, sys, tempfile
from PIL import Image, ImageChops, ImageDraw, ImageStat

HERE = os.path.dirname(os.path.abspath(__file__))
CENTER_TOL, SIZE_TOL, SIMILAR, ATLAS_SPILL = 0.08, 0.25, 0.97, 0.005   # proposed thresholds, tune if needed
safe = lambda name: re.sub(r'[\\/:*?"<>|]', '__', name)


def svg_size(path):
    t = open(path, encoding='utf-8', errors='ignore').read(2000)
    w = re.search(r'<svg[^>]*\swidth="([\d.]+)', t); h = re.search(r'<svg[^>]*\sheight="([\d.]+)', t)
    if w and h: return round(float(w.group(1))), round(float(h.group(1)))
    v = re.search(r'viewBox="[\d.\-]+[ ,]+[\d.\-]+[ ,]+([\d.]+)[ ,]+([\d.]+)', t)
    return (round(float(v.group(1))), round(float(v.group(2)))) if v else (0, 0)


def likeness(a, b):
    """correlation of two pictures' brightness+shape at 64x64; recolouring or light repainting stays near 1"""
    def flat(im):
        base = Image.new('RGBA', im.size, (128, 128, 128, 255)); base.alpha_composite(im)
        g = list(base.convert('L').resize((64, 64)).tobytes()); m = sum(g) / len(g)
        return [v - m for v in g]
    x, y = flat(a), flat(b)
    d = (sum(v * v for v in x) * sum(v * v for v in y)) ** 0.5
    return sum(i * j for i, j in zip(x, y)) / d if d else 0.0


def check_row(r, out, source, atlases):
    fails, warns = [], []
    target = os.path.join(out, r['output_path'])
    if r['action'] == 'layers':
        if not os.path.isfile(os.path.join(target, 'motion.md')): fails.append('thiếu motion.md')
        regions = atlases.get(r['source_path'], [])
        for g in regions:
            p = os.path.join(target, safe(g['name']) + '.png')
            if not os.path.isfile(p): fails.append(f"thiếu lớp {g['name']}")
            else:
                with Image.open(p) as im:
                    if im.size != (g['w'], g['h']): fails.append(f"lớp {g['name']}: {im.size[0]}x{im.size[1]}, cần {g['w']}x{g['h']}")
        return fails[:8], warns
    if not os.path.isfile(target): return ['chưa có file'], warns
    need = (int(r['width']), int(r['height']))
    if r['format'] == 'svg':
        got = svg_size(target)
        if got != need: fails.append(f'px {got[0]}x{got[1]}, cần {need[0]}x{need[1]}')
        return fails, warns
    with Image.open(target) as im:
        if im.size != need: fails.append(f'px {im.size[0]}x{im.size[1]}, cần {need[0]}x{need[1]}')
        if (im.format or '').lower() != r['format'].replace('jpg', 'jpeg'): fails.append(f"định dạng {im.format}, cần {r['format']}")
        img = im.convert('RGBA')
    alpha = img.getchannel('A'); lo, hi = alpha.getextrema()
    if hi == 0 and 'trong suốt cả file' not in r['what_to_draw']: warns.append('file trong suốt hoàn toàn')
    if r['alpha'] == 'yes' and lo >= 250: fails.append('mất nền trong suốt')
    if r['alpha'] == 'no' and lo < 250: warns.append('nền phải đặc nhưng có vùng trong suốt')
    if fails: return fails, warns
    if r['content_bbox'] and r['action'] == 'draw':
        x0, y0, x1, y1 = map(int, r['content_bbox'].split()); box = alpha.point(lambda v: 255 if v > 16 else 0).getbbox()
        if box:
            dx = abs((box[0] + box[2]) - (x0 + x1)) / 2 / need[0]; dy = abs((box[1] + box[3]) - (y0 + y1)) / 2 / need[1]
            if max(dx, dy) > CENTER_TOL: warns.append(f'tâm hình lệch {max(dx, dy):.0%} so với bản cũ')
            sw, sh = (box[2] - box[0]) / max(1, x1 - x0), (box[3] - box[1]) / max(1, y1 - y0)
            if abs(sw - 1) > SIZE_TOL or abs(sh - 1) > SIZE_TOL: warns.append(f'vùng hình {sw:.0%} x {sh:.0%} bản cũ (pivot, va chạm có thể lệch)')
    if r['action'] == 'atlas':
        mask = Image.new('L', need, 255); d = ImageDraw.Draw(mask)
        for g in atlases.get('unity:' + r['source_path'].replace('unity_current/', ''), []):
            w, h = (g['h'], g['w']) if g.get('rotate') else (g['w'], g['h'])
            d.rectangle([g['x'], g['y'], g['x'] + w - 1, g['y'] + h - 1], fill=0)
        spill = ImageStat.Stat(ImageChops.multiply(alpha.point(lambda v: 255 if v > 16 else 0), mask)).mean[0] / 255
        if spill > ATLAS_SPILL: warns.append(f'{spill:.1%} điểm ảnh nằm ngoài ô atlas')
    master = os.path.join(out, 'source', r['output_path'])
    if os.path.isfile(master):
        with Image.open(master) as m:
            if m.width < need[0] or m.height < need[1]: warns.append(f'file nguồn {m.width}x{m.height} nhỏ hơn bản xuất: đã phóng to hoặc kéo giãn')
    root = HERE if r['set'] == 'UNITY_REDRAW' else source
    if r['source_path'] and root:
        p = os.path.join(root, r['source_path'])
        if not os.path.isfile(p): warns.append('không thấy ảnh gốc để kiểm trùng')
        else:
            with Image.open(p) as o: old = o.convert('RGBA')
            if old.size == img.size and ImageChops.difference(old, img).getbbox(alpha_only=False) is None: fails.append('trùng y ảnh cũ')
            elif r['set'] == 'GODOT' and hi and likeness(old, img) > SIMILAR: warns.append('quá giống ảnh gốc (nghi vẽ đè hoặc đổi màu): kiểm lại')
    return fails, warns


def fill_fail(path, min_w, min_h):
    """the visible picture must cover at least this share of the canvas (a shrunken bar has the right px but is broken)"""
    with Image.open(path) as im: box = im.convert('RGBA').getchannel('A').point(lambda v: 255 if v > 16 else 0).getbbox()
    size = Image.open(path).size
    w, h = ((box[2] - box[0]) / size[0], (box[3] - box[1]) / size[1]) if box else (0, 0)
    return f'hình chỉ phủ {w:.0%} x {h:.0%} khung, cần ít nhất {min_w:.0%} x {min_h:.0%}' if w < min_w or h < min_h else None


def run(manifest, out, source, batch=None, report=None, only=None, fill=None):
    atlases = json.load(open(os.path.join(os.path.dirname(manifest), 'atlas_regions.json'), encoding='utf-8'))
    rows = [r for r in csv.DictReader(open(manifest, encoding='utf-8-sig')) if r['action'] != 'skip' and (batch is None or r['batch'] == str(batch)) and (not only or any(r['output_path'] == o or r['output_path'].endswith('/' + o) for o in only))]
    if only:
        for o in only:
            n = sum(r['output_path'] == o or r['output_path'].endswith('/' + o) for r in rows)
            if n != 1: raise SystemExit(f'"{o}" khớp {n} file trong manifest, cần đúng 1')
    need = {}
    if fill: need = {x['output_path']: (float(x['min_w']), float(x['min_h'])) for x in csv.DictReader(open(fill, encoding='utf-8-sig')) if x.get('min_w')}
    result = []
    for r in rows:
        try:
            f, w = check_row(r, out, source, atlases)
            target = os.path.join(out, r['output_path'])
            if r['output_path'] in need and os.path.isfile(target):
                msg = fill_fail(target, *need[r['output_path']])
                if msg: f = f + [msg]
        except Exception as e: f, w = [f'không đọc được: {e}'], []
        result.append(dict(batch=r['batch'], output_path=r['output_path'], result='FAIL' if f else 'WARN' if w else 'OK', detail='; '.join(f + w)))
    if report:
        with open(report, 'w', newline='', encoding='utf-8-sig') as fh:
            wr = csv.DictWriter(fh, ['batch', 'output_path', 'result', 'detail']); wr.writeheader(); wr.writerows(result)
    return result


def selftest():
    with tempfile.TemporaryDirectory() as d:
        os.makedirs(os.path.join(d, 'out')); os.makedirs(os.path.join(d, 'src'))
        def pic(path, size, fill=(200, 30, 30, 255), shape='ellipse'):
            im = Image.new('RGBA', size, (0, 0, 0, 0)); getattr(ImageDraw.Draw(im), shape)([10, 10, size[0] - 10, size[1] - 10], fill=fill); im.save(path)
        pic(f'{d}/src/a.png', (100, 100)); pic(f'{d}/out/ok.png', (100, 100), shape='rectangle', fill=(10, 200, 10, 255))
        os.makedirs(f'{d}/out/source'); pic(f'{d}/out/soft.png', (100, 100), shape='rectangle', fill=(10, 200, 10, 255)); pic(f'{d}/out/source/soft.png', (50, 50))
        pic(f'{d}/out/small.png', (90, 100)); pic(f'{d}/out/copy.png', (100, 100)); pic(f'{d}/out/tint.png', (100, 100), fill=(30, 30, 200, 255))
        cols = 'batch action set source_path output_path width height format alpha content_bbox what_to_draw'.split()
        with open(f'{d}/m.csv', 'w', newline='', encoding='utf-8-sig') as fh:
            wr = csv.DictWriter(fh, cols); wr.writeheader()
            for n in ('ok', 'small', 'copy', 'tint', 'gone', 'soft'):
                wr.writerow(dict(batch=0, action='draw', set='GODOT', source_path='a.png', output_path=n + '.png', width=100, height=100, format='png', alpha='yes', content_bbox='10 10 91 91', what_to_draw=''))
        json.dump({}, open(f'{d}/atlas_regions.json', 'w'))
        got = {r['output_path'][:-4]: r['result'] for r in run(f'{d}/m.csv', f'{d}/out', f'{d}/src')}
        assert [r['output_path'] for r in run(f'{d}/m.csv', f'{d}/out', f'{d}/src', only=['ok.png'])] == ['ok.png']
    assert got == dict(ok='OK', small='FAIL', copy='FAIL', tint='WARN', gone='FAIL', soft='WARN'), got
    with tempfile.TemporaryDirectory() as d:
        im = Image.new('RGBA', (100, 40), (0, 0, 0, 0)); ImageDraw.Draw(im).rectangle([25, 0, 74, 39], fill=(1, 2, 3, 255)); im.save(f'{d}/bar.png')
        assert fill_fail(f'{d}/bar.png', 0.9, 0.9) and not fill_fail(f'{d}/bar.png', 0.5, 0.9)
    print('selftest ok')


if __name__ == '__main__':
    sys.stdout.reconfigure(encoding='utf-8')
    ap = argparse.ArgumentParser()
    ap.add_argument('--manifest', default=os.path.join(HERE, 'asset_manifest.csv')); ap.add_argument('--out'); ap.add_argument('--source'); ap.add_argument('--batch', type=int)
    ap.add_argument('--report', default='report.csv'); ap.add_argument('--selftest', action='store_true')
    ap.add_argument('--only', help='tên file cách nhau bằng dấu phẩy, để kiểm một phần')
    ap.add_argument('--fill', help='CSV có cột output_path, min_w, min_h: hình phải phủ khung ít nhất chừng đó')
    a = ap.parse_args()
    if a.selftest: selftest(); sys.exit()
    if not a.out or not a.source: ap.error('cần --out và --source (thư mục gốc GodotProject, để kiểm trùng ảnh gốc)')
    res = run(a.manifest, a.out, a.source, a.batch, a.report, a.only.split(',') if a.only else None, a.fill)
    n = {k: sum(r['result'] == k for r in res) for k in ('OK', 'WARN', 'FAIL')}
    print(n, '| báo cáo:', a.report)
    sys.exit(1 if n['FAIL'] or not res else 0)
