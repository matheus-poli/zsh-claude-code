// Summarizes a `scripts/bench.zsh` run: medians per model and feature, plus
// one sample reply per model for each prompt so quality can be eyeballed.
// Usage: node scripts/bench-report.mjs <bench_dir>
import { readFileSync } from 'node:fs';
import { join } from 'node:path';

const dir = process.argv[2];
const rows = readFileSync(join(dir, 'index.tsv'), 'utf8')
  .trim()
  .split('\n')
  .map((line, i) => {
    const [model, feature, c, rc, wallMs] = line.split('\t');
    return { i, model, feature, c: Number(c), rc: Number(rc), wallMs: Number(wallMs) };
  });

// index.tsv rows are in call order; JSON files are named by round, case, model.
const seen = {};
for (const row of rows) {
  const key = `${row.c}-${row.model}`;
  seen[key] = (seen[key] ?? 0) + 1;
  let data = null;
  try {
    data = JSON.parse(readFileSync(join(dir, `r${seen[key]}-c${row.c}-${row.model}.json`), 'utf8'));
  } catch {}
  row.ok = row.rc === 0 && data && !data.is_error;
  if (row.ok) {
    const u = data.usage;
    row.inTok = u.input_tokens + u.cache_read_input_tokens + u.cache_creation_input_tokens;
    row.outTok = u.output_tokens;
    row.apiMs = data.duration_api_ms;
    row.cost = data.total_cost_usd;
    row.result = data.result;
  }
}

const median = (xs) => {
  const s = [...xs].sort((a, b) => a - b);
  const m = s.length >> 1;
  return s.length % 2 ? s[m] : (s[m - 1] + s[m]) / 2;
};

const models = [...new Set(rows.map((r) => r.model))];
const features = [...new Set(rows.map((r) => r.feature))];

const header = ['model', 'feature', 'ok', 'wall ms', 'api ms', 'in tok', 'out tok', 'cost/call'];
const table = [header];
for (const feature of features) {
  for (const model of models) {
    const all = rows.filter((r) => r.model === model && r.feature === feature);
    const ok = all.filter((r) => r.ok);
    if (!ok.length) {
      table.push([model, feature, `0/${all.length}`, '-', '-', '-', '-', '-']);
      continue;
    }
    table.push([
      model,
      feature,
      `${ok.length}/${all.length}`,
      median(ok.map((r) => r.wallMs)).toFixed(0),
      median(ok.map((r) => r.apiMs)).toFixed(0),
      median(ok.map((r) => r.inTok)).toFixed(0),
      median(ok.map((r) => r.outTok)).toFixed(0),
      `$${(ok.reduce((s, r) => s + r.cost, 0) / ok.length).toFixed(5)}`,
    ]);
  }
}

const widths = header.map((_, col) => Math.max(...table.map((row) => row[col].length)));
console.log('\nMedians per model and feature (cost is the mean)\n');
for (const row of table) {
  console.log(row.map((cell, col) => (col < 2 ? cell.padEnd(widths[col]) : cell.padStart(widths[col]))).join('  '));
}

console.log('\nSample replies (first round)\n');
for (const c of [...new Set(rows.map((r) => r.c))]) {
  const first = rows.filter((r) => r.c === c && r.ok);
  if (!first.length) continue;
  console.log(`[${first[0].feature} #${c}]`);
  for (const model of models) {
    const row = first.find((r) => r.model === model);
    if (row) console.log(`  ${model.padEnd(7)} ${row.result.replace(/\s+/g, ' ').slice(0, 160)}`);
  }
}
