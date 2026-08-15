---
name: software-development
description: Senior software engineering playbook for planning and writing production-quality code that follows the project's EXISTING architecture, design system, and best practices — read the current code first, match the project's UI/design guidelines and tokens (never generic AI-looking UI), SOLID design, typing and input validation, exhaustive error handling, security, performance (incl. Core Web Vitals), testing, small focused diffs, and a self-review gate. Covers Flutter, React/Next.js, Node.js, and Shopify. Use this whenever you plan an implementation, write UI or code, or fix code — even if "best practices" isn't said explicitly.
---

# Senior Software Development

This is the engineering standard for everything built here. Whether you are
*planning* an implementation (architect) or *writing* it (developer/fixer), hold
this bar. The golden rule: **conform to the project as it already is.** You are
extending an existing codebase, not starting a greenfield one.

## 1. Read the current code FIRST — always

Never plan or write from assumptions. Before any plan or any edit:
- Read the actual source of the area you're touching. Map entry points, data
  flow, and the existing patterns (state management, data layer, routing,
  styling, error handling).
- Locate the project's conventions and **reuse** them: existing utilities,
  helpers, components, hooks, services. Duplicating something that already exists
  is a defect, not a shortcut.
- Only after you understand the current implementation do you decide what to
  change. "Read, then plan, then change" — in that order, every time.

## 2. Architecture principles

- **Match the codebase.** Adopt its conventions, naming, folder structure, and
  paradigm. Do not introduce a competing pattern. Consistency beats personal
  preference.
- **Single responsibility.** Each function/component/module does one thing.
- **Separation of concerns.** UI, business logic, and data access stay in their
  own layers. No fetch calls in view components, no business rules in the data
  layer.
- **Smallest change that's correct.** No speculative abstraction, no gold-plating.
- **If the existing architecture is genuinely bad,** flag it and propose a
  contained refactor — never silently work around it, never pile new code on a
  broken foundation. Architecture decisions belong to the architect; if you're
  implementing, escalate rather than improvise.

## 3. Match the project's UI / design system (do NOT invent UI)

Any user-facing change must look like it was built by the same team that built
the rest of the app. Generic AI-default styling is a defect here.

**Before writing any UI, find and read the project's design source of truth:**
- **Design tokens / theme:** colors, typography (families, sizes, weights, line
  heights), spacing scale, border radius, shadows/elevation, motion/transition
  values, breakpoints. These usually live in a theme file, a tokens file, a
  Tailwind config, CSS custom properties, or a design-system folder. Use the
  tokens — never hardcode one-off hex values, magic pixel numbers, or ad-hoc
  fonts.
- **Component library:** the project's existing buttons, inputs, cards, modals,
  layout primitives. Reuse them. Do not rebuild a button that already exists, and
  do not introduce a new UI library the project doesn't already use.
- **Patterns & conventions:** how the project does spacing, states (hover/active/
  disabled/loading/empty/error), iconography, form layout, responsive behavior,
  dark mode, and accessibility. Mirror them exactly.
- **Reference designs:** if there's a Figma/spec/design doc for this feature
  (e.g. extracted design tokens for a specific screen), follow it precisely —
  match the tokens, don't approximate.

**Explicitly avoid the generic AI look:** default Inter font, purple gradients,
uniform rounded cards, safe neutral palettes, and centered hero layouts that
don't match the product. If you can't tell what the project's design language is,
that means you haven't found the design source yet — go find it before building.

Per stack:
- **Flutter:** use the app's `ThemeData` / `ColorScheme` / `TextTheme` and any
  custom theme extensions; don't hardcode colors or text styles inline.
- **React / Next.js:** use the existing Tailwind config / CSS variables / styled
  system and the project's component library; don't add a second styling approach.
- **Shopify:** respect theme settings, section schema, and the theme's CSS
  variables/snippets; match the store's existing typography, spacing, and color
  variables; don't break the theme editor.

## 4. Correctness and safety

- **Type everything.** No `any`/`dynamic` without a written reason.
- **Validate every external input** — API params, form fields, route params,
  webhook payloads, env values. Never trust the boundary.
- **Error handling is mandatory.** Every async call, network request, file/JSON
  parse has an explicit failure path. No empty `catch`, no swallowed errors.
- **No secrets in code.** Keys, tokens, pixel IDs, DB creds -> env/config.
- **Concurrency & state:** avoid races; don't mutate shared state without control;
  clean up listeners/subscriptions/timers.

## 5. Performance

- No N+1 queries; batch and paginate. No unbounded loops over network calls.
- Don't block the main thread / event loop with heavy sync work.
- Ship optimized media; lazy-load below the fold.
- **Web — protect Core Web Vitals (LCP, CLS, INP).** Reserve space to avoid
  layout shift, defer non-critical JS, preconnect critical origins, avoid
  render-blocking resources. (Directly relevant to naturesecret.pk.)

## 6. Testing

- Where the project has tests, add/adjust them for your change — happy path plus
  the failure paths you introduced.
- Where it doesn't, still structure code so it *could* be tested.
- Run the build, linter, type-checker, and tests for the area you touched. Make
  them green before declaring done. Report honestly if something can't pass.

## 7. Diffs and commits

- Keep diffs small and focused on one unit of work. Unrelated cleanups go
  separately. Don't touch files outside your assigned unit.
- Commit messages: what changed and why, referencing the task.

## 8. Self-review gate (before you say "done")

- [ ] Read the current code before changing it; reused what exists.
- [ ] Matches the plan/spec exactly; no unplanned design decisions.
- [ ] UI matches the project's design tokens/components — no generic AI styling.
- [ ] Follows existing patterns and conventions.
- [ ] Typed; all external input validated.
- [ ] Every failure path handled; no empty catches.
- [ ] No secrets; no obvious perf regression (CWV on web).
- [ ] Build/lint/types/tests green.
- [ ] Diff is minimal and scoped.

## Anti-patterns
- Planning or writing before reading the surrounding code.
- Inventing UI / using generic AI defaults instead of the project's design system.
- Hardcoding colors/spacing/fonts instead of using the project's tokens.
- Introducing a new architecture or styling approach mid-task.
- Empty `catch` blocks, swallowed errors, untyped/unvalidated boundaries.
- "While I'm here" changes that balloon the diff.
- Declaring done without running the build/tests.
