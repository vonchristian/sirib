---
name: Sirib
description: Cooperative banking platform for Philippine cooperatives
colors:
  primary: "#5b8c5a"
  primary-50: "#f0f7ef"
  primary-100: "#dcecdb"
  primary-200: "#b8d4b5"
  primary-300: "#8fb68b"
  primary-400: "#6fa06b"
  primary-500: "#5b8c5a"
  primary-600: "#4a7649"
  primary-700: "#3d6b3c"
  primary-800: "#2d522c"
  primary-900: "#1e381d"
  surface: "#ffffff"
  surface-alt: "#f7f5f0"
  surface-raised: "#ffffff"
  text-primary: "#2c241b"
  text-secondary: "#6e6358"
  text-tertiary: "#aea398"
  border: "#e8e0d5"
  border-strong: "#d4cabd"
  positive: "#059669"
  positive-50: "#ecfdf5"
  positive-700: "#047857"
  warning: "#d97706"
  warning-50: "#fffbeb"
  danger: "#dc2626"
  danger-50: "#fef2f2"
  landing-bg: "#faf9f7"
  landing-alt: "#f5f3ef"
  landing-text: "#1c1917"
  landing-muted: "#78716c"
  landing-dim: "#a8a29e"
  landing-accent: "#5b8c5a"
  landing-accent-dark: "#3d6b3c"
  landing-border: "#e7e5e4"
  dark-surface: "#1e1b18"
  dark-surface-alt: "#231f1c"
  dark-surface-raised: "#2a2622"
  dark-text-primary: "#f5efe6"
  dark-text-secondary: "#aea398"
  dark-text-tertiary: "#897f75"
  dark-border: "#352e27"
  dark-border-strong: "#4c443c"
typography:
  display:
    fontFamily: "Inter, ui-sans-serif, system-ui, -apple-system, BlinkMacSystemFont, sans-serif"
    fontSize: "clamp(2.5rem, 5vw, 4.5rem)"
    fontWeight: 300
    lineHeight: 1
    letterSpacing: "-0.04em"
  body:
    fontFamily: "Inter, ui-sans-serif, system-ui, -apple-system, BlinkMacSystemFont, sans-serif"
    fontSize: "0.875rem"
    fontWeight: 400
    lineHeight: 1.5
  label:
    fontFamily: "JetBrains Mono, ui-monospace, monospace"
    fontSize: "0.75rem"
    fontWeight: 500
    lineHeight: 1
    letterSpacing: "0.1em"
    textTransform: uppercase
rounded:
  xs: "0.25rem"
  sm: "0.375rem"
  md: "0.5rem"
  lg: "0.5rem"
  xl: "0.625rem"
  "2xl": "0.75rem"
spacing:
  xs: "0.25rem"
  sm: "0.5rem"
  md: "0.75rem"
  lg: "1rem"
  xl: "1.25rem"
  "2xl": "1.5rem"
components:
  button-primary:
    backgroundColor: "{colors.primary}"
    textColor: "#ffffff"
    rounded: "{rounded.md}"
    padding: "0.5rem 1rem"
  button-primary-hover:
    backgroundColor: "{colors.primary-700}"
  button-secondary:
    backgroundColor: "{colors.surface}"
    textColor: "{colors.text-primary}"
    rounded: "{rounded.md}"
    padding: "0.5rem 1rem"
  button-ghost:
    backgroundColor: transparent
    textColor: "{colors.text-primary}"
    rounded: "{rounded.md}"
    padding: "0.5rem 1rem"
  button-danger:
    backgroundColor: "{colors.danger}"
    textColor: "#ffffff"
    rounded: "{rounded.md}"
    padding: "0.5rem 1rem"
  button-positive:
    backgroundColor: "{colors.positive}"
    textColor: "#ffffff"
    rounded: "{rounded.md}"
    padding: "0.5rem 1rem"
  card:
    backgroundColor: "{colors.surface}"
    rounded: "{rounded.lg}"
  input:
    backgroundColor: "{colors.surface}"
    rounded: "{rounded.md}"
    padding: "0.5rem 0.75rem"
  badge:
    backgroundColor: "{colors.primary-50}"
    textColor: "{colors.primary-700}"
    rounded: 9999px
    padding: "0.125rem 0.625rem"
  badge-success:
    backgroundColor: "{colors.positive-50}"
    textColor: "{colors.positive-700}"
    rounded: 9999px
  badge-warning:
    backgroundColor: "{colors.warning-50}"
    textColor: "{colors.warning}"
    rounded: 9999px
  badge-danger:
    backgroundColor: "{colors.danger-50}"
    textColor: "{colors.danger}"
    rounded: 9999px
  nav-link:
    rounded: "{rounded.md}"
    padding: "0.5rem 0.75rem"
  nav-link-active:
    backgroundColor: "#f0e8d8"
    textColor: "{colors.primary-700}"
  stat-card:
    backgroundColor: "{colors.surface}"
    rounded: "{rounded.lg}"
    padding: "{spacing.xl}"
---

# Design System: Sirib

## 1. Overview

**Creative North Star: "The Toolbox Standard"**

Sirib's design is a set of reliable, well-crafted tools that feel solid in the hand — like a well-worn ledger or a brass calculator that has never made a mistake. It is calm and professional without being cold. Every surface has a purpose, every interaction is deliberate. The system earns its keep by making daily banking operations faster, clearer, and less error-prone.

The palette is restrained: warm neutrals ground the interface, with a green primary that reads as growth and shared prosperity, not decorative gilding. Shadows are minimal — surfaces structure themselves through tonal layering, not drop-shadows. Typography is set in Inter at a compact 14px body, optimized for dense financial screens where information density is a feature, not a flaw.

This design explicitly rejects corporate banking aesthetics (navy, marble, gilded accents) and generic SaaS dashboard tropes (cold data-entry panels, uniform card grids). Sirib is for cooperative staff who have spent years or decades working with pen-and-paper or disconnected systems — the interface must earn their trust through clarity and reliability, not novelty.

**Key Characteristics:**
- Warm neutral palette with a green functional accent
- Compact 14px body for information-dense financial screens
- Minimal shadows; hierarchy through tonal layering
- Solid, responsive components with clear states
- Dark mode that mirrors the warm-light philosophy in low-light settings

## 2. Colors

A warm neutral palette anchored by a green primary that communicates growth, shared prosperity, and cooperative roots. The system uses tonal layering (surface, surface-alt, surface-raised) to create hierarchy without relying on shadows.

### Primary

- **Green 500** (`#5b8c5a` / `oklch(55% 0.075 135)`): The brand accent. Used for primary actions, active states, and key data highlights. Applied sparingly — its rarity is the point.
- **Green 600** (`#4a7649` / `oklch(48% 0.065 135)`): The primary token. Used for hover states, solid buttons, and focus indicators. Deeper and more grounded than Green 500.
- **Green 700** (`#3d6b3c` / `oklch(42% 0.06 135)`): Text on tinted surfaces, badge text, dark-mode sidebar active states.

### Positive / Warning / Danger

- **Positive** (`#059669`): Confirmation, success states, positive badges. Accompanied by Positive 50 (`#ecfdf5`) for tinted backgrounds.
- **Warning** (`#d97706`): Warning states, attention badges. Accompanied by Warning 50 (`#fffbeb`) for tinted backgrounds.
- **Danger** (`#dc2626`): Error states, destructive actions, danger badges. Accompanied by Danger 50 (`#fef2f2`) for tinted backgrounds.

### Neutral

- **Surface** (`#ffffff`): Primary card and container background. The default resting surface.
- **Surface Alt** (`#f7f5f0`): Page-level backgrounds, table header rows, sidebar alt sections. A warm off-white that sets the overall atmosphere.
- **Surface Raised** (`#ffffff`): Modals, dropdowns, floating panels. Pure white to distinguish from the surrounding surface-alt page.
- **Text Primary** (`#2c241b`): Headings, body copy, primary labels. High-contrast warm brown-black.
- **Text Secondary** (`#6e6358`): Secondary information, meta text. Readable at 14px.
- **Text Tertiary** (`#aea398`): Placeholder text, disabled states, subtle labels. Meets WCAG 2.1 AA for placeholder contrast.
- **Border** (`#e8e0d5`): Default card and container borders. Warm tan, low visual noise.
- **Border Strong** (`#d4cabd`): Table borders, input focus, prominent dividers. Slightly heavier step in the same warm tan family.

### Dark Mode

The dark palette mirrors the warm-light philosophy in reverse: the same green accent on warm dark browns.

- **Dark Surface** (`#1e1b18`): Page background. Warm near-black.
- **Dark Surface Alt** (`#231f1c`): Slightly lifted surfaces.
- **Dark Surface Raised** (`#2a2622`): Modals, dropdowns.
- **Dark Text Primary** (`#f5efe6`): Headings and body copy. Warm off-white.
- **Dark Text Secondary** (`#aea398`): Secondary text.
- **Dark Text Tertiary** (`#897f75`): Placeholder text.
- **Dark Border** (`#352e27`): Subtle container borders.
- **Dark Border Strong** (`#4c443c`): Prominent borders.

### The Green Rarity Rule

The green accent is used on ≤10% of any given screen. It appears on primary actions (buttons, active nav items), key data highlights, and brand moments. If a screen has more green than that, it's over-designed. The rarity of the accent is what gives it weight.

## 3. Typography

**Display Font:** Inter (with ui-sans-serif, system-ui fallback)
**Body Font:** Inter (with ui-sans-serif, system-ui fallback)
**Label/Mono Font:** JetBrains Mono (with ui-monospace fallback)

**Character:** A single sans-serif family (Inter) across the entire system, from display to body to UI labels. Monospace (JetBrains Mono) is reserved for data values, codes, and technical labels. The pairing is quietly precise — Inter handles the narrative, JetBrains Mono handles the numbers.

### Hierarchy

- **Display** (300, `clamp(2.5rem, 5vw, 4.5rem)`, 1, -0.04em letter-spacing): Hero headlines on the landing and marketing pages only. Never used inside the product UI.
- **Headline** (400, `clamp(1.5rem, 3vw, 2.25rem)`, 1.2, -0.03em): Section headings on marketing and landing pages.
- **Title** (600, `1rem` / 16px, 1.25): Card headers, modal titles, section titles within the product.
- **Body** (400, `0.875rem` / 14px, 1.5): Default text for the entire product UI. Max line length 65-75ch on prose, unconstrained on data tables.
- **Caption** (400, `0.75rem` / 12px, 1.4): Helper text, timestamps, secondary metadata.
- **Label** (500, `0.75rem` / 12px, 1, 0.05em tracking, uppercase): Table column headers, section labels, stat labels. JetBrains Mono at 0.75rem for data values on dashboards and stat cards.
- **Landing Label** (500, `0.75rem` / 12px, 1, 0.1em tracking, uppercase, JetBrains Mono): Eyebrow labels above landing section headings. Accent color.

### The Compact-By-Design Rule

14px body text is not a compromise — it is a deliberate choice for information-dense financial screens. The system never falls below 12px (caption / label). Touch targets remain at minimum 44px for interactive elements regardless of text size.

## 4. Elevation

The system uses minimal ambient shadows combined with tonal layering for hierarchy. Surfaces are predominantly flat at rest — shadows are subtle and reserved for hover states, dropdown menus, and modal containers. The primary depth cue is the tonal step between surface, surface-alt, and surface-raised, not the shadow beneath them.

### Shadow Vocabulary

- **Shadow XS** (`0 1px 2px 0 rgb(0 0 0 / 0.03)`): The lightest touch. Used for card hover states to indicate interactivity without visual weight.
- **Shadow SM** (`0 1px 3px 0 rgb(0 0 0 / 0.04), 0 1px 2px -1px rgb(0 0 0 / 0.04)`): Default card shadow when tonal layering isn't enough. Barely perceptible.
- **Shadow MD** (`0 4px 6px -1px rgb(0 0 0 / 0.04), 0 2px 4px -2px rgb(0 0 0 / 0.04)`): Dropdown menus, popovers, small floating panels.
- **Shadow LG** (`0 10px 15px -3px rgb(0 0 0 / 0.04), 0 4px 6px -4px rgb(0 0 0 / 0.04)`): Modals, large floating panels, full-screen overlays.

### The Flat-By-Default Rule

Surfaces are flat at rest. Shadows appear only as a response to state (hover, elevation, focus). A resting card should never look like it's floating — it sits on the page like a tool on a desk.

## 5. Components

### Buttons

- **Shape:** Gently curved corners (0.5rem / 8px). Compact padding (0.5rem 1rem).
- **Primary:** Green 600 background, white text, 14px/500 weight, 1px transparent border. Hover deepens to Green 700. Focus shows a 2px Green offset outline.
- **Secondary:** White background, warm brown text, 14px/500 weight, 1px Border Strong stroke. Hover lifts surface to Surface Alt and shifts border to Green.
- **Ghost:** Transparent background, warm brown text. Hover adds Surface Alt background and Border stroke. Used for third-tier actions and navigation.
- **Danger:** Red background, white text. Hover deepens to `#b91c1c`.
- **Positive:** Green 600 background, white text. Hover deepens to Positive 700.
- **States:** All filled buttons have a subtle shimmer sweep on hover (linear gradient moving left-to-right). All buttons have `cursor: not-allowed` and 50% opacity when disabled.

### Cards

- **Shape:** Gentle corners (0.5rem / 8px). Default white background, 1px Border stroke, no shadow at rest.
- **Internal Padding:** 1.25rem (xl) in the body; 1rem top/bottom, 1.25rem sides in the header.
- **Header:** Separated from body by a 1px Border bottom line. Contains a Title (16px/600) and optional actions.
- **Hover:** Optional lift (translateY(-2px)) with Shadow XS for clickable cards. Non-interactive cards do not hover.

### Inputs

- **Style:** Filled white surface, 1px Border stroke, 0.5rem radius. Internal padding 0.5rem 0.75rem. Warm brown text, Tertiary placeholder.
- **Focus:** Border shifts to Green, outer glow at 3px `rgba(91, 140, 90, 0.15)`. Outline explicitly set to `none`.
- **Error:** Border shifts to Primary (same Green, not red — the error message text is red). Accompanied by inline error message in Danger with icon.
- **Label:** Block display, 14px, 500 weight, warm brown, 0.375rem margin-bottom.
- **Hint:** 12px, Tertiary color, 0.25rem margin-top.

### Badges

- **Style:** Fully rounded pill (9999px), 12px/500 weight, compact padding (0.125rem 0.625rem).
- **Primary:** Green 50 background, Green 700 text.
- **Success:** Positive 50 background, Positive 700 text.
- **Warning:** Warning 50 background, Warning text.
- **Danger:** Danger 50 background, Danger text.

### Tables

- **Structure:** Full-width, left-aligned, 14px body text.
- **Header Row:** Surface Alt background. Uppercase Caption labels (12px/600, 0.05em tracking) in Tertiary color. 0.75rem/1rem padding.
- **Body Rows:** Alternating (Surface Alt for header only, no stripe). 0.75rem/1rem padding. Secondary text color right margin.
- **Hover:** Body row background shifts to Surface Alt with a 2px translateX lift.
- **Last Row:** No bottom border.

### Navigation (Sidebar)

- **Link Style:** Flex row with icon and text, 0.5rem 0.75rem padding, 0.5rem radius, 14px/400, Sidebar Text color.
- **Hover:** Sidebar Hover background, Text Primary color.
- **Active:** Sidebar Active tinted green background, Green 700 text, 500 weight, no lift.
- **Section Title:** 12px/600, uppercase, 0.1em tracking, Tertiary color, 0.5rem bottom margin.

### Stat Cards

- **Style:** 1.25rem padding, 1px Border stroke, 0.5rem radius, white background.
- **Label:** 12px/500, uppercase, 0.05em tracking, Tertiary color.
- **Value:** 24px/600, Text Primary color, 0.25rem margin-top.

### Dropdown Menu

- **Position:** Absolutely positioned below trigger, right-aligned. 0.5rem gap from trigger.
- **Surface:** White background, Border stroke, Shadow LG, 0.5rem radius. Fade-in-up animation on open.
- **Items:** 14px, Secondary text, 0.5rem 1rem padding. Hover lifts to Surface Alt background and Primary text. Full-width clickable.

### Landing Page Components

- **Card:** Landing BG background, Landing Border stroke, no shadow. 2.5rem padding on feature cards, 2rem on testimonial cards. No border-radius.
- **CTA Button:** Landing Accent background, white text, all-caps 13px/600, 0.1em tracking, 2rem/0.75rem padding on hero CTA, 2.5rem/1rem padding on final CTA. Hover deepens to Landing Accent Hover.
- **Outline Button:** Landing Border stroke, Landing Muted text, all-caps. Hover shifts border and text to Landing Accent.
- **Hero:** Full viewport min-height, grid overlay background, 5xl-7xl display heading in 300 weight, -0.04em tracking.

## 6. Do's and Don'ts

### Do:

- **Do** use the green accent sparingly — ≤10% of any screen. Its rarity is its weight.
- **Do** use tonal layering (surface → surface-alt → surface-raised) as the primary hierarchy tool before reaching for shadows.
- **Do** keep body text at 14px in the product UI. It is deliberately compact for information density.
- **Do** use JetBrains Mono for data values, codes, and technical labels to distinguish them from narrative text.
- **Do** make interactive elements have minimum 44px touch targets regardless of text size.
- **Do** maintain WCAG 2.1 AA contrast: body text ≥4.5:1 against its background, large text ≥3:1.
- **Do** provide clear, visible focus indicators (2px Green outline with 2px offset) on all interactive elements.
- **Do** respect reduced-motion preferences — all animations degrade to instant transitions.

### Don't:

- **Don't** use corporate banking aesthetics: no navy blue, gold gradients, marble textures, or heavy gilded accents.
- **Don't** build generic SaaS dashboard layouts with uniform card grids, tiny uppercase eyebrow labels on every section, or hero-metric templates.
- **Don't** apply shadows to resting surfaces — shadows indicate response to state, not default depth.
- **Don't** use gradient text (`background-clip: text` with a gradient). Single solid colors only.
- **Don't** use border-left or border-right greater than 1px as a colored accent stripe on cards, callouts, or list items.
- **Don't** create nested cards — if you need nested containers, use tonal layering instead.
- **Don't** drop below 12px type for any UI text, or below 14px for body copy.
- **Don't** animate CSS layout properties (width, height, position). Animate only transform and opacity.
- **Don't** use glassmorphism (backdrop blur on semi-transparent backgrounds) as a default treatment.
- **Don't** let heading text overflow its container at any breakpoint — reduce clamp max or rewrite copy.
