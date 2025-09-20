.PHONY: help install dev build test clean docker-up docker-down

# 기본 도움말
help:
  @echo "AI 기반 업무지원 플랫폼 개발 명령어"
  @echo "=================================="
  @echo "install    - 의존성 설치"
  @echo "dev        - 개발 서버 실행"
  @echo "build      - 프로덕션 빌드"
  @echo "test       - 테스트 실행"
  @echo "lint       - 코드 린팅"
  @echo "format     - 코드 포매팅"
  @echo "docker-up  - 개발용 Docker 서비스 시작"
  @echo "docker-down- 개발용 Docker 서비스 중지"
  @echo "clean      - 캐시 및 빌드 파일 정리"

# 의존성 설치
install:
  @echo "프론트엔드 의존성 설치 중..."
  pnpm install
  @echo "백엔드 의존성 설치 중..."
  cd apps/api-server && uv sync

# 개발 서버 실행
dev:
  @echo "개발 서버 실행 중..."
  docker-compose -f docker-compose.dev.yml up -d
  @echo "데이터베이스와 서비스가 시작될 때까지 대기 중..."
  sleep 10
  @echo "프론트엔드 및 백엔드 개발 서버 시작..."
  pnpm dev &
  cd apps/api-server && uv run python src/main.py

# Docker 서비스 시작
docker-up:
  docker-compose -f docker-compose.dev.yml up -d
  @echo "서비스 상태 확인:"
  docker-compose -f docker-compose.dev.yml ps

# Docker 서비스 중지
docker-down:
  docker-compose -f docker-compose.dev.yml down

# 빌드
build:
  pnpm build
  cd apps/api-server && uv build

# 테스트
test:
  pnpm test
  cd apps/api-server && uv run pytest

# 린팅
lint:
  pnpm lint
  cd apps/api-server && uv run black --check . && uv run isort --check . && uv run flake8 .

# 포매팅
format:
  pnpm format
  cd apps/api-server && uv run black . && uv run isort .

# 정리
clean:
  pnpm clean
  docker system prune -f
  docker volume prune -f
