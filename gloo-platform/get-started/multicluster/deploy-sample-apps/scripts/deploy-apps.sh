#!/usr/bin/env bash

# Preflight checks
if [[ -z "$CLUSTER1" ]]; then
  echo "CLUSTER1 is not set. Please set it to the name of the first data plane cluster."
  exit 1
fi

if [[ -z "$CLUSTER2" ]]; then
  echo "CLUSTER2 is not set. Please set it to the name of the second data plane cluster."
  exit 1
fi

REVISION=gloo

for cluster in "$CLUSTER1" "$CLUSTER2"; do
    kubectl --context "$cluster" create ns bookinfo
    kubectl --context "$cluster" label namespace bookinfo istio.io/rev=$REVISION --overwrite
done

# deploy bookinfo application components for all versions less than v3
kubectl -n bookinfo apply -f https://raw.githubusercontent.com/istio/istio/1.27.0/samples/bookinfo/platform/kube/bookinfo.yaml -l 'app,version notin (v3)' --context ${CLUSTER1}
# deploy an updated product page with extra container utilities such as 'curl' and 'netcat'
kubectl -n bookinfo apply -f https://raw.githubusercontent.com/solo-io/gloo-mesh-use-cases/main/policy-demo/productpage-with-curl.yaml --context ${CLUSTER1}
# deploy all bookinfo service accounts
kubectl -n bookinfo apply -f https://raw.githubusercontent.com/istio/istio/1.27.0/samples/bookinfo/platform/kube/bookinfo.yaml -l 'account' --context ${CLUSTER1}

# deploy reviews and ratings services
kubectl -n bookinfo apply -f https://raw.githubusercontent.com/istio/istio/1.27.0/samples/bookinfo/platform/kube/bookinfo.yaml -l 'service in (reviews)' --context ${CLUSTER2}
# deploy reviews-v3
kubectl -n bookinfo apply -f https://raw.githubusercontent.com/istio/istio/1.27.0/samples/bookinfo/platform/kube/bookinfo.yaml -l 'app in (reviews),version in (v3)' --context ${CLUSTER2}
# deploy ratings
kubectl -n bookinfo apply -f https://raw.githubusercontent.com/istio/istio/1.27.0/samples/bookinfo/platform/kube/bookinfo.yaml -l 'app in (ratings)' --context ${CLUSTER2}
# deploy reviews and ratings service accounts
kubectl -n bookinfo apply -f https://raw.githubusercontent.com/istio/istio/1.27.0/samples/bookinfo/platform/kube/bookinfo.yaml -l 'account in (reviews, ratings)' --context ${CLUSTER2}

# Deploy httpbin
kubectl create ns httpbin --context ${CLUSTER1}
kubectl label ns httpbin istio.io/rev=gloo --overwrite=true --context ${CLUSTER1}

kubectl -n httpbin apply -f https://raw.githubusercontent.com/solo-io/gloo-mesh-use-cases/main/policy-demo/httpbin.yaml --context ${CLUSTER1}

# Deploy hello world
kubectl create ns helloworld --context ${CLUSTER1}
kubectl label ns helloworld istio.io/rev=gloo --overwrite=true --context ${CLUSTER1}

kubectl create ns helloworld --context ${CLUSTER2}
kubectl label ns helloworld istio.io/rev=gloo --overwrite=true --context ${CLUSTER2}

kubectl -n helloworld apply --context ${CLUSTER1} -l 'service=helloworld' -f https://raw.githubusercontent.com/solo-io/gloo-mesh-use-cases/main/policy-demo/helloworld.yaml
kubectl -n helloworld apply --context ${CLUSTER1} -l 'app=helloworld,version in (v1, v2)' -f https://raw.githubusercontent.com/solo-io/gloo-mesh-use-cases/main/policy-demo/helloworld.yaml

kubectl -n helloworld apply --context ${CLUSTER2} -l 'service=helloworld' -f https://raw.githubusercontent.com/solo-io/gloo-mesh-use-cases/main/policy-demo/helloworld.yaml
kubectl -n helloworld apply --context ${CLUSTER2} -l 'app=helloworld,version in (v3, v4)' -f https://raw.githubusercontent.com/solo-io/gloo-mesh-use-cases/main/policy-demo/helloworld.yaml

