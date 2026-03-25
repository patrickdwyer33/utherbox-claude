import { McpServer } from '@modelcontextprotocol/sdk/server/mcp.js';
import { ApiClient } from '../index.js';

export function registerClaudeAuthTools(server: McpServer, client: ApiClient): void {
  server.tool(
    'fetch_claude_credentials',
    "Fetch the Claude OAuth credentials for this VM's user. Returns the credentials JSON.",
    {},
    async () => {
      const result = await client.get('/vms/me/claude-credentials');
      return { content: [{ type: 'text' as const, text: JSON.stringify(result, null, 2) }] };
    },
  );
}
