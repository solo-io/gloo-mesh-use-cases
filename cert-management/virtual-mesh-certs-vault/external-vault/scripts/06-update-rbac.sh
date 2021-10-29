#!/bin/bash

for cluster in ${CLUSTER1} ${CLUSTER2}; do
  helm upgrade -n gloo-mesh enterprise-agent enterprise-agent/enterprise-agent --kube-context="${cluster}" -f ${cluster}-values.yaml
  rm $cluster-values.yaml
done

MGMT_PLANE_VERSION=$(meshctl version | jq '.server[].components[] | select(.componentName == "enterprise-networking") | .images[] | select(.name == "enterprise-networking") | .version')

for cluster in ${CLUSTER1} ${CLUSTER2}; do
  
  kubectl patch --context $cluster -n istio-system deploy/istiod --patch '{
	"spec": {
			"template": {
				"spec": {
						"initContainers": [
							{
									"args": [
										"init-container"
									],
									"env": [
										{
												"name": "PILOT_CERT_PROVIDER",
												"value": "istiod"
										},
										{
												"name": "POD_NAME",
												"valueFrom": {
													"fieldRef": {
															"apiVersion": "v1",
															"fieldPath": "metadata.name"
													}
												}
										},
										{
												"name": "POD_NAMESPACE",
												"valueFrom": {
													"fieldRef": {
															"apiVersion": "v1",
															"fieldPath": "metadata.namespace"
													}
												}
										},
										{
												"name": "SERVICE_ACCOUNT",
												"valueFrom": {
													"fieldRef": {
															"apiVersion": "v1",
															"fieldPath": "spec.serviceAccountName"
													}
												}
										}
									],
									"volumeMounts": [
										{
												"mountPath": "/etc/cacerts",
												"name": "cacerts"
										}
									],
									"imagePullPolicy": "IfNotPresent",
									"image": "gcr.io/gloo-mesh/istiod-agent:$MGMT_PLANE_VERSION",
									"name": "istiod-agent-init"
							}
						],
						"containers": [
							{
									"args": [
										"sidecar"
									],
									"env": [
										{
												"name": "PILOT_CERT_PROVIDER",
												"value": "istiod"
										},
										{
												"name": "POD_NAME",
												"valueFrom": {
													"fieldRef": {
															"apiVersion": "v1",
															"fieldPath": "metadata.name"
													}
												}
										},
										{
												"name": "POD_NAMESPACE",
												"valueFrom": {
													"fieldRef": {
															"apiVersion": "v1",
															"fieldPath": "metadata.namespace"
													}
												}
										},
										{
												"name": "SERVICE_ACCOUNT",
												"valueFrom": {
													"fieldRef": {
															"apiVersion": "v1",
															"fieldPath": "spec.serviceAccountName"
													}
												}
										}
									],
									"volumeMounts": [
										{
												"mountPath": "/etc/cacerts",
												"name": "cacerts"
										}
									],
									"imagePullPolicy": "IfNotPresent",
									"image": "gcr.io/gloo-mesh/istiod-agent:$MGMT_PLANE_VERSION",
									"name": "istiod-agent"
							}
						],
						"volumes": [
							{
									"name": "cacerts",
									"secret": null,
									"emptyDir": {
										"medium": "Memory"
									}
							}
						]
				}
			}
	}
  }'

done
