import { createServerClient } from '@supabase/ssr'
import { NextResponse, type NextRequest } from 'next/server'

export async function updateSession(request: NextRequest) {
  let response = NextResponse.next({ request })
  const pathname = request.nextUrl.pathname
  const publicPath = pathname === '/' || pathname.startsWith('/login') || pathname.startsWith('/auth')
  const url = process.env.NEXT_PUBLIC_SUPABASE_URL
  const key = process.env.NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY

  // Let public pages render so a missing deployment variable shows a useful message
  // instead of an opaque Vercel 500. Protected routes still require Supabase.
  if (!url || !key) {
    if (publicPath) return response
    const configUrl = request.nextUrl.clone()
    configUrl.pathname = '/login'
    configUrl.searchParams.set('error', 'supabase_config')
    return NextResponse.redirect(configUrl)
  }

  const supabase = createServerClient(
    url,
    key,
    {
      cookies: {
        getAll() { return request.cookies.getAll() },
        setAll(cookiesToSet) {
          cookiesToSet.forEach(({ name, value }) => request.cookies.set(name, value))
          response = NextResponse.next({ request })
          cookiesToSet.forEach(({ name, value, options }) => response.cookies.set(name, value, options))
        },
      },
    },
  )

  const { data: claims } = await supabase.auth.getClaims()
  const user = claims?.claims?.sub

  if (!user && !publicPath) {
    const url = request.nextUrl.clone()
    url.pathname = '/login'
    return NextResponse.redirect(url)
  }

  if (user && (pathname === '/login' || pathname === '/')) {
    const url = request.nextUrl.clone()
    url.pathname = '/dashboard'
    return NextResponse.redirect(url)
  }

  return response
}
