import { onRequest } from 'firebase-functions/v2/https';
import { ensureFirstAdmin } from './utils/ensureFirstAdmin';

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

    try {
      const result = await ensureFirstAdmin();
      if (!result.created) {
        res.status(409).json({
          created: false,
          message: 'An admin account already exists.',
          email: result.email,
        });
        return;
      }

      res.status(201).json({
        created: true,
        message:
          'First admin created. Sign in with the credentials below and change the password in Firebase Console.',
        email: result.email,
        password: result.password,
        uid: result.uid,
      });
    } catch (err) {
      console.error('[bootstrapFirstAdmin]', err);
      res.status(500).json({
        error: 'bootstrap_failed',
        message: err instanceof Error ? err.message : 'Unknown error',
      });
    }
  },
);
