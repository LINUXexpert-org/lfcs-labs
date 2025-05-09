# lfcs-labs
Here are five self‑contained Bash scripts—one for each mock lab outlined in the LFCS study guide from [LINUXexpert.org](https://linuxexpert.org).

Each script:

- Detects the host distribution (Debian/Ubuntu vs. RHEL/Alma/Fedora) and exits gracefully if required tools are missing.
- Explains what it is about to do and asks for confirmation before making destructive changes.
- Creates the failure scenario.
- Drops a README in /root/lab‑<NAME>.md that restates the exercise goals and hints.
- Provides a cleanup function you can invoke with --cleanup to revert all changes.

Usage pattern

``` sudo ./lab_broken_boot.sh        # set up the scenario ```

``` sudo ./lab_broken_boot.sh --cleanup   # restore system ```

Important: Run these only in disposable VMs or snapshots!

The Scripts:
- Broken Boot (lab_broken_boot.sh)
- Network Outage (lab_network_outage.sh)
- Disk Full (lab_disk_full.sh)
- SELinux Denial (lab_selinux_denial.sh)
- LDAP Fail‑over (lab_ldap_failover.sh)

How to Organize

Save each script in ~/lfcs-labs/, make them executable (chmod +x *.sh), and snapshot the VM before running. After each practice session, run the corresponding --cleanup option or roll back the snapshot.

Happy drilling—may your reflexes be ready for LFCS day!
