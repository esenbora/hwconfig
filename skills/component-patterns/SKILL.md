---
name: component-patterns
description: Use when building React components, especially complex ones. Composition, compound components, render props, controlled components. Triggers on: component, react component, compound, composition, render prop, controlled, uncontrolled, component pattern, reusable component.
version: 1.0.0
---

# Component Patterns (Advanced)

> **Priority:** RECOMMENDED | **Auto-Load:** On component architecture work
> **Triggers:** component pattern, polymorphic, compound component, headless, render props, composition

---

## Overview

Advanced React component patterns for building flexible, reusable, and maintainable component libraries.

---

## Polymorphic Components

Components that can render as different HTML elements.

### Basic Polymorphic

```typescript
import { ComponentPropsWithoutRef, ElementType, ReactNode } from 'react';

type PolymorphicProps<E extends ElementType> = {
  as?: E;
  children?: ReactNode;
} & Omit<ComponentPropsWithoutRef<E>, 'as' | 'children'>;

function Box<E extends ElementType = 'div'>({
  as,
  children,
  ...props
}: PolymorphicProps<E>) {
  const Component = as || 'div';
  return <Component {...props}>{children}</Component>;
}

// Usage
<Box>Default div</Box>
<Box as="section">Section element</Box>
<Box as="button" onClick={handleClick}>Button element</Box>
<Box as="a" href="/about">Link element</Box>
```

### With Ref Support

```typescript
import { forwardRef, ComponentPropsWithRef, ElementType, ReactNode } from 'react';

type PolymorphicRef<E extends ElementType> = ComponentPropsWithRef<E>['ref'];

type PolymorphicProps<E extends ElementType> = {
  as?: E;
  children?: ReactNode;
} & Omit<ComponentPropsWithRef<E>, 'as' | 'children'>;

type PolymorphicComponent = <E extends ElementType = 'div'>(
  props: PolymorphicProps<E> & { ref?: PolymorphicRef<E> }
) => ReactNode;

const Box: PolymorphicComponent = forwardRef(
  <E extends ElementType = 'div'>(
    { as, children, ...props }: PolymorphicProps<E>,
    ref: PolymorphicRef<E>
  ) => {
    const Component = as || 'div';
    return <Component ref={ref} {...props}>{children}</Component>;
  }
);

// Usage with ref
const buttonRef = useRef<HTMLButtonElement>(null);
<Box as="button" ref={buttonRef}>Button with ref</Box>
```

### Text Component Example

```typescript
type TextProps<E extends ElementType = 'span'> = PolymorphicProps<E> & {
  variant?: 'body' | 'heading' | 'label' | 'caption';
  weight?: 'normal' | 'medium' | 'semibold' | 'bold';
};

function Text<E extends ElementType = 'span'>({
  as,
  variant = 'body',
  weight = 'normal',
  className,
  ...props
}: TextProps<E>) {
  const Component = as || 'span';

  return (
    <Component
      className={cn(
        // Variant styles
        variant === 'heading' && 'text-2xl tracking-tight',
        variant === 'body' && 'text-base',
        variant === 'label' && 'text-sm',
        variant === 'caption' && 'text-xs text-muted-foreground',
        // Weight styles
        weight === 'medium' && 'font-medium',
        weight === 'semibold' && 'font-semibold',
        weight === 'bold' && 'font-bold',
        className
      )}
      {...props}
    />
  );
}

// Usage
<Text variant="heading" as="h1">Page Title</Text>
<Text variant="body">Paragraph text</Text>
<Text variant="label" as="label" htmlFor="input">Label</Text>
```

---

## Compound Components

Components that work together to form a complete unit.

### Context-Based Compound

```typescript
import { createContext, useContext, useState, ReactNode } from 'react';

// Context
type AccordionContextType = {
  openItems: Set<string>;
  toggle: (id: string) => void;
};

const AccordionContext = createContext<AccordionContextType | null>(null);

function useAccordionContext() {
  const context = useContext(AccordionContext);
  if (!context) {
    throw new Error('Accordion components must be used within <Accordion>');
  }
  return context;
}

// Root Component
type AccordionProps = {
  children: ReactNode;
  type?: 'single' | 'multiple';
  defaultValue?: string[];
};

function Accordion({ children, type = 'single', defaultValue = [] }: AccordionProps) {
  const [openItems, setOpenItems] = useState(new Set(defaultValue));

  const toggle = (id: string) => {
    setOpenItems((prev) => {
      const next = new Set(prev);
      if (next.has(id)) {
        next.delete(id);
      } else {
        if (type === 'single') next.clear();
        next.add(id);
      }
      return next;
    });
  };

  return (
    <AccordionContext.Provider value={{ openItems, toggle }}>
      <div className="divide-y">{children}</div>
    </AccordionContext.Provider>
  );
}

// Item Component
type AccordionItemProps = {
  children: ReactNode;
  value: string;
};

function AccordionItem({ children, value }: AccordionItemProps) {
  return (
    <div data-state={useAccordionContext().openItems.has(value) ? 'open' : 'closed'}>
      {children}
    </div>
  );
}

// Trigger Component
type AccordionTriggerProps = {
  children: ReactNode;
  value: string;
};

function AccordionTrigger({ children, value }: AccordionTriggerProps) {
  const { openItems, toggle } = useAccordionContext();
  const isOpen = openItems.has(value);

  return (
    <button
      onClick={() => toggle(value)}
      aria-expanded={isOpen}
      className="flex w-full items-center justify-between py-4 font-medium"
    >
      {children}
      <ChevronDown className={cn('h-4 w-4 transition-transform', isOpen && 'rotate-180')} />
    </button>
  );
}

// Content Component
type AccordionContentProps = {
  children: ReactNode;
  value: string;
};

function AccordionContent({ children, value }: AccordionContentProps) {
  const { openItems } = useAccordionContext();
  const isOpen = openItems.has(value);

  if (!isOpen) return null;

  return (
    <div className="pb-4 pt-0">
      {children}
    </div>
  );
}

// Attach sub-components
Accordion.Item = AccordionItem;
Accordion.Trigger = AccordionTrigger;
Accordion.Content = AccordionContent;

// Usage
<Accordion type="single" defaultValue={['item-1']}>
  <Accordion.Item value="item-1">
    <Accordion.Trigger value="item-1">Section 1</Accordion.Trigger>
    <Accordion.Content value="item-1">Content 1</Accordion.Content>
  </Accordion.Item>
  <Accordion.Item value="item-2">
    <Accordion.Trigger value="item-2">Section 2</Accordion.Trigger>
    <Accordion.Content value="item-2">Content 2</Accordion.Content>
  </Accordion.Item>
</Accordion>
```

---

## Headless Components (Logic-Only Hooks)

Separate logic from presentation.

### useModal Hook

```typescript
import { useRef, useEffect, useCallback, useState } from 'react';

type UseModalOptions = {
  defaultOpen?: boolean;
  onOpenChange?: (open: boolean) => void;
};

function useModal({ defaultOpen = false, onOpenChange }: UseModalOptions = {}) {
  const [isOpen, setIsOpen] = useState(defaultOpen);
  const triggerRef = useRef<HTMLElement>(null);
  const contentRef = useRef<HTMLElement>(null);

  const open = useCallback(() => {
    setIsOpen(true);
    onOpenChange?.(true);
  }, [onOpenChange]);

  const close = useCallback(() => {
    setIsOpen(false);
    onOpenChange?.(false);
    // Restore focus to trigger
    triggerRef.current?.focus();
  }, [onOpenChange]);

  const toggle = useCallback(() => {
    isOpen ? close() : open();
  }, [isOpen, open, close]);

  // Handle escape key
  useEffect(() => {
    if (!isOpen) return;

    const handleKeyDown = (e: KeyboardEvent) => {
      if (e.key === 'Escape') close();
    };

    document.addEventListener('keydown', handleKeyDown);
    return () => document.removeEventListener('keydown', handleKeyDown);
  }, [isOpen, close]);

  // Focus trap
  useEffect(() => {
    if (!isOpen || !contentRef.current) return;

    const focusableElements = contentRef.current.querySelectorAll(
      'button, [href], input, select, textarea, [tabindex]:not([tabindex="-1"])'
    );
    const firstFocusable = focusableElements[0] as HTMLElement;
    firstFocusable?.focus();
  }, [isOpen]);

  return {
    isOpen,
    open,
    close,
    toggle,
    triggerProps: {
      ref: triggerRef,
      onClick: toggle,
      'aria-expanded': isOpen,
      'aria-haspopup': 'dialog' as const,
    },
    contentProps: {
      ref: contentRef,
      role: 'dialog' as const,
      'aria-modal': true,
    },
    backdropProps: {
      onClick: close,
      'aria-hidden': true,
    },
  };
}

// Usage with custom UI
function MyModal() {
  const modal = useModal();

  return (
    <>
      <button {...modal.triggerProps}>Open Modal</button>

      {modal.isOpen && (
        <>
          <div
            {...modal.backdropProps}
            className="fixed inset-0 bg-black/50"
          />
          <div
            {...modal.contentProps}
            className="fixed inset-0 flex items-center justify-center"
          >
            <div className="bg-white rounded-lg p-6">
              <h2>Modal Title</h2>
              <p>Modal content here</p>
              <button onClick={modal.close}>Close</button>
            </div>
          </div>
        </>
      )}
    </>
  );
}
```

### useDropdown Hook

```typescript
function useDropdown<T>() {
  const [isOpen, setIsOpen] = useState(false);
  const [selectedIndex, setSelectedIndex] = useState(-1);
  const [selectedValue, setSelectedValue] = useState<T | null>(null);
  const triggerRef = useRef<HTMLButtonElement>(null);
  const listRef = useRef<HTMLUListElement>(null);

  const open = () => setIsOpen(true);
  const close = () => {
    setIsOpen(false);
    setSelectedIndex(-1);
    triggerRef.current?.focus();
  };

  const select = (value: T) => {
    setSelectedValue(value);
    close();
  };

  // Keyboard navigation
  const handleKeyDown = (e: KeyboardEvent, items: T[]) => {
    if (!isOpen) {
      if (e.key === 'ArrowDown' || e.key === 'Enter' || e.key === ' ') {
        e.preventDefault();
        open();
      }
      return;
    }

    switch (e.key) {
      case 'ArrowDown':
        e.preventDefault();
        setSelectedIndex((prev) => Math.min(prev + 1, items.length - 1));
        break;
      case 'ArrowUp':
        e.preventDefault();
        setSelectedIndex((prev) => Math.max(prev - 1, 0));
        break;
      case 'Enter':
      case ' ':
        e.preventDefault();
        if (selectedIndex >= 0) select(items[selectedIndex]);
        break;
      case 'Escape':
        close();
        break;
    }
  };

  return {
    isOpen,
    selectedIndex,
    selectedValue,
    open,
    close,
    select,
    triggerProps: {
      ref: triggerRef,
      onClick: () => (isOpen ? close() : open()),
      onKeyDown: (e: React.KeyboardEvent, items: T[]) => handleKeyDown(e.nativeEvent, items),
      'aria-expanded': isOpen,
      'aria-haspopup': 'listbox' as const,
    },
    listProps: {
      ref: listRef,
      role: 'listbox' as const,
      'aria-activedescendant': selectedIndex >= 0 ? `option-${selectedIndex}` : undefined,
    },
    getItemProps: (index: number, value: T) => ({
      id: `option-${index}`,
      role: 'option' as const,
      'aria-selected': selectedIndex === index,
      onClick: () => select(value),
      onMouseEnter: () => setSelectedIndex(index),
    }),
  };
}
```

---

## Render Props Pattern

Pass rendering control to consumers.

```typescript
type DataFetcherProps<T> = {
  url: string;
  children: (state: {
    data: T | null;
    loading: boolean;
    error: Error | null;
    refetch: () => void;
  }) => ReactNode;
};

function DataFetcher<T>({ url, children }: DataFetcherProps<T>) {
  const [data, setData] = useState<T | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<Error | null>(null);

  const fetchData = useCallback(async () => {
    setLoading(true);
    setError(null);
    try {
      const response = await fetch(url);
      const json = await response.json();
      setData(json);
    } catch (e) {
      setError(e as Error);
    } finally {
      setLoading(false);
    }
  }, [url]);

  useEffect(() => {
    fetchData();
  }, [fetchData]);

  return <>{children({ data, loading, error, refetch: fetchData })}</>;
}

// Usage
<DataFetcher<User[]> url="/api/users">
  {({ data, loading, error, refetch }) => {
    if (loading) return <Spinner />;
    if (error) return <ErrorMessage error={error} onRetry={refetch} />;
    return (
      <ul>
        {data?.map((user) => (
          <li key={user.id}>{user.name}</li>
        ))}
      </ul>
    );
  }}
</DataFetcher>
```

---

## Slot Pattern (Component Injection)

Allow component customization via slots.

```typescript
import { Slot } from '@radix-ui/react-slot';

type CardProps = {
  children: ReactNode;
  asChild?: boolean;
  className?: string;
};

function Card({ children, asChild, className }: CardProps) {
  const Comp = asChild ? Slot : 'div';

  return (
    <Comp className={cn('rounded-lg border bg-card p-6', className)}>
      {children}
    </Comp>
  );
}

// Usage - default div
<Card>
  <h2>Card Title</h2>
  <p>Card content</p>
</Card>

// Usage - as link
<Card asChild>
  <a href="/details">
    <h2>Clickable Card</h2>
    <p>Click anywhere to navigate</p>
  </a>
</Card>

// Usage - as button
<Card asChild>
  <button onClick={handleClick}>
    <h2>Interactive Card</h2>
  </button>
</Card>
```

---

## Higher-Order Components (HOC)

Wrap components with additional functionality.

```typescript
// withAuth HOC
function withAuth<P extends object>(
  WrappedComponent: ComponentType<P>
): ComponentType<P> {
  return function AuthenticatedComponent(props: P) {
    const { user, loading } = useAuth();

    if (loading) return <LoadingSpinner />;
    if (!user) return <Redirect to="/login" />;

    return <WrappedComponent {...props} />;
  };
}

// Usage
const ProtectedDashboard = withAuth(Dashboard);

// withErrorBoundary HOC
function withErrorBoundary<P extends object>(
  WrappedComponent: ComponentType<P>,
  fallback: ReactNode
): ComponentType<P> {
  return function WithErrorBoundary(props: P) {
    return (
      <ErrorBoundary fallback={fallback}>
        <WrappedComponent {...props} />
      </ErrorBoundary>
    );
  };
}
```

---

## Component Composition Best Practices

### 1. Prefer Composition Over Props

```typescript
// BAD - Too many props
<Button
  leftIcon={<SearchIcon />}
  rightIcon={<ChevronIcon />}
  loading
  loadingText="Searching..."
>
  Search
</Button>

// GOOD - Composition
<Button>
  <SearchIcon />
  <span>Search</span>
  <ChevronIcon />
</Button>

<Button disabled>
  <Spinner />
  <span>Searching...</span>
</Button>
```

### 2. Use Children for Flexibility

```typescript
// BAD - Limited flexibility
<Modal title="Confirm" message="Are you sure?" />

// GOOD - Flexible composition
<Modal>
  <Modal.Header>
    <Modal.Title>Confirm</Modal.Title>
    <Modal.Close />
  </Modal.Header>
  <Modal.Body>
    <p>Are you sure you want to continue?</p>
  </Modal.Body>
  <Modal.Footer>
    <Button variant="ghost">Cancel</Button>
    <Button>Confirm</Button>
  </Modal.Footer>
</Modal>
```

### 3. Expose Primitives

```typescript
// Export both composed and primitive versions
export { Button, ButtonIcon, ButtonSpinner } from './button';
export { Input, InputLabel, InputError, InputIcon } from './input';
export { Modal, ModalHeader, ModalBody, ModalFooter } from './modal';
```

---

## Quick Reference

| Pattern | Use Case | Flexibility |
|---------|----------|-------------|
| **Polymorphic** | Render as different elements | High |
| **Compound** | Related components that share state | High |
| **Headless** | Logic without UI | Very High |
| **Render Props** | Custom rendering | Very High |
| **Slot** | Component injection | Medium |
| **HOC** | Cross-cutting concerns | Medium |

---

## Resources

- [Radix UI Primitives](https://www.radix-ui.com/primitives)
- [Headless UI](https://headlessui.com)
- [React Component Patterns](https://www.patterns.dev/react)
- [Compound Components](https://kentcdodds.com/blog/compound-components-with-react-hooks)
