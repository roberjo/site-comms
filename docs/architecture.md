# Site Communications Backend Architecture

## System Overview

The Site Communications Backend is a serverless system built on AWS that provides real-time communication capabilities, user management, and notification services. The system is designed to be scalable, maintainable, and cost-effective.

## Architecture Diagram

```mermaid
graph TB
    Client[Client Application] -->|HTTP/WebSocket| APIGW[API Gateway]
    APIGW -->|HTTP| REST[HTTP API]
    APIGW -->|WebSocket| WS[WebSocket API]
    
    REST -->|POST /users| CreateUser[Create User Lambda]
    REST -->|GET /users/{id}| GetUser[Get User Lambda]
    REST -->|PUT /users/{id}| UpdateUser[Update User Lambda]
    REST -->|DELETE /users/{id}| DeleteUser[Delete User Lambda]
    REST -->|POST /messages| SendMessage[Send Message Lambda]
    
    WS -->|$connect| Connect[Connection Handler Lambda]
    WS -->|$disconnect| Disconnect[Connection Handler Lambda]
    
    CreateUser -->|Write| Users[(Users Table)]
    GetUser -->|Read| Users
    UpdateUser -->|Update| Users
    DeleteUser -->|Delete| Users
    
    SendMessage -->|Write| Messages[(Messages Table)]
    SendMessage -->|Write| Notifications[(Notifications Table)]
    SendMessage -->|Publish| SNS[SNS Topic]
    SendMessage -->|Send| WS
    
    Connect -->|Write| Connections[(Connections Table)]
    Disconnect -->|Delete| Connections
    
    SNS -->|Push| Mobile[Mobile Devices]
    SNS -->|Email| Email[Email Service]
    
    subgraph Monitoring
        CloudWatch[CloudWatch]
        Alarms[CloudWatch Alarms]
    end
    
    CreateUser -->|Logs| CloudWatch
    GetUser -->|Logs| CloudWatch
    UpdateUser -->|Logs| CloudWatch
    DeleteUser -->|Logs| CloudWatch
    SendMessage -->|Logs| CloudWatch
    Connect -->|Logs| CloudWatch
    Disconnect -->|Logs| CloudWatch
    
    CloudWatch -->|Alerts| Alarms
    Alarms -->|Notifications| SNS
```

## Components

### 1. API Gateway
- **HTTP API**: Handles RESTful requests for user and message operations
- **WebSocket API**: Manages real-time connections for instant notifications
- **Routes**:
  - `POST /users`: Create new user
  - `GET /users/{userId}`: Get user details
  - `PUT /users/{userId}`: Update user
  - `DELETE /users/{userId}`: Delete user
  - `POST /messages`: Send message
  - WebSocket routes: `$connect`, `$disconnect`

### 2. Lambda Functions

#### User Management
- **Create User**: Creates new user records
- **Get User**: Retrieves user information
- **Update User**: Modifies user details
- **Delete User**: Removes user records

#### Message Handling
- **Send Message**: 
  - Creates message records
  - Generates notifications
  - Sends real-time updates
  - Triggers push notifications

#### WebSocket Management
- **Connection Handler**:
  - Manages WebSocket connections
  - Stores connection information
  - Handles connection lifecycle

### 3. DynamoDB Tables

#### Users Table
- Primary Key: `userId` (String)
- Attributes:
  - `email` (String)
  - `firstName` (String)
  - `lastName` (String)
  - `settings` (Map)
  - `createdAt` (String)
  - `updatedAt` (String)

#### Messages Table
- Primary Key: `messageId` (String)
- Sort Key: `userId` (String)
- Attributes:
  - `senderId` (String)
  - `content` (String)
  - `read` (Boolean)
  - `createdAt` (String)
  - `updatedAt` (String)

#### Notifications Table
- Primary Key: `notificationId` (String)
- Sort Key: `userId` (String)
- Attributes:
  - `type` (String)
  - `title` (String)
  - `content` (String)
  - `read` (Boolean)
  - `createdAt` (String)

#### Connections Table
- Primary Key: `connectionId` (String)
- GSI: `userId` (String)
- Attributes:
  - `userId` (String)
  - `timestamp` (String)

### 4. SNS Topics
- **Notifications Topic**: For push notifications
- **Alerts Topic**: For system alerts and monitoring

### 5. CloudWatch
- **Log Groups**: For each Lambda function
- **Alarms**:
  - Lambda errors
  - Lambda duration
  - API Gateway errors
  - WebSocket connection issues

## Data Flow

### User Creation Flow
1. Client sends POST request to `/users`
2. API Gateway routes to Create User Lambda
3. Lambda validates input and creates user record
4. Response returned to client

### Message Sending Flow
1. Client sends POST request to `/messages`
2. API Gateway routes to Send Message Lambda
3. Lambda:
   - Creates message record
   - Creates notification
   - Publishes to SNS
   - Sends WebSocket message
4. Response returned to client

### Real-time Notification Flow
1. Client establishes WebSocket connection
2. Connection Handler stores connection info
3. When message is sent:
   - Lambda sends to WebSocket API
   - API delivers to connected clients
4. On disconnect:
   - Connection Handler removes connection info

## Security

### Authentication
- JWT-based authentication
- Cognito integration for user management
- API Gateway authorizers

### Authorization
- IAM roles for Lambda functions
- DynamoDB access policies
- SNS topic policies

### Data Protection
- Data encryption at rest
- TLS for data in transit
- Input validation
- Output sanitization

## Monitoring and Alerting

### CloudWatch Alarms
- Lambda function errors
- Lambda execution duration
- API Gateway errors
- WebSocket connection issues

### Logging
- Structured logging in Lambda functions
- API Gateway access logs
- WebSocket connection logs

## Scalability

### Horizontal Scaling
- Lambda functions auto-scale
- DynamoDB auto-scaling
- API Gateway throttling

### Performance
- DynamoDB DAX for caching
- Lambda provisioned concurrency
- API Gateway caching

## Cost Optimization

### Lambda
- Appropriate memory allocation
- Provisioned concurrency for critical functions
- Function timeout optimization

### DynamoDB
- On-demand capacity mode
- Auto-scaling
- TTL for temporary data

### API Gateway
- Caching where appropriate
- Request throttling
- WebSocket connection cleanup 