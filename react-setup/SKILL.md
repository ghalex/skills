---
name: react-setup
description: This skill should be used when the user asks to "create a new React project", "setup a react app", "new react frontend", "scaffold a react spa", "initialize a react frontend", or "start a new react app". Scaffolds a React 19 + Vite + TypeScript + Tailwind CSS v4 + shadcn/ui + Redux Toolkit SPA with auth and routing.
version: 2.0.0
---

# React SPA Setup

Ask the user for the **project name** if not provided. Use it as `{project}` throughout.

## Steps

### 1. Scaffold and clean up

```bash
pnpm create vite {project} -- --template react-ts
cd {project}
pnpm install
rm src/App.tsx src/App.css src/index.css
rm -rf src/assets
```

### 2. Create directory structure

```bash
mkdir -p src/pages src/lib src/hooks src/store/auth src/components/auth src/components/ui
```

### 3. Install dependencies

```bash
pnpm add @reduxjs/toolkit react-redux react-router sonner clsx tailwind-merge tailwindcss @tailwindcss/vite
pnpm add -D @types/node tw-animate-css shadcn
```

### 4. Write all files below

---

### `index.html`
```html
<!doctype html>
<html lang="en">
  <head>
    <meta charset="UTF-8" />
    <link rel="icon" type="image/svg+xml" href="/vite.svg" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />
    <title>{project}</title>
  </head>
  <body>
    <div id="root"></div>
    <script type="module" src="/src/main.tsx"></script>
  </body>
</html>
```

### `vite.config.ts`
```ts
import path from 'path'
import tailwindcss from '@tailwindcss/vite'
import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'

export default defineConfig({
  plugins: [react(), tailwindcss()],
  resolve: {
    alias: {
      '@': path.resolve(__dirname, './src'),
    },
  },
  server: {
    proxy: {
      '/api': {
        target: 'http://localhost:8000',
        changeOrigin: true,
        rewrite: (path) => path.replace(/^\/api/, ''),
      },
    },
  },
})
```

### `tsconfig.app.json` — add `paths` to compilerOptions
```json
{
  "compilerOptions": {
    "baseUrl": ".",
    "paths": {
      "@/*": ["./src/*"]
    }
  }
}
```
Merge these into the existing `tsconfig.app.json` compilerOptions — do not overwrite the whole file.

### `components.json`
```json
{
  "$schema": "https://ui.shadcn.com/schema.json",
  "style": "new-york",
  "rsc": false,
  "tsx": true,
  "tailwind": {
    "config": "",
    "css": "src/main.css",
    "baseColor": "neutral",
    "cssVariables": true,
    "prefix": ""
  },
  "iconLibrary": "lucide",
  "aliases": {
    "components": "@/components",
    "utils": "@/lib/utils",
    "ui": "@/components/ui",
    "lib": "@/lib",
    "hooks": "@/hooks"
  }
}
```

### `src/main.css`
```css
@import "tailwindcss";
@import "tw-animate-css";

@source "../**/*.{ts,tsx}";

@custom-variant dark (&:is(.dark *));

@theme inline {
  --radius-sm: calc(var(--radius) - 4px);
  --radius-md: calc(var(--radius) - 2px);
  --radius-lg: var(--radius);
  --radius-xl: calc(var(--radius) + 4px);
  --color-background: var(--background);
  --color-foreground: var(--foreground);
  --color-card: var(--card);
  --color-card-foreground: var(--card-foreground);
  --color-popover: var(--popover);
  --color-popover-foreground: var(--popover-foreground);
  --color-primary: var(--primary);
  --color-primary-foreground: var(--primary-foreground);
  --color-secondary: var(--secondary);
  --color-secondary-foreground: var(--secondary-foreground);
  --color-muted: var(--muted);
  --color-muted-foreground: var(--muted-foreground);
  --color-accent: var(--accent);
  --color-accent-foreground: var(--accent-foreground);
  --color-destructive: var(--destructive);
  --color-border: var(--border);
  --color-input: var(--input);
  --color-ring: var(--ring);
  --color-sidebar: var(--sidebar);
  --color-sidebar-foreground: var(--sidebar-foreground);
  --color-sidebar-primary: var(--sidebar-primary);
  --color-sidebar-primary-foreground: var(--sidebar-primary-foreground);
  --color-sidebar-accent: var(--sidebar-accent);
  --color-sidebar-accent-foreground: var(--sidebar-accent-foreground);
  --color-sidebar-border: var(--sidebar-border);
  --color-sidebar-ring: var(--sidebar-ring);
}

:root {
  --radius: 0.625rem;
  --background: oklch(1 0 0);
  --foreground: oklch(0.145 0 0);
  --card: oklch(1 0 0);
  --card-foreground: oklch(0.145 0 0);
  --popover: oklch(1 0 0);
  --popover-foreground: oklch(0.145 0 0);
  --primary: oklch(0.205 0 0);
  --primary-foreground: oklch(0.985 0 0);
  --secondary: oklch(0.97 0 0);
  --secondary-foreground: oklch(0.205 0 0);
  --muted: oklch(0.97 0 0);
  --muted-foreground: oklch(0.556 0 0);
  --accent: oklch(0.97 0 0);
  --accent-foreground: oklch(0.205 0 0);
  --destructive: oklch(0.577 0.245 27.325);
  --border: oklch(0.922 0 0);
  --input: oklch(0.922 0 0);
  --ring: oklch(0.708 0 0);
  --sidebar: oklch(0.985 0 0);
  --sidebar-foreground: oklch(0.145 0 0);
  --sidebar-primary: oklch(0.205 0 0);
  --sidebar-primary-foreground: oklch(0.985 0 0);
  --sidebar-accent: oklch(0.97 0 0);
  --sidebar-accent-foreground: oklch(0.205 0 0);
  --sidebar-border: oklch(0.922 0 0);
  --sidebar-ring: oklch(0.708 0 0);
}

.dark {
  --background: oklch(0.145 0 0);
  --foreground: oklch(0.985 0 0);
  --card: oklch(0.205 0 0);
  --card-foreground: oklch(0.985 0 0);
  --popover: oklch(0.205 0 0);
  --popover-foreground: oklch(0.985 0 0);
  --primary: oklch(0.922 0 0);
  --primary-foreground: oklch(0.205 0 0);
  --secondary: oklch(0.269 0 0);
  --secondary-foreground: oklch(0.985 0 0);
  --muted: oklch(0.269 0 0);
  --muted-foreground: oklch(0.708 0 0);
  --accent: oklch(0.269 0 0);
  --accent-foreground: oklch(0.985 0 0);
  --destructive: oklch(0.704 0.191 22.216);
  --border: oklch(1 0 0 / 10%);
  --input: oklch(1 0 0 / 15%);
  --ring: oklch(0.556 0 0);
  --sidebar: oklch(0.205 0 0);
  --sidebar-foreground: oklch(0.985 0 0);
  --sidebar-primary: oklch(0.488 0.243 264.376);
  --sidebar-primary-foreground: oklch(0.985 0 0);
  --sidebar-accent: oklch(0.269 0 0);
  --sidebar-accent-foreground: oklch(0.269 0 0);
  --sidebar-border: oklch(1 0 0 / 10%);
  --sidebar-ring: oklch(0.556 0 0);
}

@layer base {
  * {
    @apply border-border outline-ring/50;
  }
  body {
    @apply bg-background text-foreground;
  }
}
```

### `src/main.tsx`
```tsx
import { StrictMode } from 'react'
import { createRoot } from 'react-dom/client'
import { BrowserRouter } from 'react-router'
import { Provider } from 'react-redux'
import App from './app'
import { store } from './store'

createRoot(document.getElementById('root')!).render(
  <StrictMode>
    <Provider store={store}>
      <BrowserRouter>
        <App />
      </BrowserRouter>
    </Provider>
  </StrictMode>,
)
```

### `src/app.tsx`
```tsx
import { useEffect } from 'react'
import './main.css'
import AppRoutes from '@/routes'
import { useAppDispatch } from '@/store/hooks'
import { restoreFromStorage } from '@/store/auth'

export default function App() {
  const dispatch = useAppDispatch()

  useEffect(() => {
    dispatch(restoreFromStorage())
  }, [dispatch])

  return <AppRoutes />
}
```

### `src/routes.tsx`
```tsx
import { Route, Routes, Navigate } from 'react-router'
import Home from './pages/home'
import Login from './pages/login'
import { PrivateRoute, PublicRoute } from './components/auth'

export default function AppRoutes() {
  return (
    <Routes>
      <Route path="/login" element={<PublicRoute><Login /></PublicRoute>} />
      <Route path="/" element={<PrivateRoute><Home /></PrivateRoute>} />
      <Route path="*" element={<Navigate to="/" replace />} />
    </Routes>
  )
}
```

### `src/types.ts`
```ts
export interface User {
  id: string
  email: string
  name?: string
  createdAt?: string
}

export interface LoginData {
  email: string
  password: string
}

export interface SignupData {
  email: string
  password: string
  name?: string
}
```

### `src/config.ts`
```ts
export default {
  appName: (import.meta.env.VITE_APP_NAME as string) || '{project}',
  apiUrl: (import.meta.env.VITE_API_URL as string) || '/api',
}
```

### `src/lib/utils.ts`
```ts
import { clsx, type ClassValue } from 'clsx'
import { twMerge } from 'tailwind-merge'

export function cn(...inputs: ClassValue[]) {
  return twMerge(clsx(inputs))
}

export function getApiEndpoint(): string {
  return (import.meta.env.VITE_API_URL as string) || '/api'
}
```

### `src/lib/token.ts`
```ts
const TOKEN_KEY = 'app-token'
const USER_KEY = 'app-user'

export const getToken = () => localStorage.getItem(TOKEN_KEY)
export const setToken = (token: string) => localStorage.setItem(TOKEN_KEY, token)
export const removeToken = () => localStorage.removeItem(TOKEN_KEY)

export const getUserData = (): unknown => {
  try { return JSON.parse(localStorage.getItem(USER_KEY) || '') } catch { return null }
}
export const setUserData = (user: unknown) => localStorage.setItem(USER_KEY, JSON.stringify(user))
export const removeUserData = () => localStorage.removeItem(USER_KEY)

export const clearAuthData = () => { removeToken(); removeUserData() }

export const isTokenExpired = (token = getToken()): boolean => {
  if (!token) return true
  try {
    const { exp } = JSON.parse(atob(token.split('.')[1])) as { exp?: number }
    return exp ? exp < Math.floor(Date.now() / 1000) : false
  } catch { return true }
}
```

### `src/lib/api.ts`
```ts
import { fetchBaseQuery } from '@reduxjs/toolkit/query/react'
import type { BaseQueryFn, FetchArgs, FetchBaseQueryError } from '@reduxjs/toolkit/query'
import { clearStoredAuth, clearCurrentUser } from '@/store/auth/slice'
import { getToken } from '@/lib/token'

export const createBaseQueryWithReauth = (
  baseUrl: string,
): BaseQueryFn<string | FetchArgs, unknown, FetchBaseQueryError> =>
  async (args, api, extraOptions) => {
    const result = await fetchBaseQuery({
      baseUrl,
      prepareHeaders: (headers) => {
        const token = getToken()
        if (token) headers.set('authorization', `Bearer ${token}`)
        return headers
      },
    })(args, api, extraOptions)

    if (result.error?.status === 401) {
      clearStoredAuth()
      api.dispatch(clearCurrentUser())
    }

    return result
  }
```

### `src/store/hooks.ts`
```ts
import { useDispatch, useSelector } from 'react-redux'
import type { AppRootState, AppDispatch } from './index'

export const useAppDispatch = useDispatch.withTypes<AppDispatch>()
export const useAppSelector = useSelector.withTypes<AppRootState>()
```

### `src/store/index.ts`
```ts
import { configureStore } from '@reduxjs/toolkit'
import { authReducer, authApi } from './auth'

export const store = configureStore({
  reducer: {
    auth: authReducer,
    [authApi.reducerPath]: authApi.reducer,
  },
  middleware: (getDefaultMiddleware) =>
    getDefaultMiddleware().concat(authApi.middleware),
})

export type AppRootState = ReturnType<typeof store.getState>
export type AppDispatch = typeof store.dispatch
```

### `src/store/auth/slice.ts`
```ts
import { createSlice } from '@reduxjs/toolkit'
import type { User } from '@/types'
import { getToken, getUserData, clearAuthData, isTokenExpired } from '@/lib/token'

export const clearStoredAuth = clearAuthData

interface AuthState {
  current: User | null
  isAuthenticated: boolean
  isInitialized: boolean
}

export const authSlice = createSlice({
  name: 'auth',
  initialState: { current: null, isAuthenticated: false, isInitialized: false } as AuthState,
  reducers: {
    setCurrentUser: (state, action) => {
      state.current = action.payload
      state.isAuthenticated = true
      state.isInitialized = true
    },
    clearCurrentUser: (state) => {
      state.current = null
      state.isAuthenticated = false
      state.isInitialized = true
    },
    restoreFromStorage: (state) => {
      const token = getToken()
      const user = getUserData()
      if (token && user && !isTokenExpired(token)) {
        state.current = user as User
        state.isAuthenticated = true
      } else {
        clearAuthData()
      }
      state.isInitialized = true
    },
  },
})

export const { setCurrentUser, clearCurrentUser, restoreFromStorage } = authSlice.actions

export const selectCurrentUser = (state: { auth: AuthState }) => state.auth.current
export const selectIsAuthenticated = (state: { auth: AuthState }) => state.auth.isAuthenticated
export const selectIsInitialized = (state: { auth: AuthState }) => state.auth.isInitialized

export default authSlice.reducer
```

### `src/store/auth/api.ts`
```ts
import { createApi } from '@reduxjs/toolkit/query/react'
import type { User, LoginData, SignupData } from '@/types'
import { setCurrentUser, clearCurrentUser } from './slice'
import { createBaseQueryWithReauth } from '@/lib/api'
import { setToken, setUserData, clearAuthData } from '@/lib/token'
import { getApiEndpoint } from '@/lib/utils'

interface AuthResponse { access_token: string; user: User }

export const authApi = createApi({
  reducerPath: 'authApi',
  baseQuery: createBaseQueryWithReauth(getApiEndpoint()),
  endpoints: (builder) => ({
    login: builder.mutation<AuthResponse, LoginData>({
      query: (body) => ({ url: '/auth/login', method: 'POST', body }),
      async onQueryStarted(_, { dispatch, queryFulfilled }) {
        try {
          const { data } = await queryFulfilled
          setToken(data.access_token)
          setUserData(data.user)
          dispatch(setCurrentUser(data.user))
        } catch {}
      },
    }),
    signup: builder.mutation<AuthResponse, SignupData>({
      query: (body) => ({ url: '/auth/signup', method: 'POST', body }),
      async onQueryStarted(_, { dispatch, queryFulfilled }) {
        try {
          const { data } = await queryFulfilled
          setToken(data.access_token)
          setUserData(data.user)
          dispatch(setCurrentUser(data.user))
        } catch {}
      },
    }),
    logout: builder.mutation<void, void>({
      query: () => ({ url: '/auth/logout', method: 'POST' }),
      async onQueryStarted(_, { dispatch, queryFulfilled }) {
        clearAuthData()
        dispatch(clearCurrentUser())
        try { await queryFulfilled } catch {}
      },
    }),
  }),
})

export const { useLoginMutation, useSignupMutation, useLogoutMutation } = authApi
```

### `src/store/auth/index.ts`
```ts
export { default as authReducer, setCurrentUser, clearCurrentUser, restoreFromStorage, selectCurrentUser, selectIsAuthenticated, selectIsInitialized } from './slice'
export { authApi, useLoginMutation, useSignupMutation, useLogoutMutation } from './api'
```

### `src/components/auth/PrivateRoute.tsx`
```tsx
import { Navigate, useLocation } from 'react-router'
import { useAppSelector } from '@/store/hooks'
import { selectIsAuthenticated, selectIsInitialized } from '@/store/auth'

export default function PrivateRoute({ children }: { children: React.ReactNode }) {
  const isAuthenticated = useAppSelector(selectIsAuthenticated)
  const isInitialized = useAppSelector(selectIsInitialized)
  const location = useLocation()

  if (!isInitialized) {
    return <div className="flex min-h-screen items-center justify-center">Loading...</div>
  }

  return isAuthenticated
    ? <>{children}</>
    : <Navigate to="/login" state={{ from: location }} replace />
}
```

### `src/components/auth/PublicRoute.tsx`
```tsx
import { Navigate, useLocation } from 'react-router'
import { useAppSelector } from '@/store/hooks'
import { selectIsAuthenticated } from '@/store/auth'

export default function PublicRoute({ children }: { children: React.ReactNode }) {
  const isAuthenticated = useAppSelector(selectIsAuthenticated)
  const location = useLocation()
  const from = (location.state as { from?: { pathname: string } })?.from?.pathname || '/'

  return isAuthenticated ? <Navigate to={from} replace /> : <>{children}</>
}
```

### `src/components/auth/index.ts`
```ts
export { default as PrivateRoute } from './PrivateRoute'
export { default as PublicRoute } from './PublicRoute'
```

### `src/pages/home.tsx`
```tsx
import { useAppSelector } from '@/store/hooks'
import { selectCurrentUser, useLogoutMutation } from '@/store/auth'

export default function Home() {
  const user = useAppSelector(selectCurrentUser)
  const [logout] = useLogoutMutation()

  return (
    <div className="flex min-h-screen flex-col items-center justify-center gap-2">
      <h1 className="text-2xl font-bold">Hello, {user?.name || user?.email}</h1>
      <button onClick={() => logout()} className="text-sm text-muted-foreground underline">
        Logout
      </button>
    </div>
  )
}
```

### `src/pages/login.tsx`
```tsx
import { useState } from 'react'
import { useLoginMutation } from '@/store/auth'

export default function Login() {
  const [email, setEmail] = useState('')
  const [password, setPassword] = useState('')
  const [login, { isLoading, isError }] = useLoginMutation()

  return (
    <div className="flex min-h-screen items-center justify-center">
      <form
        onSubmit={(e) => { e.preventDefault(); login({ email, password }) }}
        className="flex w-full max-w-sm flex-col gap-4 p-8"
      >
        <h1 className="text-xl font-bold">Sign in</h1>
        <input
          type="email" value={email} onChange={(e) => setEmail(e.target.value)}
          placeholder="Email" required
          className="rounded-md border border-input bg-background px-3 py-2 text-sm"
        />
        <input
          type="password" value={password} onChange={(e) => setPassword(e.target.value)}
          placeholder="Password" required
          className="rounded-md border border-input bg-background px-3 py-2 text-sm"
        />
        {isError && <p className="text-sm text-destructive">Invalid credentials.</p>}
        <button
          type="submit" disabled={isLoading}
          className="rounded-md bg-primary px-4 py-2 text-sm font-medium text-primary-foreground disabled:opacity-50"
        >
          {isLoading ? 'Signing in...' : 'Sign in'}
        </button>
      </form>
    </div>
  )
}
```

### `.env.example`
```
VITE_APP_NAME={project}
VITE_API_URL=http://localhost:8000
```

### `CLAUDE.md`
```markdown
# CLAUDE.md

## Stack
React 19 + Vite + TypeScript + Tailwind CSS v4 + shadcn/ui + Redux Toolkit + React Router

## Structure
- `src/pages/` — one file per route
- `src/store/{domain}/` — `slice.ts` + `api.ts` + `index.ts` per domain
- `src/lib/` — shared utilities (api, token, utils)
- `src/components/auth/` — PrivateRoute / PublicRoute guards
- `src/components/ui/` — shadcn components (do not edit manually)

## Rules
- Use `useAppDispatch` / `useAppSelector` — never plain hooks
- Server data → RTK Query (`api.ts`), client state → Redux slice (`slice.ts`)
- All protected routes use `<PrivateRoute>`, public routes use `<PublicRoute>`
- Path alias `@` → `src/`

## Adding a domain
1. Types → `src/types.ts`
2. `src/store/{domain}/slice.ts` → `api.ts` → `index.ts`
3. Register in `src/store/index.ts`
4. Page → `src/pages/{domain}.tsx`
5. Route → `src/routes.tsx`
```

---

## After Scaffolding — Tell the User

```bash
cp .env.example .env
pnpm dev
# → http://localhost:5173
```

Add shadcn components as needed:
```bash
pnpm dlx shadcn@latest add button card input label
```

Auth expects from your backend:
- `POST /auth/login` → `{ access_token, user }`
- `POST /auth/signup` → `{ access_token, user }`
- `POST /auth/logout`
