---
name: shadcn
description: shadcn/ui component library patterns and customization. Triggers on: components/ui folder.
version: 1.0.0
detect: ["components/ui"]
---

# shadcn/ui

Copy-paste component library built on Radix UI and Tailwind CSS.

## Installation

```bash
npx shadcn-ui@latest init
npx shadcn-ui@latest add button card dialog
```

## Common Components

### Button

```tsx
import { Button } from '@/components/ui/button'

// Variants
<Button variant="default">Primary</Button>
<Button variant="secondary">Secondary</Button>
<Button variant="outline">Outline</Button>
<Button variant="ghost">Ghost</Button>
<Button variant="link">Link</Button>
<Button variant="destructive">Destructive</Button>

// Sizes
<Button size="sm">Small</Button>
<Button size="default">Default</Button>
<Button size="lg">Large</Button>
<Button size="icon"><Icon /></Button>

// Loading state
<Button disabled>
  <Loader2 className="mr-2 h-4 w-4 animate-spin" />
  Loading
</Button>

// As child (for custom elements)
<Button asChild>
  <Link href="/dashboard">Go to Dashboard</Link>
</Button>
```

### Card

```tsx
import {
  Card,
  CardContent,
  CardDescription,
  CardFooter,
  CardHeader,
  CardTitle,
} from '@/components/ui/card'

<Card>
  <CardHeader>
    <CardTitle>Card Title</CardTitle>
    <CardDescription>Card description here</CardDescription>
  </CardHeader>
  <CardContent>
    <p>Card content goes here.</p>
  </CardContent>
  <CardFooter>
    <Button>Action</Button>
  </CardFooter>
</Card>
```

### Dialog

```tsx
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogFooter,
  DialogHeader,
  DialogTitle,
  DialogTrigger,
} from '@/components/ui/dialog'

<Dialog>
  <DialogTrigger asChild>
    <Button>Open Dialog</Button>
  </DialogTrigger>
  <DialogContent>
    <DialogHeader>
      <DialogTitle>Dialog Title</DialogTitle>
      <DialogDescription>
        This is the dialog description.
      </DialogDescription>
    </DialogHeader>
    <div className="py-4">
      {/* Dialog content */}
    </div>
    <DialogFooter>
      <Button type="submit">Save</Button>
    </DialogFooter>
  </DialogContent>
</Dialog>
```

### Form

```tsx
import { zodResolver } from '@hookform/resolvers/zod'
import { useForm } from 'react-hook-form'
import { z } from 'zod'
import {
  Form,
  FormControl,
  FormDescription,
  FormField,
  FormItem,
  FormLabel,
  FormMessage,
} from '@/components/ui/form'
import { Input } from '@/components/ui/input'

const formSchema = z.object({
  username: z.string().min(2).max(50),
})

function ProfileForm() {
  const form = useForm<z.infer<typeof formSchema>>({
    resolver: zodResolver(formSchema),
    defaultValues: { username: '' },
  })

  function onSubmit(values: z.infer<typeof formSchema>) {
    console.log(values)
  }

  return (
    <Form {...form}>
      <form onSubmit={form.handleSubmit(onSubmit)} className="space-y-8">
        <FormField
          control={form.control}
          name="username"
          render={({ field }) => (
            <FormItem>
              <FormLabel>Username</FormLabel>
              <FormControl>
                <Input placeholder="johndoe" {...field} />
              </FormControl>
              <FormDescription>
                This is your public display name.
              </FormDescription>
              <FormMessage />
            </FormItem>
          )}
        />
        <Button type="submit">Submit</Button>
      </form>
    </Form>
  )
}
```

### Select

```tsx
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from '@/components/ui/select'

<Select>
  <SelectTrigger className="w-[180px]">
    <SelectValue placeholder="Select option" />
  </SelectTrigger>
  <SelectContent>
    <SelectItem value="option1">Option 1</SelectItem>
    <SelectItem value="option2">Option 2</SelectItem>
    <SelectItem value="option3">Option 3</SelectItem>
  </SelectContent>
</Select>
```

### Toast

```tsx
// Setup: Add Toaster to layout
import { Toaster } from '@/components/ui/toaster'

export default function RootLayout({ children }) {
  return (
    <html>
      <body>
        {children}
        <Toaster />
      </body>
    </html>
  )
}

// Usage
import { useToast } from '@/components/ui/use-toast'

function MyComponent() {
  const { toast } = useToast()

  return (
    <Button
      onClick={() => {
        toast({
          title: 'Success!',
          description: 'Your changes have been saved.',
        })
      }}
    >
      Save
    </Button>
  )
}
```

### Data Table

```tsx
import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from '@/components/ui/table'

<Table>
  <TableHeader>
    <TableRow>
      <TableHead>Name</TableHead>
      <TableHead>Email</TableHead>
      <TableHead className="text-right">Amount</TableHead>
    </TableRow>
  </TableHeader>
  <TableBody>
    {data.map((item) => (
      <TableRow key={item.id}>
        <TableCell className="font-medium">{item.name}</TableCell>
        <TableCell>{item.email}</TableCell>
        <TableCell className="text-right">{item.amount}</TableCell>
      </TableRow>
    ))}
  </TableBody>
</Table>
```

## Customization

### Extending Components

```tsx
// components/ui/button.tsx - Add custom variants
const buttonVariants = cva(
  'inline-flex items-center justify-center...',
  {
    variants: {
      variant: {
        default: '...',
        // Add custom variant
        success: 'bg-green-500 text-white hover:bg-green-600',
      },
    },
  }
)
```

### Theme Colors

```css
/* globals.css - Customize colors */
@layer base {
  :root {
    --primary: 262 83% 58%; /* Purple */
    --primary-foreground: 0 0% 100%;
  }
}
```

---

## Ekosistem ve Kaynaklar

### shadcn Genisletmeleri

| Kaynak | URL | Aciklama |
|--------|-----|----------|
| **tweakcn** | tweakcn.com | shadcn bilesenlerini istedigin sekilde ozellestir |
| **21st.dev** | 21st.dev | Hazir React componentleri, kolay entegrasyon |

### Landing Page & Marketing UI

| Kaynak | URL | Kullanim Alani |
|--------|-----|----------------|
| **Aceternity UI** | ui.aceternity.com | Apple tarzi animasyonlar, modern efektler |
| **Magic UI** | magicui.design | Piriltili butonlar, animasyonlu listeler |
| **Preline** | preline.co | Kurumsal projeler icin Tailwind bilesenleri |
| **HyperUI** | hyperui.dev | Pazarlama ve e-ticaret Tailwind snippet'lari |
| **Float UI** | floatui.com | Minimalist, responsive UI bilesenleri |

### Mikro Etkilesimler & Efektler

| Kaynak | URL | Kullanim Alani |
|--------|-----|----------------|
| **Animata** | animata.design | Mikro etkilesimler, el yazisi efektleri, acik kaynak |
| **Origin UI** | originui.com | Input, checkbox, mikro etkilesimler |
| **UIverse** | uiverse.io | Topluluk butonlari, kartlari, inputlari (CSS/Tailwind) |

### Ilham ve Referans

| Kaynak | URL | Kullanim Alani |
|--------|-----|----------------|
| **Mobbin** | mobbin.com | Milyon dolarlik sirketlerin A/B testleri, dashboard ornekleri |
| **Land-book** | land-book.com | Landing page tasarim ilhami |

### Ikonlar

| Kaynak | URL | Ozellik |
|--------|-----|---------|
| **Phosphor Icons** | phosphoricons.com | Duo-tone ikonlar, 6 farkli stil |
| **Hugeicons** | hugeicons.com | 4000+ modern ikon |
| **Lucide** | lucide.dev | shadcn varsayilan, hafif ve tutarli |

---

## Onerilern Kullanim Senaryolari

```
Landing Page yaparken:
1. Aceternity UI → Hero section, scroll animasyonlari
2. Magic UI → CTA butonlari, feature kartlari
3. Land-book → Ilham icin referans tasarimlar

Dashboard yaparken:
1. shadcn/ui → Temel bilesenler (Table, Card, Form)
2. Mobbin → A/B test edilmis layout ornekleri
3. Origin UI → Input ve form mikro etkilesimleri

Marketing sitesi:
1. HyperUI → E-ticaret kartlari, pricing tablolari
2. Preline → Kurumsal header, footer, testimonial
3. Float UI → Responsive section'lar
```

---

## Hizli Kurulum Ornekleri

### Aceternity Hero Section

```bash
# Aceternity UI'dan kopyala, yapistir
# https://ui.aceternity.com/components/hero-parallax
```

### Magic UI Animated Button

```bash
# Magic UI'dan Shimmer Button
# https://magicui.design/docs/components/shimmer-button
```

### Phosphor Icons Kurulum

```bash
npm install @phosphor-icons/react

# Kullanim
import { House, Gear, User } from '@phosphor-icons/react'

<House size={24} weight="duotone" />
<Gear size={24} weight="fill" />
```
