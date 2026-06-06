---
name: kafi-ui-reference
description: Enforces Kafi UI screen-by-screen against the v8 HTML mockup and extends the same theme to screens not in the HTML. Use when building, reviewing, or fixing any Kafi screen, widget, theme, or component styling.
---

# Kafi UI Reference (v8 HTML)

## Source of truth

**File:** `kafi-platform-v8-final (1).html` (project root)

- **Mapped screens:** match that section pixel-for-pattern (layout, copy placement, states).
- **Unmapped screens:** no new visual language — derive from the shared theme + closest HTML screen (see below).

Docs = behavior. HTML = look for mapped screens. **Theme tokens + component library = look for all screens.**

## When to apply

Every Kafi UI change: new screen, edit, bugfix, theme, shared widget.

## Workflow

### A. Screen has a section in HTML

1. Find section `id` in [screen-map.md](screen-map.md); read full HTML block for that screen.
2. Run **Screen comparison checklist** (below) — every item, not a spot-check.
3. Fix any mismatch in code before finishing.
4. If behavior differs from docs but visuals differ from HTML → **HTML wins for UI** unless user overrides.

### B. Screen is NOT in HTML

1. Map to **closest HTML screen** by flow (e.g. settings → `nanny-dash`; payment error → `pricing`; edit form → `nanny-info`).
2. Reuse **only** tokens, fonts, and components from the mockup — never Material defaults or ad-hoc colors.
3. Run the same **Screen comparison checklist** against the closest reference screen + global theme.
4. New layouts must look like they belong in the same app: same header style (`.fhdr`), form sections (`.fsec`), cards, chips, CTAs, empty/loading patterns as sibling screens.

### C. After any screen work

- Scan **other screens** you touched or that share widgets — regressions must match theme.
- Prefer **shared theme/widgets** over one-off styling so unmapped screens stay consistent.

## Screen comparison checklist

Copy and verify **per screen** before marking done:

```
Screen: _______________  HTML id: _______________  (or "unmapped → ref: ___")

Structure & layout
- [ ] Same hierarchy (header → body → footer/actions)
- [ ] Padding/margins match reference (form-body ~12px, section gaps ~13px)
- [ ] Grids/columns match (g2, g3, chip-wrap, photo-row)
- [ ] Scroll areas and fixed footers behave like mockup

Chrome & navigation
- [ ] Status/header bar (.sbar, .fhdr) style matches
- [ ] Back button (.back-btn) size ~27px, white circle, shadow
- [ ] Progress bar / step dots if flow is multi-step
- [ ] Bottom nav / tab styling if screen has nav (navy bar, rose active)

Typography
- [ ] Pacifico: logo, .pg-title
- [ ] Fredoka: tabs, buttons, chips, badges
- [ ] Nunito: body, labels, inputs
- [ ] Text colors: td / tm / ts — not generic grey/black

Color & surfaces
- [ ] Background gradients match screen family (rose login, purple OTP, green success, etc.)
- [ ] Cards: white + #FFD8E8 border, ~12px radius
- [ ] No off-palette colors; use :root tokens only

Components (every instance on screen)
- [ ] Primary / purple / green buttons (.next-btn, .nb-r / .nb-p / .nb-g)
- [ ] Inputs (.inp / .inp-p): bg, border, focus, placeholder tone
- [ ] Selects, textareas, toggles, chips (.chip .on states)
- [ ] Upload / video areas (.pu-area, .vid-area) if applicable
- [ ] List rows (.doc-item), badges (.callable-badge), avatars
- [ ] Icons/emojis consistent with mockup role

States & content
- [ ] Default, focused, selected, disabled, locked, empty, error, loading
- [ ] Copy placement and emphasis (titles, subtitles, tips)
- [ ] Shadows and gradients on CTAs and icon circles

Final
- [ ] Side-by-side with HTML section (or reference screen) — no visual outliers
- [ ] Same screen at different sizes still uses theme scale, not new styles
```

## Design tokens (from `:root`)

| Token | Value | Use |
|-------|-------|-----|
| rose / rose-d / rose-l / rose-p | `#FF8FAB` / `#FF5C8A` / `#FFB5C8` / `#FFF0F5` | Primary CTAs, accents |
| pur / pur-l / pur-b | `#9B6EDB` / `#F5EEFF` / `#E0C8F0` | Secondary / purple flows |
| grn / grn-l / grn-d | `#6DBF8A` / `#E8F8EE` / `#2E9A58` | Success, callable badges |
| amb / amb-l | `#FFB347` / `#FFF4E0` | Warnings |
| navy / navy-s | `#1E2A4A` / `#E8EBF5` | Tab bar, dark chrome |
| teal | `#0EA5A0` | Accents |
| td / tm / ts | `#3D1A26` / `#7A3A50` / `#C490A0` | Text primary / mid / soft |

**Fonts:** `Pacifico` (logo, page titles), `Fredoka` (tabs, buttons, chips), `Nunito` (body, inputs).

**Scale:** mock ~292px wide — keep radius (~10–14px cards, ~12px buttons, ~40px phone shell), shadows, and spacing ratios when scaling up.

## Component patterns (global — all screens)

| Pattern | HTML class | Rule |
|---------|------------|------|
| Primary CTA | `.next-btn.nb-r` | Rose gradient, Fredoka ~13px, radius 12px, shadow |
| Secondary CTA | `.nb-p` / `.nb-g` | Purple / green gradient |
| Input | `.inp` / `.inp-p` | Rose or purple variant; never plain grey fields |
| Section title | `.fsec-hd` | Uppercase small label, icon box, rose underline |
| Chip | `.chip.cr` / `.cp` + `.on` | Rose or purple selected state |
| Card | `.exp-card`, `.ref-card`, `.doc-item` | White, `#FFD8E8` border |
| Page title | `.pg-title` + `.pg-sub` | Pacifico title + soft subtitle |

Unmapped screens: combine these patterns only; grep HTML for the nearest example.

## Fixing mismatches

1. Theme tokens (colors, fonts, radii)
2. Shared component wrong → fix widget, then all screens using it
3. Layout vs HTML reference section
4. Missing states/elements from reference
5. Never ship a one-off style that breaks the Kafi look

## Coordination with Kafi docs

`kafi-doc-sync` for flows and rules. This skill for **all visual work** — mapped and unmapped screens.

## Additional resources

- [screen-map.md](screen-map.md) — HTML section ids
- `kafi-platform-v8-final (1).html` lines 8–120+ — full `:root` and shared CSS
