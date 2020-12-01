#!/usr/bin/env bash

set -e

SOURCE="${BASH_SOURCE[0]}"
while [ -h "$SOURCE" ]; do SOURCE="$(readlink "$SOURCE")"; done
ROOT_DIR="$(cd -P "$(dirname "$SOURCE")/.." && pwd)"

CONFIG_DIR=$ROOT_DIR/configs
CHART_DIR=$ROOT_DIR/charts

# Create the namespaces.
kubectl apply -f $CONFIG_DIR/growingsewfast/namespace.yaml
kubectl apply -f $CONFIG_DIR/metadiversions/namespace.yaml
kubectl apply -f $CONFIG_DIR/ingress/namespace.yaml


# Install the ingress controller.
helm upgrade --install \
  -f $CONFIG_DIR/ingress/traefik-controller.yaml \
  -n ingress \
  traefik \
  $CHART_DIR/traefik 

# Install the simpleweb service.
helm upgrade --install \
  -n metadiversions \
  sw1 \
  $CHART_DIR/simpleweb

# Install the ingresses
kubectl apply \
  -f $CONFIG_DIR/metadiversions/ingress.yaml \
  -n metadiversions
