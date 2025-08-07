#!/usr/bin/env bash
set -euo pipefail
NS="${NS:-nr-entain}"

# Header
printf '%-12s %-45s %-20s %s\n' "KIND" "NAME" "ZONES(seen)" "OK?"

# Pull all Pods once
kubectl get pods -n "$NS" -o json |
jq -r '
  .items[] |
  {
    kind:      (.metadata.ownerReferences[0].kind   // "Pod"),
    name:      (.metadata.ownerReferences[0].name   // .metadata.name),
    zone:      (.metadata.labels["topology.kubernetes.io/zone"]
                // .metadata.labels["failure-domain.beta.kubernetes.io/zone"]
                // "unknown")
  } |
  "\(.kind)\t\(.name)\t\(.zone)"
' |
# Aggregate zones per controller
awk -F'\t' '
  {
    key=$1":"$2
    zones[key][$3]=1
  }
  END {
    PROCINFO["sorted_in"]="@ind_str_asc"
    for (k in zones) {
      split(k,a,":"); kind=a[1]; name=a[2]
      zlist=""; count=0
      for (z in zones[k]) { zlist=zlist z ","; count++ }
      sub(/,$/,"",zlist)
      status=(count>1?"✅":"❌")
      printf "%-12s %-45s %-20s %s\n", kind, name, zlist, status
    }
  }' | sort | column -t
