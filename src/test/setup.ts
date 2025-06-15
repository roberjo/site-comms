// Set test environment variables
process.env.USERS_TABLE_NAME = 'test-users-table';
process.env.MESSAGES_TABLE_NAME = 'test-messages-table';
process.env.NOTIFICATIONS_TABLE_NAME = 'test-notifications-table';
process.env.NOTIFICATIONS_TOPIC_ARN = 'arn:aws:sns:us-east-1:123456789012:test-notifications';

// Mock console.error to keep test output clean
const originalConsoleError = console.error;
console.error = (...args: any[]) => {
  if (args[0]?.includes('Error creating user:')) {
    return;
  }
  originalConsoleError.apply(console, args);
};

// Reset all mocks before each test
beforeEach(() => {
  jest.clearAllMocks();
});

// Clean up after all tests
afterAll(() => {
  console.error = originalConsoleError;
}); 