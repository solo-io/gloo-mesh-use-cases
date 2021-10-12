#! /bin/bash

MGMT=mgmt
CLUSTER1=cluster1
CLUSTER2=cluster2

# Get latest from gloo-mesh-enterprise
helm repo add gloo-mesh-enterprise https://storage.googleapis.com/gloo-mesh-enterprise/gloo-mesh-enterprise
helm repo update

# Installing GM
helm install gloo-mesh-enterprise gloo-mesh-enterprise/gloo-mesh-enterprise \
  --kube-context ${MGMT} \
  --namespace gloo-mesh \
  --version 1.1.6 \
  --set licenseKey=${GLOO_MESH_LICENSE_KEY} \
  --set rbac-webhook.enabled=true \
  --set enterprise-networking.selfSigned=false \
  --set enterprise-networking.disableRelayCa=true \
  --set enterprise-networking.enterpriseNetworking.floatingUserId=true \
  --set rbac-webhook.rbacWebhook.floatingUserId=true \
  --set gloo-mesh-ui.dashboard.floatingUserId=true \
  --set gloo-mesh-ui.redis-dashboard.redisDashboard.floatingUserId=true \
  --set enterprise-networking.prometheus.server.securityContext=false \
  --set "rbac-webhook.adminSubjects[0].kind=User" \
  --set "rbac-webhook.adminSubjects[0].name=$(oc whoami)"

kubectl --context ${MGMT} -n gloo-mesh rollout status deploy/enterprise-networking

while [ -z "$SVC" ]; do 
SVC=$(kubectl --context ${MGMT} -n gloo-mesh get svc enterprise-networking \
  -o jsonpath='{.status.loadBalancer.ingress[0].*}') \
  && echo "waiting for GM LB IP" && sleep 5;
done

echo "found enterprise-networking IP: ${SVC}"

# Ensure latest enterprise agent helm chart 
helm repo add enterprise-agent https://storage.googleapis.com/gloo-mesh-enterprise/enterprise-agent
helm repo update

# Installing Agents
helm install enterprise-agent enterprise-agent/enterprise-agent \
  --kube-context=${CLUSTER1} \
  --namespace gloo-mesh \
  --set relay.serverAddress=${SVC}:9900 \
  --set relay.cluster=${CLUSTER1} \
  --set enterpriseAgent.floatingUserId=true \
  --version 1.1.6

helm install enterprise-agent enterprise-agent/enterprise-agent \
  --kube-context=${CLUSTER2} \
  --namespace gloo-mesh \
  --set relay.serverAddress=${SVC}:9900 \
  --set relay.cluster=${CLUSTER2} \
  --set enterpriseAgent.floatingUserId=true \
  --version 1.1.6

## Creating KubeCluster CRDs

kubectl apply --context ${MGMT} -f- <<EOF
apiVersion: multicluster.solo.io/v1alpha1
kind: KubernetesCluster
metadata:
  name: ${CLUSTER1}
  namespace: gloo-mesh
spec:
  clusterDomain: cluster.local
EOF

kubectl apply --context ${MGMT} -f- <<EOF
apiVersion: multicluster.solo.io/v1alpha1
kind: KubernetesCluster
metadata:
  name: ${CLUSTER2}
  namespace: gloo-mesh
spec:
  clusterDomain: cluster.local
EOF

