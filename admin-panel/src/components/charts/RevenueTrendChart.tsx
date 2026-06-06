import {
  Area,
  AreaChart,
  CartesianGrid,
  ResponsiveContainer,
  Tooltip,
  TooltipProps,
  XAxis,
  YAxis,
} from 'recharts';

export interface TrendPoint {
  label: string;  // bucket label, e.g. "07/06" (daily) or "Jun 2026" (monthly)
  amount: number; // AED total for the bucket
  pct: number;    // 0..100 (already computed by buildRangeTrend; unused by chart but kept for shape parity)
}

export interface RevenueTrendChartProps {
  data: TrendPoint[];
  /** Bucket granularity, used only to thin X-axis labels. */
  mode: 'daily' | 'monthly';
}

/** Compact AED Y-axis formatter: 1000 → "1k", 1500 → "1.5k", 800 → "800". */
function compactAed(v: number): string {
  if (v >= 1000) {
    return `${(v / 1000).toFixed(v % 1000 === 0 ? 0 : 1)}k`;
  }
  return String(v);
}

/** Custom tooltip matching the app's design tokens. */
function TrendTooltip({ active, payload, label }: TooltipProps<number, string>) {
  if (!active || !payload || payload.length === 0) return null;
  const amount = payload[0].value ?? 0;
  return (
    <div className="rounded-lg border border-[#EBEEF8] bg-white px-2 py-1 shadow-sm">
      <div className="text-[8px] font-bold text-[#8090B0]">{label}</div>
      <div className="text-[10px] font-extrabold text-navy">
        AED {Number(amount).toLocaleString()}
      </div>
    </div>
  );
}

/**
 * Presentational Recharts area chart for revenue trend data.
 * Receives pre-bucketed data from Revenue.tsx's buildRangeTrend — owns zero data logic.
 */
export default function RevenueTrendChart({ data, mode: _mode }: RevenueTrendChartProps) {
  // Thin X-axis labels on long ranges: guarantees ≤ ~12 visible ticks, no overflow.
  const xAxisInterval = data.length > 14 ? Math.ceil(data.length / 12) - 1 : 0;

  return (
    <div className="h-40 w-full">
      <ResponsiveContainer width="100%" height="100%">
        <AreaChart data={data} margin={{ top: 8, right: 8, left: -8, bottom: 0 }}>
          <defs>
            <linearGradient id="revTrendFill" x1="0" y1="0" x2="0" y2="1">
              <stop offset="0%" stopColor="#FF5C8A" stopOpacity={0.35} />
              <stop offset="100%" stopColor="#FF8FAB" stopOpacity={0} />
            </linearGradient>
          </defs>
          <CartesianGrid vertical={false} stroke="#EBEEF8" strokeDasharray="3 3" />
          <XAxis
            dataKey="label"
            tick={{ fontSize: 8, fill: '#8090B0' }}
            tickLine={false}
            axisLine={{ stroke: '#EBEEF8' }}
            interval={xAxisInterval}
            minTickGap={8}
          />
          <YAxis
            tick={{ fontSize: 8, fill: '#8090B0' }}
            tickLine={false}
            axisLine={false}
            width={34}
            tickFormatter={compactAed}
          />
          <Tooltip content={<TrendTooltip />} cursor={{ stroke: '#EBEEF8' }} />
          <Area
            type="monotone"
            dataKey="amount"
            stroke="#FF5C8A"
            strokeWidth={2}
            fill="url(#revTrendFill)"
            dot={false}
            activeDot={{ r: 3, fill: '#FF5C8A' }}
            isAnimationActive={false}
          />
        </AreaChart>
      </ResponsiveContainer>
    </div>
  );
}
