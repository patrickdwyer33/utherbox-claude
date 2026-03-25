import { McpServer } from '@modelcontextprotocol/sdk/server/mcp.js';
import { ApiClient } from '../index.js';

export function registerLimitsTools(server: McpServer, client: ApiClient): void {
  server.tool(
    'get_limits',
    'Get account limits: max_vms, allowed_instance_categories, and current vm_count.',
    {},
    async () => {
      const result = await client.get('/account/limits');
      return { content: [{ type: 'text' as const, text: JSON.stringify(result, null, 2) }] };
    },
  );
}
