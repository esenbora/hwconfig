---
name: accessibility
description: Use when building UI, forms, buttons, inputs, modals, or any user interface. WCAG 2.2 patterns for screen readers, keyboard navigation, focus management, ARIA labels, color contrast. Triggers on: accessible, a11y, screen reader, keyboard, focus, aria, wcag, disability, blind, contrast, tab order.
version: 1.0.0
---

# Accessibility (WCAG 2.2 Level AA)

> **Priority:** CRITICAL | **Auto-Load:** On UI/component work
> **Triggers:** accessibility, a11y, wcag, aria, screen reader, keyboard, focus

---

## WCAG 2.2 Level AA Requirements

### Focus Indicators (2.4.7, 2.4.11, 2.4.12)

```css
/* Minimum focus indicator requirements */
:focus-visible {
  outline: 2px solid currentColor; /* Minimum 2px */
  outline-offset: 2px;
  /* 3:1 contrast ratio against adjacent colors */
}

/* Never remove focus outlines without replacement */
/* BAD */ :focus { outline: none; }
/* GOOD */ :focus-visible { outline: 2px solid #0066cc; }
```

**Requirements:**
- Minimum 2px outline with 3:1 contrast ratio
- Focus visible on ALL interactive elements
- Focus not obscured by other content (2.4.11)
- Focus indicator area ≥ perimeter of element (2.4.12)

---

### Touch Targets (2.5.8)

```css
/* Minimum touch target size */
.interactive-element {
  min-width: 24px;   /* WCAG minimum */
  min-height: 24px;
  /* Recommended: 44x44px for comfortable touch */
}

/* Spacing between targets */
.button-group > * + * {
  margin-left: 8px; /* Prevent accidental taps */
}
```

**Requirements:**
- Minimum 24x24 CSS pixels
- Recommended 44x44 CSS pixels for mobile
- Adequate spacing between adjacent targets

---

### Dragging Alternatives (2.5.7)

```typescript
// All drag operations MUST have single-pointer alternatives

// BAD - Drag only
<div draggable onDragEnd={handleReorder} />

// GOOD - Drag + keyboard + button alternatives
<div
  draggable
  onDragEnd={handleReorder}
  onKeyDown={(e) => {
    if (e.key === 'ArrowUp') moveUp();
    if (e.key === 'ArrowDown') moveDown();
  }}
  tabIndex={0}
  role="listitem"
  aria-describedby="reorder-instructions"
>
  <button onClick={moveUp} aria-label="Move up">↑</button>
  <button onClick={moveDown} aria-label="Move down">↓</button>
</div>
```

---

### ARIA Patterns

```typescript
// ANTI-PATTERN - Div pretending to be button
<div onClick={handleClick} aria-label="Close">X</div>

// CORRECT - Semantic button with accessible icon
<button onClick={handleClick} aria-label="Close dialog">
  <XIcon aria-hidden="true" />
</button>

// Icon-only button pattern
<button aria-label="Delete item">
  <TrashIcon aria-hidden="true" />
</button>

// Icon with visible text
<button>
  <DownloadIcon aria-hidden="true" />
  <span>Download</span>
</button>
```

**ARIA Rules:**
1. Prefer semantic HTML over ARIA (button > div[role="button"])
2. Every interactive element needs accessible name
3. Decorative icons use `aria-hidden="true"`
4. Dynamic content uses live regions

---

### Focus Management

```typescript
// Modal Focus Trap
import { useRef, useEffect } from 'react';

function Modal({ isOpen, onClose, children }) {
  const modalRef = useRef<HTMLDivElement>(null);
  const previousFocusRef = useRef<HTMLElement | null>(null);

  useEffect(() => {
    if (isOpen) {
      // Save current focus
      previousFocusRef.current = document.activeElement as HTMLElement;
      // Focus first focusable element in modal
      modalRef.current?.querySelector('button, [href], input')?.focus();
    } else {
      // Restore focus on close
      previousFocusRef.current?.focus();
    }
  }, [isOpen]);

  // Handle Escape key
  const handleKeyDown = (e: KeyboardEvent) => {
    if (e.key === 'Escape') onClose();
    if (e.key === 'Tab') trapFocus(e, modalRef.current);
  };

  return (
    <div
      ref={modalRef}
      role="dialog"
      aria-modal="true"
      aria-labelledby="modal-title"
      onKeyDown={handleKeyDown}
    >
      <h2 id="modal-title">Modal Title</h2>
      {children}
    </div>
  );
}

// Focus trap utility
function trapFocus(e: KeyboardEvent, container: HTMLElement | null) {
  if (!container) return;
  const focusable = container.querySelectorAll(
    'button, [href], input, select, textarea, [tabindex]:not([tabindex="-1"])'
  );
  const first = focusable[0] as HTMLElement;
  const last = focusable[focusable.length - 1] as HTMLElement;

  if (e.shiftKey && document.activeElement === first) {
    e.preventDefault();
    last.focus();
  } else if (!e.shiftKey && document.activeElement === last) {
    e.preventDefault();
    first.focus();
  }
}
```

---

### Skip Links

```tsx
// Add at top of page layout
function SkipLinks() {
  return (
    <a
      href="#main-content"
      className="sr-only focus:not-sr-only focus:absolute focus:top-4 focus:left-4 focus:z-50 focus:px-4 focus:py-2 focus:bg-white focus:text-black"
    >
      Skip to main content
    </a>
  );
}

// Main content target
<main id="main-content" tabIndex={-1}>
  {/* Page content */}
</main>
```

---

### Live Regions

```tsx
// Announce dynamic content to screen readers
function Notification({ message, type }) {
  return (
    <div
      role="alert"           // Immediate announcement
      aria-live="assertive"  // Interrupts current speech
      aria-atomic="true"     // Read entire region
    >
      {message}
    </div>
  );
}

// For less urgent updates
<div
  role="status"
  aria-live="polite"  // Waits for pause in speech
>
  {loadingMessage}
</div>

// Hidden live region pattern
<div className="sr-only" aria-live="polite" aria-atomic="true">
  {screenReaderMessage}
</div>
```

---

### Color & Contrast

| Element | Minimum Ratio | Notes |
|---------|--------------|-------|
| Normal text | 4.5:1 | < 18pt or < 14pt bold |
| Large text | 3:1 | ≥ 18pt or ≥ 14pt bold |
| UI components | 3:1 | Buttons, inputs, icons |
| Focus indicators | 3:1 | Against adjacent colors |

```css
/* Never rely on color alone */
/* BAD */ .error { color: red; }
/* GOOD */ .error { color: red; border-left: 4px solid red; }
.error::before { content: "Error: "; }
```

---

### Motion & Animation

```css
/* Respect user preference for reduced motion */
@media (prefers-reduced-motion: reduce) {
  *,
  *::before,
  *::after {
    animation-duration: 0.01ms !important;
    animation-iteration-count: 1 !important;
    transition-duration: 0.01ms !important;
  }
}
```

```typescript
// React hook for reduced motion
function usePrefersReducedMotion() {
  const [prefersReducedMotion, setPrefersReducedMotion] = useState(false);

  useEffect(() => {
    const mediaQuery = window.matchMedia('(prefers-reduced-motion: reduce)');
    setPrefersReducedMotion(mediaQuery.matches);

    const handler = (e: MediaQueryListEvent) => setPrefersReducedMotion(e.matches);
    mediaQuery.addEventListener('change', handler);
    return () => mediaQuery.removeEventListener('change', handler);
  }, []);

  return prefersReducedMotion;
}

// Usage
const shouldAnimate = !usePrefersReducedMotion();
```

---

### Form Accessibility

```tsx
// Accessible form field pattern
function FormField({ id, label, error, required, ...props }) {
  const errorId = error ? `${id}-error` : undefined;
  const describedBy = errorId;

  return (
    <div>
      <label htmlFor={id}>
        {label}
        {required && <span aria-hidden="true"> *</span>}
        {required && <span className="sr-only"> (required)</span>}
      </label>
      <input
        id={id}
        aria-required={required}
        aria-invalid={!!error}
        aria-describedby={describedBy}
        {...props}
      />
      {error && (
        <span id={errorId} role="alert" className="text-red-600">
          {error}
        </span>
      )}
    </div>
  );
}

// Form error summary
function FormErrorSummary({ errors }) {
  const summaryRef = useRef<HTMLDivElement>(null);

  useEffect(() => {
    if (errors.length > 0) {
      summaryRef.current?.focus();
    }
  }, [errors]);

  if (errors.length === 0) return null;

  return (
    <div
      ref={summaryRef}
      role="alert"
      tabIndex={-1}
      className="border-l-4 border-red-500 p-4"
    >
      <h2>Please fix the following errors:</h2>
      <ul>
        {errors.map((error, i) => (
          <li key={i}>
            <a href={`#${error.fieldId}`}>{error.message}</a>
          </li>
        ))}
      </ul>
    </div>
  );
}
```

---

### Screen Reader Testing

| Platform | Screen Reader | Test Command |
|----------|--------------|--------------|
| macOS | VoiceOver | Cmd + F5 |
| iOS | VoiceOver | Settings > Accessibility |
| Windows | NVDA | Free download |
| Windows | JAWS | Commercial |
| Android | TalkBack | Settings > Accessibility |
| Chrome | ChromeVox | Extension |

**Testing Checklist:**
1. Navigate with Tab only - logical order?
2. Navigate with screen reader - all content announced?
3. Activate with Enter/Space - all actions work?
4. Forms - labels announced, errors clear?
5. Dynamic content - changes announced?

---

## Accessibility Checklist

### Before Every PR

- [ ] All interactive elements keyboard accessible (Tab, Enter, Escape)
- [ ] Focus indicators visible (2px minimum, 3:1 contrast)
- [ ] Touch targets ≥ 24px (prefer 44px on mobile)
- [ ] No drag-only operations (keyboard/button alternatives exist)
- [ ] ARIA roles and labels correct (prefer semantic HTML)
- [ ] Color contrast meets requirements (4.5:1 text, 3:1 UI)
- [ ] Motion respects `prefers-reduced-motion`
- [ ] Form errors announced to screen readers
- [ ] Skip link present for main content
- [ ] Modal focus properly trapped and restored
- [ ] Images have alt text (or `aria-hidden` if decorative)
- [ ] Page has proper heading hierarchy (h1 → h2 → h3)

---

## Quick Reference

```typescript
// Screen reader only text
<span className="sr-only">Descriptive text for screen readers</span>

// Hidden from screen readers
<span aria-hidden="true">Decorative content</span>

// Required field
<input aria-required="true" />

// Invalid field
<input aria-invalid="true" aria-describedby="error-message" />

// Live region for updates
<div aria-live="polite" aria-atomic="true">{status}</div>

// Modal
<div role="dialog" aria-modal="true" aria-labelledby="title">

// Expandable
<button aria-expanded={isOpen} aria-controls="panel-id">
<div id="panel-id" hidden={!isOpen}>

// Loading
<button aria-busy={isLoading} disabled={isLoading}>
```

---

## Tailwind CSS Classes

```css
/* Screen reader only */
.sr-only {
  position: absolute;
  width: 1px;
  height: 1px;
  padding: 0;
  margin: -1px;
  overflow: hidden;
  clip: rect(0, 0, 0, 0);
  white-space: nowrap;
  border-width: 0;
}

/* Make visible on focus */
.focus:not-sr-only:focus {
  position: static;
  width: auto;
  height: auto;
  padding: inherit;
  margin: inherit;
  overflow: visible;
  clip: auto;
  white-space: normal;
}
```

---

## Resources

- [WCAG 2.2 Quick Reference](https://www.w3.org/WAI/WCAG22/quickref/)
- [Radix UI Accessibility](https://www.radix-ui.com/primitives/docs/overview/accessibility)
- [ARIA Authoring Practices](https://www.w3.org/WAI/ARIA/apg/)
- [axe DevTools](https://www.deque.com/axe/devtools/) - Automated testing
- [WAVE](https://wave.webaim.org/) - Web accessibility evaluation
