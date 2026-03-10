---
name: react-hook-form
description: Use when building forms with react-hook-form. Form state, validation, field arrays. Triggers on: react-hook-form, useForm, form, register, handleSubmit, field array.
version: 1.0.0
detect: ["react-hook-form"]
---

# React Hook Form

Performant form handling with minimal re-renders.

## Basic Setup

```typescript
'use client'

import { useForm } from 'react-hook-form'
import { zodResolver } from '@hookform/resolvers/zod'
import { z } from 'zod'

const schema = z.object({
  email: z.string().email('Invalid email'),
  password: z.string().min(8, 'Min 8 characters'),
})

type FormData = z.infer<typeof schema>

export function LoginForm() {
  const {
    register,
    handleSubmit,
    formState: { errors, isSubmitting },
  } = useForm<FormData>({
    resolver: zodResolver(schema),
  })

  const onSubmit = async (data: FormData) => {
    await login(data)
  }

  return (
    <form onSubmit={handleSubmit(onSubmit)}>
      <div>
        <input {...register('email')} placeholder="Email" />
        {errors.email && <span>{errors.email.message}</span>}
      </div>
      
      <div>
        <input {...register('password')} type="password" placeholder="Password" />
        {errors.password && <span>{errors.password.message}</span>}
      </div>
      
      <button type="submit" disabled={isSubmitting}>
        {isSubmitting ? 'Loading...' : 'Login'}
      </button>
    </form>
  )
}
```

## With shadcn/ui Form

```typescript
'use client'

import { useForm } from 'react-hook-form'
import { zodResolver } from '@hookform/resolvers/zod'
import { z } from 'zod'
import {
  Form,
  FormControl,
  FormField,
  FormItem,
  FormLabel,
  FormMessage,
} from '@/components/ui/form'
import { Input } from '@/components/ui/input'
import { Button } from '@/components/ui/button'

const schema = z.object({
  name: z.string().min(1, 'Name is required'),
  email: z.string().email('Invalid email'),
})

type FormData = z.infer<typeof schema>

export function ProfileForm() {
  const form = useForm<FormData>({
    resolver: zodResolver(schema),
    defaultValues: {
      name: '',
      email: '',
    },
  })

  const onSubmit = async (data: FormData) => {
    await updateProfile(data)
  }

  return (
    <Form {...form}>
      <form onSubmit={form.handleSubmit(onSubmit)} className="space-y-4">
        <FormField
          control={form.control}
          name="name"
          render={({ field }) => (
            <FormItem>
              <FormLabel>Name</FormLabel>
              <FormControl>
                <Input {...field} />
              </FormControl>
              <FormMessage />
            </FormItem>
          )}
        />

        <FormField
          control={form.control}
          name="email"
          render={({ field }) => (
            <FormItem>
              <FormLabel>Email</FormLabel>
              <FormControl>
                <Input type="email" {...field} />
              </FormControl>
              <FormMessage />
            </FormItem>
          )}
        />

        <Button type="submit" disabled={form.formState.isSubmitting}>
          {form.formState.isSubmitting ? 'Saving...' : 'Save'}
        </Button>
      </form>
    </Form>
  )
}
```

## Server Action Integration

```typescript
'use client'

import { useForm } from 'react-hook-form'
import { zodResolver } from '@hookform/resolvers/zod'
import { useFormState } from 'react-dom'
import { createPost, createPostSchema } from '@/app/actions'

type FormData = z.infer<typeof createPostSchema>

export function CreatePostForm() {
  const form = useForm<FormData>({
    resolver: zodResolver(createPostSchema),
  })

  const onSubmit = async (data: FormData) => {
    const result = await createPost(data)
    
    if (!result.success) {
      // Set server errors
      Object.entries(result.errors || {}).forEach(([field, messages]) => {
        form.setError(field as keyof FormData, {
          message: messages?.[0],
        })
      })
      return
    }

    // Success
    form.reset()
  }

  return (
    <form onSubmit={form.handleSubmit(onSubmit)}>
      {/* form fields */}
    </form>
  )
}
```

## Field Arrays

```typescript
import { useFieldArray, useForm } from 'react-hook-form'

const schema = z.object({
  items: z.array(z.object({
    name: z.string().min(1),
    quantity: z.number().min(1),
  })).min(1, 'Add at least one item'),
})

export function OrderForm() {
  const form = useForm({
    resolver: zodResolver(schema),
    defaultValues: {
      items: [{ name: '', quantity: 1 }],
    },
  })

  const { fields, append, remove } = useFieldArray({
    control: form.control,
    name: 'items',
  })

  return (
    <form onSubmit={form.handleSubmit(onSubmit)}>
      {fields.map((field, index) => (
        <div key={field.id}>
          <input {...form.register(`items.${index}.name`)} />
          <input
            type="number"
            {...form.register(`items.${index}.quantity`, { valueAsNumber: true })}
          />
          <button type="button" onClick={() => remove(index)}>
            Remove
          </button>
        </div>
      ))}
      
      <button type="button" onClick={() => append({ name: '', quantity: 1 })}>
        Add Item
      </button>
      
      <button type="submit">Submit</button>
    </form>
  )
}
```

## Watch and Computed Values

```typescript
const form = useForm()

// Watch single field
const email = form.watch('email')

// Watch multiple fields
const [firstName, lastName] = form.watch(['firstName', 'lastName'])

// Watch all
const allValues = form.watch()

// Conditional rendering
{form.watch('showMore') && (
  <div>Additional fields...</div>
)}
```

## Reset and Default Values

```typescript
const form = useForm({
  defaultValues: {
    name: '',
    email: '',
  },
})

// Reset to defaults
form.reset()

// Reset to specific values
form.reset({ name: 'John', email: 'john@example.com' })

// Set value programmatically
form.setValue('name', 'Jane')

// Async default values
const form = useForm({
  defaultValues: async () => {
    const user = await fetchUser()
    return { name: user.name, email: user.email }
  },
})
```
