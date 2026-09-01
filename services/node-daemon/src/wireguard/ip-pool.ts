/**
 * IP Pool manager for allocating WireGuard virtual IPs within a /24 subnet (e.g. 10.8.0.2 - 10.8.0.254)
 */
export class IpPool {
  private basePrefix: string; // e.g. "10.8.0"
  private allocatedIps: Map<string, string> = new Map(); // publicKey -> IP
  private ipToPublicKey: Map<string, string> = new Map(); // IP -> publicKey
  private nextHostIndex: number = 2; // .1 is reserved for server

  constructor(subnet: string = '10.8.0.0/24') {
    // Extract base prefix from e.g. "10.8.0.0/24" -> "10.8.0"
    const base = subnet.split('/')[0];
    const parts = base.split('.');
    this.basePrefix = `${parts[0]}.${parts[1]}.${parts[2]}`;
  }

  public allocate(publicKey: string): string {
    if (this.allocatedIps.has(publicKey)) {
      return this.allocatedIps.get(publicKey)!;
    }

    // Find next free IP in pool (2 to 254)
    for (let i = 2; i <= 254; i++) {
      const candidateIndex = ((this.nextHostIndex + i - 2) % 253) + 2;
      const candidateIp = `${this.basePrefix}.${candidateIndex}`;

      if (!this.ipToPublicKey.has(candidateIp)) {
        this.nextHostIndex = (candidateIndex % 253) + 1;
        this.allocatedIps.set(publicKey, candidateIp);
        this.ipToPublicKey.set(candidateIp, publicKey);
        return candidateIp;
      }
    }

    throw new Error('IP Pool exhausted: No available virtual IPs on this node');
  }

  public release(publicKey: string): boolean {
    const ip = this.allocatedIps.get(publicKey);
    if (!ip) return false;

    this.allocatedIps.delete(publicKey);
    this.ipToPublicKey.delete(ip);
    return true;
  }

  public getIp(publicKey: string): string | undefined {
    return this.allocatedIps.get(publicKey);
  }

  public getAllAllocations(): Array<{ publicKey: string; ip: string }> {
    const result: Array<{ publicKey: string; ip: string }> = [];
    for (const [publicKey, ip] of this.allocatedIps.entries()) {
      result.push({ publicKey, ip });
    }
    return result;
  }
}
