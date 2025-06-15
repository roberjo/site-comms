import { APIGatewayProxyEvent, APIGatewayProxyResult } from 'aws-lambda';
import { DynamoDBClient } from '@aws-sdk/client-dynamodb';
import { DynamoDBDocumentClient, PutCommand } from '@aws-sdk/lib-dynamodb';
import { User } from '../../shared/types';
import { createSuccessResponse, createErrorResponse, getCurrentTimestamp, generateId, validateEmail } from '../../shared/utils';

const dynamoDb = new DynamoDBClient({});
const docClient = DynamoDBDocumentClient.from(dynamoDb);

export const handler = async (event: APIGatewayProxyEvent): Promise<APIGatewayProxyResult> => {
  try {
    if (!event.body) {
      return createErrorResponse('Request body is required', 'MISSING_BODY');
    }

    const body = JSON.parse(event.body);
    const { email, firstName, lastName, settings } = body;

    // Validate required fields
    if (!email || !firstName || !lastName) {
      return createErrorResponse('Missing required fields', 'INVALID_INPUT');
    }

    // Validate email format
    if (!validateEmail(email)) {
      return createErrorResponse('Invalid email format', 'INVALID_EMAIL');
    }

    const timestamp = getCurrentTimestamp();
    const userId = generateId();

    const user: User = {
      userId,
      email,
      firstName,
      lastName,
      settings: settings || {
        notifications: {
          email: true,
          push: true,
          inApp: true,
        },
        theme: 'light',
        language: 'en',
      },
      createdAt: timestamp,
      updatedAt: timestamp,
    };

    await docClient.send(new PutCommand({
      TableName: process.env.USERS_TABLE_NAME,
      Item: user,
      ConditionExpression: 'attribute_not_exists(userId)',
    }));

    return createSuccessResponse(user, 201);
  } catch (error: any) {
    console.error('Error creating user:', error);
    
    if (error.name === 'ConditionalCheckFailedException') {
      return createErrorResponse('User already exists', 'USER_EXISTS');
    }

    return createErrorResponse('Internal server error', 'INTERNAL_ERROR', 500);
  }
}; 