const requiredVars = [
  'NEXT_PUBLIC_APP_URL',
  'NEXT_PUBLIC_SUPABASE_URL',
  'NEXT_PUBLIC_SUPABASE_ANON_KEY',
] as const;

type RequiredVar = (typeof requiredVars)[number];

function getRequiredEnvVar(name: RequiredVar): string {
  const value = process.env[name];

  if (!value) {
    throw new Error(`[env] Missing required environment variable: ${name}`);
  }

  return value;
}

export const env = {
  nodeEnv: process.env.NODE_ENV ?? 'development',
  appEnv: process.env.NEXT_PUBLIC_APP_ENV ?? 'development',
  appUrl: getRequiredEnvVar('NEXT_PUBLIC_APP_URL'),
  supabase: {
    url: getRequiredEnvVar('NEXT_PUBLIC_SUPABASE_URL'),
    anonKey: getRequiredEnvVar('NEXT_PUBLIC_SUPABASE_ANON_KEY'),
    serviceRoleKey: process.env.SUPABASE_SERVICE_ROLE_KEY,
  },
  sentryDsn: process.env.SENTRY_DSN,
} as const;
