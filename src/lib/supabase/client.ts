import { createBrowserClient } from '@supabase/ssr';

import { env } from '@/config';
import type { Database } from '@/types/database';

export function createSupabaseBrowserClient() {
  return createBrowserClient<Database>(env.supabase.url, env.supabase.anonKey);
}
