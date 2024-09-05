#!/bin/bash

# ****************************************************
# Licensed Materials - Property of HCL.
# (c) Copyright HCL Technologies Ltd. 2017, 2024.
# Note to U.S. Government Users *Restricted Rights.
# ****************************************************

main() {
  echo "installing Secagent webhook..."

  user_config_path="./configs/user-config.json"
  asoc_config_path="./configs/asoc-config.json"

  user_config_default_value='{}'
  asoc_config_default_value='{"accessToken": "","host": ""}'
  NAMESPACE="secagent"

  if kubectl get namespace "$NAMESPACE" > /dev/null 2>&1; then
    echo "Error - Namespace $NAMESPACE already exists. Exiting installation."
    echo "To reinstall, first uninstall the existing deployment using uninstall-secagent-webhook.sh"
    exit_with_pause
  fi

  kubectl create namespace $NAMESPACE
  create_configmap "$user_config_path" "user-config" "$user_default_value"
  create_configmap "$asoc_config_path" "asoc-config" "$asoc_default_value"


  kubectl apply -f configs/rbac.yaml || exit_with_pause
  kubectl apply -f configs/deployment.yaml || exit_with_pause
  kubectl apply -f configs/service.yaml || exit_with_pause

  echo "Waiting for webhook to be ready..."

  wait_for_webhook_pod_creation

  # wait for webhook pod to be ready:
  kubectl wait --for=condition=Ready pod -l app=secagent-mutating-webhook -n $NAMESPACE --timeout=500s && success=true || success=false

  if [ "$success" = true ]; then
     echo "Secagent webhook is ready!"
  else
     echo "Failed to install Secagent webhook"
  fi

  if [ "$1" != "--silent-run" ]; then
      exit_with_pause
  else
      exit
  fi
}

create_configmap() {
  local config_path=$1
  local config_name=$2
  local default_value=$3

  if [ -f "$config_path" ]; then
    kubectl create configmap "$config_name" --from-file="$config_path" -n secagent
    echo "Using $config_name"
  else
    kubectl create configmap "$config_name" --from-literal="$config_name.json=$default_value" -n secagent
    echo "Using empty $config_name"
  fi
}

wait_for_webhook_pod_creation() {
  timeout=20
  sleep_time=2
  while [ $timeout -gt 0 ] && ! is_webhook_pod_created; do
      sleep $sleep_time
      timeout=$((timeout - sleep_time))
  done
}

is_webhook_pod_created() {
    if kubectl get pods -n $NAMESPACE 2>/dev/null | grep "secagent-mutating-webhook" >/dev/null; then
      return 0
    else
      return 1
    fi
}

exit_with_pause() {
  read -n 1 -s -r -p "Press any key to exit"
  exit
}

main "$@"; exit
