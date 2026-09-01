import { createServer } from '../server.js';

async function runTests() {
  console.log('--- Starting Argus Control Plane & Shield Filtering Test ---');
  const server = await createServer();
  await server.listen({ port: 4003, host: '127.0.0.1' });

  const baseUrl = 'http://127.0.0.1:4003';

  try {
    // 1. Health check
    console.log('[Test 1] Testing GET /health...');
    const healthRes = await fetch(`${baseUrl}/health`);
    const healthData = await healthRes.json() as any;
    console.log('-> Response:', healthData);
    if (healthData.status !== 'OK') throw new Error('Health check failed');
    console.log('✓ Test 1 Passed');

    // 2. User Registration
    console.log('[Test 2] Testing POST /api/auth/register...');
    const regRes = await fetch(`${baseUrl}/api/auth/register`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        email: 'user@argusvpn.com',
        password: 'securePassword123'
      })
    });
    const regData = await regRes.json() as any;
    console.log('-> Response:', { email: regData.user?.email, tokenReceived: !!regData.token });
    if (!regData.token || regData.user.email !== 'user@argusvpn.com') {
      throw new Error('Registration failed');
    }
    const token = regData.token;
    console.log('✓ Test 2 Passed: User registered with JWT');

    // 3. Server List Discovery
    console.log('[Test 3] Testing GET /api/servers...');
    const serversRes = await fetch(`${baseUrl}/api/servers`, {
      headers: { Authorization: `Bearer ${token}` }
    });
    const serversData = await serversRes.json() as any;
    console.log('-> Response:', { serverCount: serversData.servers?.length, recommended: serversData.recommendedServerId });
    if (!serversData.servers || serversData.servers.length === 0) {
      throw new Error('Server discovery failed');
    }
    console.log(`✓ Test 3 Passed: Found ${serversData.servers.length} active server nodes`);

    // 4. Argus Shield: Read default settings & update (Block Adult & Gambling)
    console.log('[Test 4] Testing GET & PUT /api/shield/settings (Content Filtering)...');
    const shieldGetRes = await fetch(`${baseUrl}/api/shield/settings`, {
      headers: { Authorization: `Bearer ${token}` }
    });
    const shieldGetData = await shieldGetRes.json() as any;
    console.log('-> Default Shield Settings:', shieldGetData.settings);

    // Turn ON Adult content and Betting/Gambling blocking
    const shieldPutRes = await fetch(`${baseUrl}/api/shield/settings`, {
      method: 'PUT',
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${token}`
      },
      body: JSON.stringify({
        blockAdultContent: true,
        blockGambling: true
      })
    });
    const shieldPutData = await shieldPutRes.json() as any;
    console.log('-> Updated Shield Settings:', shieldPutData.settings);
    if (!shieldPutData.settings.blockAdultContent || !shieldPutData.settings.blockGambling) {
      throw new Error('Shield settings update failed');
    }
    console.log('✓ Test 4 Passed: Argus Shield updated (Adult & Gambling blocked)');

    // 5. Connect VPN with Shield active
    console.log('[Test 5] Testing POST /api/vpn/connect (Orchestrating tunnel with custom DNS)...');
    const mockClientPubKey = 'TEST_CLIENT_WG_PUB_KEY_9876543210ABCDEF==';
    const connectRes = await fetch(`${baseUrl}/api/vpn/connect`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${token}`
      },
      body: JSON.stringify({
        clientPublicKey: mockClientPubKey,
        preferredCountryCode: 'DE'
      })
    });
    const connectData = await connectRes.json() as any;
    console.log('-> VPN Profile received:', {
      sessionId: connectData.sessionId,
      assignedIp: connectData.assignedVirtualIp,
      server: connectData.server?.hostname,
      dns: connectData.config?.interface?.dns,
      shield: connectData.shieldSettings
    });

    if (!connectData.sessionId || !connectData.config?.peer?.endpoint) {
      throw new Error('VPN Connection failed');
    }
    // Verify DNS was configured with family/gambling protection DNS
    if (!connectData.config.interface.dns.includes('185.228.168.10')) {
      throw new Error('DNS filtering mismatch for Adult + Gambling shield');
    }
    console.log('✓ Test 5 Passed: VPN Profile generated with DNS content filtering active');

    // 6. Disconnect VPN
    console.log('[Test 6] Testing POST /api/vpn/disconnect...');
    const disconnectRes = await fetch(`${baseUrl}/api/vpn/disconnect`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${token}`
      },
      body: JSON.stringify({
        sessionId: connectData.sessionId
      })
    });
    const disconnectData = await disconnectRes.json() as any;
    console.log('-> Response:', disconnectData);
    if (!disconnectData.success) {
      throw new Error('Disconnect failed');
    }
    console.log('✓ Test 6 Passed');

    console.log('\n======================================================');
    console.log('  ALL CONTROL PLANE & SHIELD TESTS PASSED (6/6)       ');
    console.log('======================================================\n');
  } finally {
    await server.close();
  }
}

runTests().catch((err) => {
  console.error('Test failed:', err);
  process.exit(1);
});
