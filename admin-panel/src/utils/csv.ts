export interface CsvColumn<T> {
  header: string;
  value: (row: T) => string | number | undefined | null;
}

function escape(v: unknown): string {
  if (v === null || v === undefined) return '';
  const s = String(v);
  if (s.includes(',') || s.includes('"') || s.includes('\n')) {
    return `"${s.replace(/"/g, '""')}"`;
  }
  return s;
}

export function exportCsv<T>(filename: string, rows: T[], cols: CsvColumn<T>[]) {
  const head = cols.map((c) => escape(c.header)).join(',');
  const body = rows.map((r) => cols.map((c) => escape(c.value(r))).join(',')).join('\n');
  const csv = `${head}\n${body}`;
  const blob = new Blob([csv], { type: 'text/csv;charset=utf-8' });
  const url = URL.createObjectURL(blob);
  const a = document.createElement('a');
  a.href = url;
  a.download = filename;
  document.body.appendChild(a);
  a.click();
  document.body.removeChild(a);
  URL.revokeObjectURL(url);
}
