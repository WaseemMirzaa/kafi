import { AppConfig } from '../config/app';
import { t } from '../locales/t';

export type BootstrapAdminResult =
  | { created: true; email: string; password: string; uid?: string; message?: string }
  | { created: false; email?: string; message?: string };

function bootstrapUrl(): string {
  const explicit = import.meta.env.VITE_BOOTSTRAP_ADMIN_URL as string | undefined;
  if (explicit?.trim()) return explicit.trim();

  const projectId = import.meta.env.VITE_FIREBASE_PROJECT_ID as string | undefined;
  if (!projectId) {
    throw new Error(t('login.projectIdNotSet'));
  }
  return `https://us-central1-${projectId}.cloudfunctions.net/bootstrapFirstAdmin`;
}

/** Calls the Cloud Function once; only succeeds when no admin exists yet. */
export async function bootstrapFirstAdminIfNeeded(): Promise<BootstrapAdminResult> {
  if (AppConfig.useMock) {
    return { created: false, message: t('login.mockModeMessage') };
  }

  const res = await fetch(bootstrapUrl(), {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: '{}',
  });

  const data = (await res.json()) as BootstrapAdminResult & {
    password?: string;
    error?: string;
  };

  if (res.status === 201 && data.created && data.email && data.password) {
    return {
      created: true,
      email: data.email,
      password: data.password,
      uid: data.uid,
      message: data.message,
    };
  }

  if (res.status === 409) {
    return { created: false, email: data.email, message: data.message };
  }

  throw new Error(data.message || data.error || t('login.bootstrapFailed', { status: res.status }));
}
