export const appConfig = {
  name: 'PROBE',
  description: 'Production-grade financial infrastructure platform',
  company: 'PROBE',
  supportEmail: 'support@probe.local',
} as const;

export type AppConfig = typeof appConfig;
