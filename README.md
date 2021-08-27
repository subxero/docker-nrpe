# docker-nrpe [![Docker Repository on Quay](https://quay.io/repository/subxero2k/docker-nrpe/status "Docker Repository on Quay")](https://quay.io/repository/subxero2k/docker-nrpe)
NRPE Docker Container

## About
Provides NRPE Server within docker container. This allows remote monitoring of docker hosts from nagios/Icinga.

## Status
Ready for production

## Images
The docker-nrpe image is available on docker hub [subxero2k/docker-nrpe:latest](https://quay.io/repository/subxero2k/docker-nrpe). It is setup using hub's automated build process.

## Running
In order to run the NRPE container , use command :

```
docker pull quay.io/subxero2k/docker-nrpe
docker run --privileged -v /:/mnt/ROOT --rm --name nrpe -it -p 5666:5666 subxero2k/docker-nrpe
```

Once up, you can monitor server using nagios/icinga.
