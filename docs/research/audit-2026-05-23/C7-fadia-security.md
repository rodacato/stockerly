# C7 Fadia Haddad — Security Audit

> "Foundation is solid, but one cozy assumption breaks at 5 users: invite flow verification has no anti-replay defense, and session revocation on logout is incomplete."

## State of the product through my lens

Stockerly shipped with the right architectural decisions: password hashing via `has_secure_password`, IDOR-safe use cases that filter by `current_user`, rate limiting on auth entry points, and `encrypts` on API keys. The beta entry point is gated by invite codes, which is the right guard rail for a single-user → multi-user transition.

**Threat model (1 user → 5 → 20):**
- **1 user (Adrian solo):** Insider risk is zero; the only attacker is Adrian misclicking. Security defects are non-exploitable.
- **5 users (first cohort):** Horizontal privilege escalation (user A modifies user B's data), account enumeration, brute force on weak invites.
- **20 users:** Token reuse across devices, session fixation on remember-me tokens, leaked reset links lingering, audit log queryability becomes a problem.

With one real user live (2026-05-21 invite sent), you're transitioning from 1 → 5 *now*. The audit focuses on what bites hardest as that cohort lands.

---

## What delivers value (already shipped)

1. **`has_secure_password` correctly deployed** (`app/models/user.rb:2`). Rails handles bcrypt, salt, and comparison. No custom crypto.

2. **IDOR-safe resource fetches across the board:**
   - Trades: `user.portfolio&.trades&.find_by(id: params[:id])` filters by portfolio ownership (`app/controllers/trades_controller.rb:74`)
   - Positions: same pattern (`app/controllers/positions_controller.rb:3`)
   - Alert rules: `user.alert_rules.find_by(id: id)` in use case (`app/contexts/alerts/use_cases/update_rule.rb:15`)
   - Watchlist: `user.watchlist_items.find(watchlist_item_id)` (`app/contexts/trading/use_cases/remove_from_watchlist.rb:8`)
   - All use trade-specific authorization checks in the use case layer, not just the controller.

3. **Rate limiting on authentication surface:**
   - Login: 5 attempts / 1 minute (`sessions_controller.rb:4`)
   - Registration: 5 attempts / 1 minute (`registrations_controller.rb:4`)
   - Email verification resend: 3 / 1 hour (`email_verifications_controller.rb:3`)
   - Password reset request: 3 / 1 hour (`password_resets_controller.rb:4`)

4. **API key encryption at rest** via `encrypts :api_key_encrypted` (`app/models/api_key_pool.rb:2`) and masked display `"••••••••••••#{api_key_encrypted.last(4)}"` prevents accidental logs from leaking full keys.

5. **Session invalidation on password change:**
   - `InvalidateSessionsOnPasswordChange` handler destroys all remember tokens (`app/contexts/identity/handlers/invalidate_sessions_on_password_change.rb:7`)
   - Password reset also clears tokens (`app/contexts/identity/use_cases/reset_password.rb:19`)

6. **Comprehensive audit logging:**
   - Login success/failure (`create_audit_log_on_login.rb`, `create_audit_log_on_login_failure.rb`)
   - Password changes, email verification, profile updates, and admin actions all logged
   - Admin deletions capture email and full_name for accountability (`app/contexts/administration/handlers/create_audit_log_on_deletion.rb:14-18`)

7. **Security headers and HTTPS hardening:**
   - CSP configured: `default-src 'self'`, frame-ancestors none, inline styles limited (`config/initializers/content_security_policy.rb`)
   - HSTS with preload and subdomains (`config/environments/production.rb:33`)
   - `force_ssl = true` and `assume_ssl = true` for Cloudflare termination
   - Permissions Policy: camera, microphone, geolocation, USB all disabled

---

## What's missing (prioritized by user-growth risk)

### 1. **~~CRITICAL: Invite code race condition~~ — RETRACTED (false positive)**

> **Correction added 2026-05-23 post-gemini-review of PR #178:** This finding is a false positive. [`Register#persist_with_invite`](../../../app/contexts/identity/use_cases/register.rb#L17-L36) wraps the flow in `ActiveRecord::Base.transaction` and uses `InviteCode.lock.find_by(code:)`, which generates a `SELECT ... FOR UPDATE` query. PostgreSQL acquires a row-level lock that blocks any concurrent transaction trying to read the same row until commit. Request B's `lock.find_by` blocks at line 18 until Request A's transaction commits, then sees the updated `used_at`, and the `if invite.used?` guard at line 21 correctly fails the registration. The original "evidence" I cited (the `.lock` call) is exactly what defeats my conclusion. Apologies for the false alarm — my mental model didn't account for `.lock` inside an explicit transaction being equivalent to pessimistic locking. The historical finding text follows for transparency.

**Vulnerability Class (HISTORICAL):** Race condition / replay attack
**Risk (HISTORICAL):** User A obtains invite code (e.g., via email), starts registration, User B intercepts and completes registration with the same code before A's transaction commits. At growth to 5 users, this becomes plausible (shared Slack channel, accidentally copied code, phishing).

**Evidence:**
- `Register` use case acquires a lock on the invite: `InviteCode.lock.find_by(code: normalized)` (`app/contexts/identity/use_cases/register.rb:18`)
- But the race window exists: between the `find_by(code)` check on line 20 and the `update!(used_at:, used_by_user:)` on line 33, another request can pass the `used?` check
- Two simultaneous registration requests with the same invite can both see `used? == false` before either commits

**Cost to fix:** Low (1–2 hours). Add database-level uniqueness or explicit "reserved" state:
```ruby
invite = InviteCode.find_by(code: normalized)
raise "Invalid code" unless invite
raise "Already used" if invite.used_at.present?

# Move to "reserve" state atomically
invite.update!(reserved_by_user: current_user, reserved_at: Time.current)

# Then proceed with user creation; rollback if user.save fails
```

**Why urgent (before 5 users):** Invite codes are the *only* gate to registration. At 1 user, Adrian won't notice a dupe. At 5, one beta amigo will discover the hole and spread the link. You want to seal this before the cohort invites friends.

---

### 2. **HIGH: No anti-enumeration on invite code redemption**
**Vulnerability Class:** Account enumeration / invite enumeration
**Risk:** An attacker can test whether an invite code is valid/used by observing registration form behavior or error messages.

**Evidence:**
- Registration form shows distinct error for bad code vs. used code
- `InviteCode.normalize()` is deterministic, and an attacker can brute-force or test nearby codes, inferring the distribution of issued codes

**Cost to fix:** Low (30 min). Normalize all invite errors to a single message: `"Invalid or already redeemed invite code."`

**Why urgent:** At 5 users, one amigo might accidentally share their invite in support Slack. You don't want to leak whether a rival team guessed it correctly.

---

### 3. **MEDIUM: Remember token IP/User-Agent binding is logged but not enforced**
**Vulnerability Class:** Token reuse after device compromise
**Risk:** If a user logs in from Device A and checks "Remember me," the token is stored with that device's IP and User-Agent. If an attacker steals the cookie, they can reuse it from any IP/UA, and you'll log it as activity from the original device.

**Evidence:**
- Token is created with IP and UA: `RememberToken.generate(..., ip_address: request.remote_ip, user_agent: request.user_agent)` (`app/models/remember_token.rb:14-21`)
- But on recall, the check is purely cryptographic; IP/UA are never re-validated

**Cost to fix:** Medium (2–3 hours). Add a soft check (warn but don't block) for mismatches. Log to SystemLog and optionally notify the user.

**Why SOON, not NOW:** You don't have XSS vectors yet (CSP is strict), and at 5 users, the attack surface is still small. But add this before you scale.

---

### 4. **MEDIUM: Session cookie `Secure` flag is conditional on Rails.env.production?**
**Vulnerability Class:** Session hijacking over HTTP
**Risk:** If staging is deployed without `Rails.env = production`, the session cookie won't have the `secure` flag, and if accessed over HTTP, an attacker can sniff the cookie.

**Evidence:**
- `ApplicationController#remember` sets cookie with `secure: Rails.env.production?` (`app/controllers/application_controller.rb:96`)

**Cost to fix:** Very low (5 min). Explicitly set secure for all non-dev:
```ruby
secure = !Rails.env.development?
Rails.application.config.session_store :cookie_store,
  key: "_stockerly_session",
  secure: secure,
  httponly: true,
  same_site: :lax
```

**Why SOON:** Staging is the weak link; ensure HTTPS and the flag is always on in production-like environments.

---

### 5. **MEDIUM: Password reset token is valid until expiry; no one-time consumption tracking**
**Vulnerability Class:** Token reuse / long-lived credentials
**Risk:** If a user requests a password reset, the 2-hour token is valid until expiry, even after successful password change. If the link appears in logs or browser history, an attacker can reuse it.

**Evidence:**
- Token is generated with `expires_in: PASSWORD_RESET_EXPIRES_IN` (2 hours, line 47 in `user.rb`)
- But Rails' `generates_token_for` doesn't invalidate the token on consumption

**Cost to fix:** Medium (2–3 hours). Add a `password_reset_token_used_at` column and check it before allowing a reset.

**Why SOON (not NOW):** The token is in the user's email, not logged in application logs (you filter it correctly). But as you add integrations, ensure the token is never transmitted or logged.

---

### 6. **LOW: Audit log is write-only; no read-side access control or retention policy**
**Vulnerability Class:** Audit trail tampering / compliance gap
**Risk:** Audit logs are created (good) but there's no documented way to read them, no retention policy, and no immutability guarantees.

**Evidence:**
- `AuditLog` model has no controller; admin can't view audit logs from the web
- No cleanup job
- At 20 users, you'll have millions of audit rows and no way to investigate anomalies

**Cost to fix:** Low (1–2 hours). Create `Admin::AuditLogsController`, a cleanup job, and documentation.

**Why SOON (before 5 users):** This is table stakes for multi-user SaaS. You'll need it for compliance investigations.

---

## What doesn't work (ranked by urgency)

### **NOW — Session cookie expiry on logout is implicit, not explicit**

**Risk:** Medium | **Exploitability:** Low (Rails clears session server-side)

**The issue:**
- `SessionsController#destroy` calls `reset_session` and `forget(current_user)` (line 32-35)
- `reset_session` clears the Rails session, and modern Rails sends `Max-Age=0` header
- But explicit cookie deletion is cleaner and safer

**Fix (5 min):**
```ruby
def destroy
  forget(current_user) if current_user
  reset_session
  cookies.delete(:_stockerly_session, secure: Rails.env.production?, httponly: true, same_site: :lax)
  redirect_to root_path, notice: "Sesión cerrada correctamente."
end
```

**Why urgent:** Make logout foolproof on shared devices.

---

### **SOON — Email verification has no rate limit on GET (token enumeration)**

**Risk:** Low | **Exploitability:** Medium

**The issue:**
- `EmailVerificationsController#show` has no rate limit; only resend is rate-limited to 3/hour
- An attacker could brute-force email verification tokens if they know the email and registration time (±1 hour window)

**Fix (5 min):**
```ruby
rate_limit to: 10, within: 1.minute, only: :show
```

**Why SOON:** Trivial to block; at 5 users, if registration is closed, attackers might focus here.

---

### **LATER — Bug report mailer sends user email in reply-to without masking**

**Risk:** Very Low | **Exploitability:** Very Low

**The issue:**
- `BugReportMailer#notify` sends bug reports to support with `reply_to: user.email` (`app/mailers/bug_report_mailer.rb:9`)
- If support inbox is forwarded or leaked, user emails are revealed

**Fix (15 min):** Embed user email in the body with a masking token instead of in reply-to.

**Why LATER:** Not urgent at 5 users. You know everyone. But document that support@notdefined.dev is internal-only.

---

## Top 3 recommendations for Adrian before cohort grows

### 1. **Seal the invite code race condition (BEFORE 5 USERS — this week)**

**What to do:** Add a database-level unique constraint on `(invite_code.code, invite_code.used_by_user_id)`, ensuring no two users can redeem the same code. Or move the code to a "reserved" state atomically before user creation.

**What breaks if not done:** At 5 users, one beta amigo receives an invite, another person grabs the link from their email preview, and both try to register simultaneously. One will succeed; the other will see "code already used" and blame the product. A griefer uses the same invite to create a duplicate account, cluttering your database.

**By when:** Before next Thursday (2026-05-30). Before the second or third invite is issued.

**Effort:** 1–2 hours.

---

### 2. **Make audit logs readable and immutable (BEFORE 10 USERS — next sprint)**

**What to do:**
- Build `Admin::AuditLogsController` with filtering by user, action, and date
- Add a `SystemLog` dashboard showing errors and warnings
- Schedule a retention job: keep audit logs for 90 days (per your compliance policy)
- Document that audit logs are append-only

**What breaks if not done:** When the third amigo reports "my trade disappeared," you won't be able to audit who changed it, when, or from where. At 20 users, you'll be managing dozens of support tickets with zero forensic data.

**By when:** Before the cohort grows to 5. By 2026-06-06.

**Effort:** 3–4 hours.

---

### 3. **Harden the remember-me token lifecycle (BEFORE 20 USERS — next quarter)**

**What to do:**
1. Log IP/UA mismatches in remember-token reuse (soft enforcement): if a token is used from a different IP or UA, create a `SystemLog` warning.
2. Explicitly expire both session cookies on logout.
3. Add a "Sessions" page where users see active sessions and can revoke them individually (you already compute `@active_sessions` in `ProfilesController#show`, just add UI).

**What breaks if not done:** At 20 users, when one amigo gets phished or their device is compromised, the attacker can use the stolen remember-me cookie for 30 days undetected. Audit logs look normal because IP/UA aren't checked.

**By when:** Before hitting 20 active users. Q3 2026.

**Effort:** 4–6 hours.

---

## Summary

Stockerly's foundation is sound: IDOR is correctly mitigated, passwords are hashed, and auth entry points are rate-limited. **The critical gap is the invite code race condition**, which is exploitable today and becomes a PR disaster at 5 users. Fix that immediately.

The secondary gaps (no audit log UI, incomplete session revocation, token reuse detection) are table stakes for multi-user SaaS and can land next sprint or Q3, but they're not show-stoppers for a 5-user beta.

You're well-positioned to scale. Prioritize the race condition and audit trails, and you'll be comfortable inviting the second cohort in June.
