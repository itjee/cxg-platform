# 관리자 시스템 (web-tnnt) 기본 모듈

## 1. 테넌트 관리 (Tenant Management) → tnnt

- tenants : 테넌트 마스터 정보
- subscriptions : 구독 및 요금제 관리
- onboarding : 온보딩 프로세스 추적
- users : 테넌트 사용자 정보
- api_keys : API 키 관리
- sessions : 사용자 세션 추적
- login_logs : 테넌트 사용자 로그인 로그

## 2. 인프라 및 리소스 관리 (Infrastructure Management) → ifra

- resources : 클라우드 리소스 관리
- resource_usages : 리소스 사용량 메트릭

## 3. 사용자 및 접근 관리 (User & Access Management) → idam

- **users :** 운영자 사용자 정보
- **api_keys** : API 키 관리
- **sessions** : 운영자 사용자 세션 추적
- permissions : 운영자 권한 카탈로그
- roles : 운영자 역할 정의
- role_permissions : 역할-권한 매핑 관리
- user_roles : 사용자-역할 매핑 관리
- login_logs : 운영자 사용자 로그인 로그

## 4. 요금 및 청구 관리 (Billing Management) → bill

- plans : 요금제 마스터
- invoices : 청구서 관리
- transactions : 결제 거래 내역

## 5. 시스템 모니터링 (System Monitoring) → mntr

- health_checks : 시스템 헬스체크
- incidents : 장애 및 인시던트 관리
- system_metrics : 시스템 성능 메트릭

## 6. 보안 및 감사 (Security & Audit) → audt

- **audit_logs** : 보안 감사 로그
- **assessments** : 컴플라이언스 보고서
- **policies** : 보안 정책 관리

## 7. 성능 및 분석 (Analytics) → stat

- tenant_stats : 테넌트 분석 데이터
- usage_stats : 사용량 요약 통계

## 8. 지원 및 고객 관리 (Support Management) → supt

- tickets : 고객 지원 티켓
- ticket_comments : 티켓 댓글 및 대화
- feedbacks : 고객 피드백

## 9. 시스템 설정 (Configuration Management) → cnfg

- configurations : 시스템 구성 관리
- feature_flags : 기능 플래그 관리
- tenant_features : 테넌트별 기능 오버라이드
- service_quotas - 서비스 할당량 관리

## 10. 백업 및 복구 (Backup & Recovery) → bkup

- executions : 백업 작업 관리
- schedules : 백업 스케줄 정의
- recovery_plans : 재해복구 계획

## 11. 알림 및 커뮤니케이션 (Notifications) → noti

- notifications : 알림 관리
- templates : 알림 템플릿
- campaigns : 이메일 캠페인

## 12. 외부 연동 (External Integrations) → intg

- apis : 외부 시스템 연동 API
- webhooks : 웹훅 엔드포인트
- rate_limits : API 호출 제한

## 13. 운영 자동화 (Automation) → auto

- workflows : 자동화 워크플로우
- executions : 워크플로우 실행 이력
- tasks : 스케줄된 작업
