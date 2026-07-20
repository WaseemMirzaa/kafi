# Kafi — Payments (RevenueCat) setup

Subscriptions in Kafi are **server-owned**: the security rules forbid a family
from writing its own `subscription` field, so a subscription only ever becomes
active when **RevenueCat** confirms a purchase and calls our webhook, which
writes the state to Firestore.

## ⚠️ Current status — DEFERRED (known launch blocker)

Real payment integration is **intentionally not wired yet** (product decision,
2026-07). The live build ships with `useMockSubscription = true`, and the mock
entitlement is **not** synced to the server, so:

- No money is charged; the subscribe/pricing/trial-payment path is mock.
- `families/{id}.subscription.status` is not written for "paid" families, so the
  server-enforced `onContactRevealRequested` **denies contact reveal** to them —
  UI entitlement and server entitlement diverge. **This is the #1 launch
  blocker** and must be resolved before charging real users.
- Because nothing writes the `transactions` collection, the admin **Revenue**
  page has no data; it shows a "billing not integrated" placeholder instead of
  misleading zeros until this is completed.

To resolve, complete the RevenueCat steps below (the webhook already writes both
`subscription` state and can populate `transactions`), **or** enable a
server-side sync of the mock subscription for a free soft-launch. The
`revenueCatWebhook` groundwork is done — only the client purchase + account
setup remain.

## What's already built (no action needed)

- **`revenueCatWebhook`** Cloud Function (`functions/src/triggers/webhook.ts`) —
  authenticated (shared secret), handles `INITIAL_PURCHASE`, `RENEWAL`,
  `CANCELLATION`, `EXPIRATION`, `BILLING_ISSUE`, `UNCANCELLATION`,
  `PRODUCT_CHANGE`; writes `families/{id}.subscription.*` and now also drops a
  notification into the family's in-app **inbox** + FCM.
- **Scheduled enforcers** (`scheduled.ts`) — `subscriptionExpiredEnforcer`
  flips lapsed subscriptions to `expired`; `subscriptionExpiringReminder` warns 3
  days out.
- **Client lockdown** — `SubscriptionController` reads the state and gates
  contacts/chat; free-tier + trial bypass already work.

## The one remaining step (needs YOUR RevenueCat + store accounts)

The client still has to **initiate the purchase** through the RevenueCat SDK.
This is the only piece that can't be finished without your accounts, because it
depends on real store products + API keys. Steps:

### 1. RevenueCat dashboard
1. Create a project; add your iOS + Android apps.
2. Create products in **App Store Connect** and **Google Play Console** (one per
   plan in `SubscriptionConstants.plans`), then import them into RevenueCat.
3. Create an **entitlement** (e.g. `pro`) and attach the products.
4. Create **Offerings** whose package identifiers map to your plan ids.
5. Copy the **public SDK keys** (one per platform) and create a **webhook**:
   - URL: your deployed `revenueCatWebhook` URL.
   - Authorization header: a secret you choose.

### 2. Wire the webhook secret (server)
Set the same secret on the function so it accepts the webhook:
```bash
firebase functions:secrets:set REVENUECAT_WEBHOOK_SECRET
# or as an env var in your deploy environment
```
The function already **refuses to run** without it, so anonymous webhooks are
never accepted.

### 3. Add the SDK to the client
```yaml
# kafi_app/pubspec.yaml
dependencies:
  purchases_flutter: ^8.0.0
```

Pass the platform SDK key at build time (kept out of source, like the Firebase
config): `--dart-define=REVENUECAT_API_KEY=<public-sdk-key>`.

### 4. Configure on login + purchase in `subscribe()`
Configure RevenueCat once the family is known (e.g. in `AuthController` after
sign-in / in `SubscriptionController.onInit`), using the **familyId** as the
RevenueCat `appUserID` — that's what the webhook reads as `app_user_id`:

```dart
import 'package:purchases_flutter/purchases_flutter.dart';

const _rcKey = String.fromEnvironment('REVENUECAT_API_KEY');

Future<void> configurePurchases(String familyId) async {
  if (_rcKey.isEmpty) return; // dev / mock builds run without RevenueCat
  await Purchases.configure(PurchasesConfiguration(_rcKey)..appUserID = familyId);
}
```

Then replace the body of `SubscriptionController.subscribe(planId)` for live
builds so it purchases instead of writing Firestore directly (which the rules
deny):

```dart
Future<void> subscribe(String planId) async {
  final id = currentFamilyId(_auth);
  if (id == null) return;
  if (AppConfig.useMock) {          // dev simulation keeps working
    await _subs.subscribe(id, planId);
    await refreshAndEnforce();
    return;
  }
  final offerings = await Purchases.getOfferings();
  final pkg = offerings.current?.availablePackages
      .firstWhereOrNull((p) => p.identifier == planId);
  if (pkg == null) { Get.snackbar('Unavailable', 'Plan not available'); return; }
  await Purchases.purchasePackage(pkg);   // → RevenueCat → webhook → Firestore
  // The webhook flips the subscription; refresh picks it up (poll briefly if
  // the webhook is still in flight).
  await refreshAndEnforce();
}

Future<void> restorePurchases() async {
  if (!AppConfig.useMock) await Purchases.restorePurchases();
  await refreshAndEnforce();
}
```

### 5. Verify
Use RevenueCat **sandbox** testers to buy → confirm the webhook fires (function
logs) → confirm `families/{id}.subscription.status == 'active'` and the app
unlocks. Test `EXPIRATION`/`BILLING_ISSUE` from the RevenueCat dashboard's event
tester.

## Why the client change isn't committed here
Adding a native IAP plugin can't be end-to-end verified without your store
products + keys, and the APK build isn't a PR gate — shipping it blind could
break the native build. The snippets above are drop-in; ping me once RevenueCat
is set up and I'll wire + verify them against your config.
