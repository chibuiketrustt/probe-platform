import Link from "next/link";
import { ReactNode } from "react";

const navigationItems = [
  { href: "/dashboard", label: "Dashboard" },
  { href: "/receipts", label: "Receipts" },
  { href: "/sales", label: "Sales" },
  { href: "/analytics", label: "Analytics" },
  { href: "/settings", label: "Settings" }
];

type AppShellProps = {
  children: ReactNode;
};

export function AppShell({ children }: AppShellProps) {
  return (
    <div className="app-shell">
      <header className="app-header">
        <strong>Probe</strong>
      </header>

      <div className="app-body">
        <nav className="app-nav" aria-label="Primary">
          <ul>
            {navigationItems.map((item) => (
              <li key={item.href}>
                <Link href={item.href}>{item.label}</Link>
              </li>
            ))}
          </ul>
        </nav>

        <main className="app-content">{children}</main>
      </div>
    </div>
  );
}
