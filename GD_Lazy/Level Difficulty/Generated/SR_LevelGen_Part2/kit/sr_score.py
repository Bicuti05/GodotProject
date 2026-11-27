"""Điểm SR: độ khó của một bàn theo thang riêng của Sweet Rope, trọng số học từ bàn default của Sort Streak.

fast(layout)  chỉ số trên bàn + bot (khoảng 0,4 giây), dùng để tìm kiếm.
full(layout)  thêm 5 người chơi máy (khoảng 6 giây), là Điểm SR chính thức. Sai trung bình 4,0 so với summaryScore
              trên bàn default mô hình chưa thấy.
Dữ liệu học: sr_train.npz (mỗi bàn default một lần)."""
import os
os.environ['OMP_NUM_THREADS'] = os.environ['OPENBLAS_NUM_THREADS'] = '1'      # one worker = one core
import json, hashlib
import numpy as np
from sklearn.ensemble import HistGradientBoostingRegressor, ExtraTreesRegressor
from sim3 import measure
from dfeat2 import feats2
from players import player_feats, FEATURES

HERE = os.path.dirname(os.path.abspath(__file__))
TRAIN = os.path.join(HERE, 'sr_train.npz')
_m = None


def models():
    global _m
    if _m is None:
        d = np.load(TRAIN)
        Xs, Xa, y = d['Xs'], np.hstack([d['Xs'], d['Xp']]), d['y']
        gb = lambda: HistGradientBoostingRegressor(loss='absolute_error', max_iter=600, learning_rate=.05, max_leaf_nodes=31, min_samples_leaf=20, random_state=0)
        _m = dict(old=[str(n) for n in d['names_old']], new=[str(n) for n in d['names_new']],
                  fast=gb().fit(Xs, y), gb=gb().fit(Xa, y),
                  trees=ExtraTreesRegressor(300, min_samples_leaf=2, max_features=.5, random_state=0).fit(Xa, y))
    return _m


def seed_of(layout, salt=0):
    return int(hashlib.md5(json.dumps(layout, sort_keys=True).encode()).hexdigest()[:7], 16) + salt


def static(layout, salt=0):
    """(feature row, bot win rate) of the board-level inputs"""
    m = models(); a = measure(layout, seed=seed_of(layout, salt)); b = feats2(layout)
    return [a[n] for n in m['old']] + [b[n] for n in m['new']], a['win']


def clip(v): return float(min(100.0, max(0.0, v)))


def fast(layout):
    row, _ = static(layout)
    return clip(models()['fast'].predict(np.nan_to_num([row]))[0])


def full(layout, salt=0):
    """-> dict(score, bot_win, player_win)"""
    m = models(); row, win = static(layout, salt); p = player_feats(layout, seed_of(layout, salt) % 10 ** 6)
    x = np.nan_to_num([row + [p[k] for k in FEATURES]])
    return dict(score=clip((m['gb'].predict(x)[0] + m['trees'].predict(x)[0]) / 2), bot_win=win,
                player_win=sum(p[k] for k in FEATURES if k.endswith('_win')) / 5)
