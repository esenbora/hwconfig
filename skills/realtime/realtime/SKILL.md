---
name: realtime
description: Real-time features with WebSockets, SSE, and Supabase Realtime. Triggers on: ws, pusher, or supabase realtime usage.
version: 1.0.0
detect: ["pusher", "socket.io", "@supabase/realtime-js"]
---

# Real-time Features

Patterns for real-time communication.

## Supabase Realtime

```typescript
'use client'

import { createClient } from '@/lib/supabase/client'
import { useEffect, useState } from 'react'

export function useRealtimePosts() {
  const [posts, setPosts] = useState<Post[]>([])
  const supabase = createClient()

  useEffect(() => {
    // Initial fetch
    const fetchPosts = async () => {
      const { data } = await supabase.from('posts').select('*')
      if (data) setPosts(data)
    }
    fetchPosts()

    // Subscribe to changes
    const channel = supabase
      .channel('posts-changes')
      .on(
        'postgres_changes',
        { event: '*', schema: 'public', table: 'posts' },
        (payload) => {
          if (payload.eventType === 'INSERT') {
            setPosts((prev) => [payload.new as Post, ...prev])
          } else if (payload.eventType === 'UPDATE') {
            setPosts((prev) =>
              prev.map((p) => (p.id === payload.new.id ? payload.new as Post : p))
            )
          } else if (payload.eventType === 'DELETE') {
            setPosts((prev) => prev.filter((p) => p.id !== payload.old.id))
          }
        }
      )
      .subscribe()

    return () => {
      supabase.removeChannel(channel)
    }
  }, [supabase])

  return posts
}
```

## Presence (Online Users)

```typescript
'use client'

import { createClient } from '@/lib/supabase/client'
import { useEffect, useState } from 'react'

interface PresenceState {
  id: string
  name: string
  online_at: string
}

export function usePresence(roomId: string, user: User) {
  const [onlineUsers, setOnlineUsers] = useState<PresenceState[]>([])
  const supabase = createClient()

  useEffect(() => {
    const channel = supabase.channel(`room:${roomId}`)

    channel
      .on('presence', { event: 'sync' }, () => {
        const state = channel.presenceState<PresenceState>()
        const users = Object.values(state).flat()
        setOnlineUsers(users)
      })
      .subscribe(async (status) => {
        if (status === 'SUBSCRIBED') {
          await channel.track({
            id: user.id,
            name: user.name,
            online_at: new Date().toISOString(),
          })
        }
      })

    return () => {
      supabase.removeChannel(channel)
    }
  }, [roomId, user, supabase])

  return onlineUsers
}
```

## Broadcast (Ephemeral Events)

```typescript
'use client'

import { createClient } from '@/lib/supabase/client'
import { useEffect, useCallback } from 'react'

// Cursor sharing
export function useCursorSharing(roomId: string) {
  const supabase = createClient()

  useEffect(() => {
    const channel = supabase.channel(`cursors:${roomId}`)

    channel
      .on('broadcast', { event: 'cursor' }, ({ payload }) => {
        // Update cursor position for other user
        updateCursor(payload.userId, payload.x, payload.y)
      })
      .subscribe()

    return () => {
      supabase.removeChannel(channel)
    }
  }, [roomId, supabase])

  const sendCursor = useCallback(
    (x: number, y: number) => {
      supabase.channel(`cursors:${roomId}`).send({
        type: 'broadcast',
        event: 'cursor',
        payload: { userId: 'current-user', x, y },
      })
    },
    [roomId, supabase]
  )

  return { sendCursor }
}
```

## Server-Sent Events (SSE)

```typescript
// app/api/events/route.ts
export async function GET() {
  const stream = new ReadableStream({
    start(controller) {
      const encoder = new TextEncoder()

      // Send initial event
      controller.enqueue(encoder.encode('event: connected\ndata: {}\n\n'))

      // Send periodic updates
      const interval = setInterval(() => {
        const data = JSON.stringify({ time: new Date().toISOString() })
        controller.enqueue(encoder.encode(`data: ${data}\n\n`))
      }, 1000)

      // Cleanup
      return () => clearInterval(interval)
    },
  })

  return new Response(stream, {
    headers: {
      'Content-Type': 'text/event-stream',
      'Cache-Control': 'no-cache',
      Connection: 'keep-alive',
    },
  })
}

// Client
function useSSE(url: string) {
  const [data, setData] = useState(null)

  useEffect(() => {
    const eventSource = new EventSource(url)

    eventSource.onmessage = (event) => {
      setData(JSON.parse(event.data))
    }

    return () => eventSource.close()
  }, [url])

  return data
}
```

## Pusher

```typescript
// lib/pusher.ts
import Pusher from 'pusher'
import PusherClient from 'pusher-js'

// Server
export const pusher = new Pusher({
  appId: process.env.PUSHER_APP_ID!,
  key: process.env.NEXT_PUBLIC_PUSHER_KEY!,
  secret: process.env.PUSHER_SECRET!,
  cluster: process.env.NEXT_PUBLIC_PUSHER_CLUSTER!,
  useTLS: true,
})

// Client
export const pusherClient = new PusherClient(
  process.env.NEXT_PUBLIC_PUSHER_KEY!,
  { cluster: process.env.NEXT_PUBLIC_PUSHER_CLUSTER! }
)

// Send event (server)
await pusher.trigger('channel', 'event', { message: 'Hello' })

// Subscribe (client)
useEffect(() => {
  const channel = pusherClient.subscribe('channel')
  
  channel.bind('event', (data: any) => {
    console.log('Received:', data)
  })

  return () => {
    channel.unbind_all()
    pusherClient.unsubscribe('channel')
  }
}, [])
```

## Optimistic Updates with Realtime

```typescript
function ChatRoom({ roomId }: { roomId: string }) {
  const [messages, setMessages] = useState<Message[]>([])
  const [optimistic, setOptimistic] = useState<Message[]>([])

  // Send message with optimistic update
  const sendMessage = async (content: string) => {
    const tempMessage = {
      id: `temp-${Date.now()}`,
      content,
      createdAt: new Date().toISOString(),
      pending: true,
    }

    // Add optimistic message
    setOptimistic((prev) => [...prev, tempMessage])

    try {
      await supabase.from('messages').insert({ content, room_id: roomId })
    } catch {
      // Remove on error
      setOptimistic((prev) => prev.filter((m) => m.id !== tempMessage.id))
    }
  }

  // Realtime removes optimistic when real message arrives
  useEffect(() => {
    const channel = supabase
      .channel(`room:${roomId}`)
      .on('postgres_changes', { event: 'INSERT', table: 'messages' }, (payload) => {
        setMessages((prev) => [...prev, payload.new as Message])
        // Clear matching optimistic message
        setOptimistic((prev) =>
          prev.filter((m) => m.content !== payload.new.content)
        )
      })
      .subscribe()

    return () => supabase.removeChannel(channel)
  }, [roomId])

  const allMessages = [...messages, ...optimistic]

  return (
    <div>
      {allMessages.map((msg) => (
        <div key={msg.id} className={msg.pending ? 'opacity-50' : ''}>
          {msg.content}
        </div>
      ))}
    </div>
  )
}
```
