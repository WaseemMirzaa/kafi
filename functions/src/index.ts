import * as admin from 'firebase-admin';
import { onNewMessage } from './triggers/chat';
import {
  onNewApplication,
  onTrialEnded,
  onTrialOffered,
  onTrialResponse,
} from './triggers/trial';
import { onDocumentReviewed, onNannySubmitted } from './triggers/nanny';
import {
  subscriptionExpiredEnforcer,
  subscriptionExpiringReminder,
  trialStartingReminder,
} from './triggers/scheduled';
import { revenueCatWebhook } from './triggers/webhook';
import { onBroadcastCreated } from './triggers/broadcast';
import { onUserDeleted } from './triggers/delete';

admin.initializeApp();

export {
  onNewMessage,
  onNewApplication,
  onTrialOffered,
  onTrialResponse,
  onTrialEnded,
  onDocumentReviewed,
  onNannySubmitted,
  subscriptionExpiredEnforcer,
  subscriptionExpiringReminder,
  trialStartingReminder,
  revenueCatWebhook,
  onBroadcastCreated,
  onUserDeleted,
};
