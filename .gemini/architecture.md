# 아키텍처 가이드

## 🏗️ 전체 시스템 아키텍처

### 관리자 시스템 (apps/web-mgmt)
- **API 방식**: REST (기본) + GraphQL (복잡한 쿼리)
- **실시간**: WebSocket + Server-Sent Events
- **오프라인**: Service Worker + IndexedDB
- **상태 관리**: Zustand + TanStack Query
- **UI**: Next.js + shadcn/ui + Tailwind CSS

### 사용자 시스템 (apps/web-tnnt)
- **API 방식**: REST (기본) + GraphQL (복잡한 쿼리)
- **실시간**: WebSocket + Server-Sent Events
- **오프라인**: Service Worker + IndexedDB
- **상태 관리**: Zustand + TanStack Query
- **UI**: Next.js + shadcn/ui + Tailwind CSS

### 백엔드 (apps/api)
- **프레임워크**: FastAPI + SQLAlchemy
- **데이터베이스**: PostgreSQL (멀티테넌트)
- **캐싱**: Redis
- **메시지큐**: Redis Streams / RabbitMQ

## 🔄 데이터 플로우
```
Frontend → API Gateway → Business Logic → Database
    ↓           ↓              ↓           ↓
  Cache ←   Auth/Valid   →  Events   →  Logs
```

## 📊 모니터링 스택
- **APM**: OpenTelemetry
- **메트릭**: Prometheus + Grafana
- **로그**: ELK Stack
- **알림**: PagerDuty / Slack
