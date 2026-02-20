export {};

declare global {
  namespace NodeJS {
    interface ProcessEnv {
      NODE_ENV?: 'development' | 'test' | 'production';
      NEXT_PUBLIC_APP_ENV?: 'development' | 'staging' | 'production';
      NEXT_PUBLIC_APP_URL?: string;
      NEXT_PUBLIC_SUPABASE_URL?: string;
      NEXT_PUBLIC_SUPABASE_ANON_KEY?: string;
      SUPABASE_SERVICE_ROLE_KEY?: string;
      SENTRY_DSN?: string;
    }
  }

  type Nullable<T> = T | null;
  type Optional<T> = T | undefined;
}
