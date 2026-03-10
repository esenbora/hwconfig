# Security (Non-Negotiable)

- No API keys in client code (no NEXT_PUBLIC_/EXPO_PUBLIC_ with secrets)
- All endpoints: auth + permissions check
- All inputs sanitized, all queries parameterized
- Calculations server-side, premium features verified server-side
- Rate limit expensive operations
- No console.logs with sensitive data
- Error messages don't leak internals
- Frontend -> API -> Database (never Frontend -> Database)
- Confirm: auth changes, middleware changes, raw SQL, file uploads, CORS, webhooks
