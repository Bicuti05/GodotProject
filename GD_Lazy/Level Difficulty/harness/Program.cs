// usage: harness pack.json [nodeBudget] [moves.json]
// moves.json (optional): one list of [src, j, dst] per level. A level whose list replays to a win through the
// game's own rules counts as Solved (status Replayed); otherwise the game's BoardSolver searches.
// Output: one line per level: index|validator errors|status|moves
using System;
using System.Collections.Generic;
using System.IO;
using IEC;
using Newtonsoft.Json;

var pack = LevelJson.FromJson<LevelPackFile>(File.ReadAllText(args[0]));
int budget = args.Length > 1 ? int.Parse(args[1]) : 200000;
var lines = args.Length > 2 ? JsonConvert.DeserializeObject<List<List<int[]>>>(File.ReadAllText(args[2])) : null;
int i = 0;
foreach (var stage in pack.stages)
    foreach (var level in stage.levels)
    {
        var report = LevelValidator.ValidateLevel(level);
        var status = "NotRun"; var moves = 0;
        if (report.errors.Count == 0)
        {
            var line = lines != null && i < lines.Count ? lines[i] : null;
            var path = new List<SolverMove>();
            if (line != null) foreach (var m in line) path.Add(new SolverMove { src = m[0], j = m[1], dst = m[2] });
            if (path.Count > 0 && BoardSolver.Replay(BoardState.FromLevel(level), path)) { status = "Replayed"; moves = path.Count; }
            else
            {
                var result = BoardSolver.Solve(BoardState.FromLevel(level), budget);
                status = result.status.ToString(); moves = result.moves.Count;
            }
        }
        Console.WriteLine($"{i++}|{string.Join("; ", report.errors)}|{status}|{moves}");
    }
