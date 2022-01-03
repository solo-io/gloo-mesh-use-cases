# Point to Point use cases


### Multi Cluster

This is the multi-cluster setup we will be utilizing. 

![](./multi-cluster-ptp.png)


## Gloo Mesh Enterprise 1.x


### Traffic Policy

#### 1. Selectors
* Source Selector
  * Labels
  * Namespace / Clusters
* Destination Selector
  * kubeServiceMatcher
  * kubeServiceRefs
  * virtualDestinationMatcher
  * virtualDestinationRefs
  * externalServiceMatcher - https://github.com/solo-io/gloo-mesh-enterprise/issues/2142
  * externalServiceRefs - https://github.com/solo-io/gloo-mesh-enterprise/issues/2142

#### 2. Route Selectors - Skipped due to alternatives in VirtualHost/VirtualGateway/RouteTable

#### 3. HTTP Request Matchers
- URI
- Headers
- Query Parameters
- Methods

#### 4. Connection Pool Settings
- HTTP
  - http1MaxPendingRequests
  - http2MaxRequests
  - maxRequestsPerConnection
  - maxRetries
  - idleTimeout
  - h2UpgradePolicyH2UpgradePolicy 		
  - useClientProtocol
- TCP
  - maxConnections
  - connectTimeout
  - tcpKeepalive

#### 5. Traffic Shift
- Weighted Destination

#### 6. Fault Injection
- Delaying requests
- Aborting requests
- Faults for percentage of traffic

#### 7. Request Timeout / Retries
- Setting timeouts
- Adding retries 

#### 8. CORS
- Setting allowed origins
- Allowed methods & headers
- Exposed headers
- Preflight request caching
- Access-Control-Allow-Credentials

#### 9. Mirroring
- Send percentage of traffic to mirrored destination (kubeService only)

#### 10. Header Manipulation
- Request Headers
  - Add Request Header
  - Remove Request Header
- Response Headers
  - Add Response Header
  - Remove Response Header

#### 11. Outlier Detection
- Outlier Detection for failover routing to a global destination

#### 12. mTLS
- Setting mTLS settings per destination

#### 13. CSRF
- Setting CSRF Policy
- Setting CSRF Policy

#### 14. Rate Limit
- Using raw Rate Limit definition
- Rate Limit on source cluster  (TODO does this make sense)
- Rate Limit on destination cluster (TODO use istio cluster name?)
- Rate Limit on request headers
- Rate Limit on remote address
- Rate Limit on generic key
- Rate Limit on the existence of a requst header
- Rate Limit on metadata
- Using separate Rate Limit config

#### 15. Ext Auth
- Using a custom auth server
- OIDC with AuthConfig
- Using an API token

### Virtual Destination

#### 16. Hostname
- Custom Hostname
- Override Kube Service

#### 17. Port Selection
- Custom Port

#### 18. Mesh Selection
- Single Mesh
- Multi-Mesh

#### 19.Static Destination

#### 20. Locality
- Outlier Detection


### Access Policy

#### 21. Source Selection
- kubeIdentityMatcher
- kubeServiceAccountRefs
- requestIdentityMatcher

#### 22. DestinationSelection
* Destination Selector
  * kubeServiceMatcher
  * kubeServiceRefs
  * virtualDestinationMatcher
  * virtualDestinationRefs
  * externalServiceMatcher
  * externalServiceRefs

#### 23. Allowed
- Paths
- Methods
- Ports


### 24. Service Dependencies
- Namespace Selection
- Cluster Selection
- Label Selectors