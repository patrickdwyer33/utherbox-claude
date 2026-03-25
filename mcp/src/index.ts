import * as fs from 'fs';
import * as os from 'os';
import { McpServer } from '@modelcontextprotocol/sdk/server/mcp.js';
import { StdioServerTransport } from '@modelcontextprotocol/sdk/server/stdio.js';

export interface Credentials {
  platform_api_token: string;
  platform_api_base_url: string;
}

export interface VmMe {
  id: string;
  name: string;
  status: string;
  project_id: string;
}

export class ApiClient {
  constructor(
    private readonly baseUrl: string,
    private readonly token: string,
  ) {}

  async get<T>(path: string): Promise<T> {
    const res = await fetch(`${this.baseUrl}${path}`, {
      headers: {
        Authorization: `Bearer ${this.token}`,
        'Content-Type': 'application/json',
      },
    });
    if (!res.ok) {
      const body = await res.text().catch(() => '');
      throw new Error(`GET ${path} → ${res.status}: ${body}`);
    }
    return res.json() as Promise<T>;
  }

  async post<T>(path: string, body?: unknown): Promise<T> {
    const res = await fetch(`${this.baseUrl}${path}`, {
      method: 'POST',
      headers: {
        Authorization: `Bearer ${this.token}`,
        'Content-Type': 'application/json',
      },
      body: body !== undefined ? JSON.stringify(body) : undefined,
    });
    if (!res.ok) {
      const text = await res.text().catch(() => '');
      throw new Error(`POST ${path} → ${res.status}: ${text}`);
    }
    return res.json() as Promise<T>;
  }

  async put<T>(path: string, body?: unknown): Promise<T> {
    const res = await fetch(`${this.baseUrl}${path}`, {
      method: 'PUT',
      headers: {
        Authorization: `Bearer ${this.token}`,
        'Content-Type': 'application/json',
      },
      body: body !== undefined ? JSON.stringify(body) : undefined,
    });
    if (!res.ok) {
      const text = await res.text().catch(() => '');
      throw new Error(`PUT ${path} → ${res.status}: ${text}`);
    }
    return res.json() as Promise<T>;
  }

  async delete<T>(path: string): Promise<T> {
    const res = await fetch(`${this.baseUrl}${path}`, {
      method: 'DELETE',
      headers: {
        Authorization: `Bearer ${this.token}`,
        'Content-Type': 'application/json',
      },
    });
    if (!res.ok) {
      const text = await res.text().catch(() => '');
      throw new Error(`DELETE ${path} → ${res.status}: ${text}`);
    }
    if (res.status === 204 || res.headers.get('content-length') === '0') {
      return undefined as unknown as T;
    }
    return res.json() as Promise<T>;
  }
}

// Tool registration imports (added in subsequent tasks)
// import { registerVmTools } from './tools/vms.js';
// import { registerStorageTools } from './tools/storage.js';
// import { registerDnsTools } from './tools/dns.js';
// import { registerDomainsTools } from './tools/domains.js';
// import { registerLimitsTools } from './tools/limits.js';
// import { registerCloudflareTools } from './tools/cloudflare.js';
// import { registerClaudeAuthTools } from './tools/claude_auth.js';

async function main(): Promise<void> {
  const credsPath = `${os.homedir()}/.utherbox-credentials.json`;
  if (!fs.existsSync(credsPath)) {
    process.stderr.write(`utherbox MCP: credentials not found at ${credsPath}\n`);
    process.exit(1);
  }

  let creds: Credentials;
  try {
    creds = JSON.parse(fs.readFileSync(credsPath, 'utf8')) as Credentials;
  } catch (e) {
    process.stderr.write(`utherbox MCP: failed to parse credentials: ${e}\n`);
    process.exit(1);
  }

  if (!creds.platform_api_token || !creds.platform_api_base_url) {
    process.stderr.write('utherbox MCP: credentials missing platform_api_token or platform_api_base_url\n');
    process.exit(1);
  }

  const client = new ApiClient(creds.platform_api_base_url, creds.platform_api_token);

  let projectId: string;
  try {
    const me = await client.get<VmMe>('/vms/me');
    projectId = me.project_id;
  } catch (e) {
    process.stderr.write(`utherbox MCP: GET /vms/me failed: ${e}\n`);
    process.exit(1);
  }

  const server = new McpServer({
    name: 'utherbox',
    version: '1.0.0',
  });

  // Tools registered in subsequent tasks
  // Remove this line when adding the first registerXxxTools() call below:
  void projectId;

  const transport = new StdioServerTransport();
  await server.connect(transport);
}

main().catch((e: unknown) => {
  process.stderr.write(`utherbox MCP startup failed: ${e}\n`);
  process.exit(1);
});
