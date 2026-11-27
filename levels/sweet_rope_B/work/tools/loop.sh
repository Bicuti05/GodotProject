#!/bin/bash
# Chạy các lô từ trên xuống: loop.sh HI LO STEP N   (vd 195 51 25 12)
cd "$(git rev-parse --show-toplevel)"; HI=$1; LO=$2; STEP=$3; N=$4
TMP=${TMPDIR_B:-/tmp/srb}
for ((b=HI; b>=LO; b-=STEP)); do
  a=$((b-STEP+1)); [ $a -lt $LO ] && a=$LO
  T=$TMP/b$b; python3 levels/sweet_rope_B/work/tools/pipeline.py $a $b $N $T || exit 1
  python3 levels/sweet_rope_B/tools/score.py "$T/ge_*.json" > $T/scores.csv
  git pull -q --no-rebase origin New_Level
  python3 levels/sweet_rope_B/work/tools/check.py $T/chk_in.json "$T/chk_v.json" $T/scores.csv $a $b levels/sweet_rope_B/reports/$(date +%F)_kiem_man_$a-$b
  git add levels/sweet_rope_B/work levels/sweet_rope_B/final levels/sweet_rope_B/reports
  git commit -qm "Generate and check set B levels $a-$b (top-down batch)

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>
Claude-Session: https://claude.ai/code/session_01PaTmqGmqwLJpAat9B3nPDX"
  for k in 1 2 3 4; do git pull -q --no-rebase origin New_Level && git push -q origin New_Level && break; sleep $((k*5)); done
  echo "BATCH $a-$b DONE"
done
