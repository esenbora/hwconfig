# Critical Project Notes

> Project-wide patterns and constraints. Claude checks this at session start.
> Add your project-specific rules here.

---

## Tech Stack Decisions

<!-- Example entries:
- Use Zustand for client state (not Redux)
- Tailwind only, no CSS modules
- Server Components by default
-->

---

## Architecture Constraints

<!-- Example entries:
- All API routes require auth middleware
- Database access only through API layer
- No direct Supabase queries from client
-->

---

## Code Style

<!-- Example entries:
- No default exports (use named exports)
- Prefer const arrow functions
- Use absolute imports (@/...)
-->

---

## Security Requirements (Non-Negotiable)

1. No direct database queries from frontend
2. All endpoints require auth + permissions check
3. Rate limiting on all public endpoints
4. Parameterized queries only (no string concat SQL)
5. Sanitize all user inputs
6. API keys never in NEXT_PUBLIC_*

---

## Known Issues

<!-- Example entries:
- Legacy endpoint /api/v1/users still in use
- Mobile app v2.0.0 has auth token bug
-->

---

## Tool Preferences

- TLDR before reading large files
- Glob for file patterns, Grep for content search
- Use Task agent for complex exploration

---

*Add your project-specific notes above*
