import { ApiResponse, ErrorResponse } from './types';
import { APIGatewayProxyResult } from 'aws-lambda';

export const createSuccessResponse = <T>(data: T, statusCode = 200): APIGatewayProxyResult => ({
  statusCode,
  body: JSON.stringify(data),
  headers: {
    'Content-Type': 'application/json',
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Credentials': true,
  },
});

export const createErrorResponse = (message: string, code: string, statusCode = 400): APIGatewayProxyResult => ({
  statusCode,
  body: JSON.stringify({
    message,
    code,
  }),
  headers: {
    'Content-Type': 'application/json',
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Credentials': true,
  },
});

export const getCurrentTimestamp = (): string => {
  return new Date().toISOString();
};

export const generateId = (): string => {
  return Math.random().toString(36).substring(2) + Date.now().toString(36);
};

export const validateEmail = (email: string): boolean => {
  const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
  return emailRegex.test(email);
};

export const sanitizeUserData = (user: any): any => {
  const { password, ...sanitizedUser } = user;
  return sanitizedUser;
}; 