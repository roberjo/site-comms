import { handler } from '../createUser';
import { DynamoDBClient } from '@aws-sdk/client-dynamodb';
import { DynamoDBDocumentClient, PutCommand } from '@aws-sdk/lib-dynamodb';

// Mock AWS SDK
jest.mock('@aws-sdk/client-dynamodb');
jest.mock('@aws-sdk/lib-dynamodb');

const mockSend = jest.fn();
(DynamoDBDocumentClient as jest.Mock).mockImplementation(() => ({
  send: mockSend,
}));

describe('createUser Lambda', () => {
  beforeEach(() => {
    jest.clearAllMocks();
    process.env.USERS_TABLE_NAME = 'test-users-table';
  });

  it('should create a new user successfully', async () => {
    const event = {
      body: JSON.stringify({
        email: 'test@example.com',
        firstName: 'John',
        lastName: 'Doe',
      }),
    };

    mockSend.mockResolvedValueOnce({});

    const response = await handler(event as any);

    expect(response.statusCode).toBe(201);
    expect(JSON.parse(response.body)).toMatchObject({
      email: 'test@example.com',
      firstName: 'John',
      lastName: 'Doe',
    });
    expect(mockSend).toHaveBeenCalledWith(expect.any(PutCommand));
  });

  it('should return error for missing body', async () => {
    const event = {};

    const response = await handler(event as any);

    expect(response.statusCode).toBe(400);
    expect(JSON.parse(response.body)).toEqual({
      message: 'Request body is required',
      code: 'MISSING_BODY',
    });
  });

  it('should return error for missing required fields', async () => {
    const event = {
      body: JSON.stringify({
        email: 'test@example.com',
        // Missing firstName and lastName
      }),
    };

    const response = await handler(event as any);

    expect(response.statusCode).toBe(400);
    expect(JSON.parse(response.body)).toEqual({
      message: 'Missing required fields',
      code: 'INVALID_INPUT',
    });
  });

  it('should return error for invalid email format', async () => {
    const event = {
      body: JSON.stringify({
        email: 'invalid-email',
        firstName: 'John',
        lastName: 'Doe',
      }),
    };

    const response = await handler(event as any);

    expect(response.statusCode).toBe(400);
    expect(JSON.parse(response.body)).toEqual({
      message: 'Invalid email format',
      code: 'INVALID_EMAIL',
    });
  });

  it('should return error when user already exists', async () => {
    const event = {
      body: JSON.stringify({
        email: 'test@example.com',
        firstName: 'John',
        lastName: 'Doe',
      }),
    };

    mockSend.mockRejectedValueOnce({
      name: 'ConditionalCheckFailedException',
    });

    const response = await handler(event as any);

    expect(response.statusCode).toBe(400);
    expect(JSON.parse(response.body)).toEqual({
      message: 'User already exists',
      code: 'USER_EXISTS',
    });
  });

  it('should return error for internal server error', async () => {
    const event = {
      body: JSON.stringify({
        email: 'test@example.com',
        firstName: 'John',
        lastName: 'Doe',
      }),
    };

    mockSend.mockRejectedValueOnce(new Error('Internal error'));

    const response = await handler(event as any);

    expect(response.statusCode).toBe(500);
    expect(JSON.parse(response.body)).toEqual({
      message: 'Internal server error',
      code: 'INTERNAL_ERROR',
    });
  });
}); 