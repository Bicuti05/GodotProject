#!/usr/bin/env python3
"""Chấm độ khó level Sweet Rope theo thang summaryScore của Sort Streak.

Cách dùng (chạy từ thư mục gốc repo, Godot 4.6.1):
  1) Gom level vào một file JSON dạng mảng [{"uid": "...", "raw": <level JSON>}, ...] (vd. in.json).
  2) Sao chép greedy_ext.gd và solver_metrics.gd vào .godot/ rồi chạy (có thể chia shard để chạy song song):
       godot --headless --path . -s res://.godot/greedy_ext.gd    -- in.json ge_0.json 0 1
       godot --headless --path . -s res://.godot/solver_metrics.gd -- in.json out_0.json 0 1
  3) python3 levels/sweet_rope_B/tools/score.py "ge_*.json" "out_*.json" > scores.csv

Công thức (hiệu chỉnh trên 392 level Sort Streak có summaryScore):
  diem = 32.83 - 53.67*lw - 24.493*ld + 32.315*rand_win + 4.128*ln(min(beam_w,200)) + 0.602*opt_len
  lw = trung bình tỉ lệ thắng 4 cấu hình bot greedy (eps 0.3/0.45/0.6, softmax T=4), mỗi cấu hình 2 seed x 30 ván
  ld = trung bình tỉ lệ cốc hoàn thành của 4 cấu hình đó
  rand_win = tỉ lệ thắng chơi ngẫu nhiên (3 seed x 40 ván); beam_w = độ rộng beam nhỏ nhất thắng (999 nếu không thắng)
  opt_len = độ dài đường thắng của beam (thiếu thì 50). Kết quả kẹp trong 0..100.
CỘT CHÍNH: diem_lw (chỉ cần greedy_ext.gd, ~9 s/level). Kiểm chứng trên 240 level Sort Streak chưa dùng để hiệu chỉnh,
vùng điểm 0-70: sai số trung bình 8.8, 67% trong ±10, 36% trong ±5; trên 70 điểm bị chấm thấp ~18.
diem_5f (cần thêm solver_metrics.gd) không tốt hơn (9.2); chỉ dùng tham khảo.
Xem levels/checks/REPORT_do_tin_cay_cach_cham.md về sai số thực tế.
"""
import glob, json, math, sys, csv

COEF = dict(intercept=32.83, lw=-53.67, ld=-24.493, rand_win=32.315, beam_logw=4.128, opt_len=0.602)
OPT_LEN_FILL = 50.0
# Bảng lw -> điểm (hồi quy đơn điệu, hiệu chỉnh trên 632 level Sort Streak); nội suy tuyến tính giữa các điểm
LW_X = [0.0, 0.0042, 0.0083, 0.0125, 0.0167, 0.0208, 0.0458, 0.05, 0.0542, 0.0583, 0.0625, 0.0667, 0.0875, 0.0917, 0.0958, 0.125, 0.1292, 0.1333, 0.1375, 0.1625, 0.1667, 0.1917, 0.1958, 0.2083, 0.2125, 0.2167, 0.2208, 0.225, 0.2292, 0.2458, 0.25, 0.2708, 0.275, 0.3042, 0.3083, 0.3458, 0.35, 0.3542, 0.3583, 0.4083, 0.4125, 0.4667, 0.4708, 0.475, 0.5458, 0.55, 0.5542, 0.5583, 0.5708, 0.575, 0.5792, 0.5833, 0.5875, 0.6708, 0.6792, 0.6917, 0.6958, 0.7333, 0.7458, 0.8208, 0.8417, 0.8917, 0.9167, 1.0]
LW_Y = [93.84, 86.16, 85.13, 81.64, 74.72, 74.21, 74.21, 69.31, 69.31, 67.49, 67.49, 64.62, 64.62, 60.68, 57.61, 57.61, 56.4, 55.72, 52.84, 52.84, 48.34, 48.34, 46.78, 46.78, 43.48, 43.48, 40.66, 40.66, 38.37, 38.37, 38.17, 38.17, 37.64, 37.64, 36.84, 36.84, 34.77, 31.86, 30.45, 30.45, 27.95, 27.95, 25.9, 24.21, 24.21, 22.77, 22.77, 22.5, 22.5, 21.5, 19.9, 19.9, 15.32, 15.32, 13.82, 13.82, 13.35, 13.35, 8.54, 8.54, 6.13, 6.13, 3.35, 0.0]

def interp(x):
    if x <= LW_X[0]: return LW_Y[0]
    if x >= LW_X[-1]: return LW_Y[-1]
    for i in range(1, len(LW_X)):
        if x <= LW_X[i]:
            a, b = LW_X[i - 1], LW_X[i]
            return LW_Y[i - 1] if b == a else LW_Y[i - 1] + (LW_Y[i] - LW_Y[i - 1]) * (x - a) / (b - a)

def load(pattern):
    out = []
    for f in sorted(glob.glob(pattern)):
        out += json.load(open(f))
    return out

def main():
    ge = {x["uid"]: x for x in load(sys.argv[1])}
    sm = {x["uid"]: x for x in load(sys.argv[2])} if len(sys.argv) > 2 else {}
    w = csv.writer(sys.stdout)
    w.writerow(["uid", "lw", "diem_lw", "ld", "rand_win", "beam_w", "opt_len", "diem_5f"])
    for uid, x in ge.items():
        wins, dones = [], []
        for c in x["cfg"]:
            wins.append(sum(s["win"] for s in c["seeds"]) / len(c["seeds"]))
            dones.append(sum(s["done"] for s in c["seeds"]) / len(c["seeds"]))
        lw, ld = sum(wins) / len(wins), sum(dones) / len(dones)
        diem_lw = round(interp(lw), 2)
        diem = rw = bw = ol = ""
        if uid in sm:
            m = sm[uid]
            rw = sum(s["win"] for s in m["rand_seeds"]) / len(m["rand_seeds"])
            okb = [b for b in m["beam"] if b["win"]]
            bw = okb[0]["w"] if okb else 999
            ol = m.get("opt_len")
            ol = OPT_LEN_FILL if ol is None or (isinstance(ol, float) and math.isnan(ol)) else ol
            d = (COEF["intercept"] + COEF["lw"] * lw + COEF["ld"] * ld + COEF["rand_win"] * rw
                 + COEF["beam_logw"] * math.log(min(bw, 200)) + COEF["opt_len"] * ol)
            diem = round(min(100.0, max(0.0, d)), 2)
        w.writerow([uid, round(lw, 4), diem_lw, round(ld, 4), rw if rw == "" else round(rw, 4), bw, ol, diem])

if __name__ == "__main__":
    main()
