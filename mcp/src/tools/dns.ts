import { z } from 'zod';
import { McpServer } from '@modelcontextprotocol/sdk/server/mcp.js';
import { ApiClient } from '../index.js';

export function registerDnsTools(server: McpServer, client: ApiClient, projectId: string): void {

  server.tool(
    'list_dns_records',
    "List DNS records in the user's Cloudflare zone.",
    {},
    async () => {
      const result = await client.get('/cloudflare/records');
      return { content: [{ type: 'text' as const, text: JSON.stringify(result, null, 2) }] };
    },
  );

  server.tool(
    'create_dns_record',
    "Create a DNS record in the user's Cloudflare zone.",
    {
      type: z.string().describe('Record type: A, AAAA, CNAME, MX, TXT, etc.'),
      name: z.string().describe('Record name (e.g. "api" or "api.example.com")'),
      content: z.string().describe('Record value (e.g. IP address or target hostname)'),
      ttl: z.number().optional().describe('TTL in seconds (default 1 = automatic)'),
      proxied: z.boolean().optional().describe('Enable Cloudflare proxy (default false)'),
    },
    async ({ type, name, content, ttl, proxied }) => {
      const body: Record<string, unknown> = { type, name, content };
      if (ttl !== undefined) body.ttl = ttl;
      if (proxied !== undefined) body.proxied = proxied;
      const result = await client.post('/cloudflare/records', body);
      return { content: [{ type: 'text' as const, text: JSON.stringify(result, null, 2) }] };
    },
  );

  server.tool(
    'update_dns_record',
    'Update an existing DNS record by Cloudflare record ID.',
    {
      record_id: z.string().describe('Cloudflare record ID'),
      type: z.string().describe('Record type'),
      name: z.string().describe('Record name'),
      content: z.string().describe('New record value'),
      ttl: z.number().optional(),
      proxied: z.boolean().optional(),
    },
    async ({ record_id, type, name, content, ttl, proxied }) => {
      const body: Record<string, unknown> = { type, name, content };
      if (ttl !== undefined) body.ttl = ttl;
      if (proxied !== undefined) body.proxied = proxied;
      const result = await client.put(`/cloudflare/records/${record_id}`, body);
      return { content: [{ type: 'text' as const, text: JSON.stringify(result, null, 2) }] };
    },
  );

  server.tool(
    'delete_dns_record',
    'Delete a DNS record by Cloudflare record ID.',
    {
      record_id: z.string().describe('Cloudflare record ID'),
    },
    async ({ record_id }) => {
      const result = await client.delete(`/cloudflare/records/${record_id}`);
      return { content: [{ type: 'text' as const, text: JSON.stringify(result, null, 2) }] };
    },
  );

  server.tool(
    'register_subdomain',
    'Register a free subdomain under utherbox.com (Light tier). Returns the registered subdomain.',
    {
      label: z.string().describe('Subdomain label, e.g. "myapp" → myapp.utherbox.com'),
    },
    async ({ label }) => {
      const result = await client.post('/dns/subdomains', { label, project_id: projectId });
      return { content: [{ type: 'text' as const, text: JSON.stringify(result, null, 2) }] };
    },
  );
}
