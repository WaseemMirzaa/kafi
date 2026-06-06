interface StatCardProps {
  label: string;
  value: string | number;
  icon: string;
  color?: 'rose' | 'purple' | 'green' | 'amber';
}

const colors = {
  rose: 'bg-rose-pale border-rose-light',
  purple: 'bg-purple-light border-purple',
  green: 'bg-green-light border-green',
  amber: 'bg-amber-light border-amber',
};

export default function StatCard({ label, value, icon, color = 'rose' }: StatCardProps) {
  return (
    <div className={`rounded-xl border-2 p-4 ${colors[color]}`}>
      <div className="flex items-center gap-3">
        <span className="text-2xl">{icon}</span>
        <div>
          <div className="text-2xl font-bold text-td">{value}</div>
          <div className="text-xs text-tm font-medium">{label}</div>
        </div>
      </div>
    </div>
  );
}
