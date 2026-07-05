import { onDocumentWritten } from 'firebase-functions/v2/firestore';
import {
  computeTranslationUpdates,
  googleProvider,
  FAMILY_TX,
  JOB_TX,
  NANNY_TX,
  TranslateConfig,
  TranslationProvider,
} from '../utils/translate';

// One provider per instance (reused across invocations).
let _provider: TranslationProvider | null = null;
const provider = (): TranslationProvider => (_provider ??= googleProvider());

/**
 * Builds an onWrite trigger that keeps a doc's `<field>_i18n` translation maps
 * in sync with its source free-text fields — on create and on every edit.
 * Writes back with merge, and is loop-safe (see computeTranslationUpdates).
 */
function translator(path: string, cfg: TranslateConfig) {
  return onDocumentWritten(path, async (event) => {
    const after = event.data?.after;
    if (!after?.exists) return; // deleted → nothing to translate

    const updates = await computeTranslationUpdates(
      event.data?.before?.data(),
      after.data() as Record<string, unknown>,
      cfg,
      provider(),
    );

    if (Object.keys(updates).length > 0) {
      await after.ref.set(updates, { merge: true });
    }
  });
}

/** Translate nanny bio / health / religious notes → en+ar. */
export const translateNanny = translator('nannies/{nannyId}', NANNY_TX);

/** Translate family "about" / house rules → en+ar. */
export const translateFamily = translator('families/{familyId}', FAMILY_TX);

/** Translate job title / schedule / additional notes → en+ar. */
export const translateJob = translator('jobs/{jobId}', JOB_TX);
