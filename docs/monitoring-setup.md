# TruVoice Monitoring Setup

This document provides a comprehensive guide to the monitoring setup for the TruVoice application using Prometheus and Grafana.

## Overview

The monitoring stack consists of:

1. **Prometheus**: For metrics collection and storage
2. **Grafana**: For metrics visualization and dashboards
3. **Node Exporter**: For system metrics collection
4. **Application Metrics**: Custom metrics exposed by the TruVoice application

## Architecture

```
┌─────────────┐     ┌─────────────┐     ┌─────────────┐
│             │     │             │     │             │
│  TruVoice   │◄────┤ Prometheus  │◄────┤   Grafana   │
│  Application│     │             │     │             │
│             │     │             │     │             │
└─────────────┘     └─────────────┘     └─────────────┘
       ▲                    ▲
       │                    │
       ▼                    ▼
┌─────────────┐     ┌─────────────┐
│             │     │             │
│  Node       │     │  Kubernetes │
│  Exporter   │     │  API        │
│             │     │             │
└─────────────┘     └─────────────┘
```

## Components

### Prometheus

Prometheus is deployed in the `monitoring` namespace and configured to scrape metrics from:

- Kubernetes pods with Prometheus annotations
- The TruVoice application metrics endpoint (`/api/metrics`)
- Node Exporter for system metrics

The Prometheus service is exposed as a NodePort on port 30090 for external access.

### Grafana

Grafana is deployed in the `monitoring` namespace and configured with:

- Prometheus as the default data source
- A custom dashboard for TruVoice metrics
- NodePort service on port 30300 for external access

### Node Exporter

Node Exporter is deployed to collect system metrics from the Kubernetes nodes.

### Application Metrics

The TruVoice application exposes the following metrics:

- `http_requests_total`: Total number of HTTP requests
- `http_request_duration_seconds`: Duration of HTTP requests
- `voice_recording_duration_seconds`: Duration of voice recordings
- `authentication_attempts_total`: Total number of authentication attempts

## Deployment

### Prerequisites

- Kubernetes cluster with kubectl configured
- Access to the cluster with sufficient permissions

### Deployment Steps

1. Create the monitoring namespace:
   ```bash
   kubectl apply -f k8s/monitoring/namespace.yaml
   ```

2. Deploy Prometheus:
   ```bash
   kubectl apply -f k8s/monitoring/prometheus-config.yaml
   kubectl apply -f k8s/monitoring/prometheus.yaml
   ```

3. Deploy Grafana:
   ```bash
   kubectl apply -f k8s/monitoring/grafana-datasource.yaml
   kubectl apply -f k8s/monitoring/grafana-dashboard.yaml
   kubectl apply -f k8s/monitoring/grafana.yaml
   ```

4. Verify the deployment:
   ```bash
   kubectl get pods -n monitoring
   kubectl get svc -n monitoring
   ```

## Accessing the Monitoring Stack

### Prometheus

Access Prometheus at: `http://<your-server-ip>:30090`

### Grafana

Access Grafana at: `http://<your-server-ip>:30300`

Default credentials:
- Username: `admin`
- Password: `admin123` (change this in production!)

## Grafana Dashboards

The TruVoice dashboard includes the following panels:

1. **HTTP Request Rate**: Shows the rate of HTTP requests by method, route, and status code
2. **HTTP Request Duration**: Shows the average duration of HTTP requests by method, route, and status code
3. **Voice Recording Duration**: Shows the average duration of voice recordings by user
4. **Authentication Attempts**: Shows the rate of authentication attempts by status

## Troubleshooting

### Prometheus Issues

1. Check if Prometheus is running:
   ```bash
   kubectl get pods -n monitoring -l app=prometheus
   ```

2. Check Prometheus logs:
   ```bash
   kubectl logs -n monitoring -l app=prometheus
   ```

3. Check if Prometheus can scrape the metrics:
   ```bash
   kubectl port-forward -n monitoring svc/prometheus 9090:9090
   ```
   Then access `http://localhost:9090/targets` in your browser.

### Grafana Issues

1. Check if Grafana is running:
   ```bash
   kubectl get pods -n monitoring -l app=grafana
   ```

2. Check Grafana logs:
   ```bash
   kubectl logs -n monitoring -l app=grafana
   ```

3. Check if Grafana can connect to Prometheus:
   ```bash
   kubectl port-forward -n monitoring svc/grafana 3000:3000
   ```
   Then access `http://localhost:3000` in your browser and check the data sources.

### Application Metrics Issues

1. Check if the metrics endpoint is accessible:
   ```bash
   kubectl port-forward svc/truvoice-service 3000:3000
   curl http://localhost:3000/api/metrics
   ```

2. Check if the application is generating metrics:
   ```bash
   kubectl logs -l app=truvoice
   ```

## Security Considerations

1. **Change Default Passwords**: Change the default Grafana admin password in production.
2. **Restrict Access**: Use network policies to restrict access to the monitoring stack.
3. **TLS**: Enable TLS for Prometheus and Grafana in production.
4. **Authentication**: Enable authentication for Prometheus in production.

## Maintenance

### Updating Prometheus

1. Update the Prometheus image:
   ```bash
   kubectl set image deployment/prometheus -n monitoring prometheus=prom/prometheus:latest
   ```

2. Verify the update:
   ```bash
   kubectl rollout status deployment/prometheus -n monitoring
   ```

### Updating Grafana

1. Update the Grafana image:
   ```bash
   kubectl set image deployment/grafana -n monitoring grafana=grafana/grafana:latest
   ```

2. Verify the update:
   ```bash
   kubectl rollout status deployment/grafana -n monitoring
   ```

### Backup and Restore

1. Backup Prometheus data:
   ```bash
   kubectl exec -n monitoring -it $(kubectl get pods -n monitoring -l app=prometheus -o jsonpath='{.items[0].metadata.name}') -- tar -czf /tmp/prometheus-data.tar.gz /prometheus
   kubectl cp monitoring/$(kubectl get pods -n monitoring -l app=prometheus -o jsonpath='{.items[0].metadata.name}'):/tmp/prometheus-data.tar.gz ./prometheus-data.tar.gz
   ```

2. Restore Prometheus data:
   ```bash
   kubectl cp ./prometheus-data.tar.gz monitoring/$(kubectl get pods -n monitoring -l app=prometheus -o jsonpath='{.items[0].metadata.name}'):/tmp/prometheus-data.tar.gz
   kubectl exec -n monitoring -it $(kubectl get pods -n monitoring -l app=prometheus -o jsonpath='{.items[0].metadata.name}') -- tar -xzf /tmp/prometheus-data.tar.gz -C /
   ```

## Conclusion

This monitoring setup provides comprehensive visibility into the TruVoice application, allowing you to monitor its performance, identify issues, and make data-driven decisions for improvements. 