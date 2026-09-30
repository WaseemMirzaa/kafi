import { onRequest } from 'firebase-functions/v2/https';
import { ensureFirstAdmin } from './utils/ensureFirstAdmin';
import { resolveLocaleFromHeader, tn } from './i18n/notifications';

/** One-time HTTPS bootstrap — only creates an admin when `admins` is empty. */
export const bootstrapFirstAdmin = onRequest(
  { cors: true, invoker: 'public' },
  async (req, res) => {
    if (req.method === 'OPTIONS') {
      res.status(204).send('');
      return;
    }
    if (req.method !== 'POST') {
      res.status(405).json({ error: 'method_not_allowed' });
      return;
    }

    // No admin/user doc exists yet at this point in the flow, so there is no
    // Firestore locale preference to read — fall back to the browser's
    // Accept-Language (the admin panel's own fetch call carries it).
    const locale = resolveLocaleFromHeader(req.headers['accept-language']);

    try {
      const result = await ensureFirstAdmin(locale);
      if (!result.created) {
        res.status(409).json({
          created: false,
          message: tn('error.adminAlreadyExists', locale),
          email: result.email,
        });
        return;
      }

      res.status(201).json({
        created: true,
        message: tn('error.firstAdminCreated', locale),
        email: result.email,
        password: result.password,
        uid: result.uid,
      });
    } catch (err) {
      console.error('[bootstrapFirstAdmin]', err);
      res.status(500).json({
        error: 'bootstrap_failed',
        message: err instanceof Error ? err.message : tn('error.unknownError', locale),
      });
    }
  },
);
