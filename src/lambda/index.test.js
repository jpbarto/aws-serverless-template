const { mockClient } = require('aws-sdk-client-mock');
const { DynamoDBDocumentClient, PutCommand, GetCommand, ScanCommand, UpdateCommand, DeleteCommand } = require('@aws-sdk/lib-dynamodb');

// Set environment variable before requiring handler
process.env.TABLE_NAME = 'test-table';

const ddbMock = mockClient(DynamoDBDocumentClient);

// Require handler after mocking
const { handler } = require('./index');

describe('URL Shortener Lambda', () => {
  beforeEach(() => {
    ddbMock.reset();
  });

  describe('POST /urls - Create URL', () => {
    test('should create a new shortened URL', async () => {
      ddbMock.on(GetCommand).resolves({});
      ddbMock.on(PutCommand).resolves({});

      const event = {
        httpMethod: 'POST',
        resource: '/urls',
        body: JSON.stringify({
          slug: 'test',
          fullUrl: 'https://example.com'
        })
      };

      const response = await handler(event);
      const body = JSON.parse(response.body);

      expect(response.statusCode).toBe(201);
      expect(body.slug).toBe('test');
      expect(body.fullUrl).toBe('https://example.com');
      expect(body.createdAt).toBeDefined();
      expect(body.updatedAt).toBeDefined();
    });

    test('should return 400 if slug is missing', async () => {
      const event = {
        httpMethod: 'POST',
        resource: '/urls',
        body: JSON.stringify({
          fullUrl: 'https://example.com'
        })
      };

      const response = await handler(event);
      const body = JSON.parse(response.body);

      expect(response.statusCode).toBe(400);
      expect(body.error).toBe('Missing required fields: slug and fullUrl');
    });

    test('should return 400 if fullUrl is missing', async () => {
      const event = {
        httpMethod: 'POST',
        resource: '/urls',
        body: JSON.stringify({
          slug: 'test'
        })
      };

      const response = await handler(event);
      const body = JSON.parse(response.body);

      expect(response.statusCode).toBe(400);
      expect(body.error).toBe('Missing required fields: slug and fullUrl');
    });

    test('should return 400 if URL format is invalid', async () => {
      const event = {
        httpMethod: 'POST',
        resource: '/urls',
        body: JSON.stringify({
          slug: 'test',
          fullUrl: 'not-a-url'
        })
      };

      const response = await handler(event);
      const body = JSON.parse(response.body);

      expect(response.statusCode).toBe(400);
      expect(body.error).toBe('Invalid URL format');
    });

    test('should return 409 if slug already exists', async () => {
      ddbMock.on(GetCommand).resolves({
        Item: { slug: 'test', fullUrl: 'https://existing.com' }
      });

      const event = {
        httpMethod: 'POST',
        resource: '/urls',
        body: JSON.stringify({
          slug: 'test',
          fullUrl: 'https://example.com'
        })
      };

      const response = await handler(event);
      const body = JSON.parse(response.body);

      expect(response.statusCode).toBe(409);
      expect(body.error).toBe('Slug already exists');
    });

    test('should return 500 on DynamoDB error', async () => {
      ddbMock.on(GetCommand).resolves({});
      ddbMock.on(PutCommand).rejects(new Error('DynamoDB error'));

      const event = {
        httpMethod: 'POST',
        resource: '/urls',
        body: JSON.stringify({
          slug: 'test',
          fullUrl: 'https://example.com'
        })
      };

      const response = await handler(event);
      const body = JSON.parse(response.body);

      expect(response.statusCode).toBe(500);
      expect(body.error).toBe('Failed to create URL');
    });
  });

  describe('GET /urls - List URLs', () => {
    test('should list all URLs', async () => {
      ddbMock.on(ScanCommand).resolves({
        Items: [
          { slug: 'test1', fullUrl: 'https://example1.com' },
          { slug: 'test2', fullUrl: 'https://example2.com' }
        ],
        Count: 2
      });

      const event = {
        httpMethod: 'GET',
        resource: '/urls'
      };

      const response = await handler(event);
      const body = JSON.parse(response.body);

      expect(response.statusCode).toBe(200);
      expect(body.items).toHaveLength(2);
      expect(body.count).toBe(2);
    });

    test('should return empty list when no URLs exist', async () => {
      ddbMock.on(ScanCommand).resolves({
        Items: [],
        Count: 0
      });

      const event = {
        httpMethod: 'GET',
        resource: '/urls'
      };

      const response = await handler(event);
      const body = JSON.parse(response.body);

      expect(response.statusCode).toBe(200);
      expect(body.items).toHaveLength(0);
      expect(body.count).toBe(0);
    });

    test('should return 500 on DynamoDB error', async () => {
      ddbMock.on(ScanCommand).rejects(new Error('DynamoDB error'));

      const event = {
        httpMethod: 'GET',
        resource: '/urls'
      };

      const response = await handler(event);
      const body = JSON.parse(response.body);

      expect(response.statusCode).toBe(500);
      expect(body.error).toBe('Failed to list URLs');
    });
  });

  describe('GET /urls/{slug} - Redirect', () => {
    test('should redirect to full URL', async () => {
      ddbMock.on(GetCommand).resolves({
        Item: { slug: 'test', fullUrl: 'https://example.com' }
      });

      const event = {
        httpMethod: 'GET',
        resource: '/urls/{slug}',
        pathParameters: { slug: 'test' }
      };

      const response = await handler(event);

      expect(response.statusCode).toBe(302);
      expect(response.headers.Location).toBe('https://example.com');
      expect(response.body).toBe('');
    });

    test('should return 404 if slug not found', async () => {
      ddbMock.on(GetCommand).resolves({});

      const event = {
        httpMethod: 'GET',
        resource: '/urls/{slug}',
        pathParameters: { slug: 'nonexistent' }
      };

      const response = await handler(event);
      const body = JSON.parse(response.body);

      expect(response.statusCode).toBe(404);
      expect(body.error).toBe('URL not found');
    });

    test('should return 500 on DynamoDB error', async () => {
      ddbMock.on(GetCommand).rejects(new Error('DynamoDB error'));

      const event = {
        httpMethod: 'GET',
        resource: '/urls/{slug}',
        pathParameters: { slug: 'test' }
      };

      const response = await handler(event);
      const body = JSON.parse(response.body);

      expect(response.statusCode).toBe(500);
      expect(body.error).toBe('Failed to get URL');
    });
  });

  describe('PUT /urls/{slug} - Update URL', () => {
    test('should update an existing URL', async () => {
      ddbMock.on(UpdateCommand).resolves({
        Attributes: {
          slug: 'test',
          fullUrl: 'https://updated.com',
          updatedAt: '2024-01-01T00:00:00.000Z'
        }
      });

      const event = {
        httpMethod: 'PUT',
        resource: '/urls/{slug}',
        pathParameters: { slug: 'test' },
        body: JSON.stringify({
          fullUrl: 'https://updated.com'
        })
      };

      const response = await handler(event);
      const body = JSON.parse(response.body);

      expect(response.statusCode).toBe(200);
      expect(body.slug).toBe('test');
      expect(body.fullUrl).toBe('https://updated.com');
      expect(body.updatedAt).toBeDefined();
    });

    test('should return 400 if fullUrl is missing', async () => {
      const event = {
        httpMethod: 'PUT',
        resource: '/urls/{slug}',
        pathParameters: { slug: 'test' },
        body: JSON.stringify({})
      };

      const response = await handler(event);
      const body = JSON.parse(response.body);

      expect(response.statusCode).toBe(400);
      expect(body.error).toBe('Missing required field: fullUrl');
    });

    test('should return 400 if URL format is invalid', async () => {
      const event = {
        httpMethod: 'PUT',
        resource: '/urls/{slug}',
        pathParameters: { slug: 'test' },
        body: JSON.stringify({
          fullUrl: 'not-a-url'
        })
      };

      const response = await handler(event);
      const body = JSON.parse(response.body);

      expect(response.statusCode).toBe(400);
      expect(body.error).toBe('Invalid URL format');
    });

    test('should return 404 if slug not found', async () => {
      const error = new Error('ConditionalCheckFailedException');
      error.name = 'ConditionalCheckFailedException';
      ddbMock.on(UpdateCommand).rejects(error);

      const event = {
        httpMethod: 'PUT',
        resource: '/urls/{slug}',
        pathParameters: { slug: 'nonexistent' },
        body: JSON.stringify({
          fullUrl: 'https://example.com'
        })
      };

      const response = await handler(event);
      const body = JSON.parse(response.body);

      expect(response.statusCode).toBe(404);
      expect(body.error).toBe('URL not found');
    });

    test('should return 500 on DynamoDB error', async () => {
      ddbMock.on(UpdateCommand).rejects(new Error('DynamoDB error'));

      const event = {
        httpMethod: 'PUT',
        resource: '/urls/{slug}',
        pathParameters: { slug: 'test' },
        body: JSON.stringify({
          fullUrl: 'https://example.com'
        })
      };

      const response = await handler(event);
      const body = JSON.parse(response.body);

      expect(response.statusCode).toBe(500);
      expect(body.error).toBe('Failed to update URL');
    });
  });

  describe('DELETE /urls/{slug} - Delete URL', () => {
    test('should delete an existing URL', async () => {
      ddbMock.on(DeleteCommand).resolves({});

      const event = {
        httpMethod: 'DELETE',
        resource: '/urls/{slug}',
        pathParameters: { slug: 'test' }
      };

      const response = await handler(event);
      const body = JSON.parse(response.body);

      expect(response.statusCode).toBe(200);
      expect(body.message).toBe('URL deleted successfully');
    });

    test('should return 404 if slug not found', async () => {
      const error = new Error('ConditionalCheckFailedException');
      error.name = 'ConditionalCheckFailedException';
      ddbMock.on(DeleteCommand).rejects(error);

      const event = {
        httpMethod: 'DELETE',
        resource: '/urls/{slug}',
        pathParameters: { slug: 'nonexistent' }
      };

      const response = await handler(event);
      const body = JSON.parse(response.body);

      expect(response.statusCode).toBe(404);
      expect(body.error).toBe('URL not found');
    });

    test('should return 500 on DynamoDB error', async () => {
      ddbMock.on(DeleteCommand).rejects(new Error('DynamoDB error'));

      const event = {
        httpMethod: 'DELETE',
        resource: '/urls/{slug}',
        pathParameters: { slug: 'test' }
      };

      const response = await handler(event);
      const body = JSON.parse(response.body);

      expect(response.statusCode).toBe(500);
      expect(body.error).toBe('Failed to delete URL');
    });
  });

  describe('OPTIONS - CORS preflight', () => {
    test('should handle OPTIONS request', async () => {
      const event = {
        httpMethod: 'OPTIONS',
        resource: '/urls'
      };

      const response = await handler(event);

      expect(response.statusCode).toBe(200);
      expect(response.headers['Access-Control-Allow-Origin']).toBe('*');
      expect(response.headers['Access-Control-Allow-Methods']).toBeDefined();
    });
  });

  describe('Unknown routes', () => {
    test('should return 404 for unknown routes', async () => {
      const event = {
        httpMethod: 'GET',
        resource: '/unknown'
      };

      const response = await handler(event);
      const body = JSON.parse(response.body);

      expect(response.statusCode).toBe(404);
      expect(body.error).toBe('Route not found');
    });
  });

  describe('Error handling', () => {
    test('should handle malformed JSON in request body', async () => {
      const event = {
        httpMethod: 'POST',
        resource: '/urls',
        body: 'invalid-json'
      };

      const response = await handler(event);
      const body = JSON.parse(response.body);

      expect(response.statusCode).toBe(500);
      expect(body.error).toBe('Internal server error');
    });
  });

  describe('CORS headers', () => {
    test('should include CORS headers in all responses', async () => {
      ddbMock.on(ScanCommand).resolves({ Items: [], Count: 0 });

      const event = {
        httpMethod: 'GET',
        resource: '/urls'
      };

      const response = await handler(event);

      expect(response.headers['Access-Control-Allow-Origin']).toBe('*');
      expect(response.headers['Content-Type']).toBe('application/json');
    });
  });
});
