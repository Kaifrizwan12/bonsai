import * as cp from 'child_process';

export interface BonsaiResult {
  file: string;
  score: number;
  band: 'GREEN' | 'YELLOW' | 'RED';
  blastScore: number;
  composability: number;
  contextDepth: number;
  suggestions: string[];
  parseError: boolean;
}

export async function runBonsai(filePath: string): Promise<BonsaiResult | null> {
  return new Promise((resolve) => {
    try {
      const command = cp.spawn('bonsai', ['analyze', '--format', 'json', filePath], {
        stdio: ['ignore', 'pipe', 'pipe'],
      });
      const timeout = setTimeout(() => {
        command.kill();
        resolve(null);
      }, 8000);

      let stdout = '';

      command.stdout.on('data', (chunk: Buffer) => {
        stdout += chunk.toString();
      });

      command.on('error', () => {
        clearTimeout(timeout);
        resolve(null);
      });

      command.on('close', (code) => {
        clearTimeout(timeout);
        if (code === 2) {
          resolve(null);
          return;
        }

        try {
          const parsed = JSON.parse(stdout);
          if (!Array.isArray(parsed)) {
            resolve(null);
            return;
          }

          const result = parsed.find((entry) => entry.file === filePath) ?? null;
          resolve(result as BonsaiResult | null);
        } catch (_) {
          resolve(null);
        }
      });
    } catch (_) {
      resolve(null);
    }
  });
}

export function isBonsaiInstalled(): boolean {
  try {
    const result = cp.spawnSync('bonsai', ['--version'], {
      stdio: 'ignore',
    });
    return result.status === 0;
  } catch (_) {
    return false;
  }
}
