// node check_core.js <core.js> <in.json> : validates and replays each {level, path} with the Level Designer tool's rules.
'use strict';
const fs = require('fs');
const core = require(process.argv[2]).SweetRopeCore;
const rows = JSON.parse(fs.readFileSync(process.argv[3], 'utf8'));
process.stdout.write(JSON.stringify(rows.map(({ level, path }) => {
  const r = core.validateLevel(level, false);
  const moves = (path || []).map(([src, j, dst]) => ({ src, j, dst }));
  const win = r.errors.length === 0 && (moves.length ? core.replay(core.fromLevel(level), moves) : core.solve(core.fromLevel(level), core.DEFAULT_NODE_BUDGET).status === 'Solved');
  return { errors: r.errors, warnings: r.warnings, win: !!win };
})));
