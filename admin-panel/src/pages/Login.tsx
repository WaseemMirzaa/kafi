import { useEffect, useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { AppConfig } from '../config/app';
import { useAuthStore } from '../hooks/useAuth';
import { bootstrapFirstAdminIfNeeded } from '../services/bootstrapAdmin';

export default function Login() {
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [bootstrapping, setBootstrapping] = useState(false);
  const [bootstrapError, setBootstrapError] = useState<string | null>(null);
  const [bootstrapCreds, setBootstrapCreds] = useState<{
    email: string;
    password: string;
  } | null>(null);
  const { login, loading, error } = useAuthStore();
  const navigate = useNavigate();

  useEffect(() => {
    if (AppConfig.useMock) return;

    let cancelled = false;
    (async () => {
      setBootstrapping(true);
      setBootstrapError(null);
      try {
        const result = await bootstrapFirstAdminIfNeeded();
        if (cancelled) return;
        if (result.created && result.email && result.password) {
          setBootstrapCreds({ email: result.email, password: result.password });
          setEmail(result.email);
          setPassword(result.password);
        }
      } catch (e) {
        if (!cancelled) {
          setBootstrapError((e as Error).message);
        }
      } finally {
        if (!cancelled) setBootstrapping(false);
      }
    })();

    return () => {
      cancelled = true;
    };
  }, []);

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
        <LoginForm
          email={email}
          setEmail={setEmail}
          password={password}
          setPassword={setPassword}
          bootstrapping={bootstrapping}
          bootstrapError={bootstrapError}
          bootstrapCreds={bootstrapCreds}
          loading={loading}
          error={error}
          onSubmit={handleSubmit}
        />
      </div>
    </div>
  );
}

function LoginForm({
  email,
  setEmail,
  password,
  setPassword,
  bootstrapping,
  bootstrapError,
  bootstrapCreds,
  loading,
  error,
  onSubmit,
}: {
  email: string;
  setEmail: (v: string) => void;
  password: string;
  setPassword: (v: string) => void;
  bootstrapping: boolean;
  bootstrapError: string | null;
  bootstrapCreds: { email: string; password: string } | null;
  loading: boolean;
  error: string | null;
  onSubmit: (e: React.FormEvent) => void;
}) {
  return (
    <>
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

      {bootstrapping && (
        <p className="text-[9px] font-semibold text-[#8090B0] text-center mb-3">
          Checking for first-time admin setup…
        </p>
      )}

      {bootstrapCreds && (
        <div className="mb-4 p-3 rounded-lg bg-[#FFF0F5] border border-[#FFD6E5]">
          <p className="text-[9px] font-black text-navy mb-1">First admin created</p>
          <p className="text-[8px] font-semibold text-[#5A6480] mb-2">
            Save these credentials — shown once on first setup.
          </p>
          <p className="text-[9px] font-bold text-navy">
            Email: <span className="font-mono">{bootstrapCreds.email}</span>
          </p>
          <p className="text-[9px] font-bold text-navy">
            Password: <span className="font-mono">{bootstrapCreds.password}</span>
          </p>
        </div>
      )}

      {bootstrapError && (
        <p className="text-[9px] font-bold text-rose-dark mb-3 text-center">{bootstrapError}</p>
      )}

      <form onSubmit={onSubmit} className="space-y-3">
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
    </>
  );
}
