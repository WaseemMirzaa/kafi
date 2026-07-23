import { initializeApp, FirebaseApp } from 'firebase/app';
import { Auth, getAuth } from 'firebase/auth';
import { Firestore, getFirestore } from 'firebase/firestore';
import { FirebaseStorage, getStorage } from 'firebase/storage';
import { AppConfig } from './app';

const firebaseConfig = {
  apiKey: import.meta.env.VITE_FIREBASE_API_KEY || 'mock-api-key',
  authDomain: import.meta.env.VITE_FIREBASE_AUTH_DOMAIN || 'mock.firebaseapp.com',
  projectId: import.meta.env.VITE_FIREBASE_PROJECT_ID || 'kafi-mock',
  storageBucket: import.meta.env.VITE_FIREBASE_STORAGE_BUCKET || 'mock.appspot.com',
  messagingSenderId: import.meta.env.VITE_FIREBASE_MESSAGING_SENDER_ID || '000000000',
  appId: import.meta.env.VITE_FIREBASE_APP_ID || '1:000:web:mock',
};

let app: FirebaseApp | null = null;
let auth: Auth | null = null;
let db: Firestore | null = null;
let storage: FirebaseStorage | null = null;

if (!AppConfig.useMock) {
  // Fail fast on a misconfigured live deploy. Without this, the placeholder
  // 'mock-api-key'/'kafi-mock' fallbacks above let initializeApp succeed against
  // a nonexistent project, so every query silently fails and the panel "looks
  // up" but never loads.
  const env = import.meta.env as Record<string, string | undefined>;
  const missing = [
    'VITE_FIREBASE_API_KEY',
    'VITE_FIREBASE_AUTH_DOMAIN',
    'VITE_FIREBASE_PROJECT_ID',
    'VITE_FIREBASE_APP_ID',
  ].filter((k) => !env[k]);
  if (missing.length) {
    throw new Error(
      `Firebase env vars missing in live mode: ${missing.join(', ')}. ` +
        'Set them or enable mock mode (VITE_USE_MOCK=true).',
    );
  }
  app = initializeApp(firebaseConfig);
  auth = getAuth(app);
  db = getFirestore(app);
  storage = getStorage(app);
}

export { auth, db, storage };
export default app;
