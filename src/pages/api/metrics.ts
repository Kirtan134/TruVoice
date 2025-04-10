import { collectDefaultMetrics, register } from 'prom-client';

// Initialize the default metrics
collectDefaultMetrics();

export default async function handler(req, res) {
  try {
    res.setHeader('Content-Type', register.contentType);
    res.send(await register.metrics());
  } catch (err) {
    res.status(500).send(err);
  }
} 