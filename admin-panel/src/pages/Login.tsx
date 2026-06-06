import { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { useAuthStore } from '../hooks/useAuth';

export default function Login() {
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const { login, loading, error } = useAuthStore();
  const navigate = useNavigate();

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    try {
      await login(email, password);
      navigate('/');
    } catch {
      // error handled in store
    }
  };

  return (
    <div className="min-h-screen flex items-center justify-center admin-main-bg px-4">
      <div className="admin-card p-6 w-full max-w-sm">
        <div className="flex items-center justify-center gap-1.5 mb-5">
          <svg width="22" height="22" viewBox="0 0 34 34" aria-hidden>
            <ellipse cx="17" cy="9" rx="6" ry="10" fill="#FF8FAB" opacity="0.8" />
            <ellipse cx="17" cy="9" rx="6" ry="10" fill="#FF8FAB" opacity="0.7" transform="rotate(60 17 17)" />
            <ellipse cx="17" cy="9" rx="6" ry="10" fill="#FF8FAB" opacity="0.7" transform="rotate(120 17 17)" />
            <circle cx="17" cy="17" r="4.5" fill="#FF8FAB" />
          </svg>
          <span className="font-pacifico text-[18px] text-rose-dark">Kafi</span>
          <span className="text-[8px] bg-navy text-white px-1.5 py-0.5 rounded-full font-fredoka font-bold">ADMIN</span>
        </div>
        <h1 className="text-base font-black text-navy text-center mb-5">Admin login</h1>
        <form onSubmit={handleSubmit} className="space-y-3">
          <div>
            <label className="block text-[8px] font-bold text-[#8090B0] uppercase tracking-wide mb-1">Email</label>
            <input
              type="email"
              value={email}
              onChange={(e) => setEmail(e.target.value)}
              className="w-full admin-card text-[10px] font-semibold text-navy px-3 py-2 border-[#EBEEF8] focus:outline-none focus:ring-1 focus:ring-rose-dark/30"
              required
            />
          </div>
          <div>
            <label className="block text-[8px] font-bold text-[#8090B0] uppercase tracking-wide mb-1">Password</label>
            <input
              type="password"
              value={password}
              onChange={(e) => setPassword(e.target.value)}
              className="w-full admin-card text-[10px] font-semibold text-navy px-3 py-2 border-[#EBEEF8] focus:outline-none focus:ring-1 focus:ring-rose-dark/30"
              required
            />
          </div>
          {error && <p className="text-[9px] font-bold text-rose-dark">{error}</p>}
          <button type="submit" disabled={loading} className="w-full qa-btn qa-r justify-center mt-2 disabled:opacity-50">
            {loading ? 'Signing in...' : 'Sign in'}
          </button>
        </form>
      </div>
    </div>
  );
}
