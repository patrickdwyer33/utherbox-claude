import { z } from 'zod';
import { McpServer } from '@modelcontextprotocol/sdk/server/mcp.js';
import { ApiClient } from '../index.js';

export function registerStorageTools(server: McpServer, client: ApiClient): void {

  server.tool(
    'create_bucket',
    'Create a new Linode Object Storage bucket for this user.',
    {
      name: z.string().describe('Bucket name (must be globally unique)'),
      cluster: z.string().describe('Linode cluster slug, e.g. us-east-1'),
    },
    async ({ name, cluster }) => {
      const result = await client.post('/buckets', { name, cluster });
      return { content: [{ type: 'text' as const, text: JSON.stringify(result, null, 2) }] };
    },
  );

  server.tool(
    'list_buckets',
    'List all Object Storage buckets owned by this user.',
    {},
    async () => {
      const result = await client.get('/buckets');
      return { content: [{ type: 'text' as const, text: JSON.stringify(result, null, 2) }] };
    },
  );

  server.tool(
    'delete_bucket',
    'Delete an Object Storage bucket by name.',
    {
      name: z.string().describe('Bucket name'),
    },
    async ({ name }) => {
      const result = await client.delete(`/buckets/${name}`);
      return { content: [{ type: 'text' as const, text: JSON.stringify(result, null, 2) }] };
    },
  );

  server.tool(
    'get_bucket_credentials',
    'Get S3-compatible access credentials for a bucket.',
    {
      name: z.string().describe('Bucket name'),
    },
    async ({ name }) => {
      const result = await client.get(`/buckets/${name}/credentials`);
      return { content: [{ type: 'text' as const, text: JSON.stringify(result, null, 2) }] };
    },
  );
}
