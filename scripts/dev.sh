#!/bin/bash
echo "🚀 Starting development server..."

# 가상환경 활성화 확인
if [[ "$VIRTUAL_ENV" == "" ]]; then
    echo "⚠️  Virtual environment not activated. Activating..."
    source .venv/bin/activate
fi

# 환경 변수 로드
if [ -f .env ]; then
    export $(cat .env | xargs)
fi

# 개발 서버 실행
uvicorn src.main:app --host 0.0.0.0 --port 8000 --reload --log-level info
