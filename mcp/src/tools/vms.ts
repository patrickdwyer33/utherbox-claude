import { z } from 'zod';
import { McpServer } from '@modelcontextprotocol/sdk/server/mcp.js';
import { ApiClient } from '../index.js';

export function registerVmTools(server: McpServer, client: ApiClient, projectId: string): void {

  server.tool(
    'create_vm',
    'Provision a new VM in this project. Polls ready state via get_vm.',
    {
      name: z.string().describe('VM name; used as the remote-control session name'),
      instance_type: z.string().describe('Linode instance type slug, e.g. g6-nanode-1'),
      region: z.string().describe('Linode region slug, e.g. us-east'),
      ssh_public_key: z.string().optional().describe('External SSH public key for direct access'),
    },
    async ({ name, instance_type, region, ssh_public_key }) => {
      const body: Record<string, unknown> = { name, instance_type, region };
      if (ssh_public_key) body.ssh_public_key = ssh_public_key;
      const result = await client.post(`/projects/${projectId}/vms`, body);
      return { content: [{ type: 'text' as const, text: JSON.stringify(result, null, 2) }] };
    },
  );

  server.tool(
    'list_vms',
    'List all VMs in this project.',
    async () => {
      const result = await client.get(`/projects/${projectId}/vms`);
      return { content: [{ type: 'text' as const, text: JSON.stringify(result, null, 2) }] };
    },
  );

  server.tool(
    'get_vm',
    'Get details and current status of a VM by ID.',
    {
      vm_id: z.string().describe('VM UUID'),
    },
    async ({ vm_id }) => {
      const result = await client.get(`/vms/${vm_id}`);
      return { content: [{ type: 'text' as const, text: JSON.stringify(result, null, 2) }] };
    },
  );

  server.tool(
    'delete_vm',
    'Delete a VM. Returns immediately; deletion is async. Check status via get_vm.',
    {
      vm_id: z.string().describe('VM UUID'),
    },
    async ({ vm_id }) => {
      const result = await client.delete(`/vms/${vm_id}`);
      return { content: [{ type: 'text' as const, text: JSON.stringify(result, null, 2) }] };
    },
  );

  server.tool(
    'get_vm_connection',
    'Get SSH connection details for a VM (host, port, user, instructions).',
    {
      vm_id: z.string().describe('VM UUID'),
    },
    async ({ vm_id }) => {
      const result = await client.get(`/vms/${vm_id}/connection`);
      return { content: [{ type: 'text' as const, text: JSON.stringify(result, null, 2) }] };
    },
  );
}
