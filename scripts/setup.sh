#!/bin/bash

echo "🚀 AI 기반 업무지원 플랫폼 개발환경 설정 시작..."

# 환경 체크
command -v node >/dev/null 2>&1 || { echo "❌ Node.js가 필요합니다." >&2; exit 1; }
command -v python3 >/dev/null 2>&1 || { echo "❌ Python 3.11+가 필요합니다." >&2; exit 1; }
command -v docker >/dev/null 2>&1 || { echo "❌ Docker가 필요합니다." >&2; exit 1; }

# pnpm 설치
if ! command -v pnpm &> /dev/null; then
    echo "📦 pnpm 설치 중..."
    npm install -g pnpm
fi

# 프론트엔드 패키지 설치
echo "📦 프론트엔드 패키지 설치 중..."
pnpm install

# 백엔드 Python 가상환경 설정
echo "🐍 백엔드 Python 환경 설정 중..."
cd apps/api
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt
cd ../..

# 환경 변수 파일 생성
if [ ! -f .env ]; then
    echo "📝 환경 변수 파일 생성 중..."
    cp .env.example .env
    echo "⚠️  .env 파일을 수정하여 필요한 환경 변수를 설정하세요."
fi

# 데이터베이스 초기화
echo "🗄️ 데이터베이스 초기화 중..."
docker-compose up -d postgres redis
sleep 10

# 데이터베이스 마이그레이션
echo "🔄 데이터베이스 마이그레이션 실행 중..."
cd apps/api
source venv/bin/activate
alembic upgrade head
cd ../..

echo "✅ 개발환경 설정 완료!"
echo ""
echo "개발 서버 시작 명령어:"
echo "  전체 서비스: pnpm dev"
echo "  API만: cd apps/api && source venv/bin/activate && uvicorn src.main:app --reload"
echo "  관리자 웹: cd apps/mgmt-web && npm run dev"
echo "  테넌트 웹: cd apps/tnnt-web && npm run dev"
echo ""
echo "접속 주소:"
echo "  API 문서: http://localhost:8000/docs"
echo "  관리자 웹: http://localhost:3000"
echo "  테넌트 웹: http://localhost:3001"
