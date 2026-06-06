# Kafi v8 HTML — screen map

Open `kafi-platform-v8-final (1).html` and jump to the `id` below.

| Section `id` | Tab label (mockup nav) |
|--------------|------------------------|
| `welcome` | Welcome |
| `login-nanny` | Login — Nanny |
| `login-family` | Login — Family |
| `otp-verify` | OTP Verify |
| `create-pw` | Create Password |
| `nanny-info` | Nanny — Personal Info |
| `nanny-media` | Nanny — Media |
| `nanny-exp` | Nanny — Experience |
| `nanny-refs` | Nanny — References |
| `nanny-docs` | Nanny — Documents |
| `nanny-pending` | Nanny — Pending |
| `nanny-dash` | Nanny — Dashboard |
| `family-form` | Family — Post Job |
| `browse` | Browse Nannies |
| `profile-locked` | Profile Locked |
| `profile-unlocked` | Profile Unlocked |
| `chat` | In-App Chat |
| `smart-match` | Smart Match |
| `trial` | Trial System |
| `pricing` | Pricing |
| `terms` | Terms |
| `privacy` | Privacy |
| `admin` | Admin |

**Tip:** Search `id="screen-name"` or the tab emoji label in the HTML file.

## Screens not in HTML

Use the same theme on every app screen even if there is no mockup tab. Pick the closest reference:

| App screen type | Reference `id` |
|-----------------|----------------|
| Auth / login / OTP / password | `login-nanny`, `otp-verify`, `create-pw` |
| Onboarding forms (personal, job, prefs) | `nanny-info`, `family-form` |
| Media upload | `nanny-media` |
| Lists / browse / search results | `browse`, `smart-match` |
| Detail / profile | `profile-locked`, `profile-unlocked` |
| Chat / messaging | `chat` |
| Subscription / paywall | `pricing` |
| Trial / booking status | `trial` |
| Dashboard / home hub | `nanny-dash` |
| Legal | `terms`, `privacy` |
| Admin / internal tools | `admin` |
| Waiting / pending states | `nanny-pending` |

If no row fits, combine patterns from the two closest ids and run the full checklist in `SKILL.md`.
