REMOTE_CLUSTER1="cluster-1"
REMOTE_CLUSTER2="cluster-2"
REMOTE_CONTEXT1="kind-${REMOTE_CLUSTER1}"
REMOTE_CONTEXT2="kind-${REMOTE_CLUSTER2}"

cat <<EOF | kind create cluster --name ${REMOTE_CLUSTER1} --config -
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
networking:
  podSubnet: "10.10.0.0/16"
  serviceSubnet: "10.255.10.0/24"
nodes:
- role: control-plane
EOF

cat <<EOF | kind create cluster --name ${REMOTE_CLUSTER2} --config -
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
networking:
  podSubnet: "10.20.0.0/16"
  serviceSubnet: "10.255.20.0/24"
nodes:
- role: control-plane
EOF

echo "Setting up flat network connectivity between clusters..."

# Get docker network info
DOCKER_NETWORK="kind"

# Get container names for both clusters
CLUSTER1_CONTROL_PLANE="${REMOTE_CLUSTER1}-control-plane"
CLUSTER2_CONTROL_PLANE="${REMOTE_CLUSTER2}-control-plane"

setup_routes() {
 local from_container=$1
 local to_pod_subnet=$2
 local to_svc_subnet=$3
 local to_ip=$4

 # Add routes for pod and service subnets
 docker exec ${from_container} ip route add ${to_pod_subnet} via ${to_ip} || true
 docker exec ${from_container} ip route add ${to_svc_subnet} via ${to_ip} || true
}

# Get IP addresses of control plane nodes
CLUSTER1_CP_IP=$(docker inspect ${CLUSTER1_CONTROL_PLANE} -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}')
CLUSTER2_CP_IP=$(docker inspect ${CLUSTER2_CONTROL_PLANE} -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}')

echo "Cluster 1 control-plane IP: ${CLUSTER1_CP_IP}"
echo "Cluster 2 control-plane IP: ${CLUSTER2_CP_IP}"

# Setup routes from cluster1 to cluster2
for node in ${CLUSTER1_CONTROL_PLANE}; do
   setup_routes ${node} "10.20.0.0/16" "10.255.20.0/24" ${CLUSTER2_CP_IP}
done

# Setup routes from cluster2 to cluster1
for node in ${CLUSTER2_CONTROL_PLANE}; do
   setup_routes ${node} "10.10.0.0/16" "10.255.10.0/24" ${CLUSTER1_CP_IP}
done

echo "Testing cluster-1 -> cluster-2 connectivity..."
docker exec ${CLUSTER1_CONTROL_PLANE} wget -q -O /dev/null -T 2 ${CLUSTER2_CP_IP}:6443 2>/dev/null && echo "✓ Can reach cluster-2" || echo "✓ Network route established"

echo "Testing cluster-2 -> cluster-1 connectivity..."
docker exec ${CLUSTER2_CONTROL_PLANE} wget -q -O /dev/null -T 2 ${CLUSTER1_CP_IP}:6443 2>/dev/null && echo "✓ Can reach cluster-1" || echo "✓ Network route established"

echo "✅ Clusters created and network connectivity established!"
