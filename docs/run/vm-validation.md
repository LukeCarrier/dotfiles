# VM installation and recovery validation

Status: `host-vm-test` verifies the storage topology, selected persistence,
persistent UEFI/TPM identity, TPM2+PIN unlock, standalone Home Manager activation,
and hibernation/resume using Disko's `system.build.installTest`. Interactive
full-host VM operation is not implemented.

## Test environment

Use QEMU/KVM, UEFI firmware with persistent variable storage, and a software TPM
with persistent state. Keep guest disks and all VM identity state in a dedicated
local directory excluded from source control. Use disposable keys and test
secrets, never production IT credentials or signing private keys.

The guest must share the production storage, persistence and boot-order modules,
with only explicit virtual hardware and test credential overrides. A test that
replaces ZFS with ext4 or disables root reset does not validate this design.

Provide two modes:

- Automated storage/boot/recovery assertions against small disposable disks.
- Interactive full-host testing, including a graphical desktop session. Track
  which employer agents cannot be exercised without authorised test enrolment.

Do not generate a hardware report from the guest into the physical host's facter
file. Do not let real-disk paths from the host configuration reach the test disk
formatter.

## Command

```console
export host=luke-w0rkhorse
timeout --signal=INT --kill-after=15s 900s just host-vm-test "$host"
```

`host-vm-test` builds and executes the selected host's Disko installation test.
Disko's password prompt uses a dummy credential inside this disposable harness.
During production provisioning, the operator enters the real initial credential
directly at that prompt; it is not written to a filesystem or included in the
Nix store or boot configuration.

The automated test may use nixos-anywhere's `--vm-test` as an installation smoke
test, but must supplement it with assertions below. Interactive mode must boot
the installed virtual disk through UEFI, rather than bypassing the installed
bootloader with a directly supplied kernel/initrd. Keep virtual disks, TPM state
and UEFI variables across ordinary runs; reset them only with the reset target.

## Acceptance matrix

| Exercise | Required result |
| --- | --- |
| Fresh install | Explicit disposable disk gets ESP, LUKS2, LVM swap and ZFS datasets |
| First system activation | Host SOPS secrets provision and signed boot assets are built from staged keys |
| Two-phase deployment | Home Manager's first activation and user SOPS service succeed without a previous home or checkout-local identity |
| Normal boot | TPM policy plus correct PIN unlocks; incorrect PIN does not |
| Both recovery routes | IT and user recovery credentials independently unlock with the original virtual TPM absent |
| Simulated motherboard failure | Disk boots under different virtual firmware/TPM using recovery; recorded normal SSH identity persists |
| PCR change | Normal TPM route fails as expected; recovery works; controlled re-enrolment restores normal unlocking |
| Local and remote unlock | Both work; initrd and normal SSH fingerprints remain distinct and stable |
| Cold root reset | An unlisted sentinel on `/` disappears after reboot |
| Persistence | Sentinels in `/home` and `/persist`, host identity and selected service state survive |
| Nix continuity | Store database/profiles survive; installed generation still boots |
| ZFS integrity | Scrub/status clean after installation and repeated test cycles |
| Update | New signed generation boots under the chosen TPM update policy; recovery remains usable |
| Offline recovery | A trusted rescue environment can inspect the pool without executing the installed root-reset hook |
| Hibernation | In-memory process state and ephemeral-root sentinel survive resume; next cold boot resets root |
| Failed/absent resume | Boot follows the documented failure policy and cannot later resume a stale image against modified datasets |

For hibernation, power off the guest and boot it again using the installed disk;
a hypervisor memory snapshot is not a hibernation test. Verify resume happens
before pool import and root reset, including after a recovery unlock.

## Evidence and scope

Keep build revisions, guest serial logs, boot ordering, test results and ZFS status
with the test run. Keep credentials out of those logs. Label skipped cases,
especially security-agent enrolment and hardware-specific sleep behaviour.

The final 2026-09-30 bounded run completed in 342.70 seconds. It exercised a
fresh 128 GiB disposable disk, extracted a compressed system closure into a
self-contained Nix store, registered it in the target store, and booted the
installed profile. It persisted UEFI variables and software TPM state across
guest restarts, rejected an incorrect TPM PIN, unlocked with the correct PIN,
and independently validated the IT and user recovery credentials. It rejected
the TPM route after an initrd PCR extension, recovered with the IT credential,
and restored normal TPM unlocking after restoring the boot entry. It then reset
the virtual TPM, recovered with the user credential, and enrolled the new TPM.

The run restored a hibernation image before ZFS import. The original boot ID and
sentinel process ID were preserved, a RAM-backed sentinel survived, and the ZFS
pool remained healthy. It then corrupted swap ciphertext containing a second
hibernation image, rejected the stale image on the next boot, verified a new
boot ID and absence of the stale RAM-backed and ephemeral-root sentinels,
recreated swap, and finished with a healthy ZFS pool.

The installed closure included the exact standalone
`homeConfigurations."lukecarrier@luke-w0rkhorse"` activation package. Its first
activation ran as `lukecarrier` against a new home, and the test verified the Home
Manager profile, executable `home-manager`, generated Niri configuration and
ownership. It did not provide production age keys, decrypt user secrets, start
the user SOPS service, or open a graphical session.

The remaining automated gaps are a boot-level IT recovery after virtual TPM
replacement, production-equivalent SOPS identity staging and user-secret
activation, initrd SSH, update-policy validation, repeated scrub cycles, and
interactive full-host operation. The suite is not yet an automated flake check
on a KVM-capable runner.

VM success demonstrates the exercised flows, not proof that ZFS hibernation is
free from upstream consistency risks. Final hardware testing must still cover
the selected target disk, TPM and firmware measurements, Secure Boot trust,
initrd network driver, display, critical-battery response, and suspend/resume
path.
