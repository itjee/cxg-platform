#!/usr/bin/env python3
"""
IDAM 기본 데이터 시드 스크립트
사용법: python seed_idam.py
"""

import os
import sys

# 프로젝트 루트를 Python 경로에 추가
sys.path.insert(0, os.path.join(os.path.dirname(__file__), "src"))

from src.modules.mgmt.idam.seed_data import seed_idam_data

if __name__ == "__main__":
    print("=== IDAM 기본 데이터 시드 스크립트 ===")
    print()

    try:
        seed_idam_data()
        print()
        print("✅ 기본 데이터 생성이 성공적으로 완료되었습니다!")
        print()
        print("생성된 데이터:")
        print("📋 권한 (Permissions): 26개")
        print("   - 사용자 관리: 5개 (CREATE, READ, UPDATE, DELETE, LIST)")
        print("   - 역할 관리: 5개 (CREATE, READ, UPDATE, DELETE, LIST)")
        print("   - 권한 관리: 5개 (CREATE, READ, UPDATE, DELETE, LIST)")
        print("   - 테넌트 관리: 5개 (CREATE, READ, UPDATE, DELETE, LIST)")
        print("   - API 키 관리: 5개 (CREATE, READ, UPDATE, DELETE, LIST)")
        print(
            "   - 시스템 관리: 3개 (SYSTEM_ADMIN, AUDIT_VIEW, DASHBOARD_VIEW)"
        )
        print()
        print("👥 역할 (Roles): 5개")
        print("   - 슈퍼 관리자 (SUPER_ADMIN): 모든 권한")
        print("   - 관리자 (ADMIN): 대부분 권한")
        print("   - 테넌트 관리자 (TENANT_ADMIN): 테넌트 관련 권한")
        print("   - 사용자 매니저 (USER_MANAGER): 사용자 관리 권한")
        print("   - 뷰어 (VIEWER): 읽기 전용 권한 (기본 역할)")
        print()

    except Exception as e:
        print(f"❌ 오류가 발생했습니다: {e}")
        sys.exit(1)
