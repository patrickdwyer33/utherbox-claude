import { z } from 'zod';
import { McpServer } from '@modelcontextprotocol/sdk/server/mcp.js';
import { ApiClient } from '../index.js';

export function registerCloudflareTools(server: McpServer, client: ApiClient): void {
  server.tool(
    'link_cloudflare',
    'Link a Cloudflare API token and zone ID to this account. Required before using DNS tools on a custom domain.',
    {
      cf_api_token: z.string().describe('Cloudflare API token with Zone:DNS:Edit permission'),
      cf_zone_id: z.string().describe('Cloudflare zone ID (32 hex chars from zone overview page)'),
    },
    async ({ cf_api_token, cf_zone_id }) => {
      const result = await client.post('/cloudflare/link', { cf_api_token, cf_zone_id });
      return { content: [{ type: 'text' as const, text: JSON.stringify(result, null, 2) }] };
    },
  );
}
