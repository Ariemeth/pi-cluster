#!/usr/bin/env bash

set -e

SOURCE="${BASH_SOURCE[0]}"
while [ -h "$SOURCE" ]; do SOURCE="$(readlink "$SOURCE")"; done
ROOT_DIR="$(cd -P "$(dirname "$SOURCE")/.." && pwd)"

CONFIG_DIR=$ROOT_DIR/configs
CHART_DIR=$ROOT_DIR/charts

# Add references to 3rd party charts
helm repo add traefik https://helm.traefik.io/traefik
helm repo add openebs https://openebs.github.io/charts
helm repo add jetstack https://charts.jetstack.io

helm repo update

# Create the namespaces.
kubectl apply -f $CONFIG_DIR/growingsewfast/namespace.yaml
kubectl apply -f $CONFIG_DIR/metadiversions/namespace.yaml
kubectl apply -f $CONFIG_DIR/ingress/namespace.yaml
kubectl create namespace openebs
kubectl create namespace cert-manager

# Install OpenEBS
helm upgrade --install \
  --namespace openebs \
  openebs \
  openebs/openebs \
  --version "2.3.0"

# Install the ingress controller.
helm upgrade --install \
  -f $CONFIG_DIR/ingress/traefik-controller.yaml \
  -n ingress \
  traefik \
  traefik/traefik \
  --version "9.11.0"

helm upgrade --install \
  -n cert-manager \
  cert-manager \
  jetstack/cert-manager \
  --set installCRDs=true \
  --version "v1.1.0"

# Install the simpleweb service in the metadiversions namespace.
helm upgrade --install \
  -n metadiversions \
  sw1 \
  $CHART_DIR/simpleweb

# Install the simpleweb service in the growingsewfast namespace.
helm upgrade --install \
  -n growingsewfast \
  sw1 \
  $CHART_DIR/simpleweb

# Get certificates
kubectl apply -f $CONFIG_DIR/le-production.yaml
kubectl -n metadiversions apply -f $CONFIG_DIR/metadiversions/le-cert.yaml
kubectl -n growingsewfast apply -f $CONFIG_DIR/growingsewfast/le-cert.yaml

# Install the ingresses for metadiversions.com
kubectl apply \
  -f $CONFIG_DIR/metadiversions/ingressRoute.yaml \
  -n metadiversions

# Install the ingresses for growingsewfast.com
kubectl apply \
  -f $CONFIG_DIR/growingsewfast/ingressRoute.yaml \
  -n growingsewfast

