# S5 Ileana Voinea — Legal & Compliance MX Audit

> **Stockerly has published the correct privacy notice for a closed beta, collects only what it discloses, and has documented the ARCO process — but the support email doesn't route to a real domain, and there's no in-app way for users to request account deletion. For <20 friends, the exposure is low. Before the cohort grows, fix the mailbox and add a deletion flow.**

---

## State of the Product Through My Lens

Stockerly is in a **closed beta with ~4 users** (first amigo invite went out 2026-05-21). The privacy notice published at `/privacy` is honest and LFPDPPP-compliant for the current state. Adrian has collected explicit consent for patrimonial data at registration (stored as `consents_data_processing_at` timestamp). The product discloses transactional email via Resend and data-only API calls to Polygon, FMP, Banxico, and CoinGecko — none of which leak PII.

The realistic legal exposure **today is low** — the LFPDPPP applies, but enforcement risk is minimal in a beta cerrada with fewer than 20 invited friends. The law doesn't go lighter on small cohorts; compliance is binary. What *does* change is enforceability: a regulator doesn't prioritize <20 users. However, the obligation itself is real.

**Critical blocker:** the support email is `support@notdefined.dev`. That domain does not appear to be owned or maintained by Adrian. If a user sends an ARCO request there, it will bounce or land in the void. That violates Art. 32 LFPDPPP (right to response within 20 business days). It's the single biggest risk today.

---

## What's Compliant (3 items)

1. **Privacy notice is substantively compliant.** The notice at `/privacy` names the responsible party (Adrian Castillo, CDMX), discloses data categories (identification, authentication, patrimonial, operational), states purposes separately (necessary vs voluntary), promises 30-day deletion after account closure, names encargados (hosting provider, mail provider, market-data APIs), and points to the ARCO procedure. The omission of the street address is documented transparently in ADR-008 as a conscious trade-off for personal security; the notice says to request it by email. Complies with Art. 16 Fracción I in spirit (regulator can reach Adrian) even if not literally (no street address on public web). **Risk: low** if <20 users; revisit if the beta opens.

2. **Express consent for patrimonial data is captured and persisted.** The registration form (lines 61–67 in `app/views/registrations/new.html.erb`) requires a non-pre-checked checkbox with explicit language citing Art. 8 LFPDPPP. The timestamp is recorded in the database. This satisfies Art. 8's requirement for *consentimiento expreso* (express consent). It's not pre-checked, so the user cannot accidentally proceed. **Complies.** The contract in `register_contract.rb` enforces the checkbox as required — good.

3. **ARCO procedure is documented operationally.** The file `docs/ops/arco-procedure.md` is thorough: it names the timeline (5 days for identity validation, 20 business days for response, 30 days for deletion), specifies the identity-validation rules (email match, proof if third-party requestor), and describes what each right (Acceso, Rectificación, Cancelación, Oposición) entails. It's written in plain language and executable by Adrian. However, the procedure is *documented but not technically implementable in-app* (see "What's Missing").

---

## What's Missing (3 items, prioritized by risk)

### 1. **Support email doesn't route to Adrian — HIGH RISK**

**Status:** The privacy notice and ARCO procedure reference `support@notdefined.dev`. I cannot confirm this domain exists or that Adrian controls it.

**LFPDPPP obligation:** Art. 16 Fracción I and Art. 32 both require the responsible party to be reachable. If an amigo sends "I want to exercise my right to access my data" to that email, and it bounces or disappears, Stockerly has violated the right itself — not just the notice.

**Why it matters now:** Doesn't matter if no one exercises ARCO. But the moment someone does (which you should expect as soon as you invite a lawyer, auditor, or anyone who reads the privacy notice seriously), you have a compliance incident: failure to respond within 20 days = Art. 32 violation. The user can file a complaint with SABG (the successor to INAI as of March 2025). For a one-person project, that's reputational damage and potential claims.

**Concrete fix:**
- Use a personal email Adrian actively checks (e.g., adrian@notdefined.dev if he owns the domain, or an alias on his Gmail), OR
- Create `support@stockerly.notdefined.dev` if that domain exists, OR
- Use a forwarder (e.g., via Resend, which already handles mail for the app).
- Update `Stockerly::SUPPORT_EMAIL` constant in `config/initializers/stockerly.rb`.
- Test it: send a test ARCO request to the new email and confirm it lands and is answered within 5 business days.

**How long:** 15 minutes.

**Risk if unfixed:** User sends ARCO request → email bounces → user complains to SABG → regulatory contact + reputational damage.

---

### 2. **No in-app "delete my account" flow — MEDIUM-HIGH RISK**

**Status:** The privacy notice (section 4, lines 50–51) promises deletion within 30 days of cancellation. The ARCO procedure (section 3) describes how to process cancellation requests *by email*. But there's no UI in the app for a user to request it.

**LFPDPPP obligation:** Art. 19 gives the data subject the right to revoke consent and request cancellation at any time. The data controller must offer a channel. Email-only is technically legal (Art. 31 allows oral, written, electronic), but it shifts burden to the user — they have to know to email, compose a request, and wait. Better practice: offer in-app.

**Why it matters now:** Most users won't notice the missing self-service flow. But if someone wants to revoke consent (e.g., "I'm pulling my data, deleting the account"), they have to guess that `support@notdefined.dev` is where to ask. If they ask in a GitHub issue, bug report, or Twitter DM instead, there's no clear audit trail that triggers the 20-day clock.

**Concrete fix:**
- Add a "Delete account" button in the Profile view (`app/views/profiles/show.html.erb`), gated to the current user.
- Clicking it opens a modal with a warning: "Deleting your account is irreversible. Your data will be deleted within 30 days. Confirm?" and a checkbox "I understand and want to delete."
- The form POSTs to a new `delete_account` action in `ProfilesController`.
- The use case: `Identity::UseCases::DeleteAccount` (new). It:
  - Validates the user is the one requesting deletion.
  - Sets `deleted_requested_at` timestamp.
  - Optionally sends an email confirmation: "Your account deletion has been requested. We'll erase it by [date 30 days from now]. Email us if you change your mind."
  - Enqueues a job to run in 30 days: checks if `deleted_requested_at` is still set, and if so, permanently deletes the user and associated records.
- In the meantime, log the deletion request in the ARCO bitácora (in `docs/ops/arco-procedure.md` section 5).

**How long:** half day (controller, use case, view, migration to add `deleted_requested_at` column).

**Risk if unfixed:** User wants to leave, has to email, no clear SLA, creates support burden, and—worst case—no audit trail if the deletion actually happened.

---

### 3. **No "export my data" (Acceso right) flow — MEDIUM RISK**

**Status:** The ARCO procedure (section 3, "Acceso") describes generating a CSV/JSON export. No in-app implementation.

**LFPDPPP obligation:** Art. 19 (Acceso) is one of four ARCO rights. Users have the right to request a copy of their data.

**Why it matters:** Less urgent than deletion, because most users won't ask. But it's a common request in modern privacy practice (influenced by GDPR familiarity). The notice *mentions* it; users expect it to be available.

**Concrete fix:**
- Add a button in Profile: "Download my data."
- Clicking it creates a job that generates a JSON or CSV file containing:
  - User identification (full_name, email, email_verified_at)
  - Portfolio data (all trades, positions, alerts)
  - Account metadata (created_at, onboarded_at, consents_data_processing_at)
  - Technical logs (last 90 days of login IPs from `audit_log` and `system_log`)
- The file is encrypted, zipped, and delivered via email or a time-limited download link.
- Log the request in the ARCO bitácora.

**How long:** one day.

**Risk if unfixed:** User asks, Adrian emails a CSV manually. OK for 4 people, unsustainable at 20.

---

## What Doesn't Work (3 items)

1. **Bug report mailer leaks the user's email address without explicit consent.** The `BugReportMailer.notify()` method (lines 6–11 in `app/mailers/bug_report_mailer.rb`) sends an email *to* "support@notdefined.dev" with `reply_to: user.email`. The email body presumably includes the user's name and description. That email transits through Resend (the SMTP provider) with the user's address visible in the `reply_to` header.

   **LFPDPPP issue:** Sending the user's email to a third-party email service (Resend) is disclosed in the privacy notice (section 5: "Proveedor de envío de correo"). That's compliant. But the implicit assumption is that it's for *transactional mail to the user* (password reset, verification, account alerts). Forwarding their email address to support for a bug report is a *secondary transfer* not clearly listed. It's a weak issue (Resend is a legitimate processor, and bug reports are arguably a valid purpose), but better practice: add a checkbox in the bug-report form: "Include my email so support can reply" (unchecked by default, or pre-checked but visible).

2. **Cookie banner / cookie consent is missing.** The privacy notice (section 5) does not mention cookies or tracking pixels. Rails `cookies.signed[:remember_token]` is used for session persistence (`app/controllers/profiles_controller.rb`, line 103), which is fine — it's functional. But the notice should disclose that a signed cookie is set for authentication. Not mentioned = potential Art. 16 violation (lack of transparency). For a closed beta, risk is low; LFPDPPP doesn't require a banner for functional cookies (unlike GDPR), but transparency requires disclosure.

   **Concrete fix:** Add a short paragraph to privacy notice, section 5: "Cookies operativos — Stockerly uses a signed cookie (`remember_token`) for session authentication if you check 'Recuérdame por 30 días' at login. This cookie is not shared with third parties and contains no personal data beyond a cryptographic token."

3. **Resend ToS / DPA is not verified.** The privacy notice names Resend as the email processor. I haven't reviewed Resend's Terms of Service to confirm they are LFPDPPP-compliant (i.e., do they guarantee confidentiality, limit processing to our instructions, not sub-process without consent?). For a closed beta, Resend is a reputable service and likely compliant, but best practice: Adrian should review Resend's DPA (Data Processing Agreement) or equivalent and keep it on file.

---

## Top 3 Recommendations Before Cohort > 5

### 1. **Fix the support email (IMMEDIATE)**

**What:** Update `Stockerly::SUPPORT_EMAIL` to a real, monitored email address that Adrian controls.

**Why required:** Any ARCO request sent to the published email must land and be answered within 20 days. Currently, it can't. Legal exposure jumps from low to medium the moment you publish an unreachable email address.

**How long:** 15 minutes (fix the constant, test, update any .env/.secrets references, deploy).

**Triggers:** Before inviting anyone beyond Adrian's personal friends (i.e., before you send a second amigo invite to someone who doesn't know you personally).

---

### 2. **Add in-app account deletion (BEFORE COHORT = 10)**

**What:** Implement the `DeleteAccount` use case and "Delete my account" button in the Profile view.

**Why required:** Users expect self-service deletion. Email-only deletion is legally compliant but operationally weak. At 10 users, you'll get the first request; you need a clear, auditable path.

**How long:** half day.

**Triggers:** After the second or third amigo feedback suggests they want the option, or before you invite more than 5 people.

---

### 3. **Clarify cookies and Resend ToS in documentation (BEFORE COHORT = 20)**

**What:**
- Add one paragraph to privacy notice disclosing `remember_token` cookie.
- Request Resend's DPA and file it in `docs/legal/` (not public, but available to Adrian for audits).

**Why required:** Transparency (Art. 16) and processor compliance (Art. 35). Small details, big trust impact.

**How long:** 1 hour (privacy notice edit, Resend email request).

**Triggers:** Before you hit 10 active users or before a regulator asks (unlikely, but prudent).

---

## Summary

Stockerly **is compliant for the current beta state** — the privacy notice is good, consent is captured, and the ARCO procedure is documented. But **one critical blocker prevents it from working in practice:** the support email doesn't exist. Fix that first (15 minutes). Then, before the cohort grows beyond a handful, add deletion and export flows (1 day total work). After that, your compliance posture is solid for a closed beta ≤20 users.

The law doesn't give smaller teams a pass on LFPDPPP. What changes is enforceability and cost of remediation. Today, you can fix this with an afternoon and a small PR. At 100 users, you'd need lawyers. Fix it now.
