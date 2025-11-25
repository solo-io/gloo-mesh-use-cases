# demo-keycloak

This directory contains the files necessary for running a demo Keycloak instance locally in a Docker container. This instance is preconfigured for OIDC access to the Solo Enterprise for kagent UI.

In a multicluster setup, run this script in the management cluster.

## Contents

* `/realm-data`: Directory that contains:
  * `kagent-dev-realm.json`: Predefined data for the `keycloak-dev` realm.
  * `kagent-dev-users-0.json`: Predefined data for `admin`, `writer`, and `reader` accounts, with the dummy credentials `admin/password`, `writer/password`, and `reader/password`.
* `demo-keycloak.sh`: Script that uses the realm data to complete the following:
  * Generates self-signed certificates for the Keycloak instance
  * Creates a demo Keycloak installation that:
    * Uses an H2 database to store its internal configuration and user configuration.
    * Serves plain-text HTTP on port 8088 and TLS encrypted traffic on port 8443 for hostname `keycloak.default`.
    * Creates clients for the UI frontend and backend:
      * `kagent-ui` is a public access client that has an PKCE-enhanced authorization code flow, and maps user group membership to a custom claim called `Groups`. 
      * `kagent-backend` is a confidential access client that is used by token validation in the UI backend.
    * Defines the `admin`, `writer`, and `reader` accounts in the `kagent-dev` realm.
  * Creates Kubernetes service configuration for Keycloak in the targeted cluster. In a multicluster setup, this resource must be created in the management cluster where the `kagent-enterprise-ui` pod runs.
  * Creates a Kubernetes secret called `kagent-backend-secret` that stores the base64-encoded secret for the `kagent-backend` client.
* `demo-keycloak-multi.sh`: Multicluster script that:
  * Completes the same processes as the `demo-keycloak.sh` script in multiple clusters, with cluster contexts `${MGMT_CONTEXT}` and `${REMOTE_CONTEXT}`.
  * Saves Keycloak IdP details in environment variables, which are necessary for steps in the multicluster installation guide.

Note that one other necessary resource, the `rbac-config.yaml` configmap to map the account roles in the cluster, is _not_ included in this script, and is installed by default in the Solo Enterprise for kagent `management` Helm chart.
