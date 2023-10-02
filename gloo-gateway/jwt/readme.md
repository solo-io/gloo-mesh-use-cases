# JWT notes

This directory has example YAMLs and JWT tokens that are used in several guides for Gloo Gateway JWT policies. The JWT tokens were made with [jwt.io](jwt.io) by using the following payloads and public keys. For more information, [see the Gloo Gateway docs](https://docs.solo.io/gloo-gateway/main/policies/jwt/).

## dev-example JWT

Payload:

```json
{
  "iss": "https://dev.example.com",
  "exp": 4804324736,
  "iat": 1648651136,
  "org": "internal",
  "email": "dev1@solo.io",
  "group": "engineering",
  "scope": "is:developer"
}
```

## login-example JWT

Payload:

```json
{
  "iss": "https://login.example.com",
  "exp": 4804324736,
  "iat": 1648651136,
  "org": "external",
  "email": "user2@example.com",
  "group": "user",
  "scope": "is:reader"
}
```

## Public key

You can provide the following public key inline in a Gloo JWT policy so that Gloo Gateway can validate the example JWTs in a request.

```
-----BEGIN PUBLIC KEY-----
MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEArER4FGhBW0h05DnVSHre
Vr7tH/+XpTGsmSVYXciDKm3BigygvE1oGXIdIrvIzwE8XTrSgfquvf+VhXvMOa4x
anvuEqrLlqV9kanlEtjkkwV6PbDksrUeukxDiaxGBTBm6XIlpQdfRI3lMSln6phM
mxtWOdMyA9QcXYEr5hXi9KJUyjGaAZGyOxYOyq+VNnxHIvqHR7pQiokTc4jkMD+X
rxgAka3Lb1ekE/WowwzPvO8dyq0cUiCBrC4TiH/Yd2/LVEwnWoM1RI8FsuRnRgcX
y2lto8nYVfQyCD6bWfnReiOo4DVQpP9GeVd3OxKDks+tt8AMT/IecrqPg08x+BCF
uwIDAQAB
-----END PUBLIC KEY-----
```

### Example YAMLs

For examples of how to create policies for the different providers, review the following GitHub gists.

* [Gloo JwtPolicy basic dev-example](https://gist.github.com/artberger/674bab05350c9a048303cc7daaffe730), filename `jwt-policy-basic.yaml`
* [Gloo JwtPolicy basic login-example](https://gist.github.com/artberger/be2ceeac3f1c794946246a3d777a024c), filename `jwt-policy-basic-login.yaml`
* [Gloo JwtPolicy both dev-example and login-example](https://gist.github.com/artberger/be2ceeac3f1c794946246a3d777a024c), filename `jwt-policy-multi.yaml`
* [Gloo JwtPolicy dev-example with claims](https://gist.github.com/artberger/dceb99b21103ab0f9f80e1bfd6b463ce), filename `jwt-policy-claims.yaml`
