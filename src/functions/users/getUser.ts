import { APIGatewayProxyEvent, APIGatewayProxyResult } from 'aws-lambda';
import { DynamoDBClient } from '@aws-sdk/client-dynamodb';
import { DynamoDBDocumentClient, GetCommand } from '@aws-sdk/lib-dynamodb';
import { createSuccessResponse, createErrorResponse, sanitizeUserData } from '../../shared/utils';

const dynamoDb = new DynamoDBClient({});
const docClient = DynamoDBDocumentClient.from(dynamoDb);

export const handler = async (event: APIGatewayProxyEvent): Promise<APIGatewayProxyResult> => {
  try {
    const userId = event.pathParameters?.userId;

    if (!userId) {
      return createErrorResponse('User ID is required', 'MISSING_USER_ID');
    }

    const result = await docClient.send(new GetCommand({
      TableName: process.env.USERS_TABLE_NAME,
      Key: { userId },
    }));

    if (!result.Item) {
      return createErrorResponse('User not found', 'USER_NOT_FOUND', 404);
    }

    return createSuccessResponse(sanitizeUserData(result.Item));
  } catch (error) {
    console.error('Error getting user:', error);
    return createErrorResponse('Internal server error', 'INTERNAL_ERROR', 500);
  }
}; 