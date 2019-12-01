A brief guide to using zfs
==========================

NOTE: All shell commands use fish syntax (i.e. `(command)` instead of `$(command)`)

Lets create our pool:

```fish
truncate --size 1G pair1-disk1.img pair1-disk2.img
sudo zpool create testpool mirror (pwd)/disk1.img (pwd)/disk2.img
```

Now lets inspect with `sudo zpool status`:

```
  pool: testpool
 state: ONLINE
  scan: none requested
config:

        NAME                                    STATE     READ WRITE CKSUM
        testpool                                ONLINE       0     0     0
          mirror-0                              ONLINE       0     0     0
            /home/erb/zfs-test/pair1-disk1.img  ONLINE       0     0     0
            /home/erb/zfs-test/pair1-disk2.img  ONLINE       0     0     0

errors: No known data errors
```



Let's add another set of mirrored drives to the array:

```fish
truncate --size 2G pair2-disk1.img pair2-disk2.img
sudo zpool add testpool mirror (pwd)/pair2-disk1.img (pwd)/pair2-disk2.img
```

Now lets inspect again:

```
  pool: testpool
 state: ONLINE
  scan: none requested
config:

        NAME                                    STATE     READ WRITE CKSUM
        testpool                                ONLINE       0     0     0
          mirror-0                              ONLINE       0     0     0
            /home/erb/zfs-test/pair1-disk1.img  ONLINE       0     0     0
            /home/erb/zfs-test/pair1-disk2.img  ONLINE       0     0     0
          mirror-1                              ONLINE       0     0     0
            /home/erb/zfs-test/pair2-disk1.img  ONLINE       0     0     0
            /home/erb/zfs-test/pair2-disk2.img  ONLINE       0     0     0

errors: No known data errors
```

## Using spares

We will add spares for both our mirrors:

```fish
truncate --size 1G spare1G.img
truncate --size 2G spare2G.img
sudo zpool add testpool spare (pwd)/spare1G.img
sudo zpool add testpool spare (pwd)/spare2G.img
```

Now lets try to replace one of the disks and see the spare replace it.

```fish
sudo zpool replace testpool (pwd)/pair2-disk2.img (pwd)/spare2G.img
```

This can also be done automatically (TODO: not included in guide nor tested).

Lets inspect:

```
  pool: testpool
 state: ONLINE
  scan: resilvered 264K in 0 days 00:00:00 with 0 errors on Sun Dec  1 10:27:06 2019
remove: Removal of vdev 1 copied 520K in 0h0m, completed on Sun Dec  1 10:26:12 2019
    672 memory used for removed device mappings
config:

        NAME                                      STATE     READ WRITE CKSUM
        testpool                                  ONLINE       0     0     0
          mirror-0                                ONLINE       0     0     0
            /home/erb/zfs-test/pair1-disk1.img    ONLINE       0     0     0
            /home/erb/zfs-test/pair1-disk2.img    ONLINE       0     0     0
          mirror-1                                ONLINE       0     0     0
            /home/erb/zfs-test/pair2-disk1.img    ONLINE       0     0     0
            spare-1                               ONLINE       0     0     0
              /home/erb/zfs-test/pair2-disk2.img  ONLINE       0     0     0
              /home/erb/zfs-test/spare2G.img      ONLINE       0     0     0
        spares
          /home/erb/zfs-test/spare1G.img          AVAIL
          /home/erb/zfs-test/spare2G.img          INUSE     currently in use

errors: No known data errors
```

Now we have two options:

 1. Detach the disk, let the spare take over.
 2. Replace the failed disk, making the spare available again.


### Option 1: Detach the disk, let spare take over

Official: https://docs.oracle.com/cd/E53394_01/html/E54801/gpegp.html#SVZFSgjfbz

Lets detach the failed disk:

```fish
sudo zpool detach testpool (pwd)/pair2-disk2.img
```

This removes the spare as an available spare:

```
  pool: testpool
 state: ONLINE
  scan: resilvered 264K in 0 days 00:00:00 with 0 errors on Sun Dec  1 10:27:06 2019
remove: Removal of vdev 1 copied 520K in 0h0m, completed on Sun Dec  1 10:26:12 2019
    672 memory used for removed device mappings
config:

        NAME                                    STATE     READ WRITE CKSUM
        testpool                                ONLINE       0     0     0
          mirror-0                              ONLINE       0     0     0
            /home/erb/zfs-test/pair1-disk1.img  ONLINE       0     0     0
            /home/erb/zfs-test/pair1-disk2.img  ONLINE       0     0     0
          mirror-1                              ONLINE       0     0     0
            /home/erb/zfs-test/pair2-disk1.img  ONLINE       0     0     0
            /home/erb/zfs-test/spare2G.img      ONLINE       0     0     0
        spares
          /home/erb/zfs-test/spare1G.img        AVAIL

errors: No known data errors
```


### Option 2: Replace the failed disk, return spare as spare.

Official: https://docs.oracle.com/cd/E53394_01/html/E54801/gpegp.html#SVZFSgjfbs

Replace the failed disk with a new disk:

```fish
sudo zpool replace testpool (pwd)/pair2-disk3.img (pwd)/pair2-disk2.img
```

The spare will automatically be freed:

```
  pool: testpool
 state: ONLINE
  scan: resilvered 1.03M in 0 days 00:00:00 with 0 errors on Sun Dec  1 10:53:42 2019
remove: Removal of vdev 1 copied 520K in 0h0m, completed on Sun Dec  1 10:26:12 2019
    672 memory used for removed device mappings
config:

        NAME                                    STATE     READ WRITE CKSUM
        testpool                                ONLINE       0     0     0
          mirror-0                              ONLINE       0     0     0
            /home/erb/zfs-test/pair1-disk1.img  ONLINE       0     0     0
            /home/erb/zfs-test/pair1-disk2.img  ONLINE       0     0     0
          mirror-2                              ONLINE       0     0     0
            /home/erb/zfs-test/pair2-disk1.img  ONLINE       0     0     0
            /home/erb/zfs-test/pair2-disk3.img  ONLINE       0     0     0
        spares
          /home/erb/zfs-test/spare1G.img        AVAIL
          /home/erb/zfs-test/spare2G.img        AVAIL

errors: No known data errors
```


## Creating a dataset


Let's create the first dataset:

```sh
sudo zfs create testpool/set1
```


## Removing a top-level vdev

Let's say you are tired of having a mirror with 1TB drives and you want to replace them with a mirror with larger drives.

```fish
sudo zpool remove mirror-1
```

The vdev should now have been removed.

From: http://blog.moellenkamp.org/archives/50-How-to-remove-a-top-level-vdev-from-a-ZFS-pool.html


## Terminology

 - pool = A collection of vdevs (called a volume in the gui/cli)
 - vdev = A virtual device containing one or more disks in a certain configuration (single/mirror/RAIDZ/etc.)


## Resources

 - https://jrs-s.net/2015/02/06/zfs-you-should-use-mirror-vdevs-not-raidz/
