apps/mgmt-web/
├── src/
│   ├── app/
│   │   ├── globals.css
│   │   ├── layout.tsx
│   │   ├── page.tsx
│   │   ├── (auth)/
│   │   │   ├── login/
│   │   │   │   └── page.tsx
│   │   │   └── register/
│   │   │       └── page.tsx
│   │   ├── dashboard/
│   │   │   ├── page.tsx
│   │   │   └── components/
│   │   │       ├── DashboardCards.tsx
│   │   │       ├── SystemMetrics.tsx
│   │   │       └── RecentActivity.tsx
│   │   ├── tnnt/
│   │   │   ├── page.tsx
│   │   │   ├── [id]/
│   │   │   │   ├── page.tsx
│   │   │   │   ├── settings/
│   │   │   │   └── billing/
│   │   │   └── components/
│   │   │       ├── TenantTable.tsx
│   │   │       ├── TenantForm.tsx
│   │   │       └── TenantDetails.tsx
│   │   ├── bill/
│   │   │   ├── page.tsx
│   │   │   ├── plans/
│   │   │   ├── invoices/
│   │   │   └── components/
│   │   │       ├── BillingOverview.tsx
│   │   │       ├── PlanManagement.tsx
│   │   │       └── InvoiceList.tsx
│   │   ├── mntr/
│   │   │   ├── page.tsx
│   │   │   ├── infrastructure/
│   │   │   ├── alerts/
│   │   │   └── components/
│   │   │       ├── SystemStatus.tsx
│   │   │       ├── PerformanceCharts.tsx
│   │   │       └── AlertsPanel.tsx
│   │   ├── supt/
│   │   │   ├── page.tsx
│   │   │   ├── tickets/
│   │   │   └── components/
│   │   │       ├── TicketList.tsx
│   │   │       ├── TicketDetails.tsx
│   │   │       └── SupportDashboard.tsx
│   │   ├── analytics/
│   │   │   ├── page.tsx
│   │   │   ├── usage/
│   │   │   ├── revenue/
│   │   │   └── components/
│   │   │       ├── UsageAnalytics.tsx
│   │   │       ├── RevenueCharts.tsx
│   │   │       └── TenantGrowth.tsx
│   │   └── settings/
│   │       ├── page.tsx
│   │       ├── users/
│   │       ├── system/
│   │       └── components/
│   │           ├── UserManagement.tsx
│   │           ├── SystemConfig.tsx
│   │           └── SecuritySettings.tsx
│   ├── components/
│   │   ├── ui/                   # shadcn/ui 컴포넌트
│   │   │   ├── button.tsx
│   │   │   ├── input.tsx
│   │   │   ├── table.tsx
│   │   │   ├── modal.tsx
│   │   │   ├── chart.tsx
│   │   │   └── form.tsx
│   │   ├── layout/
│   │   │   ├── Header.tsx
│   │   │   ├── Sidebar.tsx
│   │   │   ├── Breadcrumb.tsx
│   │   │   └── Footer.tsx
│   │   ├── forms/
│   │   │   ├── TenantForm.tsx
│   │   │   ├── BillingForm.tsx
│   │   │   └── UserForm.tsx
│   │   ├── charts/
│   │   │   ├── RevenueChart.tsx
│   │   │   ├── UsageChart.tsx
│   │   │   └── GrowthChart.tsx
│   │   ├── tables/
│   │   │   ├── TenantsTable.tsx
│   │   │   ├── BillingTable.tsx
│   │   │   └── UsersTable.tsx
│   │   └── modals/
│   │       ├── ConfirmModal.tsx
│   │       ├── TenantModal.tsx
│   │       └── SettingsModal.tsx
│   ├── lib/
│   │   ├── api.ts               # API 클라이언트
│   │   ├── auth.ts              # 인증 관리
│   │   ├── utils.ts
│   │   └── validations.ts
│   ├── hooks/
│   │   ├── useAuth.ts
│   │   ├── useTenants.ts
│   │   ├── useBilling.ts
│   │   ├── useMonitoring.ts
│   │   ├── useSupport.ts
│   │   └── useAnalytics.ts
│   ├── store/
│   │   ├── authStore.ts         # Zustand 스토어
│   │   ├── tenantStore.ts
│   │   ├── billingStore.ts
│   │   ├── monitoringStore.ts
│   │   └── globalStore.ts
│   ├── types/
│   │   ├── api.ts
│   │   ├── auth.ts
│   │   ├── tenant.ts
│   │   ├── billing.ts
│   │   ├── monitoring.ts
│   │   └── support.ts
│   └── styles/
│       └── globals.css
├── public/
│   ├── icons/
│   └── images/
├── package.json
├── next.config.js
├── tailwind.config.js
├── tsconfig.json
├── components.json              # shadcn/ui 설정
├── Dockerfile
└── .env.example
