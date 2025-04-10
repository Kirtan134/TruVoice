import { NextApiRequest, NextApiResponse } from 'next';
import { collectDefaultMetrics, Counter, Histogram, register } from 'prom-client';

// Initialize the default metrics
collectDefaultMetrics();

// Define custom metrics
const httpRequestDuration = new Histogram({
  name: 'http_request_duration_seconds',
  help: 'Duration of HTTP requests in seconds',
  labelNames: ['method', 'route', 'status_code'],
  buckets: [0.1, 0.3, 0.5, 0.7, 1, 3, 5, 7, 10],
});

const httpRequestTotal = new Counter({
  name: 'http_requests_total',
  help: 'Total number of HTTP requests',
  labelNames: ['method', 'route', 'status_code'],
});

const voiceRecordingDuration = new Histogram({
  name: 'voice_recording_duration_seconds',
  help: 'Duration of voice recordings in seconds',
  labelNames: ['user_id'],
  buckets: [1, 5, 10, 30, 60, 120, 300, 600],
});

const authenticationAttempts = new Counter({
  name: 'authentication_attempts_total',
  help: 'Total number of authentication attempts',
  labelNames: ['status'],
});

// Example function to record metrics (to be used in your application)
export const recordHttpRequest = (method: string, route: string, statusCode: number, duration: number): void => {
  httpRequestDuration.labels(method, route, statusCode.toString()).observe(duration);
  httpRequestTotal.labels(method, route, statusCode.toString()).inc();
};

export const recordVoiceRecording = (userId: string, duration: number): void => {
  voiceRecordingDuration.labels(userId).observe(duration);
};

export const recordAuthenticationAttempt = (status: string): void => {
  authenticationAttempts.labels(status).inc();
};

export default async function handler(req: NextApiRequest, res: NextApiResponse): Promise<void> {
  try {
    res.setHeader('Content-Type', register.contentType);
    res.send(await register.metrics());
  } catch (err) {
    res.status(500).send(err);
  }
} 