# Frontend Audit & Roadmap

> Audit date: July 2026

---

## Architecture Overview

| Layer | Technology | Details |
|-------|-----------|---------|
| CSS framework | Tailwind CSS v4 | CSS-first config via `@theme` in `brand.css` |
| JavaScript | Stimulus 3 | 43 controllers, ESM via importmap |
| Hotwire | Turbo | Frames, Streams, broadcasts |
| UI library | Preline | Dropdowns, modals via `vendor/preline.js` |
| Animations | Custom CSS | GPU-accelerated, respects `prefers-reduced-motion` |
| Dark mode | `.dark` class | CSS custom properties toggle |

---

## Issues Found

### 1. Missing Stimulus Controller

**File:** `app/views/loans/products/_form.html.erb`

```erb
data: { controller:"loan-product-form" }
```

The controller `loan-product-form` is referenced but no corresponding file exists (`app/javascript/controllers/loan_product_form_controller.js`).

**Fix:** Create the controller or remove the reference.

### 2. Missing Management Messaging Views

Routes exist for `management/messaging/messages` and `management/messaging/channels`, but no view directories exist under `app/views/management/messaging/`.

**Fix:** Create CRUD views or remove unused routes.

### 3. Inconsistent Flash Message Handling

Four different flash implementations across layouts:

| Layout | Style | Dismiss |
|--------|-------|---------|
| `dashboard.html.erb` | Inline SVG icon, notice/alert distinction | Inline JS `onclick` |
| `portal.html.erb` | Separate blocks for notice and alert | None |
| `shell.html.erb` | Inline in `_main.html.erb` | Stimulus `dismiss_controller` |
| `sessions/new.html.erb` | Custom alert block | Stimulus `dismiss_controller` |

**Fix:** Unify on a single partial using Stimulus `dismiss_controller`. Remove inline `onclick`.

### 4. Two Sidebar Systems

- `shared/_sidebar.html.erb` — used by `dashboard` layout
- `shell/` partials — used by `shell` layout

Both serve similar navigation purposes. Risk of divergence.

**Fix:** Consider consolidating into one sidebar component. At minimum, document the distinction.

### 5. Missing Skip-to-Content Links

Only the `landing` layout has a skip-to-content link.

- `app/views/layouts/dashboard.html.erb` — missing
- `app/views/layouts/shell.html.erb` — missing
- `app/views/layouts/portal.html.erb` — missing

**Fix:** Add `role="alert"` or skip-to-content `aria-label` to all layouts.

### 6. Missing `role="alert"` on Error Messages

Form validation errors and flash messages lack `role="alert"` for screen reader announcement.

**Fix:** Add `role="alert"` to flash message containers and form error blocks.

### 7. No `aria-live` Regions on Turbo Frame Updates

When Turbo replaces content (e.g., member tabs, entry detail), screen readers are not notified.

**Fix:** Add `aria-live="polite"` to Turbo Frame containers.

### 8. Dropdown Lacks ARIA Attributes

**File:** `app/views/accounting/journal_entries/index.html.erb`

Dropdown component has no `aria-haspopup`, `aria-expanded`, or `role` attributes.

**Fix:** Add proper ARIA attributes to interactive dropdowns.

### 9. Dead Code

| File | Reason |
|------|--------|
| `app/views/members/_member_row.html.erb` | Appears unused — only `_table_body.html.erb` is rendered from `index.html.erb` |
| `app/javascript/controllers/hello_controller.js` | Default Stimulus scaffold |

**Fix:** Remove unused files.

### 10. CSS Concerns

| Issue | Details |
|-------|---------|
| Broad selector in `animations.css` | `[class*="rounded-lg border"]` applies hover transforms to many elements unintentionally |
| Some `landing-*` classes outside layers | `brand.css` uses `@layer` but some utilities are unlayered |
| Large compiled CSS | `app/assets/builds/tailwind.css` is 1.9MB |

**Fix:** Restrict animation selectors. Audit landing classes for layering. Consider PurgeCSS optimization.

---

## Positive Highlights

- Comprehensive design token system with dark mode
- Strong Turbo adoption (stream broadcasts for live accounting data)
- 43 Stimulus controllers covering complex interactions
- GPU-accelerated animations with `prefers-reduced-motion` support
- Consistent form labeling throughout
- Good use of semantic HTML and ARIA on interactive elements
- Pagination includes proper `aria-label`
- Logo has `role="img"` and `aria-label`

---

## Remediation Order

1. Create missing `loan-product-form` Stimulus controller or remove reference
2. Create management messaging views or remove routes
3. Unify flash message handling across layouts
4. Add skip-to-content links to dashboard, shell, portal layouts
5. Add `role="alert"` to flash messages and form errors
6. Add `aria-live` regions to Turbo Frame containers
7. Remove dead code (`_member_row.html.erb`, `hello_controller.js`)
8. Add ARIA attributes to dropdown components
9. Fix CSS selector specificity issues
