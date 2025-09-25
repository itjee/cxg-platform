#!/bin/bash

# 코드 포매팅 및 린팅 스크립트

echo "🔧 Python 코드 포매팅 시작..."

# 가상환경 활성화
source .venv/bin/activate

# Ruff로 포매팅 및 린팅
echo "📝 Ruff 포매팅 실행..."
ruff format src/ --line-length=79

echo "🔍 Ruff 린팅 실행..."
ruff check src/ --line-length=79 --fix

# Black 포매팅 (추가 보완)
echo "⚫ Black 포매팅 실행..."
black src/ --line-length=79

echo "✅ 포매팅 완료!"

# 포매팅 결과 확인
echo "📊 포매팅 결과 확인 중..."
ruff check src/ --line-length=79
