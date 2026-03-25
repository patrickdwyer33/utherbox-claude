import { z } from 'zod';
import { McpServer } from '@modelcontextprotocol/sdk/server/mcp.js';
import { ApiClient } from '../index.js';

export function registerDomainsTools(server: McpServer, client: ApiClient): void {

  server.tool(
    'check_ns_propagation',
    'Get domain details including ownership status, Cloudflare zone ID, and nameservers. Use to check NS propagation after purchasing a domain.',
    {
      domain_id: z.string().describe('Domain UUID from the platform'),
    },
    async ({ domain_id }) => {
      const result = await client.get(`/domains/${domain_id}`);
      return { content: [{ type: 'text' as const, text: JSON.stringify(result, null, 2) }] };
    },
  );

  server.tool(
    'transfer_domain_out',
    'Initiate a domain transfer-out. Domain must be in active status. Auth code relay is manual — contact platform support.',
    {
      domain_id: z.string().describe('Domain UUID from the platform'),
    },
    async ({ domain_id }) => {
      const result = await client.post(`/domains/${domain_id}/transfer-out`);
      return { content: [{ type: 'text' as const, text: JSON.stringify(result, null, 2) }] };
    },
  );
}
