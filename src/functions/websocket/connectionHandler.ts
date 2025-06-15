import { APIGatewayProxyEvent, APIGatewayProxyResult } from 'aws-lambda';
import { DynamoDBClient } from '@aws-sdk/client-dynamodb';
import { DynamoDBDocumentClient, PutCommand, DeleteCommand } from '@aws-sdk/lib-dynamodb';
import { createSuccessResponse, createErrorResponse } from '../../shared/utils';

const dynamoDb = new DynamoDBClient({});
const docClient = DynamoDBDocumentClient.from(dynamoDb);

export const handler = async (event: APIGatewayProxyEvent): Promise<APIGatewayProxyResult> => {
  try {
    const connectionId = event.requestContext.connectionId;
    const routeKey = event.requestContext.routeKey;
    const userId = event.requestContext.authorizer?.claims?.sub;

    if (!connectionId) {
      return createErrorResponse('Connection ID is required', 'MISSING_CONNECTION_ID');
    }

    switch (routeKey) {
      case '$connect':
        if (!userId) {
          return createErrorResponse('User ID is required for connection', 'MISSING_USER_ID');
        }

        // Store connection in DynamoDB
        await docClient.send(new PutCommand({
          TableName: process.env.CONNECTIONS_TABLE_NAME,
          Item: {
            connectionId,
            userId,
            timestamp: new Date().toISOString(),
          },
        }));
        break;

      case '$disconnect':
        // Remove connection from DynamoDB
        await docClient.send(new DeleteCommand({
          TableName: process.env.CONNECTIONS_TABLE_NAME,
          Key: { connectionId },
        }));
        break;

      default:
        return createErrorResponse('Invalid route key', 'INVALID_ROUTE');
    }

    return createSuccessResponse({ message: 'Connection handled successfully' });
  } catch (error) {
    console.error('Error handling WebSocket connection:', error);
    return createErrorResponse('Internal server error', 'INTERNAL_ERROR', 500);
  }
}; 