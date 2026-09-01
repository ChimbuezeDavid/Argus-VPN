export interface NodeMetrics {
  nodeId: string;
  timestamp: number;
  cpuUsagePercent: number;
  memoryUsagePercent: number;
  activePeers: number;
  rxBytesTotal: number;
  txBytesTotal: number;
  rxBytesPerSec: number;
  txBytesPerSec: number;
}

export interface ClientConnectionStats {
  bytesReceived: number;
  bytesSent: number;
  durationSeconds: number;
  currentDownloadSpeedBps: number;
  currentUploadSpeedBps: number;
  lastHandshakeTimestamp?: number;
}
