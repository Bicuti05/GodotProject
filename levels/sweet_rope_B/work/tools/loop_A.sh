#!/bin/bash
# Bản A: loop_A.sh HI LO STEP N. Khung = bộ default Sort Streak, mục tiêu = sweet_rope_A/report.csv diem_muc_tieu.
cd "$(git rev-parse --show-toplevel)"; HI=$1; LO=$2; STEP=$3; N=$4; TMP=${TMPDIR_B:-/tmp/sra}
export TARGETS=levels/sweet_rope_A/work/targets_A.csv WORK=levels/sweet_rope_A/work FINAL_A=levels/sweet_rope_A
for ((b=HI; b>=LO; b-=STEP)); do
  a=$((b-STEP+1)); [ $a -lt $LO ] && a=$LO; T=$TMP/a$b
  python3 levels/sweet_rope_B/work/tools/pipeline.py $a $b $N $T || exit 1
  python3 levels/sweet_rope_B/tools/score.py "$T/ge_*.json" > $T/scores.csv
  git pull -q --no-rebase origin New_Level
  python3 levels/sweet_rope_B/work/tools/check.py $T/chk_in.json "$T/chk_v.json" $T/scores.csv $a $b levels/sweet_rope_A/work/kiem_man_$a-$b
  git add levels/sweet_rope_A/level_*.json levels/sweet_rope_A/work
  git commit -qm "Regenerate set A levels $a-$b on Sort Streak default frame (capacity matches)

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>
Claude-Session: https://claude.ai/code/session_01PaTmqGmqwLJpAat9B3nPDX"
  for k in 1 2 3 4; do git pull -q --no-rebase origin New_Level && git push -q origin New_Level && break; sleep $((k*5)); done
  echo "BATCH A $a-$b DONE"
done
