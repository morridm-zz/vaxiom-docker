vaxiom-docker
=============
# Docker files
Various docker files for dev/test.

## Base Docker files for Centos 6.5
Docker files to build minimal SSH enabled Centos images.

    $ cd base/centos

    #build image
    $ ./build-docker-image centos latest $HOME/$USER/.ssh/id_rsa.pub

    #launch 5 containers, host volume mapped to /opt/data/centos-N
    $ launch-docker-containers centos latest 5

    #stop and remove containers named centos
    $ stop-docker-containers centos*

