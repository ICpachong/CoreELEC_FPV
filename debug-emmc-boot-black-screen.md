# Debug Session: emmc-boot-black-screen
- **Status**: [OPEN]
- **Issue**: CoreELEC installed to ZTE W100D eMMC remains black on HDMI after boot; Armbian currently boots from USB.
- **Debug Server**: Not started; initial evidence is collected read-only over SSH.
- **Log File**: Not created.

## Reproduction Steps
1. Run install2emmc from CoreELEC boot media.
2. Power off, remove boot media, and power on from eMMC.
3. HDMI remains black after ten minutes.
4. Boot Armbian from USB to inspect the eMMC.

## Hypotheses & Verification
| ID | Hypothesis | Likelihood | Effort | Evidence |
|----|------------|------------|--------|----------|
| A | Required boot files are missing or the compiled boot scripts are incorrect | Low | Low | Rejected: all required files exist; kernel/SYSTEM MD5 match; script contents match the sources |
| B | Partition offset/type is not accepted by vendor U-Boot | Low | Low | Rejected by layout inspection: p1 is FAT32 LBA at 1000-1512 MiB, p2 starts at 1513 MiB; actual U-Boot read remains under runtime test |
| C | Saved U-Boot environment does not execute mmc 1:1/emmc_autoscript | Low | High | Rejected: saved environment at 180 MiB contains the expected bootcmd and start_emmc_autoscript |
| D | Kernel starts but storage mounting or HDMI/Kodi initialization fails | High | High | Confirmed: initramfs fails in mount_flash because Amlogic MPT replaces the installer-created MBR partitions |
| E | emmc_autoscript/cfgload execution or kernel/DTB loading stops before bootm | Low | High | Rejected: independent U-Boot markers prove both kernel and DTB load successfully and execution reaches bootm |

## Log Evidence
- Armbian reports /dev/mmcblk2p1 as 512 MiB vfat with label COREELEC.
- Armbian reports /dev/mmcblk2p2 as ext4 with label STORAGE.
- Current Armbian boot media is /dev/sda.
- p1 contains aml_autoscript, emmc_autoscript, cfgload, kernel.img, dtb.img and SYSTEM.
- kernel.img MD5 c0c194b6b6eb86a854031a06b9a9870c and SYSTEM MD5 5188877af9b123297ad4ef94b30b6701 match their manifest files.
- Saved U-Boot environment: bootcmd=run start_autoscript; run storeboot; start_emmc_autoscript loads mmc 1:1/emmc_autoscript and sets mmc device 1.
- No new Kodi log was created on the eMMC storage partition during failed attempts.
- FAT-write diagnostics did not create any marker and did not execute an eMMC attempt; these rounds provide no evidence about CoreELEC itself.
- A saveenv-based one-shot diagnostic successfully ran `fatload mmc 1:1 ... emmc_autoscript`; after the subsequent black screen and power cycle, the saved state was `ce_diag_attempted=1`, `ce_diag_stage=emmc_loaded`. This rejects a simple partition/environment read failure but does not yet prove the first instruction inside emmc_autoscript executed.
- Installed instrumented emmc_autoscript and cfgload on eMMC after backing up the originals to `/root/ce-emmc-boot-backup`. New stages distinguish emmc_entry, cfgload_loaded, cfgload_entry, kernel/DTB loading, and before_bootm.
- Restored `/root/emmc-env-180m-backup.bin` before the next attempt to clear ce_diag_attempted and preserve one-shot fallback behavior.
- Independent U-Boot markers confirmed `ce_diag_kernel=loaded`, `ce_diag_dtb=loaded`, and `ce_diag_stage=before_bootm`; neither kernel nor DTB FAT loading failed.
- With HDMI console and verbose diagnostics enabled, the board still had no network and no Kodi log. The user observed HDMI-related text but did not capture exact lines.
- Persistent post-flash/post-sysroot hooks produced no files at all, proving execution did not reach a successful mount_flash hook. This places the failure before that hook, including kernel boot, device discovery, check_disks, or mount_flash.
- Armbian fsck.fat -n and e2fsck -n both reported clean eMMC filesystems.
- CoreELEC ramoops is built in at 0x07400000. Armbian's ramoops module accepted the same layout, but no records survived the cold power cycle.
- Added a temporary initramfs error() diagnostic that writes the failure to kmsg and warm-reboots after 10 seconds, allowing ramoops collection after an automatic Armbian fallback.
- The second diagnostic kernel wrote `ce-init-error.txt`, `ce-init-dmesg.log`, `ce-init.log`, and `ce-fsck.log` to the Armbian USB boot partition before warm rebooting. The fatal error is `mount_common: Could not mount LABEL=COREELEC`.
- CoreELEC initially enumerates `mmcblk0: p1 p2`, then logs `skip mounting disk with MPT partition`, successfully reads the original MPT, deletes the MBR partitions, and registers the original 22 Amlogic partitions instead. Thus neither CoreELEC nor STORAGE can be resolved by label.
- The original 36 MiB MPT region is backed up on the board at `/root/w100d-mpt-36m-before.bin` (SHA-256 `0e3016519534d7561213e840c6d542ebdabfa2ee24370d68873967e256a4589f`). It contains a valid 22-entry MPT whose `reserved` entry starts at 36 MiB and whose `env` entry starts at 180 MiB.
- Kernel source confirms that only the four-byte `MPT\0` signature at 36 MiB gates `aml_emmc_partition_ops`. If it is absent, the Amlogic key/DTB/DDR MPT helpers are not entered and the standard MBR partitions remain registered.
- Saved U-Boot commands load `emmc_autoscript` directly from `mmc 1:1`; no MPT lookup is needed to load CoreELEC.
- Clearing only the MPT magic was not persistent: the diagnostic boot reached `before_bootm`, but U-Boot restored the complete original 1 MiB MPT region byte-for-byte before Linux started. The next CoreELEC attempt therefore failed identically. Simple MPT invalidation is rejected as a final fix.
- The original MPT checksum equals the Amlogic kernel's legacy algorithm (the first 40-byte entry checksum multiplied by `part_num`), not a sum over all entries. This was verified against the original bytes.
- A compatible 20-entry MPT was generated for runtime testing. It preserves the original 18 vendor entries below 1 GiB, removes only the four Android entries overlapping the new filesystems, and adds COREELEC at 1000 MiB/512 MiB and STORAGE at 1513 MiB/to end with exactly the same byte offsets as the MBR.
- The 20-entry MPT had a valid legacy checksum but was restored to the original 22-entry table by vendor U-Boot, so this approach was rejected.
- A second 22-entry MPT preserved every original partition name and modified only the `system`/`product` offsets and sizes to match COREELEC/STORAGE. It was also restored to the original table (the post-test header again reported 22 entries and checksum `0xa77cfa62`), rejecting this approach as well.
- Amlogic U-Boot reference code compares the stored MPT against the vendor DTB partition table entry by entry and rewrites the stored table when they differ. This matches all three on-device restoration tests.
- The selected fix keeps the original MPT for U-Boot and adds the eMMC-only `emmc_mbr=1` kernel option. It bypasses both MPT detection in the generic partition scanner and the Amlogic MPT registration that would otherwise delete the standard MBR partitions.
- The formal patch `linux-11-add-emmc-mbr-boot-option.patch` applied during a clean W100D build, which completed successfully as image `CoreELEC-Amlogic-ng.arm-21.2-Omega_devel_20261105143129-ZTE_W100D.img.gz`.
- The installed eMMC kernel, cfgload and emmc_autoscript were replaced with that build. Their SHA-256 values are respectively `3139cc7fcaae1e1f66d48d1486ded1a868839996e43fd01334badbbba47fdab9`, `32ef96073afb1853ad3cc51392c0cefa16a255d5f17d16d20d453cf50cdde101` and `d6c182ecf445e40fa87eec053dab840f81e6177059c6d2fbe027bd5018e06868`; the compiled scripts contain `emmcmbr_opt=emmc_mbr=1` and append it to `initargs`.
- Before the test, the complete original 1 MiB MPT region matched the initial backup byte-for-byte, and the original U-Boot environment was restored and hash-verified.

## Verification Conclusion
The MPT/MBR root cause is fixed and runtime-verified. The 4.9 kernel reported `mmcblk0: p1 p2` and `keep standard MBR partitions`, mounted `/dev/mmcblk0p1` as `/flash`, checked both COREELEC and STORAGE successfully, and reached `post-sysroot` at 4.45 seconds. The original 1 MiB MPT region still matches the initial backup byte-for-byte. No `mount_flash` failure recurred. The remaining no-display/no-network symptom occurs after `post-sysroot`; persistent per-step initramfs tracing and persistent journal storage have been enabled to locate that separate later-stage issue.
