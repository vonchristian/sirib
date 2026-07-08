---
target: app/views/home/landing.html.erb
total_score: 28
p0_count: 2
p1_count: 3
timestamp: 2026-07-08T02-10-49Z
slug: app-views-home-landing-html-erb
---
Method: dual-agent (A: ses_0c084dcb7ffeiY735rMFLk4mBd · B: ses_0c084ca9bffe6p5VEnCavyJzNP)

## Design Health Score

| # | Heuristic | Score | Key Issue |
|---|-----------|-------|-----------|
| 1 | Visibility of System Status | 2 | No scroll progress, no loading states for images |
| 2 | Match System / Real World | 4 | Cooperative-specific language throughout, authentic voice |
| 3 | User Control and Freedom | 3 | Escape+backdrop on mobile nav, accordion works; dead-end CTA costs a point |
| 4 | Consistency and Standards | 4 | Heading patterns, button styles, section rhythm all consistent |
| 5 | Error Prevention | 3 | Static page — minimal risk; FAQ silently fails if content missing |
| 6 | Recognition Rather Than Recall | 3 | Descriptive headings, roles repeated in nav/body/footer |
| 7 | Flexibility and Efficiency | 2 | No skip-to-content, no search, no keyboard accelerators |
| 8 | Aesthetic and Minimalist Design | 4 | Clean, restrained, purposeful — genuine improvement |
| 9 | Error Recovery | 1 | Broken SVGs get native alt but no styled fallback; no error handling on links |
| 10 | Help and Documentation | 2 | FAQ addresses real concerns but no support link, no docs reference |
| **Total** | | **28/40** | **Good** (up from 19/40, +9 pts) |

## Anti-Patterns Verdict

**AI slop?** No — the page has genuinely moved past AI-template territory. The copy is specific, the card differentiation is earned, the numbered steps serve a real sequence, and the warm palette is intentional brand language (not default beige).

**Deterministic scan**: 3 findings, all `side-tab` — the `border-l-4` gold accent bars on testimonial cards (lines 181, 189, 197). This is an absolute ban per the skill. While the intent (differentiation) is valid, the pattern is detectably AI. Could be replaced with a full background tint or a leading quote icon large enough to serve as the accent.

**Browser evidence**: Page loads and renders. 2 console 404s (`animations.css`, `brand.css`) — these assets are referenced in the layout but missing from the compiled pipeline. Core Tailwind styles load fine, so the page looks correct, but any custom animation/brand classes from those files would be absent.

## Overall Impression

The page improved dramatically: the brand color alignment, eyebrow reduction, and card differentiation each fix major wounds from the first critique. The copy and emotional journey are the strongest parts. But two real bugs surfaced (the mobile nav is broken, both CTA buttons are infinite loops), and the remaining surface-level issues (contrast, side-tab detector hits) prevent this from being production-ready.

## What's Working

1. **Transition section emotional architecture** — The 4-step parallel-run process (lines 132-172) is the best-designed part of the page. It directly addresses switching risk, the #1 objection for cooperative decision-makers.

2. **Card differentiation** — Features get gold gradient top bars, roles get `border-l-2`, testimonials get `border-l-4` + quote icons + alt background. Each section reads distinctly without fragmentation. This alone fixes the "card factory" problem from the first critique.

3. **Copy voice consistency** — "No Pitch. Just Proof.", "without the busywork", "end-of-day is done before the last member leaves" — the toolbox-standard voice is consistent and credible.

## Priority Issues

### P0 — Mobile nav drawer is broken
The Stimulus target name `menu` is applied to both the hamburger SVG icon and the drawer panel. `this.menuTarget` always returns the first match (the SVG), so `open()` toggles `translate-x-0`/`translate-x-full` on the SVG — invisible. The backdrop appears, body scroll locks, but the drawer never slides in. A user tapping the hamburger sees a dark overlay with no panel behind it. Fix: remove `data-mobile-nav-target="menu"` from the hamburger SVG, or rename the drawer target to something unique.
**Suggested command**: `/impeccable adapt`

### P0 — Side-tab borders detected as AI slop (3 count)
All three testimonial cards use `border-l-4 border-[var(--color-landing-accent,#c8922a)]` — a thick gold left border. The detector flags this as an absolute-ban AI pattern. While the testimonials look better than the previous identically-carded version, the implementation hit the wrong pattern. Replace with a full background tint or a large decorative quote mark as the primary accent.
**Suggested command**: `/impeccable layout`

### P1 — `landing-label` eyebrow text fails WCAG contrast (~1.4:1)
Gold `#d4af37` / `#c8922a` at 0.75rem on `#faf9f7` warm cream — ~1.4:1. WCAG AA needs 4.5:1. The three eyebrow labels are invisible for users with low vision or in bright light. Fix: darken gold to ~`#7a6618` or switch to the muted color token.
**Suggested command**: `/impeccable colorize`

### P1 — Hero stat labels fail WCAG contrast (~2.7:1)
`#a8a29e` (`landing-dim`) on white — ~2.7:1. Three stat labels ("members served daily and growing", "as fast as 48 hours", "that started with Sirib is still on it"). Fix: darken to `#8a7f75` or use the `landing-muted` token.
**Suggested command**: `/impeccable colorize`

### P1 — Both CTA buttons anchor to #demo (infinite loop)
"Watch the Walkthrough" and "Talk to a Fellow Coop Manager" both point to `#demo` — the section containing those same buttons. A cooperative manager ready to act gets the same page with no form, no calendar, no email capture. The page has no conversion mechanism. Fix: wire buttons to an actual action (form modal, calendar booking, contact page).
**Suggested command**: `/impeccable harden`

### P2 — `landing-nav-dropdown` fallback is near-black `#0a0a0a`
If `--color-landing-bg` is unset (it's not in `:root`), the dropdown renders as a black panel on a light page. Fix: change fallback to `#faf9f7` or declare the variable in `:root`.
**Suggested command**: `/impeccable polish`

### P3 — 2 missing CSS assets in browser (404s)
`/assets/animations.css` and `/assets/brand.css` 404. Core page renders fine via Tailwind, but any custom classes from those files are silently missing.
**Suggested command**: `/impeccable polish`

## Persona Red Flags

**Riley (Stress Tester)** — Broken mobile nav confirmed. Riley opens on mobile, taps hamburger, sees backdrop with no panel. Instant critical bug.

**Jordan (First Timer)** — No conversion path. Jordan finishes the page ready to act, clicks "Book a Call", lands back at the same buttons. The page has no funnel entry. Also, "For Staff" nav label is ambiguous — does this mean Sirib's staff or cooperative staff?

**Alex (Power User)** — No skip-to-content, no section TOC on a 7-section page, no search. Alex would scan once, find no efficiency path, and leave.

## Minor Observations

- `data-accordion-target="item"` on FAQ wrappers — no Stimulus target `"item"` exists in the controller. Only `"content"` is declared. Dead attribute.
- Footer links (Tellers, Loan Officers, Finance, Compliance) all go to `/tellers`, `/loan-officers`, etc. — are these pages built?
- "Watch Overview" (nav) vs "Watch the Walkthrough" (CTA) — mismatched labels for what sounds like the same action.
- No `<title>` in the partial — relying on the layout. Hurts SEO if the layout doesn't set a page-specific title.
- No "About" link, no pricing signal, no team/company page — for a financial system targeting risk-averse cooperative boards, institutional credibility signals are missing from the bottom of the funnel.

## Questions to Consider

1. What actually happens when a coop manager clicks "Talk to a Fellow Coop Manager"? If the answer is nothing yet, that should be the very next thing built — it's the entire conversion point of the page.

2. Who builds and runs Sirib? The copy uses "we" consistently but never identifies who "we" is. For cooperative boards making a financial system decision, this anonymity works against credibility.

3. Are the testimonials from real people anonymized, or are they placeholders? The attribution pattern ("General Manager, Luzon Cooperative") reads as semi-fictional. Real names and real coop names would dramatically increase trust.
