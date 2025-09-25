#!/bin/bash

# API 서버 개발 모드 실행 스크립트

# 가상환경 활성화
source .venv/bin/activate

# PYTHONPATH 설정하여 src 모듈 인식
export PYTHONPATH=.

# 개발 서버 실행
python -m uvicorn src.main:app --host 0.0.0.0 --port 8101 --reload
