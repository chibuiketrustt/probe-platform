import { createServerClient } from '@supabase/ssr';
import { cookies } from 'next/headers';

import { env } from '@/config';
import type { Database } from '@/types/database';

export async function createSupabaseServerClient() {
  const cookieStore = await cookies();

  return createServerClient<Database>(env.supabase.url, env.supabase.anonKey, {
    cookies: {
      get(name: string) {
        return cookieStore.get(name)?.value;
      },
      set(name: string, value: string, options: Parameters<typeof cookieStore.set>[2]) {
        cookieStore.set({ name, value, ...options });
      },
      remove(name: string, options: Parameters<typeof cookieStore.set>[2]) {
        cookieStore.set({ name, value: '', ...options });
      },
    },
  });
}
