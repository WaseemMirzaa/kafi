import * as admin from 'firebase-admin';
import { onNewMessage } from './triggers/chat';
import {
  onNewApplication,
  onTrialEnded,
  onTrialOffered,
  onTrialResponse,
} from './triggers/trial';
import { onDocumentReviewed } from './triggers/nanny';
import {
  subscriptionExpiredEnforcer,
  subscriptionExpiringReminder,
  trialStartingReminder,
} from './triggers/scheduled';
import { revenueCatWebhook } from './triggers/webhook';
import { onBroadcastCreated } from './triggers/broadcast';
import { onUserDeleted } from './triggers/delete';
import { translateNanny, translateFamily, translateJob } from './triggers/translate';

admin.initializeApp();

export {
  onNewMessage,
  onNewApplication,
  onTrialOffered,
  onTrialResponse,
  onTrialEnded,
  onDocumentReviewed,
  subscriptionExpiredEnforcer,
  subscriptionExpiringReminder,
  trialStartingReminder,
  revenueCatWebhook,
  onBroadcastCreated,
  onUserDeleted,
  translateNanny,
  translateFamily,
  translateJob,
};
