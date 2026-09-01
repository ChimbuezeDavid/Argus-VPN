class DnsOption {
  final String id;
  final String name;
  final String description;
  final List<String> servers;
  final String category; // 'standard', 'security', 'family', 'custom'

  const DnsOption({
    required this.id,
    required this.name,
    required this.description,
    required this.servers,
    required this.category,
  });

  static const List<DnsOption> presetOptions = [
    DnsOption(
      id: 'argus_shield',
      name: 'Argus Shield (Auto-Filter)',
      description: 'Intelligently adapts DNS resolvers to match your Shield toggles',
      servers: ['94.140.14.14', '1.1.1.2'],
      category: 'security',
    ),
    DnsOption(
      id: 'cloudflare',
      name: 'Cloudflare DNS',
      description: 'Ultra-fast resolution with strict privacy (No logs)',
      servers: ['1.1.1.1', '1.0.0.1'],
      category: 'standard',
    ),
    DnsOption(
      id: 'google',
      name: 'Google Public DNS',
      description: 'Global, resilient and reliable resolution by Google',
      servers: ['8.8.8.8', '8.8.4.4'],
      category: 'standard',
    ),
    DnsOption(
      id: 'quad9',
      name: 'Quad9 Security DNS',
      description: 'Blocks malicious domains, botnets, and phishing scams',
      servers: ['9.9.9.9', '149.112.112.112'],
      category: 'security',
    ),
    DnsOption(
      id: 'adguard',
      name: 'AdGuard DNS',
      description: 'Blocks intrusive ads, popups, and user-tracking networks',
      servers: ['94.140.14.14', '94.140.15.15'],
      category: 'security',
    ),
    DnsOption(
      id: 'cloudflare_family',
      name: 'Cloudflare 1.1.1.3 Family',
      description: 'Blocks malware and explicit adult / pornographic sites',
      servers: ['1.1.1.3', '1.0.0.3'],
      category: 'family',
    ),
    DnsOption(
      id: 'cleanbrowsing_adult',
      name: 'CleanBrowsing Adult Filter',
      description: 'Strict filtering for adult content and gambling sites',
      servers: ['185.228.168.10', '185.228.169.11'],
      category: 'family',
    ),
    DnsOption(
      id: 'custom',
      name: 'Custom DNS Server',
      description: 'Enter your preferred primary and secondary DNS server IPs',
      servers: [],
      category: 'custom',
    ),
  ];
}
