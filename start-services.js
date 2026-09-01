import { spawn } from 'child_process';
import path from 'path';
import { fileURLToPath } from 'url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

console.log('====================================================');
console.log('       STARTING ARGUS VPN BACKEND SERVICES          ');
console.log('====================================================');

// 1. Start Node Daemon (Port 4001)
const nodeDaemon = spawn('node', ['dist/server.js'], {
  cwd: path.join(__dirname, 'services', 'node-daemon'),
  stdio: 'inherit',
  shell: true,
  env: { ...process.env, PORT: '4001' }
});

// 2. Start Control Plane (Port 4000)
const controlPlane = spawn('node', ['dist/server.js'], {
  cwd: path.join(__dirname, 'services', 'control-plane'),
  stdio: 'inherit',
  shell: true,
  env: { ...process.env, PORT: '4000' }
});

process.on('SIGINT', () => {
  console.log('\n[!] Shutting down Argus VPN services...');
  nodeDaemon.kill();
  controlPlane.kill();
  process.exit();
});
