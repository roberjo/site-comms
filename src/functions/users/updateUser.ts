import { APIGatewayProxyEvent, APIGatewayProxyResult } from 'aws-lambda';
import { DynamoDBClient } from '@aws-sdk/client-dynamodb';
import { DynamoDBDocumentClient, UpdateCommand } from '@aws-sdk/lib-dynamodb';
import { createSuccessResponse, createErrorResponse, getCurrentTimestamp, validateEmail } from '../../shared/utils';

const dynamoDb = new DynamoDBClient({});
const docClient = DynamoDBDocumentClient.from(dynamoDb);

export const handler = async (event: APIGatewayProxyEvent): Promise<APIGatewayProxyResult> => {
  try {
    const userId = event.pathParameters?.userId;

    if (!userId) {
      return createErrorResponse('User ID is required', 'MISSING_USER_ID');
    }

    if (!event.body) {
      return createErrorResponse('Request body is required', 'MISSING_BODY');
    }

    const body = JSON.parse(event.body);
    const { email, firstName, lastName, settings } = body;

    // Validate email if provided
    if (email && !validateEmail(email)) {
      return createErrorResponse('Invalid email format', 'INVALID_EMAIL');
    }

    const updateExpression: string[] = [];
    const expressionAttributeValues: Record<string, any> = {};
    const expressionAttributeNames: Record<string, string> = {};

    if (email) {
      updateExpression.push('#email = :email');
      expressionAttributeValues[':email'] = email;
      expressionAttributeNames['#email'] = 'email';
    }

    if (firstName) {
      updateExpression.push('#firstName = :firstName');
      expressionAttributeValues[':firstName'] = firstName;
      expressionAttributeNames['#firstName'] = 'firstName';
    }

    if (lastName) {
      updateExpression.push('#lastName = :lastName');
      expressionAttributeValues[':lastName'] = lastName;
      expressionAttributeNames['#lastName'] = 'lastName';
    }

    if (settings) {
      updateExpression.push('#settings = :settings');
      expressionAttributeValues[':settings'] = settings;
      expressionAttributeNames['#settings'] = 'settings';
    }

    // Always update the updatedAt timestamp
    updateExpression.push('#updatedAt = :updatedAt');
    expressionAttributeValues[':updatedAt'] = getCurrentTimestamp();
    expressionAttributeNames['#updatedAt'] = 'updatedAt';

    if (updateExpression.length === 0) {
      return createErrorResponse('No valid fields to update', 'INVALID_UPDATE');
    }

    const result = await docClient.send(new UpdateCommand({
      TableName: process.env.USERS_TABLE_NAME,
      Key: { userId },
      UpdateExpression: `SET ${updateExpression.join(', ')}`,
      ExpressionAttributeValues: expressionAttributeValues,
      ExpressionAttributeNames: expressionAttributeNames,
      ReturnValues: 'ALL_NEW',
      ConditionExpression: 'attribute_exists(userId)',
    }));

    return createSuccessResponse(result.Attributes);
  } catch (error: any) {
    console.error('Error updating user:', error);
    
    if (error.name === 'ConditionalCheckFailedException') {
      return createErrorResponse('User not found', 'USER_NOT_FOUND', 404);
    }

    return createErrorResponse('Internal server error', 'INTERNAL_ERROR', 500);
  }
}; 