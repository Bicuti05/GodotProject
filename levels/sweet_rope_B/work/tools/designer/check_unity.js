// Kiểm level Unity bằng luật của LevelDesigner (core.js = bản port C# LevelValidator/BoardSolver).
// node check_unity.js in.json out.json [budget]   in: [{uid, level}]  out: [{uid, errors, warnings, status, nodes, extra}]
'use strict';
const fs = require('fs'); const core = require('./core.js').SweetRopeCore;
const [inp, outp, b] = process.argv.slice(2); const budget = +(b || core.DEFAULT_NODE_BUDGET);
const res = JSON.parse(fs.readFileSync(inp, 'utf8')).map(x => {
  const rep = core.validateLevel(x.level, false); const o = { uid: x.uid, errors: rep.errors, warnings: rep.warnings };
  if (!rep.errors.length) {
    const st = core.fromLevel(x.level); const s = core.solve(st, budget); o.status = s.status; o.nodes = s.nodes; o.moves = s.moves.length;
    if (s.status !== 'Solved') { const e = core.solveWithExtraRope(st, budget); o.extra = e.status; }
  }
  return o;
});
fs.writeFileSync(outp, JSON.stringify(res));
const c = {}; res.forEach(r => { const k = r.errors.length ? 'ERROR' : r.status + (r.extra ? '/extra:' + r.extra : ''); c[k] = (c[k] || 0) + 1; });
console.log(JSON.stringify(c));
