# In Mesh use cases

### Multi Cluster

This is the multi-cluster setup we will be utilizing. 

![](./multi-cluster-ptp.png)

## Gloo Mesh Enterprise 1.x

### Traffic Policy

#### 1. Selectors
* 1.1 Source Selector
  * 1.1.1 Labels
  * 1.1.2 Namespace / Clusters
* 1.2 Destination Selector
  * 1.2.1 kubeServiceMatcher
  * 1.2.2 kubeServiceRefs
  * 1.2.3 virtualDestinationMatcher
  * 1.2.4 virtualDestinationRefs
  * 1.2.5 externalServiceMatcher - https://github.com/solo-io/gloo-mesh-enterprise/issues/2142
  * 1.2.6 externalServiceRefs - https://github.com/solo-io/gloo-mesh-enterprise/issues/2142

#### 2. Route Selectors - Skipped due to alternatives in VirtualHost/VirtualGateway/RouteTable

#### 3. HTTP Request Matchers
- 3.1 URI
  - 3.1.1 Exact match
  - 3.1.2 Prefix match
  - 3.1.3 Regex match
  - 3.1.4 Ignore case match
- 3.2 Header-based matching
  - 3.2.1 Name match
  - 3.2.2 Name/Value match
  - 3.2.3 Name/Regex match
  - 3.2.4 Invert match
- 3.3 Query parameter matching
  - 3.3.1 Key/Value match
  - 3.3.2 Regex match
- 3.4 HTTP method matching

#### 4. Connection Pool Settings
- 4.1 HTTP
  - 4.1.1 http1MaxPendingRequests
  - 4.1.2 http2MaxRequests
  - 4.1.3 maxRequestsPerConnection
  - 4.1.4 maxRetries
  - 4.1.5 idleTimeout
  - 4.1.6 h2UpgradePolicyH2UpgradePolicy 		
  - 4.1.7 useClientProtocol
- 4.2 TCP
  - 4.2.1 maxConnections
  - 4.2.2 connectTimeout
  - 4.2.3 tcpKeepalive

#### 5. Traffic Shift
- 5.1 Weighted destination

#### 6. Fault Injection
- 6.1 Delaying requests
- 6.2 Aborting requests
- 6.3 Faults for percentage of traffic

#### 7. Request Timeout / Retries
- 7.1 Timeouts
- 7.2 Retries

#### 8. CORS
- 8.1 Setting allowed origins
- 8.2 Allowed methods & headers
- 8.3 Exposed headers
- 8.4 Preflight request caching
- 8.5 Access-Control-Allow-Credentials

#### 9. Mirroring
- 9.1 Send percentage of traffic to mirrored destination (kubeService only)

#### 10. Header Manipulation
- 10.1 Request headers
  - 10.1.1 Add request header
  - 10.1.2 Remove request header
- 10.2 Response headers
  - 10.2.1 Add response header
  - 10.2.2 Remove response header

#### 11. Outlier Detection
- 11.1 Outlier Detection for failover routing to a global destination

#### 12. mTLS
- 12.1 Setting mTLS settings per destination

#### 13. CSRF
- 13.1 Setting CSRF policy
- 13.2 Setting CSRF policy

#### 14. Rate Limit
- 14.1 Using raw Rate Limit definition
- 14.2 Rate Limit on source cluster  (TODO does this make sense)
- 14.3 Rate Limit on destination cluster (TODO use istio cluster name?)
- 14.4 Rate Limit on request headers
- 14.5 Rate Limit on remote address
- 14.6 Rate Limit on generic key
- 14.7 Rate Limit on the existence of a requst header
- 14.8 Rate Limit on metadata
- 14.9 Using separate Rate Limit config

#### 15. Ext Auth
- 15.1 Using a custom auth server
- 15.2 OIDC with AuthConfig
- 15.2 Using an API token

### Virtual Destination

#### 1. Hostname
- 1.1 Custom hostname
- 1.2 Override kube service

#### 2. Port Selection
- 2.1 Custom port

#### 3. Mesh Selection
- 3.1 Single mesh
- 3.2 Multi-Mesh

#### 4. Static Destination
- 4.1 Static destinations

#### 5. Locality
- 5.1 Outlier detection
- 5.2 Failover

### Access Policy

#### 1. Source Selection
- 1.1 kubeIdentityMatcher
- 1.2 kubeServiceAccountRefs
- 1.3 requestIdentityMatcher
  - 1.3.1 requestPrincipals
  - 1.3.2 notRequestPrincipals

#### 2. Destination Selection
- 2.1 kubeServiceMatcher
- 2.2 kubeServiceRefs
- 2.3 virtualDestinationMatcher
- 2.4 virtualDestinationRefs
- 2.5 externalServiceMatcher
- 2.6 externalServiceRefs

#### 3. Allowed
- 3.1 Paths
- 3.2 Methods
- 3.3 Ports

### Service Dependencies
- 1.1 Namespace selection
- 1.2 Cluster selection
- 1.3 Label selectors