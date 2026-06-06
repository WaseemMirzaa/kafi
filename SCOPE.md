# Kafi — Project Scope

**Kafi** is a UAE nanny marketplace that connects **families** with verified **nannies**. The platform is delivered as two products: a **Mobile App** used by families and nannies, and an **Admin Panel** used by the operations team. Together they cover the full journey — from a nanny building a profile and a family posting a job, through verification, matching, paid contact, trial periods, and hiring.

---

## 1. Mobile App

The mobile app is a Flutter application with two role-based experiences that share a single sign-up. Family screens follow a **purple** theme and nanny screens follow a **rose** theme, with English and Arabic (RTL) supported throughout.

### 1.1 Family Flow

A family begins by registering with their phone number and a one-time code, choosing the "Family" role. They then create a job posting together with their family profile, entering information about themselves, their children, religion and household culture, the role and schedule they need, expected duties, benefits, salary, and trial and visa terms. Once posted, the family can browse matched nannies, filter results by job, and see a compatibility match percentage for each posting, with a Smart Match breakdown that explains the fit before they reach out.

Contacting a nanny and chatting in-app require a paid subscription, which the family manages through the pricing and plans screen. After subscribing, the family can message nannies, send a paid trial offer and negotiate the rate, track active trials, and finally confirm a hire once a trial is successful. Throughout, the family can edit their profile, manage their subscription, and adjust notifications, language, legal preferences, or delete their account from settings.

### 1.2 Nanny Flow

A nanny also registers by phone and one-time code, choosing the "Nanny" role, and then completes a five-step onboarding covering personal information, photos and video, work experience, references, and documents. The profile stays locked until an admin verifies the submitted documents. Once approved, the nanny lands on a dashboard showing their profile quality score, key stats, recommended jobs, and notifications.

From there, the nanny can browse and filter available jobs (All, Live-in, Live-out, or Newborn) and apply through Smart Match, with one application allowed per job. The "My Applications" area tracks each application as it moves from Pending to Viewed, Shortlisted, Trial Offered, and finally Hired. Nannies can chat with families, and when a trial offer arrives they can accept it, counter with a different rate, or decline it. They can also edit any individual onboarding section at any time and save it without re-running the whole flow, as well as manage language and legal settings.

---

## 2. Admin Panel

The admin panel is a React and TypeScript web dashboard for the operations team, and access is restricted to admin accounts. It opens on a dashboard summarising platform activity and key metrics.

From the nanny side, admins can view all nannies and open individual profiles, review and approve or reject uploaded documents such as passports and visas, and approve or reject intro videos. Approving a nanny moves them from pending to live, while rejecting keeps them off the marketplace — this verification gate is the core control that keeps the platform trusted. On the family side, admins can view all families and their profiles, manage subscriptions (including overriding plan status and resetting free-contact counts), and monitor the trials running between families and nannies.

The panel also supports operational and business functions: reviewing disputes reported between users and recording their resolutions, viewing a revenue summary with subscription trends, broadcasting announcements to users, and configuring platform settings.

---

## 3. Cross-Cutting Concerns

Several principles run across both products. Verification is a hard gate: nannies cannot be seen by families until an admin approves them. Monetisation is family-side: families pay through a subscription to unlock contacts and chat, while nannies use the app for free. Hiring is preceded by a paid trial period that includes rate negotiation. Both roles receive in-app notifications for messages, applications, trials, verification outcomes, and subscription events, and the entire experience is localised in both English and Arabic.
