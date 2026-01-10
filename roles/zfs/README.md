# ZFS Role

This role sets up a ZFS pool with optional datasets.

## Requirements

- Linux system with ZFS support
- Root access
- Clean disks (no important data)

## Role Variables

- `zfs_pool_name`: Name of the ZFS pool (default: `tank`)
- `zfs_pool_type`: Pool type - `mirror` (RAID1 equivalent), `stripe`, `raidz1`, `raidz2`, etc. (default: `mirror`)
- `zfs_pool_devices`: **REQUIRED** - List of disk devices (e.g., `['/dev/sda', '/dev/sdb']`)
- `zfs_pool_mountpoint`: Mount point for the pool (default: `/mnt/tank`)
- `zfs_pool_properties`: Dictionary of pool properties (default includes compression=lz4, atime=off, recordsize=1M, checksum=sha256)
- `zfs_datasets`: Optional list of datasets to create
- `zfs_auto_import`: Enable auto-import service (default: `true`)

## Example Playbook

```yaml
- hosts: homelab
  become: true
  vars:
    zfs_pool_devices:
      - /dev/sda
      - /dev/sdb
    zfs_pool_name: "tank"
    zfs_pool_type: "mirror"
    zfs_pool_mountpoint: "/mnt/tank"
    zfs_pool_properties:
      compression: "lz4"
      atime: "off"
      recordsize: "1M"
    zfs_datasets:
      - name: "storage"
        mountpoint: "/mnt/tank/storage"
        properties:
          compression: "zstd"
  roles:
    - role: zfs
```

## Dependencies

None

## License

Same as main project
