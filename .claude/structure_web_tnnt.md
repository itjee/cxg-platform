# 테넌트 웹 프론트엔드 (apps/tnnt-web) 구조도

apps/web-tnnt/
├── src/
│   ├── app/
│   │   ├── globals.css
│   │   ├── layout.tsx
│   │   ├── page.tsx
│   │   ├── (auth)/
│   │   │   ├── login/
│   │   │   │   └── page.tsx
│   │   │   └── signup/
│   │   │       └── page.tsx
│   │   ├── dashboard/
│   │   │   ├── page.tsx
│   │   │   └── components/
│   │   │       ├── KPICards.tsx
│   │   │       ├── BusinessChart.tsx
│   │   │       └── RecentTransactions.tsx
│   │   ├── adm/         # 기준정보
│   │   │   ├── page.tsx
│   │   │   ├── companies/
│   │   │   │   ├── page.tsx
│   │   │   │   └── [id]/
│   │   │   ├── departments/
│   │   │   ├── employees/
│   │   │   ├── customers/
│   │   │   ├── vendors/
│   │   │   ├── products/
│   │   │   ├── warehouses/
│   │   │   └── components/
│   │   │       ├── CompanyForm.tsx
│   │   │       ├── EmployeeForm.tsx
│   │   │       ├── CustomerForm.tsx
│   │   │       ├── VendorForm.tsx
│   │   │       └── ProductForm.tsx
│   │   ├── psm/         # 구매관리
│   │   │   ├── page.tsx
│   │   │   ├── requests/
│   │   │   │   ├── page.tsx
│   │   │   │   └── [id]/
│   │   │   ├── orders/
│   │   │   ├── receipts/
│   │   │   ├── returns/
│   │   │   └── components/
│   │   │       ├── PurchaseRequestForm.tsx
│   │   │       ├── PurchaseOrderForm.tsx
│   │   │       └── ProcurementDashboard.tsx
│   │   ├── srm/              # 영업관리
│   │   │   ├── page.tsx
│   │   │   ├── opportunities/
│   │   │   ├── quotations/
│   │   │   ├── orders/
│   │   │   ├── invoices/
│   │   │   └── components/
│   │   │       ├── OpportunityForm.tsx
│   │   │       ├── QuotationForm.tsx
│   │   │       ├── SalesOrderForm.tsx
│   │   │       └── SalesDashboard.tsx
│   │   ├── ivm/          # 재고관리
│   │   │   ├── page.tsx
│   │   │   ├── balances/
│   │   │   ├── transactions/
│   │   │   ├── adjustments/
│   │   │   ├── reservations/
│   │   │   └── components/
│   │   │       ├── InventoryBalance.tsx
│   │   │       ├── StockMovement.tsx
│   │   │       └── InventoryDashboard.tsx
│   │   ├── lwm/          # 물류관리
│   │   │   ├── page.tsx
│   │   │   ├── deliveries/
│   │   │   ├── receipts/
│   │   │   ├── shipping/
│   │   │   └── components/
│   │   │       ├── DeliveryOrder.tsx
│   │   │       ├── ShippingTracker.tsx
│   │   │       └── LogisticsDashboard.tsx
│   │   ├── csm/   # 고객지원
│   │   │   ├── page.tsx
│   │   │   ├── tickets/
│   │   │   ├── knowledge-base/
│   │   │   ├── faq/
│   │   │   └── components/
│   │   │       ├── TicketForm.tsx
│   │   │       ├── KnowledgeBase.tsx
│   │   │       └── CSMDashboard.tsx
│   │   ├── asm/      # A/S 관리
│   │   │   ├── page.tsx
│   │   │   ├── orders/
│   │   │   ├── warranties/
│   │   │   ├── history/
│   │   │   └── components/
│   │   │       ├── ServiceOrderForm.tsx
│   │   │       ├── WarrantyTracker.tsx
│   │   │       └── ASMDashboard.tsx
│   │   ├── fim/           # 재무관리
│   │   │   ├── page.tsx
│   │   │   ├── receivables/
│   │   │   ├── payables/
│   │   │   ├── bank-accounts/
│   │   │   ├── reports/
│   │   │   └── components/
│   │   │       ├── ARManagement.tsx
│   │   │       ├── APManagement.tsx
│   │   │       ├── BankAccount.tsx
│   │   │       └── FinanceDashboard.tsx
│   │   ├── bim/         # 경영분석
│   │   │   ├── page.tsx
│   │   │   ├── kpi/
│   │   │   ├── reports/
│   │   │   ├── dashboards/
│   │   │   └── components/
│   │   │       ├── KPIAnalytics.tsx
│   │   │       ├── BusinessReports.tsx
│   │   │       └── CustomDashboard.tsx
│   │   ├── esm/          # 전자결재
│   │   │   ├── page.tsx
│   │   │   ├── approvals/
│   │   │   ├── documents/
│   │   │   ├── templates/
│   │   │   └── components/
│   │   │       ├── ApprovalForm.tsx
│   │   │       ├── DocumentViewer.tsx
│   │   │       └── WorkflowDashboard.tsx
│   │   ├── aix/      # AI 어시스턴트
│   │   │   ├── page.tsx
│   │   │   ├── chat/
│   │   │   ├── reports/
│   │   │   ├── insights/
│   │   │   └── components/
│   │   │       ├── ChatInterface.tsx
│   │   │       ├── AIReports.tsx
│   │   │       ├── BusinessInsights.tsx
│   │   │       └── AIDashboard.tsx
│   │   └── settings/
│   │       ├── page.tsx
│   │       ├── users/
│   │       ├── roles/
│   │       ├── company/
│   │       ├── system/
│   │       └── components/
│   │           ├── UserSettings.tsx
│   │           ├── RoleSettings.tsx
│   │           ├── CompanySettings.tsx
│   │           └── SystemSettings.tsx
│   ├── components/
│   │   ├── ui/                # shadcn/ui 컴포넌트
│   │   │   ├── button.tsx
│   │   │   ├── input.tsx
│   │   │   ├── table.tsx
│   │   │   ├── modal.tsx
│   │   │   ├── chart.tsx
│   │   │   ├── form.tsx
│   │   │   ├── calendar.tsx
│   │   │   ├── tabs.tsx
│   │   │   └── dropdown.tsx
│   │   ├── layout/
│   │   │   ├── Header.tsx
│   │   │   ├── Sidebar.tsx
│   │   │   ├── Breadcrumb.tsx
│   │   │   ├── Footer.tsx
│   │   │   └── MainLayout.tsx
│   │   ├── forms/
│   │   │   ├── MasterDataForm.tsx
│   │   │   ├── ProcurementForm.tsx
│   │   │   ├── SalesForm.tsx
│   │   │   ├── InventoryForm.tsx
│   │   │   ├── FinanceForm.tsx
│   │   │   └── WorkflowForm.tsx
│   │   ├── tables/
│   │   │   ├── DataTable.tsx
│   │   │   ├── FilterTable.tsx
│   │   │   ├── ExportTable.tsx
│   │   │   └── PaginatedTable.tsx
│   │   ├── charts/
│   │   │   ├── DashboardChart.tsx
│   │   │   ├── AnalyticsChart.tsx
│   │   │   ├── ReportChart.tsx
│   │   │   └── RealtimeChart.tsx
│   │   ├── modals/
│   │   │   ├── ConfirmModal.tsx
│   │   │   ├── FormModal.tsx
│   │   │   ├── DetailModal.tsx
│   │   │   └── UploadModal.tsx
│   │   └── ai/
│   │       ├── ChatInterface.tsx
│   │       ├── InsightCard.tsx
│   │       ├── RecommendationPanel.tsx
│   │       └── AIAnalytics.tsx
│   ├── lib/
│   │   ├── api.ts              # API 클라이언트
│   │   ├── auth.ts             # 인증 관리
│   │   ├── utils.ts
│   │   ├── validations.ts
│   │   ├── formatters.ts
│   │   └── ai-client.ts
│   ├── hooks/
│   │   ├── useAuth.ts
│   │   ├── useMasterData.ts
│   │   ├── useProcurement.ts
│   │   ├── useSales.ts
│   │   ├── useInventory.ts
│   │   ├── useLogistics.ts
│   │   ├── useCustomerService.ts
│   │   ├── useAfterService.ts
│   │   ├── useFinance.ts
│   │   ├── useAnalytics.ts
│   │   ├── useWorkflow.ts
│   │   ├── useAI.ts
│   │   └── useSettings.ts
│   ├── store/
│   │   ├── authStore.ts        # Zustand 스토어
│   │   ├── masterDataStore.ts
│   │   ├── procurementStore.ts
│   │   ├── salesStore.ts
│   │   ├── inventoryStore.ts
│   │   ├── logisticsStore.ts
│   │   ├── customerServiceStore.ts
│   │   ├── afterServiceStore.ts
│   │   ├── financeStore.ts
│   │   ├── analyticsStore.ts
│   │   ├── workflowStore.ts
│   │   ├── aiStore.ts
│   │   └── globalStore.ts
│   ├── types/
│   │   ├── api.ts
│   │   ├── auth.ts
│   │   ├── master-data.ts
│   │   ├── procurement.ts
│   │   ├── sales.ts
│   │   ├── inventory.ts
│   │   ├── logistics.ts
│   │   ├── customer-service.ts
│   │   ├── after-service.ts
│   │   ├── finance.ts
│   │   ├── analytics.ts
│   │   ├── workflow.ts
│   │   └── ai.ts
│   └── styles/
│       └── globals.css
├── public/
│   ├── icons/
│   ├── images/
│   └── manifest.json
├── package.json
├── next.config.js
├── tailwind.config.js
├── tsconfig.json
├── components.json              # shadcn/ui 설정
├── Dockerfile
└── .env.example
