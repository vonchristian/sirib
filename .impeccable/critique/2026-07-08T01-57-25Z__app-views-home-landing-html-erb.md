---
target: landing page
total_score: 19
p0_count: 1
p1_count: 3
timestamp: 2026-07-08T01-57-25Z
slug: app-views-home-landing-html-erb
---
Method: dual-agent (A: ses_0c0904f60ffeK4JSNAbiOTAPyV · B: ses_0c0903db0ffeblnDV4nLjkaGVd)

## Design Health Score

| # | Heuristic | Score | Key Issue |
|---|-----------|-------|-----------|
| 1 | Visibility of System Status | 3 | No active section indicator in nav |
| 2 | Match System / Real World | 4 | Specific cooperative language — grounded, credible |
| 3 | User Control and Freedom | 2 | No skip-to-content, mobile nav overflows at <520px |
| 4 | Consistency and Standards | 1 | Two-brand-color problem: landing rust (#b45309) vs product gold (#c8922a) |
| 5 | Error Prevention | N/A | No forms on landing page |
| 6 | Recognition Rather Than Recall | 3 | Clear section labels, unambiguous callouts |
| 7 | Flexibility and Efficiency | 1 | No keyboard shortcuts, no expandable FAQ, no search |
| 8 | Aesthetic and Minimalist Design | 2 | 7 identical section structures, same card pattern repeated 4x |
| 9 | Error Recovery | N/A | Landing page has no error states |
| 10 | Help and Documentation | 3 | FAQ addresses 6 real objections, could use glossary or docs link |
| **Total** | | **19/32** | **Acceptable — significant improvements needed** |

## Anti-Patterns Verdict

**Verdict: Moderate AI slop. A sharp observer would recognize templated patterns.**

**LLM assessment:** The page exhibits multiple AI tells:
- **Eyebrow-on-every-section pattern**: All 7 sections use the identical `.landing-label` — uppercase JetBrains Mono, 0.1em tracking. This is the strongest "AI made this" signal.
- **Hero-metric template**: "8,000+ / 48 hrs / 100%" — three stat cards with monospace numbers. Classic GPT-generated landing pattern.
- **Identical card grids repeated**: Features (4), Roles (4), Testimonials (3), FAQs (6) — all same card class, same border, same spacing. Only column count varies.
- **Numbered process markers**: Steps 1-4 in the transition section are functional but visually redundant.

**Deterministic scan:** The bundled antipattern detector found **zero hits** in the file. This means the detector's rule set doesn't cover the specific patterns present (eyebrow labels, hero metrics, card grid repetition). The issues are structural/compositional, not syntactic — a human eye caught what no regex can.

**Key discrepancy:** The two-brand-color problem (rust accent on landing vs gold in product) was not flagged by the detector. This is a design-system-level issue that no automated scan would catch. **This is the single highest-impact finding.**

## Overall Impression

The copywriting is genuinely good — specific, grounded, avoids SaaS clichés. The transition section ("Your old system stays open") and CTA structure ("Watch a walkthrough OR talk to a cooperative manager") are well-considered. But the visual execution undermines the strong messaging. The page looks like a template: every section starts with the same tiny tracked label, follows with the same card grid, ends with the same border. The emotional peak (transition section) and the CTA are earned, but the middle feels assembled, not designed. The biggest problem is the brand split — the page markets a gold-accented product using a rust-accented identity.

## What's Working

1. **Copywriting is specific and grounded.** No "leverage" or "revolutionize." "Tellers", "passbooks", "BSP compliance", "45 minutes of manual counting", "ring binders" — someone who knows coops wrote this.
2. **Transition section is brilliantly framed.** "Your old system stays open until you're ready" neutralizes the primary objection. Low-risk, parallel-run framing builds trust.
3. **CTA structure is well-designed.** Two paths — watch a walkthrough OR talk to a peer — accommodate both analytical and trust-driven buyers. "No Pitch. Just Proof." is earned after the FAQ.

## Priority Issues

### P0 — Two-brand-color problem (brand.css:531 vs brand.css:13)
**What:** Landing page accent is `#b45309` (rust/amber) while product primary is `#c8922a` (gold). Additionally, `.landing-label` fallback is `#d4af37` gold while `.landing-accent` is `#b45309` rust — the page's own accent is internally inconsistent.
**Why it matters:** A visitor sees rust on the landing page, signs up, then sees gold in the app. Subconscious brand trust break. Feels like two products.
**Fix:** Align landing accent to gold primary (`#c8922a`). Remove separate `--color-landing-accent` variable.
**Command:** `/impeccable colorize landing page`

### P1 — landing-label eyebrow on every section (7 of 7)
**What:** Every section opens with `.landing-label` — same font, size, tracking, position. "For Philippine Cooperatives", "Everything You Need...", "One Source of Truth", etc.
**Why it matters:** Strongest "AI made this" signal. Undermines trust in a page that otherwise has specific copy.
**Fix:** Vary section intros. Some lead with h2 directly, some use a quote or stat, some use a different label treatment. Reserve `.landing-label` for 2-3 key sections.
**Command:** `/impeccable distill landing page`

### P1 — Hero metrics feel fabricated
**What:** "8,000+ members served daily", "48 hrs", "100% stayed" — no source, no attribution. "100% stayed" invites disbelief.
**Why it matters:** First credibility check after hero headline. Once trust is questioned, everything below gets scrutinized harder.
**Fix:** Remove or attribute. Add case study citation, real customer name, or replace with a testimonial pull-quote.
**Command:** `/impeccable clarify landing page`

### P1 — Mobile nav breaks at <520px (brand.css:561)
**What:** The "For Staff" dropdown has `width: 520px` — overflows on any screen narrower than ~600px. No hamburger menu, no responsive collapse.
**Why it matters:** Most common internet user (mobile) sees a broken nav. Credibility-killer for a productivity product.
**Fix:** Implement responsive hamburger nav at `sm:` breakpoint. Change dropdown width to responsive units or use a mobile slide-out drawer.
**Command:** `/impeccable adapt landing page`

### P2 — No progressive disclosure (FAQ always expanded, all cards visible)
**What:** FAQ shows all 6 answers always visible. Transition section shows 4 steps open. No accordion, no reveal, no interaction anywhere on page.
**Why it matters:** Landing pages should reward scanning. User must scroll past 5 irrelevant FAQ answers to find the one they need.
**Fix:** Make FAQ an accordion via Turbo Frames. Use staggered entrance animations on card grids.
**Command:** `/impeccable animate landing page`

### P2 — Identical card grids across 4 sections
**What:** Features, Roles, Testimonials, FAQ cards all use the same `.landing-card border p-8` class. Same background, same border, same spacing. Only column count varies.
**Why it matters:** Feels template-assembled rather than designed. Each section type should have a distinct visual fingerprint.
**Fix:** Differentiate per section: features get accent top borders, roles use surface-alt bg, testimonials get quote decorations, FAQs use left-aligned Q/A layout.
**Command:** `/impeccable layout landing page`

## Persona Red Flags

### Alex (Power User)
- No "Skip to content" link — must tab through nav
- No keyboard shortcuts for FAQ, CTA, or testimonials
- FAQ not collapsible — can't quickly scan

### Sam (Accessibility)
- Missing skip-to-content link (WCAG 2.4.1 failure)
- Dropdown relies on hover — `focus-within` fallback helps but keyboard reachability is unclear
- No distinct `:focus-visible` styles on landing accent buttons
- `color-mix(in oklab, ...)` on nav-bg — unsupported in pre-2023 Safari

### Casey (Mobile / Interrupted)
- Nav dropdown overflows at <520px — entire right nav breaks on iPhone
- `min-h-[90vh]` hero — must scroll past full viewport before seeing content
- `py-32` sections create enormous vertical space on mobile

## Minor Observations

- No `og:image` or social preview meta tags — shared links show bare URL on Facebook/WhatsApp
- "Watch Overview" nav link targets `#demo` which has buttons labeled "Watch the Walkthrough" — naming mismatch
- All screenshots are SVGs, not real screenshots — less credible for skeptical coop audience
- Footer links to `/tellers`, `/loan-officers`, etc. — likely 404 if those routes don't exist
- Nav has 9+ destinations — competing with the single conversion goal
- The landling-accent is `#b45309` (nice rust) but NOT the brand gold `#c8922a`

## Questions to Consider

1. If the landing page accent is rust and the app accent is gold, which one is the real Sirib brand? A user who signs up sees a different color on day one. Is the landing page marketing a different product?
2. The page has zero interaction beyond clicking links — no accordions, no reveals, no staggered animations. For a product that promises to eliminate repetition, why is the landing page itself 7 sections of identical repetitive card grids?
3. "100% of coops that started stayed." With how many coops? How would you defend this number to a board treasurer who's been burned by vendors?
4. All screenshots are below the fold after 2 sections of card grids. Why not take the user straight to the product from the hero CTA?
