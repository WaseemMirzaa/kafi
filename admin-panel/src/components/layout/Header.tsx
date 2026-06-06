import { useAuthStore } from '../../hooks/useAuth';

export default function Header() {
  const { user, logout } = useAuthStore();

  return (
    <header className="h-14 bg-white border-b border-gray-200 flex items-center justify-between px-6">
      <h1 className="text-lg font-bold text-td">Kafi Admin Panel</h1>
      <div className="flex items-center gap-4">
        <span className="text-sm text-tm">{user?.email}</span>
        <button
          onClick={logout}
          className="text-sm text-rose-dark hover:underline"
        >
          Logout
        </button>
      </div>
    </header>
  );
}
