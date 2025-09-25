# 프론트엔드 컴포넌트 구조 가이드라인

## 📋 개요

CXG 플랫폼의 일관된 프론트엔드 컴포넌트 개발을 위한 표준 가이드라인입니다.

## 🏗️ 아키텍처 원칙

### 기본 패턴: 피처(Feature) 기반 + 컴포넌트 동시 배치(Co-location)

```
apps/web-mgmt/src/app/(main)/
├── idam/
│   ├── users/
│   │   ├── components/           # 피처 전용 컴포넌트
│   │   │   ├── user-data-grid.tsx
│   │   │   ├── user-form.tsx
│   │   │   └── __tests__/        # 컴포넌트별 테스트
│   │   ├── types.ts             # 피처 타입 정의
│   │   ├── api.ts               # API 호출 함수
│   │   └── page.tsx             # 페이지 컴포넌트
│   ├── roles/
│   └── permissions/
├── dashboard/
└── components/                   # 공통 컴포넌트
    └── ui/
        ├── button.tsx
        ├── input.tsx
        └── data-grid.tsx
```

## 🎯 컴포넌트 개발 표준

### A. 컴포넌트 생성 가이드라인

#### 1. 기본 구조
```typescript
"use client"; // 상호작용이 있는 경우만

import React from "react";
import { Button } from "@/components/ui/button";

interface UserFormProps {
  /** 사용자 ID (수정 모드일 때) */
  userId?: string;
  /** 폼 제출 시 콜백 */
  onSubmit: (data: UserFormData) => void;
  /** 로딩 상태 */
  isLoading?: boolean;
}

interface UserFormData {
  username: string;
  email: string;
  fullName: string;
}

export function UserForm({ userId, onSubmit, isLoading = false }: UserFormProps) {
  return (
    <form data-testid="user-form" className="space-y-4">
      {/* 컴포넌트 내용 */}
    </form>
  );
}
```

#### 2. 명명 규칙
- **컴포넌트명**: PascalCase (예: `UserDataGrid`)
- **파일명**: kebab-case (예: `user-data-grid.tsx`)
- **Props 인터페이스**: `{ComponentName}Props`
- **데이터 타입**: `{Feature}{Purpose}Data` (예: `UserFormData`)

#### 3. 필수 속성
- `data-testid` 속성 (테스트용)
- `aria-*` 접근성 속성
- TypeScript 타입 정의
- JSDoc 주석 (공개 props)

### B. 페이지(page.tsx) 생성 가이드라인

#### 1. 서버 컴포넌트 기본
```typescript
import { Metadata } from "next";
import { UserDataGrid } from "./components/user-data-grid";
import { getUsers } from "./api";

export const metadata: Metadata = {
  title: "사용자 관리",
  description: "시스템 사용자 관리 페이지",
};

export default async function UsersPage() {
  try {
    const users = await getUsers();

    return (
      <div className="container mx-auto py-6">
        <div className="flex items-center justify-between mb-6">
          <h1 className="text-2xl font-bold">사용자 관리</h1>
        </div>
        <UserDataGrid data={users} />
      </div>
    );
  } catch (error) {
    return <div>데이터 로딩 중 오류가 발생했습니다.</div>;
  }
}
```

#### 2. 클라이언트 컴포넌트 (상호작용 필요 시)
```typescript
"use client";

import { useState, useEffect } from "react";
import { UserDataGrid } from "./components/user-data-grid";
import { getUsers } from "./api";

export default function UsersPage() {
  const [users, setUsers] = useState([]);
  const [isLoading, setIsLoading] = useState(true);

  useEffect(() => {
    const fetchUsers = async () => {
      try {
        const data = await getUsers();
        setUsers(data);
      } catch (error) {
        console.error("Failed to fetch users:", error);
      } finally {
        setIsLoading(false);
      }
    };

    fetchUsers();
  }, []);

  if (isLoading) {
    return <div>로딩 중...</div>;
  }

  return (
    <div className="container mx-auto py-6">
      <UserDataGrid data={users} />
    </div>
  );
}
```

### C. API 레이어 구조

#### api.ts 파일 구조
```typescript
// app/(main)/idam/users/api.ts
import { UserListItem } from "./types";

export async function getUsers(): Promise<UserListItem[]> {
  const response = await fetch("/api/v1/mgmt/users");
  if (!response.ok) {
    throw new Error("Failed to fetch users");
  }
  return response.json();
}

export async function createUser(userData: CreateUserData): Promise<User> {
  const response = await fetch("/api/v1/mgmt/users", {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify(userData),
  });

  if (!response.ok) {
    throw new Error("Failed to create user");
  }
  return response.json();
}
```

### D. 타입 정의 구조

#### types.ts 파일 구조
```typescript
// app/(main)/idam/users/types.ts

/** API에서 반환되는 사용자 목록 아이템 */
export interface UserListItem {
  id: string;
  username: string;
  email: string;
  full_name: string;
  user_type: string;
  created_at: string;
  last_login_at: string | null;
}

/** 사용자 생성 폼 데이터 */
export interface CreateUserData {
  username: string;
  email: string;
  password: string;
  full_name: string;
  user_type: string;
}

/** 사용자 수정 폼 데이터 */
export interface UpdateUserData {
  email?: string;
  full_name?: string;
  user_type?: string;
}

/** 데이터 그리드 Props */
export interface UserDataGridProps {
  data: UserListItem[];
  onView: (user: UserListItem) => void;
  onEdit?: (user: UserListItem) => void;
  isLoading?: boolean;
}
```

## 🧪 테스트 가이드라인

### A. 유닛 테스트 구조
```typescript
// __tests__/user-form.test.tsx
import { render, screen, fireEvent } from "@testing-library/react";
import { UserForm } from "../user-form";

describe("UserForm", () => {
  const mockOnSubmit = jest.fn();

  beforeEach(() => {
    mockOnSubmit.mockClear();
  });

  it("renders form fields correctly", () => {
    render(<UserForm onSubmit={mockOnSubmit} />);

    expect(screen.getByTestId("user-form")).toBeInTheDocument();
    expect(screen.getByLabelText("사용자명")).toBeInTheDocument();
    expect(screen.getByLabelText("이메일")).toBeInTheDocument();
  });

  it("calls onSubmit with form data", async () => {
    render(<UserForm onSubmit={mockOnSubmit} />);

    fireEvent.change(screen.getByLabelText("사용자명"), {
      target: { value: "testuser" }
    });

    fireEvent.click(screen.getByRole("button", { name: "저장" }));

    expect(mockOnSubmit).toHaveBeenCalledWith({
      username: "testuser",
      // ...
    });
  });
});
```

### B. Storybook 스토리 구조
```typescript
// user-form.stories.tsx
import type { Meta, StoryObj } from "@storybook/react";
import { UserForm } from "./user-form";

const meta: Meta<typeof UserForm> = {
  title: "Features/Users/UserForm",
  component: UserForm,
  parameters: {
    layout: "centered",
  },
  tags: ["autodocs"],
  argTypes: {
    isLoading: { control: "boolean" },
  },
};

export default meta;
type Story = StoryObj<typeof meta>;

export const Default: Story = {
  args: {
    onSubmit: (data) => console.log("Submitted:", data),
    isLoading: false,
  },
};

export const Loading: Story = {
  args: {
    ...Default.args,
    isLoading: true,
  },
};

export const EditMode: Story = {
  args: {
    ...Default.args,
    userId: "existing-user-id",
  },
};
```

## 🎨 스타일링 가이드라인

### A. Tailwind CSS 활용
```typescript
export function UserCard({ user }: UserCardProps) {
  return (
    <div className="bg-white dark:bg-gray-800 rounded-lg shadow-md p-6 hover:shadow-lg transition-shadow">
      <div className="flex items-center space-x-4">
        <div className="w-12 h-12 bg-blue-100 dark:bg-blue-900 rounded-full flex items-center justify-center">
          <span className="text-blue-600 dark:text-blue-400 font-semibold">
            {user.username[0].toUpperCase()}
          </span>
        </div>
        <div className="flex-1 min-w-0">
          <h3 className="text-lg font-medium text-gray-900 dark:text-white truncate">
            {user.full_name}
          </h3>
          <p className="text-sm text-gray-500 dark:text-gray-400">
            {user.email}
          </p>
        </div>
      </div>
    </div>
  );
}
```

### B. 반응형 디자인
```typescript
// 반응형 그리드 레이아웃
<div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 gap-6">
  {users.map(user => (
    <UserCard key={user.id} user={user} />
  ))}
</div>

// 반응형 테이블
<div className="overflow-x-auto">
  <table className="min-w-full divide-y divide-gray-200">
    <thead className="bg-gray-50">
      <tr>
        <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
          이름
        </th>
        <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider hidden md:table-cell">
          이메일
        </th>
      </tr>
    </thead>
  </table>
</div>
```

## 🔧 성능 최적화

### A. React.memo 활용
```typescript
export const UserCard = React.memo(({ user, onEdit }: UserCardProps) => {
  return (
    <div onClick={() => onEdit(user)}>
      {/* 컴포넌트 내용 */}
    </div>
  );
});

UserCard.displayName = "UserCard";
```

### B. useCallback과 useMemo
```typescript
export function UserList({ users, searchTerm }: UserListProps) {
  const filteredUsers = useMemo(() => {
    return users.filter(user =>
      user.username.toLowerCase().includes(searchTerm.toLowerCase()) ||
      user.email.toLowerCase().includes(searchTerm.toLowerCase())
    );
  }, [users, searchTerm]);

  const handleUserEdit = useCallback((user: UserListItem) => {
    // 편집 로직
  }, []);

  return (
    <div>
      {filteredUsers.map(user => (
        <UserCard key={user.id} user={user} onEdit={handleUserEdit} />
      ))}
    </div>
  );
}
```

## 📝 접근성 가이드라인

### A. 키보드 네비게이션
```typescript
export function UserForm({ onSubmit }: UserFormProps) {
  const handleKeyDown = (event: KeyboardEvent<HTMLFormElement>) => {
    if (event.key === "Enter" && (event.ctrlKey || event.metaKey)) {
      event.preventDefault();
      // 폼 제출
    }
  };

  return (
    <form onKeyDown={handleKeyDown} role="form" aria-label="사용자 정보 입력">
      <div className="space-y-4">
        <label htmlFor="username" className="block text-sm font-medium">
          사용자명
          <input
            id="username"
            type="text"
            required
            aria-describedby="username-help"
            className="mt-1 block w-full"
          />
          <span id="username-help" className="text-xs text-gray-500">
            4-20자의 영문, 숫자만 사용 가능합니다.
          </span>
        </label>
      </div>
    </form>
  );
}
```

### B. ARIA 속성 활용
```typescript
export function UserDataGrid({ data, isLoading }: UserDataGridProps) {
  return (
    <div role="region" aria-label="사용자 목록">
      {isLoading ? (
        <div role="status" aria-live="polite">
          로딩 중...
        </div>
      ) : (
        <table role="table" aria-label="사용자 정보 테이블">
          <thead>
            <tr role="row">
              <th role="columnheader" aria-sort="none">이름</th>
              <th role="columnheader" aria-sort="none">이메일</th>
            </tr>
          </thead>
          <tbody>
            {data.map(user => (
              <tr key={user.id} role="row">
                <td role="gridcell">{user.full_name}</td>
                <td role="gridcell">{user.email}</td>
              </tr>
            ))}
          </tbody>
        </table>
      )}
    </div>
  );
}
```

## 🚨 주의사항 및 안티패턴

### ❌ 피해야 할 것들

1. **Props Drilling**
```typescript
// 잘못된 예: 깊은 props 전달
<UserList users={users} onEdit={onEdit} onDelete={onDelete} permissions={permissions} />
  <UserCard user={user} onEdit={onEdit} onDelete={onDelete} permissions={permissions} />
    <UserActions onEdit={onEdit} onDelete={onDelete} permissions={permissions} />

// 올바른 예: Context API 활용
const UserContext = createContext();
<UserProvider value={{ onEdit, onDelete, permissions }}>
  <UserList users={users} />
</UserProvider>
```

2. **무분별한 'use client' 사용**
```typescript
// 잘못된 예
"use client";
export default function StaticUserInfo({ user }) {
  return <div>{user.name}</div>; // 상호작용 없음
}

// 올바른 예: 필요한 부분만 클라이언트 컴포넌트로
export default function UserPage({ user }) {
  return (
    <div>
      <UserInfo user={user} /> {/* 서버 컴포넌트 */}
      <InteractiveUserActions user={user} /> {/* 클라이언트 컴포넌트 */}
    </div>
  );
}
```

3. **타입 정의 누락**
```typescript
// 잘못된 예
export function UserForm({ user, onSubmit }) { // any 타입
  // ...
}

// 올바른 예
interface UserFormProps {
  user?: UserListItem;
  onSubmit: (data: UserFormData) => void;
}

export function UserForm({ user, onSubmit }: UserFormProps) {
  // ...
}
```

## 📚 참고 자료

- [Next.js App Router](https://nextjs.org/docs/app)
- [React TypeScript Cheatsheet](https://react-typescript-cheatsheet.netlify.app/)
- [Tailwind CSS Documentation](https://tailwindcss.com/docs)
- [Testing Library Best Practices](https://testing-library.com/docs/guiding-principles)
- [Storybook for React](https://storybook.js.org/docs/react/get-started/introduction)

---

**마지막 업데이트**: 2025-09-24
**적용 범위**: CXG 플랫폼 프론트엔드 전체
