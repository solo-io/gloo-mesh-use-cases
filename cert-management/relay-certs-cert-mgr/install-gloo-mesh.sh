#! /bin/bash

MGMT=mgmt
CLUSTER1=cluster1
CLUSTER2=cluster2

# Installing GM
helm install gloo-mesh-enterprise gloo-mesh-enterprise/gloo-mesh-enterprise \
  --kube-context ${MGMT} \
  --namespace gloo-mesh \
  --version 1.1.6 \
  --set licenseKey=${GLOO_MESH_LICENSE_KEY} \
  --set rbac-webhook.enabled=false \
  --set enterprise-networking.selfSigned=false \
  --set enterprise-networking.disableRelayCa=true

kubectl --context ${MGMT} -n gloo-mesh rollout status deploy/enterprise-networking

while [ -z "$SVC" ]; do 
SVC=$(kubectl --context ${MGMT} -n gloo-mesh get svc enterprise-networking \
  -o jsonpath='{.status.loadBalancer.ingress[0].*}') \
  && echo "waiting for GM LB IP" && sleep 5;
done

echo "found enterprise-networking IP: ${SVC}"

# Installing Agents
helm install enterprise-agent enterprise-agent/enterprise-agent \
  --kube-context=${CLUSTER1} \
  --namespace gloo-mesh \
  --set relay.serverAddress=${SVC}:9900 \
  --set relay.cluster=cluster1 \
  --version 1.1.6

helm install enterprise-agent enterprise-agent/enterprise-agent \
  --kube-context=${CLUSTER2} \
  --namespace gloo-mesh \
  --set relay.serverAddress=${SVC}:9900 \
  --set relay.cluster=cluster2 \
  --version 1.1.6

## Creating KubeCluster CRDs

kubectl apply --context ${MGMT} -f- <<EOF
apiVersion: multicluster.solo.io/v1alpha1
kind: KubernetesCluster
metadata:
  name: cluster1
  namespace: gloo-mesh
spec:
  clusterDomain: cluster.local
EOF

kubectl apply --context ${MGMT} -f- <<EOF
apiVersion: multicluster.solo.io/v1alpha1
kind: KubernetesCluster
metadata:
  name: cluster2
  namespace: gloo-mesh
spec:
  clusterDomain: cluster.local
EOF

