#!/bin/bash
set -e
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
K8S_DIR="$SCRIPT_DIR/../k8s"
kubectl apply -f "$K8S_DIR/namespaces/namespaces.yaml"
kubectl apply -f "$K8S_DIR/postgres/"
kubectl apply -f "$K8S_DIR/rabbitmq/"
kubectl wait --for=condition=ready pod -l app=postgres -n production --timeout=300s || true
kubectl wait --for=condition=ready pod -l app=rabbitmq -n production --timeout=300s || true
kubectl apply -f "$K8S_DIR/user-service/"
kubectl apply -f "$K8S_DIR/order-service/"
kubectl apply -f "$K8S_DIR/notification-service/"
kubectl apply -f "$K8S_DIR/ingress/"
kubectl apply -f "$K8S_DIR/rbac/"
kubectl apply -f "$K8S_DIR/network-policies/"
kubectl apply -f "$K8S_DIR/monitoring/"
kubectl rollout status deployment/user-service -n production --timeout=300s || true
kubectl rollout status deployment/order-service -n production --timeout=300s || true
kubectl rollout status deployment/notification-service -n production --timeout=300s || true
