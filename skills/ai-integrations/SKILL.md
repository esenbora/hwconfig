---
name: ai-integrations
description: Use when building AI features, chatbots, assistants, image generation, or any LLM integration. OpenAI, Anthropic, OpenRouter, Vercel AI SDK, Fal.ai, RAG, embeddings, agents. Triggers on: openai, ai, llm, chatbot, gpt, claude, assistant, generate image, flux, rag, embeddings, vector, ai agent, chat interface, ai feature.
version: 2.0.0
---

# AI Integration Patterns

Comprehensive patterns for integrating AI services into your applications.

## OpenAI SDK

### Basic Chat Completion

```typescript
import OpenAI from 'openai'

const openai = new OpenAI({
  apiKey: process.env.OPENAI_API_KEY, // Server-side only!
})

// Non-streaming
async function chat(messages: OpenAI.ChatCompletionMessageParam[]) {
  const response = await openai.chat.completions.create({
    model: 'gpt-4-turbo-preview',
    messages,
    temperature: 0.7,
  })
  return response.choices[0].message.content
}

// Streaming
async function* chatStream(messages: OpenAI.ChatCompletionMessageParam[]) {
  const stream = await openai.chat.completions.create({
    model: 'gpt-4-turbo-preview',
    messages,
    stream: true,
  })

  for await (const chunk of stream) {
    const content = chunk.choices[0]?.delta?.content
    if (content) yield content
  }
}
```

### Streaming with Vercel AI SDK

```typescript
import { OpenAIStream, StreamingTextResponse } from 'ai'
import OpenAI from 'openai'

const openai = new OpenAI()

export async function POST(req: Request) {
  const { messages } = await req.json()

  const response = await openai.chat.completions.create({
    model: 'gpt-4-turbo-preview',
    messages,
    stream: true,
  })

  const stream = OpenAIStream(response)
  return new StreamingTextResponse(stream)
}
```

## OpenRouter (Multi-Model)

### Setup

```typescript
import OpenAI from 'openai'

const openrouter = new OpenAI({
  baseURL: 'https://openrouter.ai/api/v1',
  apiKey: process.env.OPENROUTER_API_KEY,
  defaultHeaders: {
    'HTTP-Referer': process.env.SITE_URL,
    'X-Title': process.env.SITE_NAME,
  },
})
```

### Model Selection

```typescript
// Available models
const MODELS = {
  fast: 'anthropic/claude-3-haiku',
  balanced: 'anthropic/claude-3-sonnet',
  powerful: 'anthropic/claude-3-opus',
  cheap: 'meta-llama/llama-3-8b-instruct',
  coding: 'deepseek/deepseek-coder',
} as const

async function chat(messages: Message[], model: keyof typeof MODELS) {
  return openrouter.chat.completions.create({
    model: MODELS[model],
    messages,
  })
}
```

### Cost Tracking

```typescript
// OpenRouter returns usage in response
const response = await openrouter.chat.completions.create({...})

const usage = response.usage
console.log({
  promptTokens: usage?.prompt_tokens,
  completionTokens: usage?.completion_tokens,
  totalCost: response.usage?.total_cost, // OpenRouter specific
})
```

## Fal.ai (Image/Video Generation)

### Setup

```typescript
import * as fal from '@fal-ai/serverless-client'

fal.config({
  credentials: process.env.FAL_KEY,
})
```

### Image Generation

```typescript
// FLUX model
const result = await fal.subscribe('fal-ai/flux/dev', {
  input: {
    prompt: 'A serene mountain landscape at sunset',
    image_size: 'landscape_16_9',
    num_inference_steps: 28,
    guidance_scale: 3.5,
  },
  logs: true,
  onQueueUpdate: (update) => {
    if (update.status === 'IN_PROGRESS') {
      console.log('Progress:', update.logs)
    }
  },
})

// Result contains image URLs
const imageUrl = result.images[0].url
```

### Real-time Generation (WebSocket)

```typescript
const connection = fal.realtime.connect('fal-ai/fast-sdxl', {
  onResult: (result) => {
    console.log('Generated:', result.images[0].url)
  },
  onError: (error) => {
    console.error('Error:', error)
  },
})

// Send generation requests
connection.send({
  prompt: 'A cyberpunk city at night',
  num_inference_steps: 4,
})
```

## EachLabs Integration

### API Client Setup

```typescript
const EACHLABS_API = 'https://api.eachlabs.ai/v1'

async function eachLabsRequest(endpoint: string, data: any) {
  const response = await fetch(`${EACHLABS_API}${endpoint}`, {
    method: 'POST',
    headers: {
      'Authorization': `Bearer ${process.env.EACHLABS_API_KEY}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify(data),
  })

  if (!response.ok) {
    throw new Error(`EachLabs API error: ${response.status}`)
  }

  return response.json()
}
```

## Rate Limiting & Cost Control

### Token-Based Rate Limiting

```typescript
import { Ratelimit } from '@upstash/ratelimit'
import { Redis } from '@upstash/redis'

const ratelimit = new Ratelimit({
  redis: Redis.fromEnv(),
  limiter: Ratelimit.slidingWindow(100, '1 h'), // 100 requests/hour
  analytics: true,
})

export async function POST(req: Request) {
  const ip = req.headers.get('x-forwarded-for') ?? 'anonymous'
  const { success, limit, remaining } = await ratelimit.limit(ip)

  if (!success) {
    return new Response('Rate limit exceeded', {
      status: 429,
      headers: {
        'X-RateLimit-Limit': limit.toString(),
        'X-RateLimit-Remaining': remaining.toString(),
      },
    })
  }

  // Process AI request...
}
```

### Cost Budgeting

```typescript
// Track costs per user
async function trackUsage(userId: string, tokens: number, model: string) {
  const costPerToken = MODEL_COSTS[model] ?? 0.00001
  const cost = tokens * costPerToken

  await db.usage.create({
    data: {
      userId,
      tokens,
      model,
      cost,
      timestamp: new Date(),
    },
  })

  // Check budget
  const monthlyUsage = await db.usage.aggregate({
    where: {
      userId,
      timestamp: { gte: startOfMonth(new Date()) },
    },
    _sum: { cost: true },
  })

  if (monthlyUsage._sum.cost > USER_MONTHLY_BUDGET) {
    throw new Error('Monthly budget exceeded')
  }
}
```

## Error Handling

```typescript
async function safeAICall<T>(fn: () => Promise<T>): Promise<T> {
  try {
    return await fn()
  } catch (error) {
    if (error instanceof OpenAI.APIError) {
      if (error.status === 429) {
        // Rate limited - implement exponential backoff
        await sleep(1000)
        return safeAICall(fn)
      }
      if (error.status === 503) {
        // Service unavailable - try fallback model
        throw new Error('AI service unavailable')
      }
    }
    throw error
  }
}
```

## Security Rules

1. **NEVER expose API keys to client** - All AI calls must go through your API
2. **Always rate limit** - AI APIs are expensive
3. **Validate input** - Sanitize user prompts
4. **Set max tokens** - Prevent runaway costs
5. **Log usage** - Track costs per user
6. **Use streaming** - Better UX, same cost

## RAG Architecture

### Two-Stage Retrieval with Reranking

```typescript
async function retrieveWithRerank(query: string, limit = 10) {
  // Stage 1: Fast over-retrieval
  const queryVector = await embed(query)
  const candidates = await vectorStore.search(queryVector, limit * 5)

  // Stage 2: Cross-encoder reranking for precision
  const pairs = candidates.map(doc => [query, doc.content])
  const scores = await reranker.predict(pairs)

  // Sort by reranker scores
  return candidates
    .map((doc, i) => ({ doc, score: scores[i] }))
    .sort((a, b) => b.score - a.score)
    .slice(0, limit)
    .map(({ doc }) => doc)
}
```

### Hybrid Search (Vector + Keyword)

```typescript
function reciprocalRankFusion(
  resultLists: Result[][],
  k = 60
): Result[] {
  const scores = new Map<string, number>()
  const items = new Map<string, Result>()

  for (const results of resultLists) {
    results.forEach((result, rank) => {
      const current = scores.get(result.id) ?? 0
      scores.set(result.id, current + 1 / (k + rank + 1))
      items.set(result.id, result)
    })
  }

  return [...scores.entries()]
    .sort((a, b) => b[1] - a[1])
    .map(([id]) => items.get(id)!)
}

// Combine vector + BM25 search
const results = reciprocalRankFusion([vectorResults, keywordResults])
```

## Structured Output (Tool Use)

```typescript
import Anthropic from '@anthropic-ai/sdk'

const client = new Anthropic()

const tools = [{
  name: "extract_entities",
  description: "Extract structured entities from text",
  input_schema: {
    type: "object",
    properties: {
      entities: {
        type: "array",
        items: {
          type: "object",
          properties: {
            name: { type: "string" },
            type: { type: "string", enum: ["person", "org", "location"] },
            confidence: { type: "number", minimum: 0, maximum: 1 }
          },
          required: ["name", "type", "confidence"]
        }
      }
    },
    required: ["entities"]
  }
}]

const response = await client.messages.create({
  model: "claude-sonnet-4-20250514",
  max_tokens: 1024,
  tools,
  tool_choice: { type: "tool", name: "extract_entities" },
  messages: [{ role: "user", content: `Extract entities: ${text}` }]
})

// Response guaranteed to match schema
const entities = response.content[0].input.entities
```

## Agent Patterns

### Orchestrator-Worker Pattern

```typescript
class OrchestratorAgent {
  constructor(private workers: Map<string, Agent>) {}

  async execute(task: string) {
    // Plan: decompose into subtasks
    const plan = await this.plan(task)

    // Dispatch to workers
    const results = new Map()
    for (const subtask of plan.subtasks) {
      const worker = this.workers.get(subtask.workerType)!
      results.set(subtask.id, await worker.execute(subtask.description))
    }

    // Synthesize results
    return this.synthesize(task, results)
  }
}
```

## LLM Anti-Patterns

| Anti-Pattern | Why Bad | Do Instead |
|--------------|---------|------------|
| Stuffing context window | Performance degrades, "lost in the middle" | Selective retrieval, compress context |
| Prompts as afterthoughts | Can't reproduce or rollback | Version control prompts like code |
| Trusting LLM output directly | Will hallucinate formats | Use structured output with tool use |
| Vector search alone | Misses exact matches | Always use hybrid (vector + keyword) |
| No reranking | #1 cause of RAG hallucinations | Always rerank before passing to LLM |
| Monolithic agent | Selection accuracy decreases with tools | Use orchestrator-worker pattern |

## Anti-Patterns

- ❌ API keys in client code
- ❌ No rate limiting
- ❌ No cost tracking
- ❌ Unbounded token limits
- ❌ No error handling for API failures
- ❌ Synchronous responses for long generations
