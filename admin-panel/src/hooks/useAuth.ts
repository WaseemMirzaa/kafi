import { create } from 'zustand';
import {
  signInWithEmailAndPassword,
  signOut,
  onAuthStateChanged,
  User as FbUser,
} from 'firebase/auth';
import { AppConfig } from '../config/app';
import { auth } from '../config/firebase';

interface AdminUser {
  uid: string;
  email: string;
  displayName: string;
  isAdmin: boolean;
}

interface AuthState {
  user: AdminUser | null;
  loading: boolean;
  error: string | null;
  init: () => () => void;
  login: (email: string, password: string) => Promise<void>;
  logout: () => Promise<void>;
}

const STORAGE_KEY = 'kafi_admin_user';

function readCached(): AdminUser | null {
  try {
    const raw = localStorage.getItem(STORAGE_KEY);
    return raw ? (JSON.parse(raw) as AdminUser) : null;
  } catch {
    localStorage.removeItem(STORAGE_KEY);
    return null;
  }
}

async function toAdminUser(fb: FbUser): Promise<AdminUser> {
  const token = await fb.getIdTokenResult(true);
  const isAdmin = token.claims.admin === true;
  return {
    uid: fb.uid,
    email: fb.email ?? '',
    displayName: fb.displayName ?? fb.email ?? 'Admin',
    isAdmin,
  };
}

export const useAuthStore = create<AuthState>((set) => ({
  // Hydrate from cache so reloads don't flash the login screen, but treat
  // cached user as provisional until Firebase confirms.
  user: readCached(),
  loading: !AppConfig.useMock && !!auth,
  error: null,

  init: () => {
    if (AppConfig.useMock || !auth) {
      set({ loading: false });
      return () => {};
    }
    const authInstance = auth;
    return onAuthStateChanged(authInstance, async (fb) => {
      if (!fb) {
        localStorage.removeItem(STORAGE_KEY);
        set({ user: null, loading: false });
        return;
      }
      try {
        const u = await toAdminUser(fb);
        if (!u.isAdmin) {
          await signOut(authInstance);
          set({ user: null, loading: false, error: 'Not an admin account' });
          return;
        }
        localStorage.setItem(STORAGE_KEY, JSON.stringify(u));
        set({ user: u, loading: false });
      } catch (e) {
        set({ error: (e as Error).message, loading: false });
      }
    });
  },

  login: async (email, password) => {
    set({ loading: true, error: null });
    await new Promise((r) => setTimeout(r, 300));

    if (AppConfig.useMock || !auth) {
      if (email === AppConfig.mockAdminEmail && password === AppConfig.mockAdminPassword) {
        const mockUser: AdminUser = {
          uid: 'admin_001',
          email,
          displayName: 'Kafi Admin',
          isAdmin: true,
        };
        localStorage.setItem(STORAGE_KEY, JSON.stringify(mockUser));
        set({ user: mockUser, loading: false });
        return;
      }
      set({ error: 'Invalid email or password', loading: false });
      throw new Error('Invalid credentials');
    }

    try {
      const cred = await signInWithEmailAndPassword(auth, email, password);
      const u = await toAdminUser(cred.user);
      if (!u.isAdmin) {
        await signOut(auth);
        set({ error: 'This account is not an admin', loading: false });
        throw new Error('not_admin');
      }
      localStorage.setItem(STORAGE_KEY, JSON.stringify(u));
      set({ user: u, loading: false });
    } catch (e) {
      const msg = (e as Error).message || 'Login failed';
      set({ error: msg, loading: false });
      throw e;
    }
  },

  logout: async () => {
    if (!AppConfig.useMock && auth) {
      await signOut(auth);
    }
    localStorage.removeItem(STORAGE_KEY);
    set({ user: null });
  },
}));
