# Monitoring Setup for TruVoice

This directory contains Kubernetes manifests for setting up Prometheus and Grafana for monitoring the TruVoice application.

## Components

- **Prometheus**: Metrics collection and storage
- **Grafana**: Metrics visualization and dashboards
- **Node Exporter**: System metrics collection

## Configuration

### Prometheus

Prometheus is configured to scrape metrics from:

- Kubernetes pods with Prometheus annotations
- The TruVoice application metrics endpoint (`/api/metrics`)
- Node Exporter for system metrics

### Grafana

Grafana is configured with:

- Prometheus as the default data source
- A custom dashboard for TruVoice metrics
- NodePort service for external access

## Accessing the Monitoring Stack

### Prometheus

Access Prometheus at: `http://<your-server-ip>:30090`

### Grafana

Access Grafana at: `http://<your-server-ip>:30300`

Default credentials:
- Username: `admin`
- Password: `admin123` (change this in production!)

## Metrics

The TruVoice application exposes the following metrics:

- `http_requests_total`: Total number of HTTP requests
- `http_request_duration_seconds`: Duration of HTTP requests
- `voice_recording_duration_seconds`: Duration of voice recordings
- `authentication_attempts_total`: Total number of authentication attempts

## Deployment

To deploy the monitoring stack:

```bash
# Create the monitoring namespace
kubectl apply -f namespace.yaml

# Deploy Prometheus
kubectl apply -f prometheus-config.yaml
kubectl apply -f prometheus.yaml

# Deploy Grafana
kubectl apply -f grafana-datasource.yaml
kubectl apply -f grafana-dashboard.yaml
kubectl apply -f grafana.yaml
```

## Troubleshooting

If you encounter issues with the monitoring stack:

1. Check if the pods are running:
   ```bash
   kubectl get pods -n monitoring
   ```

2. Check the logs:
   ```bash
   kubectl logs -n monitoring <pod-name>
   ```

3. Verify the services:
   ```bash
   kubectl get svc -n monitoring
   ```

4. Check if Prometheus can scrape the metrics:
   ```bash
   kubectl port-forward -n monitoring svc/prometheus 9090:9090
   ```
   Then access `http://localhost:9090/targets` in your browser.

5. Check if Grafana can connect to Prometheus:
   ```bash
   kubectl port-forward -n monitoring svc/grafana 3000:3000
   ```
   Then access `http://localhost:3000` in your browser and check the data sources. 