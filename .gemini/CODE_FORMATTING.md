# 코드 포매팅 설정 가이드

## 개요
79자 줄 길이 제한을 준수하여 일관된 코드 스타일을 유지하기 위한 자동 포매팅 설정입니다.

## 설정된 도구들

### 1. Ruff (Primary Formatter & Linter)
- **설정 파일**: `pyproject.toml`
- **줄 길이**: 79자
- **기능**: 코드 포매팅, 린팅, import 정렬
- **자동 수정**: 활성화

### 2. Black (Secondary Formatter)
- **설정 파일**: `pyproject.toml`
- **줄 길이**: 79자
- **기능**: 코드 포매팅 (Ruff와 호환)

### 3. Pre-commit Hooks
- **설정 파일**: `.pre-commit-config.yaml`
- **기능**: Git 커밋 시 자동 포매팅
- **활성화 명령**: `pre-commit install`

### 4. VS Code 설정
- **설정 파일**: `.vscode/settings.json`
- **기능**: 저장 시 자동 포매팅, 79자 ruler 표시
- **포매터**: Black + Ruff

## 사용 방법

### 자동 포매팅 (권장)

#### 파일 저장 시 자동 포매팅
VS Code에서 파일을 저장하면 자동으로 79자 줄바꿈이 적용됩니다.

#### Git 커밋 시 자동 포매팅
```bash
git add .
git commit -m "commit message"  # 자동으로 포매팅 후 커밋
```

### 수동 포매팅

#### 전체 프로젝트 포매팅
```bash
./format.sh
```

#### Ruff만 사용
```bash
ruff format src/ --line-length=79
ruff check src/ --line-length=79 --fix
```

#### Black만 사용
```bash
black src/ --line-length=79
```

## 포매팅 규칙

### 줄 길이 제한
- **최대 79자**
- 긴 문자열은 자동으로 여러 줄로 분할
- 함수 호출 인자가 길면 각 줄로 분할

### 예시

#### Before (79자 초과)
```python
logger.info(f"사용자 생성 요청 시작: username={user_data.username}, email={user_data.email}")
```

#### After (79자 준수)
```python
logger.info(
    f"사용자 생성 요청 시작: username={user_data.username}, email={user_data.email}"
)
```

또는

```python
logger.info(
    (
        f"사용자 생성 요청 시작: username={user_data.username}, "
        f"email={user_data.email}"
    )
)
```

### Import 정렬
```python
# Standard library imports
import uuid
from datetime import datetime

# Third-party imports
from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

# Local imports
from src.models.user import User
from src.schemas.user import UserCreateRequest
```

## 트러블슈팅

### 포매팅이 적용되지 않는 경우

1. **VS Code 확장 프로그램 확인**
   - Python 확장 프로그램 설치
   - Black Formatter 확장 프로그램 설치
   - Ruff 확장 프로그램 설치

2. **Python 인터프리터 확인**
   - VS Code에서 올바른 가상환경 선택
   - `./.venv/bin/python` 경로 확인

3. **수동 포매팅 실행**
   ```bash
   ./format.sh
   ```

4. **Pre-commit 훅 재설치**
   ```bash
   pre-commit uninstall
   pre-commit install
   ```

### 설정 파일 확인

- `pyproject.toml`: Ruff, Black 설정
- `.pre-commit-config.yaml`: Git 훅 설정
- `.vscode/settings.json`: VS Code 설정

## 베스트 프랙티스

1. **파일 저장 시 자동 포매팅 활용**
2. **커밋 전 `./format.sh` 실행으로 전체 확인**
3. **긴 문자열은 f-string concatenation 사용**
4. **복잡한 함수 호출은 여러 줄로 분할**
5. **Import 구문은 자동 정렬 활용**

## 설정 완료 확인

다음 명령으로 설정이 올바르게 적용되었는지 확인:

```bash
# 포매팅 테스트
./format.sh

# Pre-commit 테스트
pre-commit run --all-files

# 서버 실행 테스트 (포매팅된 코드가 정상 작동하는지 확인)
./run_dev.sh
```
