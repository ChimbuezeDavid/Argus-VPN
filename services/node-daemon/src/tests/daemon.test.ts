import { createServer } from '../server.js';
import { config } from '../config.js';

async function runTests() {
  console.log('--- Starting Argus Node Daemon Unit & Integration Test ---');
  const server = await createServer();
  await server.listen({ port: 4002, host: '127.0.0.1' });

  const baseUrl = 'http://127.0.0.1:4002';
  const headers = {
    'Content-Type': 'application/json',
    'x-argus-node-secret': config.secretToken
  };

  try {
    // 1. Test Node Info (Public endpoint)
    console.log('[Test 1] Testing GET /api/info...');
    const infoRes = await fetch(`${baseUrl}/api/info`);
    const infoData = await infoRes.json() as any;
    console.log('-> Response:', infoData);
    if (!infoData.publicKey || infoData.status !== 'ONLINE') {
      throw new Error('Test 1 Failed: info endpoint returned invalid data');
    }
    console.log('✓ Test 1 Passed');

    // 2. Test Unauthorized access
    console.log('[Test 2] Testing Auth protection on /api/peers without secret...');
    const unauthRes = await fetch(`${baseUrl}/api/peers`);
    if (unauthRes.status !== 401) {
      throw new Error(`Test 2 Failed: Expected 401 Unauthorized, got ${unauthRes.status}`);
    }
    console.log('✓ Test 2 Passed');

    // 3. Test Registering a Peer
    console.log('[Test 3] Testing POST /api/peers (Register Peer)...');
    const mockClientPubKey = 'TEST_CLIENT_KEY_ABC1234567890XYZ+==';
    const regRes = await fetch(`${baseUrl}/api/peers`, {
      method: 'POST',
      headers,
      body: JSON.stringify({
        clientPublicKey: mockClientPubKey
      })
    });
    const regData = await regRes.json() as any;
    console.log('-> Response:', regData);
    if (!regData.success || !regData.assignedIp.startsWith('10.8.0.')) {
      throw new Error('Test 3 Failed: Peer registration failed');
    }
    console.log(`✓ Test 3 Passed: Peer registered with IP ${regData.assignedIp}`);

    // 4. Test Listing Peers
    console.log('[Test 4] Testing GET /api/peers...');
    const listRes = await fetch(`${baseUrl}/api/peers`, { headers });
    const listData = await listRes.json() as any;
    console.log('-> Response:', listData);
    if (listData.count !== 1 || listData.peers[0].publicKey !== mockClientPubKey) {
      throw new Error('Test 4 Failed: List peers did not return the registered peer');
    }
    console.log('✓ Test 4 Passed');

    // 5. Test Metrics
    console.log('[Test 5] Testing GET /api/metrics...');
    const metricsRes = await fetch(`${baseUrl}/api/metrics`, { headers });
    const metricsData = await metricsRes.json() as any;
    console.log('-> Response:', metricsData);
    if (metricsData.activePeers !== 1) {
      throw new Error('Test 5 Failed: Metrics activePeers mismatch');
    }
    console.log('✓ Test 5 Passed');

    // 6. Test Removing Peer
    console.log('[Test 6] Testing DELETE /api/peers/:publicKey...');
    const delRes = await fetch(`${baseUrl}/api/peers/${encodeURIComponent(mockClientPubKey)}`, {
      method: 'DELETE',
      headers
    });
    const delData = await delRes.json() as any;
    console.log('-> Response:', delData);
    if (!delData.success) {
      throw new Error('Test 6 Failed: Peer removal failed');
    }
    console.log('✓ Test 6 Passed');

    console.log('\n========================================');
    console.log('  ALL NODE DAEMON TESTS PASSED (6/6)    ');
    console.log('========================================\n');
  } finally {
    await server.close();
  }
}

runTests().catch((err) => {
  console.error('Test execution failed:', err);
  process.exit(1);
});
