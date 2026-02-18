const { DynamoDBClient } = require('@aws-sdk/client-dynamodb');
const { DynamoDBDocumentClient, PutCommand, GetCommand, ScanCommand, UpdateCommand, DeleteCommand } = require('@aws-sdk/lib-dynamodb');

const client = new DynamoDBClient({});
const docClient = DynamoDBDocumentClient.from(client);
const TABLE_NAME = process.env.TABLE_NAME;

// Helper function to build response
const buildResponse = (statusCode, body) => ({
  statusCode,
  headers: {
    'Content-Type': 'application/json',
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
    'Access-Control-Allow-Headers': 'Content-Type'
  },
  body: JSON.stringify(body)
});

// Helper function to build redirect response
const buildRedirectResponse = (location) => ({
  statusCode: 302,
  headers: {
    'Location': location,
    'Access-Control-Allow-Origin': '*'
  },
  body: ''
});

// Create a shortened URL
const createUrl = async (slug, fullUrl) => {
  if (!slug || !fullUrl) {
    return buildResponse(400, { error: 'Missing required fields: slug and fullUrl' });
  }

  // Validate URL format
  try {
    new URL(fullUrl);
  } catch (error) {
    return buildResponse(400, { error: 'Invalid URL format' });
  }

  // Check if slug already exists
  const getCommand = new GetCommand({
    TableName: TABLE_NAME,
    Key: { slug }
  });

  try {
    const existing = await docClient.send(getCommand);
    if (existing.Item) {
      return buildResponse(409, { error: 'Slug already exists' });
    }
  } catch (error) {
    console.error('Error checking existing slug:', error);
  }

  const timestamp = new Date().toISOString();
  const item = {
    slug,
    fullUrl,
    createdAt: timestamp,
    updatedAt: timestamp
  };

  const command = new PutCommand({
    TableName: TABLE_NAME,
    Item: item
  });

  try {
    await docClient.send(command);
    return buildResponse(201, item);
  } catch (error) {
    console.error('Error creating URL:', error);
    return buildResponse(500, { error: 'Failed to create URL' });
  }
};

// List all URLs
const listUrls = async () => {
  const command = new ScanCommand({
    TableName: TABLE_NAME
  });

  try {
    const result = await docClient.send(command);
    return buildResponse(200, {
      items: result.Items || [],
      count: result.Count || 0
    });
  } catch (error) {
    console.error('Error listing URLs:', error);
    return buildResponse(500, { error: 'Failed to list URLs' });
  }
};

// Get a URL by slug (for redirect)
const getUrl = async (slug) => {
  const command = new GetCommand({
    TableName: TABLE_NAME,
    Key: { slug }
  });

  try {
    const result = await docClient.send(command);
    if (!result.Item) {
      return buildResponse(404, { error: 'URL not found' });
    }
    return result.Item;
  } catch (error) {
    console.error('Error getting URL:', error);
    return buildResponse(500, { error: 'Failed to get URL' });
  }
};

// Update a URL
const updateUrl = async (slug, fullUrl) => {
  if (!fullUrl) {
    return buildResponse(400, { error: 'Missing required field: fullUrl' });
  }

  // Validate URL format
  try {
    new URL(fullUrl);
  } catch (error) {
    return buildResponse(400, { error: 'Invalid URL format' });
  }

  const timestamp = new Date().toISOString();
  const command = new UpdateCommand({
    TableName: TABLE_NAME,
    Key: { slug },
    UpdateExpression: 'SET fullUrl = :fullUrl, updatedAt = :updatedAt',
    ExpressionAttributeValues: {
      ':fullUrl': fullUrl,
      ':updatedAt': timestamp
    },
    ConditionExpression: 'attribute_exists(slug)',
    ReturnValues: 'ALL_NEW'
  });

  try {
    const result = await docClient.send(command);
    return buildResponse(200, result.Attributes);
  } catch (error) {
    if (error.name === 'ConditionalCheckFailedException') {
      return buildResponse(404, { error: 'URL not found' });
    }
    console.error('Error updating URL:', error);
    return buildResponse(500, { error: 'Failed to update URL' });
  }
};

// Delete a URL
const deleteUrl = async (slug) => {
  const command = new DeleteCommand({
    TableName: TABLE_NAME,
    Key: { slug },
    ConditionExpression: 'attribute_exists(slug)'
  });

  try {
    await docClient.send(command);
    return buildResponse(200, { message: 'URL deleted successfully' });
  } catch (error) {
    if (error.name === 'ConditionalCheckFailedException') {
      return buildResponse(404, { error: 'URL not found' });
    }
    console.error('Error deleting URL:', error);
    return buildResponse(500, { error: 'Failed to delete URL' });
  }
};

// Main Lambda handler
exports.handler = async (event) => {
  console.log('Event:', JSON.stringify(event, null, 2));

  const httpMethod = event.httpMethod;
  const resource = event.resource;
  const pathParameters = event.pathParameters || {};
  const slug = pathParameters.slug;

  try {
    // Handle OPTIONS for CORS
    if (httpMethod === 'OPTIONS') {
      return buildResponse(200, {});
    }

    // POST /urls - Create new shortened URL
    if (httpMethod === 'POST' && resource === '/urls') {
      const body = JSON.parse(event.body || '{}');
      return await createUrl(body.slug, body.fullUrl);
    }

    // GET /urls - List all URLs
    if (httpMethod === 'GET' && resource === '/urls') {
      return await listUrls();
    }

    // GET /urls/{slug} - Get URL and redirect
    if (httpMethod === 'GET' && resource === '/urls/{slug}') {
      const result = await getUrl(slug);
      if (result.fullUrl) {
        return buildRedirectResponse(result.fullUrl);
      }
      return result; // Error response
    }

    // PUT /urls/{slug} - Update URL
    if (httpMethod === 'PUT' && resource === '/urls/{slug}') {
      const body = JSON.parse(event.body || '{}');
      return await updateUrl(slug, body.fullUrl);
    }

    // DELETE /urls/{slug} - Delete URL
    if (httpMethod === 'DELETE' && resource === '/urls/{slug}') {
      return await deleteUrl(slug);
    }

    // Unknown route
    return buildResponse(404, { error: 'Route not found' });
  } catch (error) {
    console.error('Unhandled error:', error);
    return buildResponse(500, { error: 'Internal server error' });
  }
};
