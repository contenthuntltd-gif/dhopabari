import { Platform } from 'react-native';

// Update this to your computer's local IP address
// Find it by running `ipconfig` on Windows and looking for "IPv4 Address"
const LOCAL_IP = '192.168.0.109'; // Your PC's WiFi IP

const API_BASE = Platform.OS === 'web'
  ? 'http://localhost:4177'
  : `http://${LOCAL_IP}:4177`;

export async function api<T = any>(path: string, options: RequestInit = {}): Promise<T> {
  const response = await fetch(`${API_BASE}${path}`, {
    headers: {
      'Content-Type': 'application/json',
      ...(options.headers as Record<string, string> || {}),
    },
    ...options,
  });
  if (!response.ok) throw new Error(`API failed: ${response.status}`);
  return response.json();
}

export async function getHealth() {
  return api('/api/health');
}

export async function getPrices() {
  return api('/api/prices');
}

export async function getOrders() {
  return api('/api/orders');
}

export async function createOrder(payload: any) {
  return api('/api/orders', {
    method: 'POST',
    body: JSON.stringify(payload),
  });
}

export async function updateOrderStatus(orderId: string, status: string, riderId?: string) {
  return api(`/api/orders/${orderId}/status`, {
    method: 'PATCH',
    body: JSON.stringify({ status, riderId }),
  });
}

export async function getCustomers() {
  return api('/api/customers');
}

export async function saveCustomer(data: any) {
  return api('/api/customers', {
    method: 'POST',
    body: JSON.stringify(data),
  });
}

export async function getRiders() {
  return api('/api/riders');
}

export async function sendOtp(phone: string) {
  return api('/api/auth/otp', {
    method: 'POST',
    body: JSON.stringify({ phone }),
  });
}

export async function verifyOtp(phone: string, otp: string) {
  return api('/api/auth/verify', {
    method: 'POST',
    body: JSON.stringify({ phone, otp }),
  });
}

export async function registerCustomer(payload: { phone: string; password: string; name?: string }) {
  return api('/api/auth/register', {
    method: 'POST',
    body: JSON.stringify(payload),
  });
}

export async function loginCustomer(payload: { phone: string; password: string }) {
  return api('/api/auth/login', {
    method: 'POST',
    body: JSON.stringify(payload),
  });
}

export async function resetPassword(payload: { phone: string; otp: string; newPassword: string }) {
  return api('/api/auth/reset-password', {
    method: 'POST',
    body: JSON.stringify(payload),
  });
}

export async function getMessages(orderId: string) {
  return api(`/api/orders/${orderId}/messages`);
}

export async function sendMessage(orderId: string, text: string, sender: 'customer' | 'rider') {
  return api(`/api/orders/${orderId}/messages`, {
    method: 'POST',
    body: JSON.stringify({ text, sender }),
  });
}

export async function cancelOrder(orderId: string) {
  return api(`/api/orders/${orderId}`, {
    method: 'DELETE',
  });
}

export async function savePriceItem(item: any) {
  return api('/api/prices', {
    method: 'POST',
    body: JSON.stringify(item),
  });
}

export async function getCustomerOrders(phone: string) {
  return api(`/api/customers/${encodeURIComponent(phone)}/orders`);
}

export async function getRiderOrders(riderId: string) {
  return api(`/api/riders/${encodeURIComponent(riderId)}/orders`);
}

export async function adminLogin(payload: any) {
  return api('/api/auth/admin', {
    method: 'POST',
    body: JSON.stringify(payload),
  });
}

export async function riderLogin(payload: any) {
  return api('/api/auth/rider-login', {
    method: 'POST',
    body: JSON.stringify(payload),
  });
}

export async function createRider(payload: any) {
  return api('/api/riders', {
    method: 'POST',
    body: JSON.stringify(payload),
  });
}
