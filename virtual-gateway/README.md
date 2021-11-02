# Virtual Gateway Use Cases

Unless otherwise specified, these scenarios will assume the typical 3-cluster setup (mgmt, cluster1, cluster2) so that it will work in any environment.  This also assumes the following pre-requisites:

- Gloo Mesh Management Plane is installed 
- Remote Clusters are registered
- Istio is installed with at least version 1.10
- Bookinfo is deployed to clusters 1 and 2 as stated in the Gloo Mesh workshop
- Bookinfo Gateway and VirtualService are not installed 

If there are any deviations from the above, then a README should be supplied along with scripts to take care of the changes.

## Gloo Mesh Enterprise 1.x

### Ingress Gateway Scenarios
- Basic Application Ingress for Single Cluster
- Single Virtual Gateway attached to multiple Ingress Gateways
- Multi-cluster Virtual Gateway

### Connection Handling
- Protocol Selection
- Virtual Gateway TLS termination
- HTTPS Redirect
- Restricting Envoy filters
- SNI matching
- Wildcard domains

### Virtual Hosts
- VirtualGateway selection
- Inline VirtualHost definition

### Route matching
- Path-based matching
- Regex path-based matching
- Header-based matching
- Query parameter matching
- HTTP method matching

### Routing to Destination
- Single destination
- Weighted destination
- Routing to service with multiple ports (kubeService only)
- Multi-cluster routing (kubeService only)
- Using cluster_header
- Subset routing
- Route to VirtualDestination
- Route to Static Destination
- Request transformation (add/remove headers)
- Response transformation (add/remove headers)
- Path rewrite

### Redirects
- Host Redirect
- Path Redirect
- Rewrite Path Prefix
- Modifying the response code
- HTTP to HTTPS redirect
- Strip query

### Direct Response
- Return a direct response without routing

### Routing delegation
- Select RouteTable by name/namespace
- Select RouteTable by selector
- Sort RouteTables by weight
- Sort RouteTables by specificity

# Traffic Shifting
- Weighted via subsets
- Routing to service with multiple ports (kubeService only)
- Multi-cluster routing (kubeService only)
- Using cluster_header
- Subset routing
- Route to VirtualDestination
- Route to Static Destination
- Request transformation (add/remove headers)
- Response transformation (add/remove headers)
- Path rewrite

# Fault Injection
- Delaying requests
- Aborting requests
- Faults for percentage of traffic

# Handling timeouts
- Setting timeouts
- Adding retries 

# CORS
- Setting allowed origins
- Allowed methods & headers
- Exposed headers
- Preflight request caching
- Access-Control-Allow-Credentials

# Mirroring Traffic
- Send percentage of traffic to mirrored destination (kubeService only)

# Header Manipulation
- Request Transformation on TrafficPolicy (add/remove headers)
- Response Transformation on TrafficPolicy (add/remove headers)

# Outlier Detection
- Outlier Detection for failover routing to a global destination

# Istio mTLS Settings
- Setting mTLS settings per destination

# Cross-Site Request Forgery
- Setting CSRF Policy

# Rate Limiting
- Using raw Rate Limit definition
- Rate Limit on source cluster
- Rate Limit on destination cluster
- Rate Limit on request headers
- Rate Limit on remote address
- Rate Limit on generic key
- Rate Limit on the existence of a requst header
- Rate Limit on metadata
- Using separate Rate Limit config

# External Auth
- Using a custom auth server
- OIDC with AuthConfig
- Using an API token

# Labeled routes
- Specifying route labels for a TrafficPolicy

# TCP Destinations
- Configuring a static TCP Destination
- Configuring a virtual TCP Destination
- Configuring a kube TCP Destination
- Forwarding SNI
- Weighted routing

# TCP Options
- Setting max connection attempts
- Setting idle timeout
- Using a TCP tunnel

# Global Virtual Gateway options
- Setting a limit on connection buffers
- Setting the bind address