export interface User {
  userId: string;
  email: string;
  firstName: string;
  lastName: string;
  settings: UserSettings;
  createdAt: string;
  updatedAt: string;
}

export interface UserSettings {
  notifications: {
    email: boolean;
    push: boolean;
    inApp: boolean;
  };
  theme: 'light' | 'dark';
  language: string;
}

export interface Message {
  messageId: string;
  userId: string;
  senderId: string;
  content: string;
  read: boolean;
  createdAt: string;
  updatedAt: string;
}

export interface Notification {
  notificationId: string;
  userId: string;
  type: 'message' | 'system' | 'alert';
  title: string;
  content: string;
  read: boolean;
  createdAt: string;
}

export interface WebSocketMessage {
  action: 'connect' | 'disconnect' | 'subscribe' | 'unsubscribe';
  userId?: string;
  data?: any;
}

export interface ApiResponse<T> {
  statusCode: number;
  body: T;
  headers?: {
    [key: string]: string;
  };
}

export interface ErrorResponse {
  message: string;
  code: string;
} 