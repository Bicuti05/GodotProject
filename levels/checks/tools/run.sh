#!/bin/bash
cd /home/user/GodotProject
G=/tmp/claude-0/godot/Godot_v4.6.1-stable_linux.x86_64
for i in 0 1 2 3; do $G --headless --path . -s res://.godot/greedy_ext.gd -- /tmp/claude-0/chk/in.json /tmp/claude-0/chk/ge_$i.json $i 4 > /tmp/claude-0/chk/glog_$i.txt 2>&1 & done; wait
for i in 0 1 2 3; do $G --headless --path . -s res://.godot/solver_metrics.gd -- /tmp/claude-0/chk/in.json /tmp/claude-0/chk/out_$i.json $i 4 > /tmp/claude-0/chk/log_$i.txt 2>&1 & done; wait
echo DONE
