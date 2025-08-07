#!/usr/bin/env bash
set -euo pipefail

NS="${NS:-nr-entain}"
printf '%-12s %-45s %s\n' "KIND" "NAME" "ANTI_AFFINITY"

for KIND in deployment statefulset replicaset; do
  kubectl get "$KIND" -n "$NS" -o json | \
    jq -r --arg kind "$KIND" '
      .items[] |
      "\($kind)\t\(.metadata.name)\t\((.spec.template.spec.affinity.podAntiAffinity != null))"
    '
done | sort | column -t