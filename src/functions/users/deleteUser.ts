import { APIGatewayProxyEvent, APIGatewayProxyResult } from 'aws-lambda';
import { DynamoDBClient } from '@aws-sdk/client-dynamodb';
import { DynamoDBDocumentClient, DeleteCommand } from '@aws-sdk/lib-dynamodb';
import { createSuccessResponse, createErrorResponse } from '../../shared/utils';

const dynamoDb = new DynamoDBClient({});
const docClient = DynamoDBDocumentClient.from(dynamoDb);

export const handler = async (event: APIGatewayProxyEvent): Promise<APIGatewayProxyResult> => {
  try {
    const userId = event.pathParameters?.userId;

    if (!userId) {
      return createErrorResponse('User ID is required', 'MISSING_USER_ID');
    }

    await docClient.send(new DeleteCommand({
      TableName: process.env.USERS_TABLE_NAME,
      Key: { userId },
      ConditionExpression: 'attribute_exists(userId)',
    }));

    return createSuccessResponse({ message: 'User deleted successfully' });
  } catch (error: any) {
    console.error('Error deleting user:', error);
    
    if (error.name === 'ConditionalCheckFailedException') {
      return createErrorResponse('User not found', 'USER_NOT_FOUND', 404);
    }

    return createErrorResponse('Internal server error', 'INTERNAL_ERROR', 500);
  }
}; 