#!/bin/bash

# ****************************************************
# Licensed Materials - Property of HCL.
# (c) Copyright HCL Technologies Ltd. 2017, 2024.
# Note to U.S. Government Users *Restricted Rights.
# ****************************************************

main() {
  echo "uninstalling Secagent webhook..."

  kubectl delete deployment secagent-mutating-webhook -n secagent
  kubectl delete service secagent-mutating-webhook -n secagent
  kubectl delete configmap user-config -n secagent
  kubectl delete configmap asoc-config -n secagent
  kubectl delete MutatingWebhookConfiguration secagent-mutating-webhook
  kubectl delete ClusterRole secagent-mutating-webhook
  kubectl delete ClusterRoleBinding secagent-mutating-webhook
  kubectl delete ServiceAccount secagent-mutating-webhook -n secagent
  kubectl delete namespace secagent
  if [ "$1" != "--silent-run" ]; then
      read -n 1 -s -r -p "Press any key to exit"
  fi

}

main "$@"; exit
