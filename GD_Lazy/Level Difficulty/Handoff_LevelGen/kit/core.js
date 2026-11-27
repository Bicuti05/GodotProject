// Sweet Rope rules for the Level Designer: a line-by-line port of the game's C# in Assets/_IEC/Script/Data/Board
// (BoardState.cs, MoveRules.cs, DeliverRules.cs, BoardSolver.cs, LevelValidator.cs). The game is the source of truth:
// change a rule there, then port it here and run `node dev/parity.js` (it replays the C# golden file, see HUONG_DAN.md).
'use strict';

(function (root) {
  const TYPE_COUNT = 10, MAX_ROPES = 8, CASCADE_GUARD = 40;
  const MIN_CAPACITY = 3, MAX_CAPACITY = 8, MAX_ORDERS = 14, LEVELS_PER_STAGE = 25;
  const DEFAULT_NODE_BUDGET = 60000;
  const NO_CONTAINER = -1;

  const itemState = it => it.state || 'Normal';
  const plain = it => ({ type: it.type, state: 'Normal' });

  // ---------------- BoardState ----------------

  function fromLevel(level, allowRopeSwap) {
    const s = {
      ropes: [], deliveredTypes: [], orderCount: level.orderCount,
      iceRule: level.iceRule || 'BlockDeliver', meltType: level.meltType == null ? -1 : level.meltType,
      allowRopeSwap: !!allowRopeSwap, extraRopeUsed: false, autoRevealLastOrder: false,
      reserve: level.reserveQueue || [], hasVariableCaps: false, baseCapacity: 1,
    };
    for (const d of level.ropes) {
      if (!(d.capacity > 0)) throw new Error('Rope capacity must be positive.');
      s.ropes.push({
        capacity: d.capacity,
        containerType: d.container ? d.container.type : NO_CONTAINER,
        containerFrozen: !!(d.container && d.container.frozen),
        removed: false,
        seal: (d.kind || 'Normal') === 'Locked' ? (d.seal || null) : null,
        items: (d.items || []).map(it => ({ type: it.type, state: itemState(it) })),
      });
    }
    computeHasVariableCaps(s);
    return s;
  }

  function clone(s) {
    return {
      ropes: s.ropes.map(r => ({ capacity: r.capacity, containerType: r.containerType, containerFrozen: r.containerFrozen, removed: r.removed, seal: r.seal, items: r.items.slice() })),
      deliveredTypes: s.deliveredTypes.slice(), orderCount: s.orderCount, iceRule: s.iceRule, meltType: s.meltType,
      allowRopeSwap: s.allowRopeSwap, extraRopeUsed: s.extraRopeUsed, autoRevealLastOrder: s.autoRevealLastOrder,
      reserve: s.reserve, hasVariableCaps: s.hasVariableCaps, baseCapacity: s.baseCapacity,
    };
  }

  const hasContainer = r => r.containerType >= 0;
  const isLocked = r => r.seal != null;
  const delivered = s => s.deliveredTypes.length;
  const isWin = s => delivered(s) >= s.orderCount;
  const isDoomed = s => !isWin(s) && maxOrdersLeft(s) < s.orderCount - delivered(s);
  const isDead = s => !isWin(s) && (!hasAnyMove(s) || isDoomed(s));
  const reserveEntry = (s, i) => i >= 0 && i < s.reserve.length ? s.reserve[i] : null;

  function move(s, src, j, dst) {
    const result = { success: false, src, j, dst, count: 0, deliveries: [], unlocked: [], revealed: [] };
    const c = check(s, src, j, dst);
    result.reason = c.reason;
    if (c.reason !== 'None') return result;
    result.success = true;
    result.count = c.count;
    if (isRopeSwap(s, src, j, dst)) {
      const t = s.ropes[src].items; s.ropes[src].items = s.ropes[dst].items; s.ropes[dst].items = t;
    } else {
      const from = s.ropes[src].items;
      s.ropes[dst].items.push(...from.slice(j, j + c.count));
      from.splice(j, c.count);
    }
    settle(s, result);
    return result;
  }

  function addExtraRope(s, capacity) {
    if (s.extraRopeUsed || capacity <= 0 || s.ropes.length >= MAX_ROPES) return -1;
    s.ropes.push({ capacity, containerType: NO_CONTAINER, containerFrozen: false, removed: false, seal: null, items: [] });
    s.extraRopeUsed = true;
    return s.ropes.length - 1;
  }

  function canAutoReveal(s) {
    if (!s.autoRevealLastOrder || isWin(s) || delivered(s) !== s.orderCount - 1) return false;
    return s.ropes.some(r => r.items.some(it => it.state === 'Hidden'));
  }

  function autoReveal(s) {
    const result = { success: false, deliveries: [], unlocked: [], revealed: [] };
    if (!canAutoReveal(s)) return result;
    result.success = true;
    s.ropes.forEach((r, ri) => r.items.forEach((it, i) => { if (it.state === 'Hidden') { r.items[i] = plain(it); result.revealed.push({ rope: ri, index: i }); } }));
    runDeliveries(s, result);
    if (result.deliveries.length) unlockPass(s, result);
    return result;
  }

  function maxOrdersLeft(s) {
    const total = new Array(TYPE_COUNT).fill(0);
    for (const r of s.ropes) for (const it of r.items) if (it.type >= 0 && it.type < TYPE_COUNT) total[it.type]++;
    for (let k = delivered(s); k < s.reserve.length; k++) for (const it of (s.reserve[k].refill || [])) if (it.type >= 0 && it.type < TYPE_COUNT) total[it.type]++;
    if (!s.hasVariableCaps) {
      let even = 0;
      for (let t = 0; t < TYPE_COUNT; t++) even += Math.floor(total[t] / s.baseCapacity);
      return even;
    }
    const containers = new Array(TYPE_COUNT).fill(0), minCap = new Array(TYPE_COUNT).fill(0);
    const add = (type, cap) => { if (type < 0 || type >= TYPE_COUNT) return; containers[type]++; minCap[type] = minCap[type] === 0 ? cap : Math.min(minCap[type], cap); };
    for (const r of s.ropes) { if (r.removed || !hasContainer(r)) continue; add(r.containerType, r.capacity); }
    for (let k = delivered(s); k < s.reserve.length; k++) if (s.reserve[k].mode === 'Container') add(s.reserve[k].container.type, s.reserve[k].capacity);
    let sum = 0;
    for (let t = 0; t < TYPE_COUNT; t++) { if (containers[t] <= 0 || minCap[t] <= 0) continue; sum += Math.min(containers[t], Math.floor(total[t] / minCap[t])); }
    return sum;
  }

  function computeHasVariableCaps(s) {
    let first = -1;
    for (const r of s.ropes) { if (first < 0) first = r.capacity; else if (r.capacity !== first) { s.hasVariableCaps = true; return; } }
    for (const e of s.reserve) {
      if (e.mode === 'Remove') continue;
      if (first < 0) first = e.capacity; else if (e.capacity !== first) { s.hasVariableCaps = true; return; }
    }
    s.baseCapacity = Math.max(1, first);
    s.hasVariableCaps = false;
  }

  // ---------------- MoveRules ----------------

  const isBlocked = (s, it) => it.state === 'Hidden' || (it.state === 'Ice' && s.iceRule === 'BlockMatch');
  const canConnect = (s, from, onto) => !isBlocked(s, from) && !isBlocked(s, onto) && from.type === onto.type;

  function isRopeSwap(s, src, j, dst) {
    if (!s.allowRopeSwap || j !== 0 || src === dst) return false;
    if (src < 0 || dst < 0 || src >= s.ropes.length || dst >= s.ropes.length) return false;
    const from = s.ropes[src].items, to = s.ropes[dst].items;
    if (!from.length || !to.length) return false;
    const can = from.length + to.length <= s.ropes[dst].capacity && canConnect(s, from[0], to[to.length - 1]);
    return !can;
  }

  function check(s, src, j, dst) {
    const ropes = s.ropes;
    if (src === dst || src < 0 || dst < 0 || src >= ropes.length || dst >= ropes.length) return { reason: 'Invalid', count: 0 };
    const from = ropes[src], to = ropes[dst];
    const k = from.items.length - j;
    if (j < 0 || k <= 0) return { reason: 'Invalid', count: 0 };
    if (isLocked(from) || isLocked(to)) return { reason: 'Locked', count: 0 };
    if (isRopeSwap(s, src, j, dst)) {
      const fits = !from.removed && !to.removed && from.items.length <= to.capacity && to.items.length <= from.capacity;
      return fits ? { reason: 'None', count: k } : { reason: 'Full', count: 0 };
    }
    if (to.items.length + k > to.capacity) return { reason: 'Full', count: 0 };
    const head = from.items[j];
    if (!to.items.length) return { reason: 'None', count: k };
    const top = to.items[to.items.length - 1];
    if (canConnect(s, head, top)) return { reason: 'None', count: k };
    if (head.state === 'Hidden') return { reason: 'Hidden', count: 0 };
    if (s.iceRule === 'BlockMatch' && (head.state === 'Ice' || top.state === 'Ice')) return { reason: 'Frozen', count: 0 };
    return { reason: 'Mismatch', count: 0 };
  }

  function hasAnyMove(s) {
    const ropes = s.ropes;
    if (s.allowRopeSwap) {
      for (let src = 0; src < ropes.length; src++)
        for (let j = 0; j < ropes[src].items.length; j++)
          for (let dst = 0; dst < ropes.length; dst++)
            if (check(s, src, j, dst).reason === 'None') return true;
      return false;
    }
    for (let i = 0; i < ropes.length; i++) {
      const from = ropes[i];
      if (isLocked(from) || !from.items.length) continue;
      for (let d = 0; d < ropes.length; d++) {
        const to = ropes[d];
        if (d === i || isLocked(to)) continue;
        const room = to.capacity - to.items.length;
        if (room <= 0) continue;
        if (!to.items.length) return true;
        const top = to.items[to.items.length - 1];
        if (isBlocked(s, top)) continue;
        for (let idx = from.items.length - 1; idx >= 0 && from.items.length - idx <= room; idx--)
          if (canConnect(s, from.items[idx], top)) return true;
      }
    }
    return false;
  }

  // ---------------- DeliverRules ----------------

  function settle(s, result) {
    runDeliveries(s, result);
    if (result.deliveries.length) unlockPass(s, result);
    revealTops(s, result);
  }

  function isReady(r) {
    if (isLocked(r) || r.containerFrozen || !hasContainer(r) || r.capacity <= 0 || r.items.length !== r.capacity) return false;
    return r.items.every(it => it.state === 'Normal' && it.type === r.containerType);
  }

  function runDeliveries(s, result) {
    let again = true, guard = 0;
    while (again && guard < CASCADE_GUARD) {
      guard++; again = false;
      for (let ci = 0; ci < s.ropes.length; ci++) {
        if (!isReady(s.ropes[ci])) continue;
        deliver(s, ci, result);
        again = true;
      }
    }
  }

  function deliver(s, ci, result) {
    const r = s.ropes[ci];
    const type = r.containerType;
    const evt = { rope: ci, type, orderIndex: delivered(s) };
    r.items = [];
    if (s.meltType >= 0 && type === s.meltType) melt(s);
    s.deliveredTypes.push(type);
    const entry = reserveEntry(s, evt.orderIndex);
    evt.mode = entry == null ? 'Remove' : entry.mode;
    if (evt.mode === 'Container') { r.containerType = entry.container.type; r.capacity = entry.capacity; }
    else if (evt.mode === 'Free') { r.containerType = NO_CONTAINER; r.capacity = entry.capacity; }
    else { r.containerType = NO_CONTAINER; r.capacity = 0; r.removed = true; }
    r.seal = null;
    if (entry != null && entry.refill) placeRefill(s, entry.refill, ci);
    result.deliveries.push(evt);
  }

  function melt(s) {
    for (const r of s.ropes) {
      if (r.containerFrozen) r.containerFrozen = false;
      r.items.forEach((it, i) => { if (it.state === 'Ice') r.items[i] = plain(it); });
    }
  }

  function placeRefill(s, refill, first) {
    const hasRoom = r => !isLocked(r) && r.items.length < r.capacity;
    for (const raw of refill) {
      const item = { type: raw.type, state: itemState(raw) };
      let target = -1;
      if (hasRoom(s.ropes[first])) target = first;
      else for (let i = 0; i < s.ropes.length; i++) if (i !== first && hasRoom(s.ropes[i])) { target = i; break; }
      if (target < 0) break;
      s.ropes[target].items.push(item);
    }
  }

  function unlockPass(s, result) {
    s.ropes.forEach((r, ci) => {
      if (r.seal == null || !isSealSatisfied(s, r.seal)) return;
      r.seal = null;
      result.unlocked.push(ci);
    });
  }

  function isSealSatisfied(s, seal) {
    if ((seal.rule || 'AnyDelivery') === 'AnyDelivery') return delivered(s) >= seal.count;
    return s.deliveredTypes.filter(t => t === (seal.type || 0)).length >= seal.count;
  }

  function revealTops(s, result) {
    s.ropes.forEach((r, ci) => {
      if (!r.items.length) return;
      const top = r.items.length - 1;
      if (r.items[top].state !== 'Hidden') return;
      r.items[top] = plain(r.items[top]);
      result.revealed.push({ rope: ci, index: top });
    });
  }

  // ---------------- BoardSolver ----------------

  function apply(s, m) {
    const result = move(s, m.src, m.j, m.dst);
    if (result.success && canAutoReveal(s)) autoReveal(s);
    return result;
  }

  function replay(start, moves) {
    const s = clone(start);
    for (const m of moves) if (!apply(s, m).success) return false;
    return isWin(s);
  }

  function equivalent(a, b) {
    return a.containerType === b.containerType && a.capacity === b.capacity && a.containerFrozen === b.containerFrozen && a.seal == null && b.seal == null;
  }

  function generateMoves(s) {
    const buffer = [], ropes = s.ropes;
    for (let src = 0; src < ropes.length; src++) {
      const from = ropes[src];
      if (isLocked(from) || from.removed || !from.items.length) continue;
      for (let dst = 0; dst < ropes.length; dst++) {
        if (dst === src) continue;
        const to = ropes[dst];
        if (isLocked(to) || to.removed) continue;
        const room = to.capacity - to.items.length;
        if (room <= 0 && !s.allowRopeSwap) continue;
        const fill = from.items.length - room;
        for (let j = 0; j < from.items.length; j++) {
          const runStart = j === 0 || from.items[j - 1].type !== from.items[j].type;
          if (!runStart && j !== fill) continue;
          if (j === 0 && !to.items.length && equivalent(from, to)) continue;
          if (check(s, src, j, dst).reason !== 'None') continue;
          buffer.push({ src, j, dst });
        }
      }
    }
    return buffer;
  }

  function score(s, depth) {
    let h = (s.orderCount - delivered(s)) * 20.0;
    for (const r of s.ropes) {
      if (r.removed) continue;
      let runs = 0, mismatched = 0;
      for (let i = 0; i < r.items.length; i++) {
        if (i === 0 || r.items[i - 1].type !== r.items[i].type) runs++;
        if (hasContainer(r) && (r.items[i].type !== r.containerType || r.items[i].state !== 'Normal')) mismatched++;
      }
      h += Math.max(0, runs - 1) * 2.0 + mismatched;
    }
    return h + depth * 0.05;
  }

  // An exact key instead of the C# 64-bit hash: same states, no collisions.
  function key(s) {
    const parts = s.ropes.map(r => r.capacity + ',' + r.containerType + ',' + (r.containerFrozen ? 1 : 0) + (r.removed ? 2 : 0) +
      (r.seal ? ',' + (r.seal.rule || 'AnyDelivery') + ':' + (r.seal.type || 0) + ':' + r.seal.count : '') + '|' +
      r.items.map(it => it.type * 3 + (it.state === 'Hidden' ? 1 : it.state === 'Ice' ? 2 : 0)).join('.'));
    const perType = new Array(TYPE_COUNT).fill(0);
    for (const t of s.deliveredTypes) perType[t]++;
    return parts.join('/') + '#' + delivered(s) + ':' + perType.join('.');
  }

  // Same binary heap as the C# MinHeap (ties included), so both searches visit nodes in the same order.
  class MinHeap {
    constructor() { this.items = []; }
    get count() { return this.items.length; }
    less(a, b) { return this.items[a][0] <= this.items[b][0]; }
    swap(a, b) { const t = this.items[a]; this.items[a] = this.items[b]; this.items[b] = t; }
    push(score, value) {
      this.items.push([score, value]);
      let i = this.items.length - 1;
      while (i > 0) { const p = (i - 1) >> 1; if (this.less(p, i)) break; this.swap(p, i); i = p; }
    }
    pop() {
      const top = this.items[0][1], last = this.items.length - 1;
      this.items[0] = this.items[last]; this.items.pop();
      let i = 0;
      for (;;) {
        const l = i * 2 + 1, r = l + 1;
        let m = i;
        if (l < this.items.length && !this.less(m, l)) m = l;
        if (r < this.items.length && !this.less(m, r)) m = r;
        if (m === i) break;
        this.swap(i, m); i = m;
      }
      return top;
    }
  }

  function solve(start, nodeBudget) {
    nodeBudget = nodeBudget || DEFAULT_NODE_BUDGET;
    const result = { status: 'Exhausted', nodes: 0, moves: [] };
    const rootState = clone(start);
    if (isWin(rootState)) { result.status = 'Solved'; return result; }
    const nodes = [{ state: rootState, parent: -1, move: null, depth: 0 }];
    const open = new MinHeap();
    const seen = new Set([key(rootState)]);
    open.push(score(rootState, 0), 0);
    while (open.count > 0) {
      if (result.nodes >= nodeBudget) { result.status = 'BudgetExceeded'; return result; }
      const index = open.pop();
      const node = nodes[index];
      const state = node.state;
      node.state = null;
      result.nodes++;
      for (const m of generateMoves(state)) {
        const next = clone(state);
        apply(next, m);
        if (isWin(next)) {
          for (let i = index; nodes[i].parent >= 0; i = nodes[i].parent) result.moves.push(nodes[i].move);
          result.moves.reverse();
          result.moves.push(m);
          result.status = 'Solved';
          return result;
        }
        if (isDead(next)) continue;
        const k = key(next);
        if (seen.has(k)) continue;
        seen.add(k);
        nodes.push({ state: next, parent: index, move: m, depth: node.depth + 1 });
        open.push(score(next, node.depth + 1), nodes.length - 1);
      }
    }
    result.status = 'Exhausted';
    return result;
  }

  function solveWithExtraRope(start, nodeBudget) {
    const copy = clone(start);
    const cap = Math.max(0, ...copy.ropes.map(r => r.capacity));
    if (addExtraRope(copy, cap) < 0) return { status: 'Exhausted', nodes: 0, moves: [] };
    return solve(copy, nodeBudget);
  }

  // ---------------- LevelValidator ----------------

  function validateLevel(level, isChallenge) {
    const report = { errors: [], warnings: [] };
    if (!level) { report.errors.push('level is null'); return report; }
    const checkCapacity = (cap, at) => { if (!(cap >= MIN_CAPACITY && cap <= MAX_CAPACITY)) report.errors.push(at + 'capacity ' + (cap || 0) + ' must be ' + MIN_CAPACITY + '-' + MAX_CAPACITY); };
    const checkType = (t, at) => { if (!(t >= 0 && t < TYPE_COUNT)) report.errors.push(at + ' type ' + t + ' must be 0-9'); };
    let hasIce = false, hasFrozen = false;
    const checkItems = (items, at) => { for (const it of items) { checkType(it.type, at + 'item'); if (it.state === 'Ice') hasIce = true; } };

    if (!isChallenge) {
      if (level.levelIndex < 1 || level.levelIndex > LEVELS_PER_STAGE) report.errors.push('levelIndex must be 1-25');
      if (!(level.difficulty >= 1 && level.difficulty <= 6)) report.errors.push('difficulty must be 1-6');
      if (((level.difficultyType || 'Normal') === 'Hard') !== (level.levelIndex % 5 === 0)) report.warnings.push('difficultyType Hard is expected exactly on levelIndex 5, 10, 15, 20, 25');
    }
    if (!(level.orderCount >= 1 && level.orderCount <= MAX_ORDERS)) report.errors.push('orderCount must be 1-' + MAX_ORDERS);
    if (!level.ropes || level.ropes.length < 1 || level.ropes.length > MAX_ROPES) { report.errors.push('ropes must have 1-' + MAX_ROPES + ' entries'); return report; }

    level.ropes.forEach((rope, i) => {
      const at = 'rope ' + i + ': ';
      checkCapacity(rope.capacity, at);
      if (!rope.items) { report.errors.push(at + 'items missing'); return; }
      if (rope.items.length > rope.capacity) report.errors.push(at + 'has more items than capacity');
      checkItems(rope.items, at);
      const kind = rope.kind || 'Normal';
      if (kind === 'Free') {
        if (rope.container) report.errors.push(at + 'Free rope must not have a container');
        if (rope.seal) report.errors.push(at + 'Free rope must not have a seal');
      } else if (kind === 'Normal') {
        if (!rope.container) report.errors.push(at + 'Normal rope needs a container');
        if (rope.seal) report.errors.push(at + 'Normal rope must not have a seal');
      } else if (kind === 'Locked') {
        if (!rope.seal) report.errors.push(at + 'Locked rope needs a seal');
        else {
          if (!(rope.seal.count >= 1)) report.errors.push(at + 'seal count must be at least 1');
          if (rope.seal.rule === 'TypedDelivery') checkType(rope.seal.type || 0, at + 'seal');
        }
      }
      if (rope.container) { checkType(rope.container.type, at + 'container'); if (rope.container.frozen) hasFrozen = true; }
    });

    const queue = level.reserveQueue || [];
    queue.forEach((e, k) => {
      const at = 'reserve ' + k + ': ';
      if (e.mode === 'Container') { if (!e.container) report.errors.push(at + 'Container entry needs a container'); else checkType(e.container.type, at + 'container'); }
      if (e.mode !== 'Remove') { checkCapacity(e.capacity, at); if (e.refill) checkItems(e.refill, at); }
    });
    if (queue.length > level.orderCount - 1) report.errors.push('reserveQueue is longer than orderCount - 1');

    if (hasIce && level.iceRule == null) report.errors.push('Ice Item needs iceRule');
    if ((level.iceRule != null || hasFrozen) && level.meltType == null) report.errors.push('iceRule / Frozen Container need meltType');
    if (level.meltType != null) checkType(level.meltType, 'meltType');

    if (!report.errors.length) {
      const containers = level.ropes.filter(r => r.container).length + queue.filter(e => e.mode === 'Container').length;
      if (containers < level.orderCount) report.errors.push('only ' + containers + ' containers for ' + level.orderCount + ' orders');
      const max = maxOrdersLeft(fromLevel(level));
      if (max < level.orderCount) report.errors.push('not enough items: at most ' + max + ' of ' + level.orderCount + ' orders');
    }
    return report;
  }

  root.SweetRopeCore = {
    TYPE_COUNT, MAX_ROPES, MIN_CAPACITY, MAX_CAPACITY, MAX_ORDERS, LEVELS_PER_STAGE, DEFAULT_NODE_BUDGET,
    fromLevel, clone, move, apply, replay, solve, solveWithExtraRope, addExtraRope, validateLevel, isWin, delivered,
  };
})(typeof module !== 'undefined' ? module.exports : window);
