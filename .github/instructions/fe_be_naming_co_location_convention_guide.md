# 컨벤션 가이드 — FE/BE 공통: Co-location 기반 네이밍 & 파일 구조

**목표**
- 대규모 협업 환경에서 코드 탐색성, 일관성, 유지보수성을 높이기 위해 프론트엔드(Next.js + React + TS + Tailwind)와 백엔드(FastAPI 등 Python)에서 공통으로 적용할 수 있는 폴더·파일 네이밍 규칙과 구조를 제시합니다.
- 팀 내 합의를 통해 자동화(린터/CI)로 강제할 수 있는 실용적 규칙을 목표로 합니다.

---

## 1. 기본 원칙
1. **일관성 우선** — 팀 전체가 같은 규칙을 따릅니다.
2. **도메인(엔티티) 중심 폴더** — 각 도메인은 단수형으로 표현합니다: `user`, `role`, `permission`.
3. **파일명은 kebab-case를 기본**하되, `도메인.역할`(dot 접미사) 패턴을 허용하여 역할 구분성을 보완합니다. (예: `user.service.ts`)
4. **코드 내부 식별자**는 언어/프레임워크 컨벤션을 따릅니다: 컴포넌트는 PascalCase, 함수/변수는 camelCase, Hook은 `use*`.
5. **API 경로는 복수형**으로 표기: `/users`, `/roles`, `/permissions`.

---

## 2. 폴더 네이밍 규칙
- **단수형 사용(권장)**: `user`, `role`, `permission`.
- 폴더는 기능/도메인 단위로 모으고, 내부에 역할별 파일(또는 하위 폴더)을 둡니다.

예
```
src/features/
  user/
  role/
  permission/
```

---

## 3. 파일 네이밍 규칙 (요약)
- **기본:** `kebab-case` (파일 시스템/OS/검색 친화적)
- **역할 구분이 필요할 때:** `도메인.역할.ext` (dot 접미사) 허용
  - `user.service.ts`, `user.store.ts`, `user.schema.ts`
- **훅 파일:** `use-user.ts` (파일명에 `use-` prefix 포함)
- **컴포넌트:** `user-table.tsx` 파일 안에서 `export function UserTable() {}` (컴포넌트 이름은 PascalCase)

예시 표
```
- user.service.ts      # service (dot 패턴)
- user.store.ts        # store (dot 패턴)
- user.schema.ts       # schema (dot 패턴)
- use-user.ts          # hook
- user-table.tsx       # component file (kebab-case filename + PascalCase export)
```

---

## 4. FE/BE 별 권장 구조 예시

### 프론트엔드 (Feature-driven + App Router 혼합 권장)
```
src/
  app/                    # Next.js App Router: 라우트, 페이지 레이아웃
    (main)/
      user/
        page.tsx          # 페이지 라우트: 라우팅 전용 (minimal logic)
  features/               # 핵심 비즈니스 로직과 재사용 가능 컴포넌트
    user/
      components/
        user-table.tsx
        user-form.tsx
      hooks/
        use-user.ts
      services/
        user.service.ts
      stores/
        user.store.ts
      types/
        user.types.ts
```

### 백엔드 (Co-location per resource)
```
backend/app/modules/idam/
  user/
    routers/
      user_router.py       # APIRouter 정의 (router 변수명 권장)
    schemas/
      user_schema.py       # Pydantic models
    services/
      user_service.py      # 비즈니스 로직
    models/
      user_model.py        # ORM model
    repository/
      user_repository.py   # DB 액세스
```
- 파일명은 `snake_case`(Python 표준) 사용. (예: `user_service.py`)
- 패키지 내 `__init__.py`에서 주요 객체(router 등)를 노출하면 상위 import가 편해집니다.

---

## 5. 네이밍 디테일 & 규칙
1. **폴더는 단수형**: `user/` (도메인 개념)
2. **파일명 기본은 kebab-case**: `user-table.tsx`, `use-user.ts` 등
3. **서비스/스토어/스키마는 dot 접미사 허용**: `user.service.ts`, `user.store.ts`, `user.schema.ts` — 검색/글롭 패턴(`*.service.ts`)에 유리
4. **Hook 네이밍**: 파일 `use-user.ts` 내부 `export function useUser()`
5. **컴포넌트 네이밍**: 파일 `user-table.tsx` 내부 `export function UserTable()` (혹은 default export 허용하되 팀 합의)
6. **Type/Interface 파일**: `user.types.ts` 또는 `types/user.ts` (팀 선호에 따라)
7. **테스트 파일**: 동일 폴더에 `__tests__/` 또는 `*.test.ts` (kebab-case 권장)

---

## 6. 코드 내부 컨벤션 (예: service, store, hook)
- **service**: 순수 함수 / 클래스 형태 가능. 외부 API 호출, Envelope 처리, 공통 에러 변환 담당.
  - 파일: `user.service.ts`
  - 내부 export: `export const userService = { ... }` 또는 `export class UserService {}`

- **store**: Zustand/Redux 등. Hook 형태로 export.
  - 파일: `user.store.ts`
  - 내부 export: `export const useUserStore = create(...)`

- **hook**: 컴포넌트와 결합된 로직. React Query 등 캐시 로직 포함.
  - 파일: `use-user.ts`
  - 내부 export: `export function useUser() { ... }`

---

## 7. 테스트·린팅·CI 연동 권장 설정
- **ESLint** + **Prettier**: TS/React 규칙 적용
- **Ruff/Black/Isort** (Python) + **Pyright** for types
- **pre-commit** 훅 설정(포맷, 린트, 타입 체크)
- CI에서 **파일명 규칙 체크 스크립트**(선택)로 네이밍 위반 자동 감지 가능

---

## 8. 마이그레이션/리팩토링 가이드
1. 새로운 코드: 항상 가이드에 따라 작성
2. 레거시 파일 리팩토링: 기능 변경/버그 수정 시 함께 리네임/이동
3. `git mv`로 히스토리 보존
4. 작은 단계로 분할, PR 당 하나의 리팩토링 단위 권장

---

## 9. 자주 묻는 질문 (FAQ)
- **Q: dot 패턴이 kebab-case 규칙 위반 아닌가?**
  - A: 기본은 kebab-case지만, 역할 접미사를 명확히 하기 위해 `도메인.역할`(dot)을 허용합니다. 일관성 있게 사용하세요.
- **Q: 컴포넌트 파일만 PascalCase로 해도 되나?**
  - A: 가능합니다. 다만 파일 시스템 안전성과 검색 편의성을 위해 파일명은 kebab-case로 통일하는 것을 권장합니다. 컴포넌트 내부 export 이름은 PascalCase로 유지합니다.
- **Q: 폴더를 plural(복수형)로 해야하나?**
  - A: 내부 코드 폴더는 단수형 권장(도메인 중심). API 엔드포인트는 복수형 권장.

---

## 10. 샘플 규칙 요약 (체크리스트)
- [ ] 폴더: 단수형 (`user`, `role`)
- [ ] 파일명: kebab-case 기본 (`user-table.tsx`)
- [ ] 서비스/스토어/스키마: dot 접미사 허용 (`user.service.ts`)
- [ ] 훅: `use-*` prefix (`use-user.ts`)
- [ ] 컴포넌트 export: PascalCase (`UserTable`)
- [ ] API 경로: 복수형 (`/users`)

---

## 11. 예시 트리 (프론트엔드 + 백엔드 통합)
```
project-root/
  frontend/
    src/
      app/
        (main)/
          user/
            page.tsx
      features/
        user/
          components/
            user-table.tsx
          hooks/
            use-user.ts
          services/
            user.service.ts
          stores/
            user.store.ts
  backend/
    app/
      modules/
        idam/
          user/
            routers/
              user_router.py
            schemas/
              user_schema.py
            services/
              user_service.py
```

---

## 12. 다음 단계 (팀 적용 가이드)
1. 이 문서를 `CONTRIBUTING.md` 또는 `docs/CONVENTIONS.md`로 저장
2. GitHub PR 템플릿에 네이밍 체크 항목 추가
3. pre-commit 훅/CI 스크립트에 린트·타입·포맷 체크 추가
4. 팀 교육(30분)으로 합의 완료

---

원하시면 이 문서를 기반으로 **팀용 PR 템플릿, pre-commit 설정 샘플, ESLint + ESLint rules 예시**까지 만들어드릴게요.
