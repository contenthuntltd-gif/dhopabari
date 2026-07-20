import React from 'react';
import { useRouter } from 'expo-router';
import { useStore } from '../services/store';

export default function IndexScreen() {
  const router = useRouter();
  const { user, isHydrated } = useStore();

  React.useEffect(() => {
    if (!isHydrated) return;
    if (user && user.phone && user.name) {
      router.replace('/(tabs)/home');
    } else {
      router.replace('/login');
    }
  }, [isHydrated, user]);

  return null;
}
