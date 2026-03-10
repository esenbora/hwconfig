---
name: prisma
description: Use when working with Prisma ORM. Schema, migrations, queries, relations. Triggers on: prisma, prisma schema, prisma query, prisma migration, prisma client, schema design, database design, database structure.
version: 1.0.0
---

# Prisma Deep Knowledge

> Advanced queries, raw SQL, transactions, and performance optimization.

---

## Quick Reference

```typescript
// Basic query
const users = await prisma.user.findMany({
  where: { status: 'active' },
  include: { posts: true }
});
```

---

## Advanced Queries

### Nested Writes (Atomic Operations)

```typescript
// Create user with related records in single transaction
const user = await prisma.user.create({
  data: {
    email: 'user@example.com',
    profile: {
      create: { bio: 'Hello' }
    },
    posts: {
      create: [
        { title: 'Post 1' },
        { title: 'Post 2' }
      ]
    }
  },
  include: {
    profile: true,
    posts: true
  }
});
```

### Upsert with Connect/Create

```typescript
const post = await prisma.post.upsert({
  where: { slug: 'my-post' },
  create: {
    slug: 'my-post',
    title: 'My Post',
    author: {
      connectOrCreate: {
        where: { email: 'author@example.com' },
        create: { email: 'author@example.com', name: 'Author' }
      }
    }
  },
  update: {
    title: 'Updated Title'
  }
});
```

### Filtering on Relations

```typescript
// Users with at least one published post
const users = await prisma.user.findMany({
  where: {
    posts: {
      some: { published: true }
    }
  }
});

// Users with ALL posts published
const users = await prisma.user.findMany({
  where: {
    posts: {
      every: { published: true }
    }
  }
});

// Users with NO posts
const users = await prisma.user.findMany({
  where: {
    posts: {
      none: {}
    }
  }
});
```

### Aggregations

```typescript
// Group by with aggregates
const stats = await prisma.order.groupBy({
  by: ['status'],
  _count: { id: true },
  _sum: { total: true },
  _avg: { total: true },
  having: {
    total: {
      _sum: { gt: 1000 }
    }
  }
});

// Count with filter
const count = await prisma.post.count({
  where: { published: true }
});
```

---

## Raw SQL

### Tagged Template Queries

```typescript
// Safe parameterized query
const email = 'user@example.com';
const users = await prisma.$queryRaw`
  SELECT * FROM "User" WHERE email = ${email}
`;

// With type safety
const users = await prisma.$queryRaw<User[]>`
  SELECT * FROM "User" WHERE email = ${email}
`;
```

### Raw Execute (No Return)

```typescript
await prisma.$executeRaw`
  UPDATE "User" SET "lastLogin" = NOW() WHERE id = ${userId}
`;

// With affected row count
const count = await prisma.$executeRaw`
  DELETE FROM "Session" WHERE "expiresAt" < NOW()
`;
```

### Dynamic Raw Queries

```typescript
import { Prisma } from '@prisma/client';

// Build dynamic query safely
const orderBy = Prisma.sql`ORDER BY "createdAt" DESC`;
const users = await prisma.$queryRaw`
  SELECT * FROM "User" ${orderBy}
`;

// Join multiple raw SQL pieces
const conditions = Prisma.join([
  Prisma.sql`status = 'active'`,
  Prisma.sql`role = 'admin'`
], ' AND ');

const users = await prisma.$queryRaw`
  SELECT * FROM "User" WHERE ${conditions}
`;
```

---

## Transactions

### Interactive Transactions

```typescript
// Full control with rollback
const result = await prisma.$transaction(async (tx) => {
  const user = await tx.user.create({
    data: { email: 'user@example.com' }
  });
  
  const account = await tx.account.create({
    data: { userId: user.id, balance: 0 }
  });
  
  // If anything throws, entire transaction rolls back
  if (someCondition) {
    throw new Error('Rollback!');
  }
  
  return { user, account };
}, {
  maxWait: 5000,     // Max wait to start transaction
  timeout: 10000,    // Max transaction duration
  isolationLevel: Prisma.TransactionIsolationLevel.Serializable
});
```

### Batch Transactions

```typescript
// Multiple operations in single transaction
const [user, posts] = await prisma.$transaction([
  prisma.user.create({ data: { email: 'user@example.com' } }),
  prisma.post.createMany({ data: [...] })
]);
```

### Nested Transaction Handling

```typescript
// Transactions don't nest - use savepoints manually
async function createUserWithPosts(data: UserInput) {
  return prisma.$transaction(async (tx) => {
    const user = await tx.user.create({ data: { email: data.email } });
    
    // This is NOT a nested transaction
    // It uses the same transaction context
    await createPosts(tx, user.id, data.posts);
    
    return user;
  });
}

async function createPosts(tx: Prisma.TransactionClient, userId: string, posts: PostInput[]) {
  return tx.post.createMany({
    data: posts.map(p => ({ ...p, authorId: userId }))
  });
}
```

---

## Performance Optimization

### Select Only Needed Fields

```typescript
// Bad: fetches all fields
const users = await prisma.user.findMany();

// Good: select only needed
const users = await prisma.user.findMany({
  select: {
    id: true,
    email: true,
    name: true
  }
});
```

### Avoid N+1 with Include

```typescript
// Bad: N+1 queries
const users = await prisma.user.findMany();
for (const user of users) {
  const posts = await prisma.post.findMany({ where: { authorId: user.id } });
}

// Good: Single query with include
const users = await prisma.user.findMany({
  include: { posts: true }
});
```

### Pagination Best Practices

```typescript
// Offset pagination (fine for small offsets)
const page1 = await prisma.post.findMany({
  skip: 0,
  take: 20,
  orderBy: { createdAt: 'desc' }
});

// Cursor pagination (better for large datasets)
const page2 = await prisma.post.findMany({
  take: 20,
  skip: 1, // Skip the cursor
  cursor: { id: lastPostId },
  orderBy: { createdAt: 'desc' }
});
```

### Batch Operations

```typescript
// createMany for bulk inserts (faster than individual creates)
await prisma.user.createMany({
  data: users,
  skipDuplicates: true
});

// updateMany for bulk updates
await prisma.post.updateMany({
  where: { authorId: userId },
  data: { published: false }
});

// deleteMany for bulk deletes
await prisma.session.deleteMany({
  where: { expiresAt: { lt: new Date() } }
});
```

---

## Middleware

### Logging Middleware

```typescript
prisma.$use(async (params, next) => {
  const before = Date.now();
  const result = await next(params);
  const after = Date.now();
  
  console.log(`${params.model}.${params.action} took ${after - before}ms`);
  
  return result;
});
```

### Soft Delete Middleware

```typescript
prisma.$use(async (params, next) => {
  // Intercept delete -> update with deletedAt
  if (params.action === 'delete') {
    params.action = 'update';
    params.args.data = { deletedAt: new Date() };
  }
  
  // Filter out soft-deleted records
  if (params.action === 'findMany' || params.action === 'findFirst') {
    params.args.where = {
      ...params.args.where,
      deletedAt: null
    };
  }
  
  return next(params);
});
```

---

## Extensions (Prisma 4.16+)

### Custom Methods

```typescript
const prisma = new PrismaClient().$extends({
  model: {
    user: {
      async findByEmail(email: string) {
        return prisma.user.findUnique({ where: { email } });
      },
      async softDelete(id: string) {
        return prisma.user.update({
          where: { id },
          data: { deletedAt: new Date() }
        });
      }
    }
  }
});

// Usage
const user = await prisma.user.findByEmail('test@example.com');
await prisma.user.softDelete(user.id);
```

### Result Extensions

```typescript
const prisma = new PrismaClient().$extends({
  result: {
    user: {
      fullName: {
        needs: { firstName: true, lastName: true },
        compute(user) {
          return `${user.firstName} ${user.lastName}`;
        }
      }
    }
  }
});

const user = await prisma.user.findFirst();
console.log(user.fullName); // Computed property
```

---

## Migrations

### Safe Migration Patterns

```bash
# Generate migration without applying
npx prisma migrate dev --create-only

# Review and apply
npx prisma migrate dev

# Production deployment
npx prisma migrate deploy
```

### Handling Breaking Changes

```prisma
// 1. Add new column as optional
model User {
  newField String?
}

// 2. Backfill data (separate migration)
// 3. Make required
model User {
  newField String
}
```

### Custom Migration SQL

```sql
-- In migration.sql
-- Add custom index
CREATE INDEX CONCURRENTLY idx_users_email ON "User"(email);

-- Data migration
UPDATE "User" SET "newField" = 'default' WHERE "newField" IS NULL;
```

---

## Connection Management

### Singleton Pattern

```typescript
// lib/prisma.ts
import { PrismaClient } from '@prisma/client';

const globalForPrisma = globalThis as unknown as {
  prisma: PrismaClient | undefined;
};

export const prisma = globalForPrisma.prisma ?? new PrismaClient({
  log: process.env.NODE_ENV === 'development' 
    ? ['query', 'error', 'warn'] 
    : ['error']
});

if (process.env.NODE_ENV !== 'production') {
  globalForPrisma.prisma = prisma;
}
```

### Connection Pool Settings

```
DATABASE_URL="postgresql://user:pass@host:5432/db?connection_limit=20&pool_timeout=10"
```

---

## Debugging

```typescript
// Enable query logging
const prisma = new PrismaClient({
  log: [
    { level: 'query', emit: 'event' },
    { level: 'error', emit: 'stdout' }
  ]
});

prisma.$on('query', (e) => {
  console.log('Query:', e.query);
  console.log('Params:', e.params);
  console.log('Duration:', e.duration, 'ms');
});
```
