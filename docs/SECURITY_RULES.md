# Kafi — Firebase Security Rules & Indexes

Everything you need to lock down Firestore + Storage and deploy the required
indexes. The **canonical source** for all of this lives in the repo root and is
deployed automatically by the `Deploy` GitHub Action:

| File | What it governs |
|------|-----------------|
| [`firestore.rules`](../firestore.rules) | Who can read/write each Firestore collection |
| [`storage.rules`](../storage.rules) | Who can read/write each Cloud Storage path |
| [`firestore.indexes.json`](../firestore.indexes.json) | Composite indexes the app's queries require |

This document explains them and gives you copy‑paste content + deploy commands
for the Firebase console or CLI.

---

## 1. Prerequisites — the `admin` custom claim

Every rule that grants elevated access checks `request.auth.token.admin == true`.
That claim is **not** set automatically — you grant it to a Firebase Auth user
with one of the seed scripts:

```bash
# From functions/ (needs a service-account key; see the script header)
npx ts-node ../scripts/set-admin-claims.ts <uid-or-email>
# or create a brand-new admin user + claim:
npx ts-node ../scripts/create-admin.ts <email> <password>
```

After the claim is set the user must **sign out and back in** (or force a token
refresh) for `request.auth.token.admin` to reflect it.

> Nannies and families are ordinary users — they carry **no** custom claim. The
> rules identify them by document ownership (`request.auth.uid == <docId>`).

---

## 2. Deploy

```bash
# Everything at once (rules + indexes for both products)
firebase deploy --only firestore:rules,firestore:indexes,storage:rules

# …or individually
firebase deploy --only firestore:rules
firebase deploy --only storage:rules
firebase deploy --only firestore:indexes
```

Indexes can take a few minutes to build; queries that need a still‑building
index fail until it is `Enabled` in **Firestore → Indexes**.

If you prefer the console: paste `firestore.rules` into **Firestore Database →
Rules**, `storage.rules` into **Storage → Rules**, and add each composite index
from `firestore.indexes.json` under **Firestore Database → Indexes**.

---

## 3. Firestore rules — what each collection enforces

| Collection | Read | Create | Update | Delete |
|------------|------|--------|--------|--------|
| `users/{uid}` | self / admin | self | self / admin | admin |
| `nannies/{id}` | **self / admin / (approved+verified → public)** | self | self *(cannot self‑set `blocked`, `isVerified`, or an `approved`/`rejected` status — admin only)* | admin |
| `nannies/{id}/documents/{docId}` | self / admin | self / admin | — | — |
| `families/{id}` | self / admin | self | self *(cannot touch `subscription`, `freeContactsUsed`, `activeTrialNannyIds`, `viewedProfiles`, `blocked` — admin/server only)* | admin |
| `jobs/{id}` | any signed‑in | owner family | owner family / admin | owner family / admin |
| `applications/{id}` | the nanny or family on it / admin | the applying nanny | either party / admin | admin |
| `shortlists/{id}` | owner family / admin | owner family | owner family | owner family / admin |
| `chatThreads/{id}` | the two parties / admin | family *(needs active subscription **or** an active trial with that nanny)* | either party / admin | admin |
| `chatThreads/{id}/messages/{id}` | the two parties / admin | nanny always; family only with access/trial; admin | admin | admin |
| `trials/{id}` | the two parties / admin | owner family | either party / admin | admin |
| `notifications/{id}` | recipient / admin | **admin/server only** | recipient / admin | recipient / admin |
| `disputes/{id}` | reporter/reported / admin | reporter | admin | admin |
| `settings/{id}` | any signed‑in | — | admin | admin |
| `admins/{uid}` | self / admin | — | admin | admin |
| `broadcasts/{id}` | admin | admin | admin | admin |

Key protections baked into the rules:

- **Nannies can't self‑approve or self‑unblock.** The `nannies` update rule pins
  `blocked`, `isVerified`, and approved/rejected `status` to admin writes, while
  still letting a nanny move herself to `draft`/`pending`.
- **Families can't grant themselves paid access.** `subscription`,
  `freeContactsUsed`, `activeTrialNannyIds`, and `viewedProfiles` are server‑owned
  (Cloud Functions / RevenueCat webhook), never client‑writable.
- **Chat is gated on payment.** A family can only open a thread / send messages
  with an active subscription **or** an active trial with that specific nanny.
- **Notifications are server‑written.** Only Cloud Functions create inbox docs;
  a user may only read / mark‑read / delete their own.

---

## 4. Storage rules — what each path enforces

| Path | Read | Write |
|------|------|-------|
| `nannies/{uid}/photos/{file}` | public | owner/admin · image · ≤5 MB |
| `nannies/{uid}/videos/{file}` | public | owner/admin · video · ≤25 MB |
| `nannies/{uid}/documents/{file}` | **owner/admin only** | owner/admin · ≤25 MB |
| `families/{uid}/avatar/{file}` | signed‑in | owner/admin · image · ≤5 MB |
| `chats/{threadId}/{file}` | signed‑in | signed‑in · image · ≤8 MB |
| `public/**` | public | admin |

The app uploads to paths that match these exactly (e.g. nanny KYC docs go to
`nannies/{uid}/documents/…`, matching the `documents/` rule — an earlier `docs/`
prefix that matched no rule has been corrected).

---

## 5. ⚠️ Known security gap to close — sensitive document URLs (C5)

**Status: not yet fixed — flagged so you're aware before go‑live.**

Storage rules correctly restrict the KYC document **files** to owner/admin.
**However**, the app stores each document's **download URL** inside the nanny
document (`nannies/{id}.documents[]`). That nanny document becomes **publicly
readable** once the nanny is `approved` + `isVerified` (Section 3). Because a
Firebase Storage *download URL* embeds an access token that **bypasses Storage
rules**, anyone who can read an approved nanny's profile can currently download
her passport / visa / Emirates ID.

**Recommended fix** (tracked; needs emulator validation before shipping because
it spans the app, the admin panel, and the `onDocumentReviewed` function):

1. Persist document metadata to the **private subcollection**
   `nannies/{id}/documents/{docId}` (its rule already restricts read to
   owner/admin) instead of embedding it in the parent doc.
2. Stop writing `documents` into `NannyModel.toMap()` (the world‑readable doc).
3. Point the admin verification UI and the `onDocumentReviewed` trigger at the
   subcollection.

Until then, avoid marking nannies `approved`+`isVerified` with real ID documents
attached, or keep the profile‑level read restricted to signed‑in reviewers.

---

## 6. Full rule sources

The authoritative content is versioned in the repo; deploy straight from there.
Inlined here for convenience — if these ever differ from the repo files, **the
repo files win**.

<details><summary><code>firestore.rules</code> (paste into Firestore → Rules)</summary>

```
rules_version = '2';

service cloud.firestore {
  match /databases/{database}/documents {
    // ---------- helpers ----------
    function isSignedIn() {
      return request.auth != null;
    }
    function isUser(uid) {
      return isSignedIn() && request.auth.uid == uid;
    }
    function isAdmin() {
      return isSignedIn() && request.auth.token.admin == true;
    }
    function existing() {
      return resource.data;
    }
    function incoming() {
      return request.resource.data;
    }
    function isFamily(uid) {
      return exists(/databases/$(database)/documents/families/$(uid));
    }
    function isNanny(uid) {
      return exists(/databases/$(database)/documents/nannies/$(uid));
    }
    function familySub(uid) {
      return get(/databases/$(database)/documents/families/$(uid)).data.subscription;
    }
    function familyHasAccess(uid) {
      let s = familySub(uid);
      return s.status == 'active' || s.status == 'cancelled';
    }
    function hasActiveTrialWith(familyId, nannyId) {
      let f = get(/databases/$(database)/documents/families/$(familyId)).data;
      return f.activeTrialNannyIds is list && f.activeTrialNannyIds.hasAny([nannyId]);
    }

    // ---------- users ----------
    match /users/{uid} {
      allow read: if isUser(uid) || isAdmin();
      allow create: if isUser(uid);
      allow update: if isUser(uid) || isAdmin();
      allow delete: if isAdmin();
    }

    // ---------- nannies ----------
    match /nannies/{nannyId} {
      allow read: if isUser(nannyId)
        || isAdmin()
        || (existing().status == 'approved' && existing().isVerified == true);
      allow create: if isUser(nannyId);
      allow update: if isAdmin() || (
        isUser(nannyId)
        && incoming().get('blocked', false) == existing().get('blocked', false)
        && incoming().get('isVerified', false) == existing().get('isVerified', false)
        && (incoming().get('status', 'draft') == existing().get('status', 'draft')
            || incoming().get('status', 'draft') == 'draft'
            || incoming().get('status', 'draft') == 'pending')
      );
      allow delete: if isAdmin();

      match /documents/{docId} {
        allow read: if isUser(nannyId) || isAdmin();
        allow write: if isUser(nannyId) || isAdmin();
      }
    }

    // ---------- families ----------
    match /families/{familyId} {
      allow read: if isUser(familyId) || isAdmin();
      allow create: if isUser(familyId);
      allow update: if (isUser(familyId)
                      && !(incoming().diff(existing()).affectedKeys()
                          .hasAny(['subscription', 'freeContactsUsed', 'activeTrialNannyIds', 'viewedProfiles', 'blocked', 'blockedAt'])))
                   || isAdmin();
      allow delete: if isAdmin();
    }

    // ---------- jobs ----------
    match /jobs/{jobId} {
      allow read: if isSignedIn();
      allow create: if isSignedIn() && incoming().familyId == request.auth.uid;
      allow update, delete: if isAdmin() || (isSignedIn() && existing().familyId == request.auth.uid);
    }

    // ---------- applications ----------
    match /applications/{appId} {
      allow read: if isAdmin()
        || (isSignedIn()
            && (existing().nannyId == request.auth.uid
                || existing().familyId == request.auth.uid));
      allow create: if isSignedIn() && incoming().nannyId == request.auth.uid;
      allow update: if isAdmin()
        || (isSignedIn()
            && (existing().nannyId == request.auth.uid
                || existing().familyId == request.auth.uid));
      allow delete: if isAdmin();
    }

    // ---------- shortlists ----------
    match /shortlists/{shortlistId} {
      allow read, write: if isAdmin()
        || (isSignedIn() && (existing().familyId == request.auth.uid
                            || incoming().familyId == request.auth.uid));
    }

    // ---------- chatThreads ----------
    match /chatThreads/{threadId} {
      allow read: if isAdmin()
        || (isSignedIn()
            && (existing().familyId == request.auth.uid
                || existing().nannyId == request.auth.uid));
      allow create: if isSignedIn()
        && incoming().familyId == request.auth.uid
        && (familyHasAccess(request.auth.uid)
            || hasActiveTrialWith(incoming().familyId, incoming().nannyId));
      allow update: if isAdmin()
        || (isSignedIn()
            && (existing().familyId == request.auth.uid
                || existing().nannyId == request.auth.uid));
      allow delete: if isAdmin();

      match /messages/{msgId} {
        allow read: if isAdmin()
          || (isSignedIn()
              && (get(/databases/$(database)/documents/chatThreads/$(threadId)).data.familyId == request.auth.uid
                  || get(/databases/$(database)/documents/chatThreads/$(threadId)).data.nannyId == request.auth.uid));
        allow create: if isAdmin() || (
          isSignedIn() && (
            get(/databases/$(database)/documents/chatThreads/$(threadId)).data.nannyId == request.auth.uid
            ||
            (
              get(/databases/$(database)/documents/chatThreads/$(threadId)).data.familyId == request.auth.uid
              && (
                familyHasAccess(request.auth.uid)
                || hasActiveTrialWith(
                  request.auth.uid,
                  get(/databases/$(database)/documents/chatThreads/$(threadId)).data.nannyId
                )
              )
            )
          )
        );
        allow update: if isAdmin();
        allow delete: if isAdmin();
      }
    }

    // ---------- trials ----------
    match /trials/{trialId} {
      allow read: if isAdmin()
        || (isSignedIn()
            && (existing().familyId == request.auth.uid
                || existing().nannyId == request.auth.uid));
      allow create: if isSignedIn() && incoming().familyId == request.auth.uid;
      allow update: if isAdmin()
        || (isSignedIn()
            && (existing().familyId == request.auth.uid
                || existing().nannyId == request.auth.uid));
      allow delete: if isAdmin();
    }

    // ---------- notifications ----------
    match /notifications/{notifId} {
      allow read, update, delete: if isAdmin()
        || (isSignedIn() && existing().userId == request.auth.uid);
      allow create: if isAdmin();
    }

    // ---------- disputes / reports ----------
    match /disputes/{disputeId} {
      allow read: if isAdmin()
        || (isSignedIn()
            && (existing().reporterId == request.auth.uid
                || existing().reportedUserId == request.auth.uid));
      allow create: if isSignedIn() && incoming().reporterId == request.auth.uid;
      allow update, delete: if isAdmin();
    }

    // ---------- admin config ----------
    match /settings/{settingId} {
      allow read: if isSignedIn();
      allow write: if isAdmin();
    }
    match /admins/{uid} {
      allow read: if isUser(uid) || isAdmin();
      allow write: if isAdmin();
    }
    match /broadcasts/{id} {
      allow read: if isAdmin();
      allow write: if isAdmin();
    }
  }
}
```

> Note: the `notifications` **create: if isAdmin()** rule means only privileged
> writers (Cloud Functions run with admin privileges, so they bypass rules)
> create inbox docs — matching the server‑written inbox in the Functions layer.

</details>

<details><summary><code>storage.rules</code> (paste into Storage → Rules)</summary>

```
rules_version = '2';

service firebase.storage {
  match /b/{bucket}/o {
    function isSignedIn() { return request.auth != null; }
    function isUser(uid) { return isSignedIn() && request.auth.uid == uid; }
    function isAdmin() { return isSignedIn() && request.auth.token.admin == true; }
    function isImage() { return request.resource.contentType.matches('image/.*'); }
    function isVideo() { return request.resource.contentType.matches('video/.*'); }
    function isPdf() { return request.resource.contentType == 'application/pdf'; }
    function under(maxMB) { return request.resource.size <= maxMB * 1024 * 1024; }

    // Nanny photos (max 5 MB each)
    match /nannies/{uid}/photos/{file} {
      allow read: if true;
      allow write: if (isUser(uid) || isAdmin()) && isImage() && under(5);
    }
    // Intro videos (max 25 MB, <= 60s enforced client-side)
    match /nannies/{uid}/videos/{file} {
      allow read: if true;
      allow write: if (isUser(uid) || isAdmin()) && isVideo() && under(25);
    }
    // Sensitive documents (passport, visa, EID, police, training).
    match /nannies/{uid}/documents/{file} {
      allow read: if isUser(uid) || isAdmin();
      allow write: if (isUser(uid) || isAdmin()) && under(25);
    }
    // Family avatar
    match /families/{uid}/avatar/{file} {
      allow read: if isSignedIn();
      allow write: if (isUser(uid) || isAdmin()) && isImage() && under(5);
    }
    // Chat attachments (images only)
    match /chats/{threadId}/{file} {
      allow read: if isSignedIn();
      allow write: if isSignedIn() && isImage() && under(8);
    }
    // Public marketing/assets — admin only
    match /public/{file=**} {
      allow read: if true;
      allow write: if isAdmin();
    }
  }
}
```

</details>

<details><summary><code>firestore.indexes.json</code></summary>

See [`firestore.indexes.json`](../firestore.indexes.json). Composite indexes
cover the app's filter‑plus‑order queries: `applications`, `trials`,
`shortlists`, `disputes`, `notifications` (`userId`+`createdAt` and
`userId`+`read`), `jobs`, `subscriptions`, `nannies`, and `chatThreads`.

</details>

The most reliable way to hand these to Firebase is to run the deploy command in
Section 2 from a checkout of this repo — it reads the three files directly, so
there is nothing to copy by hand.
