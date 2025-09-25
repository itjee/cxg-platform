# ✅ 올바른 React 컴포넌트 예시

이 문서는 CXG 플랫폼 프론트엔드 React 컴포넌트 구현의 모범 사례를 보여주는 예시입니다. `CustomerForm` 컴포넌트를 통해 폼 관리, API 연동, 상태 관리 등을 보여줍니다.

```typescript
import { useState } from 'react';
import { useForm } from 'react-hook-form';
import { zodResolver } from '@hookform/resolvers/zod';
import { z } from 'zod';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Card, CardHeader, CardTitle, CardContent } from '@/components/ui/card';
import { useToast } from '@/components/ui/use-toast';

// 스키마 정의
const customerSchema = z.object({
  name: z.string().min(1, '고객명을 입력하세요'),
  email: z.string().email('올바른 이메일을 입력하세요'),
  phone: z.string().optional(),
});

type CustomerFormData = z.infer;

interface Props {
  onSuccess?: (customer: Customer) => void;
  onCancel?: () => void;
  defaultValues?: Partial;
}

export function CustomerForm({ onSuccess, onCancel, defaultValues }: Props) {
  const [isLoading, setIsLoading] = useState(false);
  const { toast } = useToast();

  const form = useForm({
    resolver: zodResolver(customerSchema),
    defaultValues,
  });

  const onSubmit = async (data: CustomerFormData) => {
    setIsLoading(true);
    try {
      const customer = await api.customers.create(data);
      toast({ title: '고객이 성공적으로 등록되었습니다' });
      onSuccess?.(customer);
    } catch (error) {
      toast({
        title: '등록 실패',
        description: error.message,
        variant: 'destructive',
      });
    } finally {
      setIsLoading(false);
    }
  };

  return (
          {/* 폼 필드들 */}
  );
}
```
