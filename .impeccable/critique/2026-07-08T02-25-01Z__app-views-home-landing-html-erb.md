---
target: app/views/home/landing.html.erb
total_score: 29
p0_count: 1
p1_count: 3
timestamp: 2026-07-08T02-25-01Z
slug: app-views-home-landing-html-erb
---
Method: dual-agent (A: ses_0c077d743ffeGyGwgf6SLMrJjQ · B: ses_0c077cc29ffexAX6F9u4iYo6lb)

## Design Health Score

| # | Heuristic | Score | Key Issue |
|---|-----------|-------|-----------|
| 1 | Visibility of System Status | 3 | Scroll reveal and accordion rotate work; no scroll-position indicator |
| 2 | Match System / Real World | 4 | Cooperative-specific language remains excellent |
| 3 | User Control and Freedom | 4 | CTAs no longer loop (#1 win); mobile nav functional; Escape closes drawer |
| 4 | Consistency and Standards | 3 | Testimonials unified; "One source of truth" still uses border-l-2 (orphan) |
| 5 | Error Prevention | 3 | Dead attrs cleaned; all links valid |
| 6 | Recognition Rather Than Recall | 3 | Section headings clear |
| 7 | Flexibility and Efficiency | 2 | No skiplink; 30+ tab stops before hero content |
| 8 | Aesthetic and Minimalist Design | 3 | Dropdown bg fixed; contrast improved; gold-on-white button contrast now critical |
| 9 | Error Recovery | 2 | Marketing page, limited interactions |
| 10 | Help and Documentation | 2 | FAQ strong; no contact/help in nav; no privacy/terms in footer |
| **Total** | | **29/40** | **Good** (up from 28/40, +1 pt) |

## Anti-Patterns Verdict

**AI slop?** Low — content is genuinely specific to Philippine cooperatives (BSP compliance, passbook handwriting, ring binder loan records). No generic filler.

**Detector scan**: 0 findings. All 3 `side-tab` warnings from last round confirmed fixed. Testimonial cards now use `rounded-lg` + bg tint + large quote icon.

**Browser evidence**: Page loads, screenshots render, 0 broken images. 2 console 404s (`animations.css`, `brand.css`) — stale precompiled assets. Fix: `bin/rails assets:clobber`.

## Overall Impression

The page is close to production-ready on content and structure. The transition section, testimonials, and dual-path CTA are genuinely strong. The remaining issues are almost entirely color-system accessibility problems and polish items — no structural or copy problems remain.

## What's Working

1. **Testimonial section** — The `rounded-lg` + bg-tint + large quote SVG transformed the weakest section into the strongest. Quotes reference specific, non-obvious pain points (handwriting passbooks, ring binders, 3-year board approval cycle).

2. **Transition section** — Numbered 4-step process with concrete timelines and permission-giving language remains the page's best asset.

3. **Dual-path CTA** — "Watch the Walkthrough" / "Sign In" serves different buyer personalities (self-evaluator vs. relationship-trust).

## Priority Issues

### P0 — White-on-gold button contrast fails WCAG AA (~2.72:1)
`#c8922a` + `#ffffff` = ~2.72:1 across every `landing-btn-accent` instance (hero L19, CTA L300, nav both buttons). Also `landing-accent` text on cream `#faf9f7` = ~2.61:1 (hero L11, feature headings, transition section). Gold cannot serve as button bg with white text at current lightness. Fix: either darken gold to `#8a6318` for interactive surfaces, or use dark brown/charcoal button bg with white text, reserving gold for decorative accents only.

### P1 — No skiplink (WCAG 2.4.1)
Tab order traverses full nav (30+ stops) before reaching hero. Keyboard users must tab through every dropdown trigger and link. Fix: add a `#main-content` skiplink.

### P1 — Accordion lacks aria-expanded
`accordion_controller.js` toggles `hidden` on content but never updates `aria-expanded` on the `<button>`. Screen readers cannot determine open/closed state. Fix: toggle `aria-expanded` in the toggle method, with initial values in the HTML (first button `true`, rest `false`).

### P1 — Mobile drawer "Sign In" gold border contrast (~2.68:1)
`landing-border-accent` (gold border) + `landing-accent` (gold text) on cream bg. Fails WCAG non-text contrast (3:1). Fix: use `landing-border-muted` for the border.

### P2 — "One source of truth" section is a visual orphan
4-column grid (L88-103) uses `border-l-2` gold accent — the last survivor of the old side-tab pattern. Looks like leftover code after testimonials were fixed. Fix: convert to `rounded-lg p-4 landing-bg-alt border` with gold accent bar to match feature cards.

### P2 — Hero stat "Every coop" is qualitative
Three stats: two concrete numbers (8,000+, 48 hrs), one claim ("Every coop that started with Sirib is still on it"). Reads as filler. Fix: replace with an actual number ("12 coops", "100% retention").

### P3 — Button label mismatch
Nav "Watch Overview" vs CTA "Watch the Walkthrough" — same action, different labels.

### P3 — No privacy/terms in footer
Financial software for regulated entities. Footer has no privacy policy, terms of service, or copyright.

## Persona Red Flags

**Jordan (board member)** — No pricing, no security posture, no ROI language. Board needs these to self-qualify. FAQ BSP question is hidden in accordion — board members scan, they don't expand.

**Riley (ops manager)** — Transition section speaks directly to Riley ✓. But "Watch the Walkthrough" → `/tellers`. If that's a generic role page instead of a 3-minute walkthrough video, trust is broken on the most important click.

**Alex (teller/loan officer)** — Features + FAQ address learning-curve fear ✓. But no screenshot of the core teller workflow (process a deposit, print passbook) — the screen they'll use 50x/day.

## Minor Observations

- Gradient accent bar `from-[var(--color-landing-accent,#c8922a)] to-transparent` repeated 4× inline. Extract to utility class.
- `landing-nav-dropdown` has fragile centering (`left:50%; translate:-50% 0`) overridden by inline style. One CSS specificity change breaks it.
- Screenshots are `.svg` files. If these are raster images wrapped in SVG, convert to `.webp` for bandwidth.
- On iOS Safari, `body.style.overflow = "hidden"` does not prevent scroll (known bug). Mobile drawer can scroll behind.

## Questions to Consider

1. **The gold accent is the most distinctive brand element. But it fails WCAG AA as text and as button backgrounds. How much of the brand are you willing to sacrifice for accessibility?** Gold can remain as decoration (borders, top bars, 30% opacity icons). But every interactive surface (buttons, links, readable labels) needs a darker, accessible shade.

2. **The CTA links to `/tellers`. Is there a 3-minute video walkthrough there?** That click is the most important action on the page. A generic role page would contradict "No Pitch. Just Proof."

3. **"One source of truth" uses the old `border-l-2` pattern you just fixed on testimonials. Intentional variation or leftover debt?** If intentional, it needs a different treatment that doesn't look like untended code.

4. **How many coops does Sirib actually serve?** "Every coop" implies 2+. If it's 10+, lead with the number. The omission reads as avoidance.
