import { APIGatewayProxyEvent, APIGatewayProxyResult } from 'aws-lambda';
import { DynamoDBClient } from '@aws-sdk/client-dynamodb';
import { DynamoDBDocumentClient, PutCommand } from '@aws-sdk/lib-dynamodb';
import { SNSClient, PublishCommand } from '@aws-sdk/client-sns';
import { ApiGatewayManagementApiClient, PostToConnectionCommand } from '@aws-sdk/client-apigatewaymanagementapi';
import { Message, Notification } from '../../shared/types';
import { createSuccessResponse, createErrorResponse, getCurrentTimestamp, generateId } from '../../shared/utils';

const dynamoDb = new DynamoDBClient({});
const docClient = DynamoDBDocumentClient.from(dynamoDb);
const snsClient = new SNSClient({});

export const handler = async (event: APIGatewayProxyEvent): Promise<APIGatewayProxyResult> => {
  try {
    if (!event.body) {
      return createErrorResponse('Request body is required', 'MISSING_BODY');
    }

    const body = JSON.parse(event.body);
    const { userId, content } = body;
    const senderId = event.requestContext.authorizer?.claims?.sub;

    if (!userId || !content || !senderId) {
      return createErrorResponse('Missing required fields', 'INVALID_INPUT');
    }

    const timestamp = getCurrentTimestamp();
    const messageId = generateId();

    // Create message
    const message: Message = {
      messageId,
      userId,
      senderId,
      content,
      read: false,
      createdAt: timestamp,
      updatedAt: timestamp,
    };

    // Create notification
    const notification: Notification = {
      notificationId: generateId(),
      userId,
      type: 'message',
      title: 'New Message',
      content: `You have received a new message from ${senderId}`,
      read: false,
      createdAt: timestamp,
    };

    // Save message to DynamoDB
    await docClient.send(new PutCommand({
      TableName: process.env.MESSAGES_TABLE_NAME,
      Item: message,
    }));

    // Save notification to DynamoDB
    await docClient.send(new PutCommand({
      TableName: process.env.NOTIFICATIONS_TABLE_NAME,
      Item: notification,
    }));

    // Send push notification via SNS
    await snsClient.send(new PublishCommand({
      TopicArn: process.env.NOTIFICATIONS_TOPIC_ARN,
      Message: JSON.stringify({
        type: 'message',
        userId,
        messageId,
        content: `New message: ${content.substring(0, 100)}${content.length > 100 ? '...' : ''}`,
      }),
    }));

    // Send real-time notification via WebSocket if connection exists
    try {
      const apiGateway = new ApiGatewayManagementApiClient({
        endpoint: process.env.WEBSOCKET_API_ENDPOINT,
      });

      await apiGateway.send(new PostToConnectionCommand({
        ConnectionId: userId, // Assuming userId is used as connectionId
        Data: JSON.stringify({
          type: 'message',
          messageId,
          content,
          senderId,
          timestamp,
        }),
      }));
    } catch (error) {
      console.warn('Failed to send WebSocket notification:', error);
      // Continue execution as WebSocket notification is not critical
    }

    return createSuccessResponse(message);
  } catch (error) {
    console.error('Error sending message:', error);
    return createErrorResponse('Internal server error', 'INTERNAL_ERROR', 500);
  }
}; 