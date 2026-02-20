import { createClient } from '@supabase/supabase-js';

import { env } from '@/config';
import type { Database } from '@/types/database';

export function createSupabaseAdminClient() {
  if (!env.supabase.serviceRoleKey) {
    throw new Error('[supabase] Missing SUPABASE_SERVICE_ROLE_KEY for admin client.');
  }

  return createClient<Database>(env.supabase.url, env.supabase.serviceRoleKey, {
    auth: { persistSession: false, autoRefreshToken: false },
  });
}
