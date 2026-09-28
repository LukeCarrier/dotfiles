# SSH host identities

Public identities expected after the replacement-disk installation:

| Use | Public key | SHA256 fingerprint |
| --- | --- | --- |
| Normal OpenSSH host and SOPS age identity | `ssh_host_ed25519_key.pub` | `SHA256:B4gdEw72WdhJydV0RdUcLO6ZvDDSEJS/LsqKRmyU1J4` |
| Initrd remote-unlock SSH only | `initrd_ssh_host_ed25519_key.pub` | `SHA256:EFKuOey9MlqqLld6cD/tpIwjbqWGOWkZ4BYZyzKFWsg` |

The normal host key converts to this age recipient:

```text
age1epgrkrtn8twdn2k3zzft4ml6qe5p06mktu49falkxd3gq3nwhugsvgvtga
```

Private material is stored in `secrets/employer-emed.yaml`. The initrd identity
is intentionally not a SOPS recipient and must not be used as the normal SSH
host identity.
