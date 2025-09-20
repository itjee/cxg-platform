# CXG Platform

AI 기반 업무지원 플랫폼
관리자 시스템(web-mgmt)과 사용자 시스템(web-tnnt), 백엔드 API 서버(api-server)로 구성된 멀티테넌트 SaaS 프로젝트입니다.

## 주요 기능

- **사용자 인증**: 회원가입, 로그인, JWT 토큰 기반 인증
- **테넌트 관리**: 멀티 테넌트 환경 지원, 관리자/사용자 DB 분리
- **AI 통합**: OpenAI API 연동
- **벡터 검색**: Pinecone 연동
- **관리자/사용자 웹**: Next.js 기반 프론트엔드(tRPC 통신)
- **모니터링**: Prometheus, Grafana, Redis, PostgreSQL

## 폴더 구조

```
cxg-platform/
├── apps/
│   ├── api-server/      # FastAPI 기반 백엔드 API 서버
│   ├── web-mgmt/        # 관리자용 Next.js 프론트엔드
│   └── web-tnnt/        # 사용자용 Next.js 프론트엔드
├── infra/               # 인프라/모니터링/DB 초기화 스크립트
├── packages/            # 공통 컴포넌트, 유틸, DB 스키마 등
├── docker-compose.dev.yml
├── docker-compose.prod.yml
├── Makefile
└── README.md
```

## 기술 스택

- **백엔드**: FastAPI, SQLAlchemy, PostgreSQL, Redis
- **프론트엔드**: Next.js, TypeScript, tRPC, React
- **인프라/배포**: Docker, Docker Compose, Prometheus, Grafana
- **기타**: OpenAI, Pinecone, pnpm, uv

## 설치 및 실행

### 1. 의존성 설치

```bash
make install
```

### 2. 개발 서버 실행

```bash
make dev
```

- web-mgmt: http://localhost:3100
- web-tnnt: http://localhost:3200
- api-server: http://localhost:8100

### 3. 프로덕션 빌드 및 배포

```bash
make build
docker compose -f docker-compose.prod.yml up -d --build
```

## 환경 변수

- 각 서비스별 `.env` 또는 `.env.local` 파일에서 API URL, DB 접속 정보 등 관리

## tRPC 연동

- web-mgmt, web-tnnt 프론트엔드는 tRPC로 API 서버와 통신
- API 서버의 `/trpc` 엔드포인트와 타입 동기화 필요

## 모니터링

- Prometheus, Grafana, Redis Insight 등 도커로 통합 제공
- infra/monitoring/prometheus.yml 참고

## 라이선스

MIT License
