---
applyTo: '**'
---
Provide project context and coding guidelines that AI should follow when generating code, answering questions, or reviewing changes.

# CXG Platform Development Instructions

## 🎯 주요 개발 원칙
1. **타입 안전성 우선**: TypeScript strict 모드 사용
2. **에러 핸들링 필수**: 모든 API와 컴포넌트에 적절한 에러 처리
3. **성능 최적화**: 페이징, 캐싱, 지연 로딩 고려
4. **보안 강화**: 인증/권한 체크, 입력 검증
5. **테스트 커버리지**: 핵심 비즈니스 로직은 반드시 테스트

## 🚀 개발 우선순위
1. 백엔드 API 안정성
2. 프론트엔드 사용자 경험
3. 데이터 일관성
4. 시스템 성능
5. 코드 품질

## 🚫 절대 하지 말 것
- 하드코딩된 설정값 사용
- SQL 인젝션 가능성 있는 코드
- localStorage 사용 (아티팩트에서 미지원)
- 타입 체크 우회 (any 타입 남용)
- 에러 핸들링 생략

## ✅ 반드시 할 것
- 모든 API에 적절한 상태 코드 반환
- 프론트엔드 컴포넌트에 로딩/에러 상태 처리
- 데이터베이스 트랜잭션 관리
- 로깅 및 모니터링 구현
- 문서화 작성

## 통신 규칙
- 모든 API 응답은 다음과 같은 envelope 구조를 가져야 합니다:
```typescript
interface Envelope<T = any> {
  success: boolean;
  data: T | null;
  error: {
    code?: string;
    message: string;
    detail?: any;
  } | null;
}
```
- 성공 시 `success: true`, 실패 시 `success: false`와 함께 `error` 필드에 상세 정보 포함
- 프론트엔드에서는 이 구조를 기반으로 응답 처리 및 에러 핸들링
- API 문서에 각 엔드포인트의 응답 구조 명시
- API 요청 시 필요한 인증 토큰은 HTTP 헤더 `Authorization`에 포함
- 모든 API 요청과 응답은 JSON 형식 사용
- 페이징이 필요한 리스트 조회 API는 `page`와 `size` 쿼리 파라미터를 사용
- 민감한 정보는 절대 응답에 포함하지 않음 (예: 비밀번호, 토큰)
- CORS 정책을 준수하여 클라이언트 도메인에서만 API 접근 허용
- API 버전 관리를 위해 URL에 버전 정보 포함 (예: `/api/v1/resource`)
- API 변경 시 반드시 문서 업데이트 및 팀원에게 공지
- 모든 API는 적절한 상태 코드(200, 201, 400, 401, 403, 404, 500 등)를 반환
- 프론트엔드에서는 API 호출 시 로딩 상태와 에러 상태를 명확히 구분하여 사용자에게 피드백 제공
- API 호출 시 네트워크 오류, 타임아웃 등 예외 상황에 대한 핸들링 구현
- API 응답 시간이 500ms를 초과하지 않도록 최적화
- API 요청 시 불필요한 데이터 전송을 피하고, 필요한 데이터만 요청
- API 응답 데이터는 가능한 한 최소화하여 네트워크 부하 감소
- 모든 API는 HTTPS를 통해 통신하여 데이터 보안 유지
- API 요청과 응답에 대한 로깅을 통해 문제 발생 시 추적 가능하도록 구현
- API 테스트 자동화를 통해 주요 기능이 정상 동작하는지 지속적으로 검증
- API 문서화 도구(Swagger, Postman 등)를 사용하여 최신 API 문서 유지
- API 응답에 타임스탬프나 요청 ID를 포함하여 문제 추적 용이
- API 응답에 메타데이터(예: 페이징 정보, 총 아이템 수 등)를 포함하여 클라이언트에서 활용 가능하도록 함
- API 응답에 데이터 변경 시각(예: `updatedAt`)을 포함하여 클라이언트에서 최신 데이터 여부 판단 가능하도록 함
- API 응답에 데이터 버전 정보를 포함하여 클라이언트에서 캐싱 및 동기화에 활용 가능하도록 함
- API 응답에 관련 리소스의 링크(예: HATEOAS)를 포함하여 클라이언트에서 추가 작업 가능하도록 함
- API 응답에 사용자 맞춤형 메시지(예: 환영 메시지, 공지사항 등)를 포함하여 사용자 경험 향상

## 통신 흐름
- 프론트엔드에서 API 호출 시 로딩 상태 표시
- API 호출 성공 시 데이터 렌더링
- API 호출 실패 시 에러 메시지 표시
- 인증이 필요한 API 호출 시 토큰 만료 시 재로그인 유도
- 네트워크 오류 시 재시도 로직 구현 (최대 3회)
- API 응답 시간이 길어질 경우 타임아웃 처리 및 사용자에게 알림
- API 호출 전후로 필요한 전처리/후처리 로직 구현 (예: 데이터 포맷 변환, 상태 업데이트 등)
- API 호출 시 필요한 헤더(예: 인증 토큰, 콘텐츠 타입 등) 설정
- API 호출 시 쿼리 파라미터 및 바디 데이터 적절히 구성
- API 호출 시 취소 가능한 요청 구현 (예: 사용자가 페이지를 떠날 때)
- API 호출 시 로컬 캐싱 전략 구현 (예: SWR, React Query 등 사용)
- API 호출 시 사용자 권한에 따른 접근 제어 구현
- API 호출 시 다국어 지원을 위한 언어 헤더 설정
- API 호출 시 사용자 행동 분석을 위한 이벤트 로깅 구현
- API 호출 시 성능 모니터링을 위한 타이밍 측정 구현
- API 호출 시 보안 강화를 위한 CSRF 토큰 사용
- API 호출 시 데이터 무결성 검증을 위한 체크섬 사용
- 백엔드 흐름은 router -> service -> repository 패턴 준수
- 프론트엔드 흐름은 component -> store(Zustand 등)를 통한 API 통신 패턴 준수

## 백엔드 개발 가이드
- FastAPI 프레임워크 사용
- SQLAlchemy ORM 사용
- Pydantic 모델로 데이터 검증
- Alembic으로 데이터베이스 마이그레이션 관리
- OAuth2 및 JWT로 인증/권한 관리
- pytest로 단위 및 통합 테스트 작성
- 로깅은 Python logging 모듈 사용
- 환경 변수로 설정 관리 (dotenv 사용 권장)

## 프론트엔드 개발 가이드
- Next.js 프레임워크 사용
- TypeScript strict 모드 사용
- React Hook과 Context API로 상태 관리
- Axios로 API 통신
- React Query로 서버 상태 관리
- React Router로 라우팅 관리
- React Hook Form으로 폼 관리
- Tailwind CSS로 스타일링
- Jest와 React Testing Library로 테스트 작성
- ESLint와 Prettier로 코드 스타일 일관성 유지
- 환경 변수로 설정 관리 (Next.js 환경 변수 사용)
