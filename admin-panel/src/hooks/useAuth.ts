import { create } from 'zustand';
import {
  signInWithEmailAndPassword,
  signOut,
  onAuthStateChanged,
  User as FbUser,
} from 'firebase/auth';
import { doc, getDoc, serverTimestamp, updateDoc } from 'firebase/firestore';
import { AppConfig } from '../config/app';
import { auth, db } from '../config/firebase';
import { t } from '../locales/t';

interface AdminUser {
  uid: string;
  email: string;
  displayName: string;
  isAdmin: boolean;
  role?: string;
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
  let isAdmin = token.claims.admin === true;
  let role = typeof token.claims.role === 'string' ? (token.claims.role as string) : undefined;

  // Firestore is the source of truth for admin accounts: an `admins/{uid}`
  // record must exist. The custom claim is still what Firestore/Storage rules
  // check for writes, so a real admin has both (seeded by scripts/create-admin).
  if (db) {
    try {
      const ref = doc(db, 'admins', fb.uid);
      const snap = await getDoc(ref);
      if (snap.exists()) {
        isAdmin = true;
        role = (snap.data().role as string) ?? role;
        // Best-effort last-login audit stamp; never blocks login.
        void updateDoc(ref, { lastLoginAt: serverTimestamp() }).catch(() => {});
      } else {
        // No admin record → not an admin, regardless of a stale claim.
        isAdmin = false;
      }
    } catch {
      // Firestore unreachable — fall back to the custom-claim result.
    }
  }

  return {
    uid: fb.uid,
    email: fb.email ?? '',
    displayName: fb.displayName ?? fb.email ?? 'Admin',
    isAdmin,
    role,
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
          set({ user: null, loading: false, error: t('login.notAdminAccount') });
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
      set({ error: t('login.invalidCredentials'), loading: false });
      throw new Error('Invalid credentials');
    }

    try {
      const cred = await signInWithEmailAndPassword(auth, email, password);
      const u = await toAdminUser(cred.user);
      if (!u.isAdmin) {
        await signOut(auth);
        set({ error: t('login.thisAccountNotAdmin'), loading: false });
        throw new Error('not_admin');
      }
      localStorage.setItem(STORAGE_KEY, JSON.stringify(u));
      set({ user: u, loading: false });
    } catch (e) {
      // 'not_admin' is our own sentinel from above — the translated message
      // is already set, so re-throwing here must not clobber it with the raw
      // (untranslated) sentinel text.
      if ((e as Error).message !== 'not_admin') {
        set({ error: (e as Error).message || t('login.loginFailed'), loading: false });
      } else {
        set({ loading: false });
      }
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
