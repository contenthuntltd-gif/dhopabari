import React, { createContext, useContext, useState, useCallback, useEffect } from 'react';
import { serviceLabels, priceMap as defaultPriceMap, FREE_DELIVERY_MINIMUM, DELIVERY_CHARGE, DELIVERY_TIME_TEXT } from '../constants/theme';
import { getPrices } from './api';
import AsyncStorage from '@react-native-async-storage/async-storage';

// Types
export interface CartItem {
  name: string;
  service: string;
  serviceLabel: string;
  qty: number;
  price: number;
  total: number;
}

export interface UserProfile {
  phone: string;
  name: string;
  area: string;
  address: string;
  avatar?: string;
}

export interface OrderPayload {
  customerName: string;
  phone: string;
  address: string;
  service: string;
  items: CartItem[];
  subtotal: number;
  delivery: number;
  discount: number;
  total: number;
  deliveryTime: string;
  status: string;
  riderId: string;
  payment: string;
}

interface StoreContextType {
  // User
  user: UserProfile;
  setUser: (u: UserProfile) => void;
  isHydrated: boolean;

  // Cart
  cart: Record<string, CartItem>;
  selectedService: string;
  setSelectedService: (s: string) => void;
  updateCartItem: (name: string, service: string, delta: number) => void;
  removeCartItem: (key: string) => void;
  clearCart: () => void;
  getCartItems: () => CartItem[];
  cartSubtotal: () => number;
  cartCount: () => number;
  deliveryCharge: () => number;
  cartTotal: () => number;

  // Order
  lastOrderId: string;
  setLastOrderId: (id: string) => void;
  orderWorkflowStatus: string;
  setOrderWorkflowStatus: (s: string) => void;
  activeRiderId: string;
  setActiveRiderId: (id: string) => void;

  // Build order payload
  getOrderPayload: () => OrderPayload;

  // Live prices
  priceMap: Record<string, Record<string, number>>;
  priceList: any[];
  itemsByCategory: Record<string, { name: string; icon: string }[]>;
  fetchPrices: () => Promise<void>;
}

const StoreContext = createContext<StoreContextType | undefined>(undefined);

export function StoreProvider({ children }: { children: React.ReactNode }) {
  const [user, setUserState] = useState<UserProfile>({
    phone: '',
    name: '',
    area: '',
    address: '',
    avatar: '👨',
  });
  const [isHydrated, setIsHydrated] = useState(false);

  // Load user from AsyncStorage on mount
  useEffect(() => {
    const loadUser = async () => {
      try {
        const stored = await AsyncStorage.getItem('@dhopa_bari_user');
        if (stored) {
          setUserState(JSON.parse(stored));
        }
      } catch (e) {
        console.warn('Failed to load user session', e);
      } finally {
        setIsHydrated(true);
      }
    };
    loadUser();
  }, []);

  // Custom setUser that persists to AsyncStorage
  const setUser = useCallback((u: UserProfile) => {
    setUserState(u);
    AsyncStorage.setItem('@dhopa_bari_user', JSON.stringify(u)).catch((e) => {
      console.warn('Failed to persist user session', e);
    });
  }, []);

  const [cart, setCart] = useState<Record<string, CartItem>>({});
  const [selectedService, setSelectedService] = useState('wash');
  const [lastOrderId, setLastOrderId] = useState('ORD-1234');
  const [orderWorkflowStatus, setOrderWorkflowStatus] = useState('pending');
  const [activeRiderId, setActiveRiderId] = useState('rider_karim');

  // Live prices
  const [livePriceMap, setLivePriceMap] = useState<Record<string, Record<string, number>>>(defaultPriceMap);
  const [livePriceList, setLivePriceList] = useState<any[]>([]);

  const fetchPrices = useCallback(async () => {
    try {
      const list = await getPrices();
      setLivePriceList(list);
      const map: Record<string, Record<string, number>> = {};
      list.forEach((item: any) => {
        map[item.name] = {
          wash: item.wash,
          dry: item.dry,
          combo: item.combo,
          iron: item.iron,
        };
      });
      setLivePriceMap(map);
    } catch (e) {
      console.warn("Failed to fetch live prices, using defaults.");
    }
  }, []);

  useEffect(() => {
    fetchPrices();
  }, [fetchPrices]);

  // Dynamically compute itemsByCategory based on livePriceList
  const dynamicItemsByCategory = (() => {
    const categories: Record<string, { name: string; icon: string }[]> = {
      male: [],
      female: [],
      kids: [],
      home: [],
    };
    
    const iconMap: Record<string, string> = {
      'শার্ট': '👔',
      'প্যান্ট': '👖',
      'টি-শার্ট': '👕',
      'পাঞ্জাবি': '🥻',
      'জুব্বা': '🧥',
      'পায়জামা': '👖',
      'কোট': '🧥',
      'কটি': '🦺',
      'সুইটার': '🧥',
      'জ্যাকেট': '🧥',
      'শাল': '🧣',
      'শেরওয়ানি': '🧥',
      'স্যুট': '🧥',
      'টাই': '👔',
      'বোরকা': '👗',
      'শাড়ি': '🥻',
      'সালোয়ার, কামিজ, ওড়না': '👗',
      'ব্লাউজ': '👚',
      'লেহেঙ্গা / গাউন': '👗',
      'হিজাব': '🧣',
      'বেডশিট / চাদর': '🛏️',
      'বালিশ কভার': '🛏️',
      'টাওয়েল': '🧼',
      'পর্দা': '🪟',
      'কম্বল': '🛌',
      'কমফোর্টার': '🛌',
      'নকশী কাঁথা': '🛌',
      'জায়নামাজ': '🕌',
      'বেবি ফ্রক': '👶',
      'বেবি রম্পার': '👶',
      'বাচ্চার সেট': '👶',
      'বেবি প্যান্ট': '👶',
      'বেবি গেঞ্জি': '👶',
      'কাঁথা': '👶',
    };

    livePriceList.forEach((item: any) => {
      const cat = item.category || 'male';
      if (categories[cat]) {
        categories[cat].push({
          name: item.name,
          icon: iconMap[item.name] || '👕'
        });
      }
    });

    if (livePriceList.length === 0) {
      return {
        male: [
          { name: 'শার্ট', icon: '👔' },
          { name: 'প্যান্ট', icon: '👖' },
          { name: 'টি-শার্ট', icon: '👕' },
          { name: 'পাঞ্জাবি', icon: '🥻' },
          { name: 'জুব্বা', icon: '🧥' },
          { name: 'পায়জামা', icon: '👖' },
          { name: 'কোট', icon: '🧥' },
          { name: 'কটি', icon: '🦺' },
          { name: 'সুইটার', icon: '🧥' },
          { name: 'জ্যাকেট', icon: '🧥' },
          { name: 'শাল', icon: '🧣' },
          { name: 'শেরওয়ানি', icon: '🧥' },
          { name: 'স্যুট', icon: '🧥' },
          { name: 'টাই', icon: '👔' },
        ],
        female: [
          { name: 'বোরকা', icon: '👗' },
          { name: 'শাড়ি', icon: '🥻' },
          { name: 'সালোয়ার, কামিজ, ওড়না', icon: '👗' },
          { name: 'ব্লাউজ', icon: '👚' },
          { name: 'লেহেঙ্গা / গাউন', icon: '👗' },
          { name: 'হিজাব', icon: '🧣' },
        ],
        kids: [
          { name: 'বেবি ফ্রক', icon: '👶' },
          { name: 'বেবি রম্পার', icon: '👶' },
          { name: 'বাচ্চার সেট', icon: '👶' },
          { name: 'বেবি প্যান্ট', icon: '👶' },
          { name: 'বেবি গেঞ্জি', icon: '👶' },
        ],
        home: [
          { name: 'বেডশিট / চাদর', icon: '🛏️' },
          { name: 'বালিশ কভার', icon: '🛏️' },
          { name: 'টাওয়েল', icon: '🧼' },
          { name: 'পর্দা', icon: '🪟' },
          { name: 'কম্বল', icon: '🛌' },
          { name: 'কমফোর্টার', icon: '🛌' },
          { name: 'নকশী কাঁথা', icon: '🛌' },
          { name: 'জায়নামাজ', icon: '🕌' },
        ],
      };
    }

    return categories;
  })();

  const cartKey = (service: string, name: string) => `${service}::${name}`;

  const updateCartItem = useCallback((name: string, service: string, delta: number) => {
    setCart((prev) => {
      const key = cartKey(service, name);
      const current = prev[key]?.qty || 0;
      const qty = Math.max(current + delta, 0);
      if (qty === 0) {
        const next = { ...prev };
        delete next[key];
        return next;
      }
      const prices = livePriceMap[name] || {};
      const price = prices[service] || 0;
      return {
        ...prev,
        [key]: {
          name,
          service,
          serviceLabel: serviceLabels[service] || service,
          qty,
          price,
          total: qty * price,
        },
      };
    });
  }, []);

  const removeCartItem = useCallback((key: string) => {
    setCart((prev) => {
      const next = { ...prev };
      delete next[key];
      return next;
    });
  }, []);

  const clearCart = useCallback(() => setCart({}), []);

  const getCartItems = useCallback((): CartItem[] => {
    return Object.values(cart).filter((item) => item.qty > 0);
  }, [cart]);

  const cartSubtotalFn = useCallback((): number => {
    return Object.values(cart).reduce((sum, item) => sum + item.qty * item.price, 0);
  }, [cart]);

  const cartCountFn = useCallback((): number => {
    return Object.values(cart).reduce((sum, item) => sum + item.qty, 0);
  }, [cart]);

  const deliveryChargeFn = useCallback((): number => {
    const sub = cartSubtotalFn();
    if (sub <= 0) return 0;
    return sub >= FREE_DELIVERY_MINIMUM ? 0 : DELIVERY_CHARGE;
  }, [cartSubtotalFn]);

  const cartTotalFn = useCallback((): number => {
    return Math.max(cartSubtotalFn() + deliveryChargeFn(), 0);
  }, [cartSubtotalFn, deliveryChargeFn]);

  const getOrderPayload = useCallback((): OrderPayload => {
    const items = getCartItems();
    const subtotal = cartSubtotalFn();
    const delivery = deliveryChargeFn();
    const services = [...new Set(items.map((i) => i.serviceLabel))];
    return {
      customerName: user.name || 'গ্রাহক',
      phone: user.phone || '০১৭XXXXXXXX',
      address: user.address || 'কক্সবাজার',
      service: services.join(' + ') || serviceLabels[selectedService],
      items,
      subtotal,
      delivery,
      discount: 0,
      total: Math.max(subtotal + delivery, 0),
      deliveryTime: DELIVERY_TIME_TEXT,
      status: 'অর্ডার পেন্ডিং',
      riderId: activeRiderId,
      payment: 'COD',
    };
  }, [getCartItems, cartSubtotalFn, deliveryChargeFn, user, selectedService, activeRiderId]);

  return (
    <StoreContext.Provider
      value={{
        user,
        setUser,
        isHydrated,
        cart,
        selectedService,
        setSelectedService,
        updateCartItem,
        removeCartItem,
        clearCart,
        getCartItems,
        cartSubtotal: cartSubtotalFn,
        cartCount: cartCountFn,
        deliveryCharge: deliveryChargeFn,
        cartTotal: cartTotalFn,
        lastOrderId,
        setLastOrderId,
        orderWorkflowStatus,
        setOrderWorkflowStatus,
        activeRiderId,
        setActiveRiderId,
        getOrderPayload,
        priceMap: livePriceMap,
        priceList: livePriceList,
        itemsByCategory: dynamicItemsByCategory,
        fetchPrices,
      }}
    >
      {children}
    </StoreContext.Provider>
  );
}

export function useStore() {
  const ctx = useContext(StoreContext);
  if (!ctx) throw new Error('useStore must be used within StoreProvider');
  return ctx;
}
