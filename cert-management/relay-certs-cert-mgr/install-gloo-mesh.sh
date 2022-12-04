#! /bin/bash

MGMT=mgmt
CLUSTER1=cluster1
CLUSTER2=cluster2

GLOO_MESH_VERSION=2.1.0

# Installing GM
helm install gloo-mesh-enterprise gloo-mesh-enterprise/gloo-mesh-enterprise \
  --kube-context ${MGMT} \
  --namespace gloo-mesh \
  --version ${GLOO_MESH_VERSION} \
  --set licenseKey=${GLOO_MESH_LICENSE_KEY} \
  --set rbac-webhook.enabled=false \
  --set glooMeshMgmtServer.relay.disableCaCertGeneration=true \
  --set glooMeshMgmtServer.relay.disableCa=true


kubectl --context ${MGMT} -n gloo-mesh rollout status deploy/gloo-mesh-mgmt-server

while [ -z "$SVC" ]; do 
SVC=$(kubectl --context ${MGMT} -n gloo-mesh get svc gloo-mesh-mgmt-server \
  -o jsonpath='{.status.loadBalancer.ingress[0].*}') \
  && echo "waiting for GM LB IP" && sleep 5;
done

echo "found enterprise-networking IP: ${SVC}"

# Installing Agents
helm upgrade --install gloo-mesh-agent gloo-mesh-agent/gloo-mesh-agent \
  --kube-context=${CLUSTER1} \
  --namespace gloo-mesh \
  --set relay.serverAddress=${SVC}:9900 \
  --set relay.cluster=cluster1 \
  --version ${GLOO_MESH_VERSION}

helm upgrade --install gloo-mesh-agent gloo-mesh-agent/gloo-mesh-agent \
  --kube-context=${CLUSTER2} \
  --namespace gloo-mesh \
  --set relay.serverAddress=${SVC}:9900 \
  --set relay.cluster=cluster2 \
  --version ${GLOO_MESH_VERSION}

## Creating KubeCluster CRDs

kubectl apply --context ${MGMT} -f- <<EOF
apiVersion: admin.gloo.solo.io/v2
kind: KubernetesCluster
metadata:
  name: cluster1
  namespace: gloo-mesh
spec:
  clusterDomain: cluster.local
EOF

kubectl apply --context ${MGMT} -f- <<EOF
apiVersion: admin.gloo.solo.io/v2
kind: KubernetesCluster
metadata:
  name: cluster2
  namespace: gloo-mesh
spec:
  clusterDomain: cluster.local
EOF

