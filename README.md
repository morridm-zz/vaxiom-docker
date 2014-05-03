vaxiom-docker
=============
# Docker files
Various docker files for dev/test.

## Base Docker files for Debian, Ubuntu and Centos
Docker files to build minimal SSH enabled Debian, Ubuntu and Centos images.

    $ cd base/centos

    #build image
    $ ./build-docker-image centos latest $HOME/$USER/.ssh/id_rsa.pub

    #launch 5 containers, host volume mapped to /opt/data/centos-N
    $ launch-docker-containers centos mytag 5

    #stop and remove containers named centos
    $ stop-docker-containers centos*

## Percona XtraDB Cluster 5.6 Dockerfile
This docker file creates an image with the most recent Percona XtraDB Cluster 5.6 package installed.
Each launched image starts a single bootstrapped Galera node. A launched image will check
if the MySQL server's data dir needs to be initated or can be re-used.

Run the bootstrap-cluster.sh script to bootstrap a cluster.
The script sets a proper wsrep-cluster-address for all instances named 'galera-N'
and then performs a rolling node restart of the DB nodes to join the cluster.

### Build a docker image
The default root user and MySQL server root password is 'root123'.
Ports exposed: 22 80 443 4444 4567 4568
