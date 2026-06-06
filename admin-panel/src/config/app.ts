/// Admin panel runtime configuration.
/// Per System Spec §11.5 — production builds MUST default `useMock` to false
/// and read it from the `VITE_USE_MOCK` env var at build time.
const envFlag = (import.meta as any).env?.VITE_USE_MOCK;

export const AppConfig = {
  useMock: envFlag === undefined ? import.meta.env.DEV : envFlag === 'true',
  mockAdminEmail: 'admin@kafi.ae',
  mockAdminPassword: 'admin123',
};
