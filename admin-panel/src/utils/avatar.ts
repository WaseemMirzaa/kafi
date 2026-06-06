const gradients = [
  'linear-gradient(135deg,#FF8FAB,#FF5C8A)',
  'linear-gradient(135deg,#9B6EDB,#C084FC)',
  'linear-gradient(135deg,#FFB347,#FF8042)',
  'linear-gradient(135deg,#6DBF8A,#3DAA65)',
  'linear-gradient(135deg,#3ABFBF,#0EA5A0)',
];

export function initials(name: string): string {
  const parts = name.trim().split(/\s+/);
  if (parts.length === 0 || !parts[0]) return '?';
  if (parts.length === 1) return parts[0][0]!.toUpperCase();
  return (parts[0][0] + parts[parts.length - 1][0]).toUpperCase();
}

export function gradientFor(id: string): string {
  let h = 0;
  for (let i = 0; i < id.length; i++) h = (h * 31 + id.charCodeAt(i)) % gradients.length;
  return gradients[Math.abs(h)];
}
