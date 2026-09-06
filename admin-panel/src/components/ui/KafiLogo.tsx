import logo from '../../assets/kafi-logo.png';

/** Same lockup as the mobile app (`kafi_app/assets/images/kafi-logo.png`). */
export function KafiLogo({
  height = 28,
  className,
}: {
  height?: number;
  className?: string;
}) {
  return (
    <img
      src={logo}
      alt="Kafi"
      height={height}
      className={className}
      style={{ height, width: 'auto' }}
    />
  );
}
