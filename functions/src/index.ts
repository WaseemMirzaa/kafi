import * as admin from 'firebase-admin';
import { onNewMessage } from './triggers/chat';
import { onNewTicketMessage, onTicketStatusChanged } from './triggers/ticket';
import { onNewDisputeMessage, onDisputeResolved } from './triggers/dispute';
import {
  onNewApplication,
  onApplicationUpdated,
  onTrialEnded,
  onTrialOffered,
  onTrialOutcomeResolved,
  onTrialResponse,
} from './triggers/trial';
import { onDocumentReviewed } from './triggers/nanny';
import {
  subscriptionExpiredEnforcer,
  subscriptionExpiringReminder,
  trialOutcomeDetector,
  trialStartingReminder,
} from './triggers/scheduled';
import { revenueCatWebhook } from './triggers/webhook';
import { onBroadcastCreated } from './triggers/broadcast';
import { onUserDeleted } from './triggers/delete';
import { translateNanny, translateFamily, translateJob } from './triggers/translate';
import {
  onShortlistCreated,
  onShortlistDeleted,
  onProfileViewed,
  onHireCreated,
  onHireEnded,
} from './triggers/stats';
import { onContactRevealRequested } from './triggers/contact';
import { bootstrapFirstAdmin } from './bootstrapAdmin';
import { syncMockSubscription } from './mockSubscription';

admin.initializeApp();

export {
  onNewMessage,
  onNewTicketMessage,
  onTicketStatusChanged,
  onNewDisputeMessage,
  onDisputeResolved,
  onNewApplication,
  onApplicationUpdated,
  onTrialOffered,
  onTrialResponse,
  onTrialOutcomeResolved,
  onTrialEnded,
  onDocumentReviewed,
  subscriptionExpiredEnforcer,
  subscriptionExpiringReminder,
  trialOutcomeDetector,
  trialStartingReminder,
  revenueCatWebhook,
  onBroadcastCreated,
  onUserDeleted,
  translateNanny,
  translateFamily,
  translateJob,
  onShortlistCreated,
  onShortlistDeleted,
  onProfileViewed,
  onHireCreated,
  onHireEnded,
  onContactRevealRequested,
  bootstrapFirstAdmin,
  syncMockSubscription,
};
