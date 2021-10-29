#!/bin/bash

if [[ "${PWD}" == *scripts ]]; then
  cd ..
fi

kubectl --context ${CLUSTER1} rollout restart deploy -n istio-system
kubectl --context ${CLUSTER1} rollout restart deploy 
kubectl --context ${CLUSTER2} rollout restart deploy -n istio-system
kubectl --context ${CLUSTER2} rollout restart deploy 
