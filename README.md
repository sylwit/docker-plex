# docker plex
This is a Dockerfile to set up ([https://plex.tv/](https://plex.tv/) "Plex Media Server") - ([https://plex.tv/](https://plex.tv/))

## Instructions
### Getting the docker image
Build from docker file

```
git clone git@github.com:timhaak/docker-plex.git
cd docker-plex
docker build -t timhaak/plex .
```

You can also obtain it via:

```
docker pull timhaak/plex
```

### Running the docker image
Instructions to run:

```
docker rm -f plex
docker run --restart=always -d --name plex -h *your_host_name* -v /*your_config_location*:/config -v /*your_videos_location*:/data -p 32400:32400 timhaak/plex
```

When the container starts, it will initialize the config directory and the configuration is populated through [environment variables](#environment-variables) that can be set using the command line or an envfile.

Browse to `http://*ipaddress*:32400/web` to run through the setup wizard.

By default, unauthenticated web access will only be available from the host machine and so to configure authentication for external access you will need a web browser on your host machine. If this is unavailable or you would like to have unauthenticated access from your LAN, then you can set the `PLEX_ALLOWED_NETWORKS` [environment variable](#environment-variables) to the subnet of your LAN either temporarily for configuration or permenantly for unauthenticated LAN access.

#### Avahi Auto Detection
For auto detection to work add --net="host". Though be aware this more insecure and not best practice with docker images. The only reason for doing it is to allow Avahi to work (as it uses broadcasts that will not cross network boundries).

See the [Docker Networking Article](https://docs.docker.com/articles/networking/#how-docker-networks-a-container) for details on how docker networks a container.

```
docker rm -f plex
docker run --restart=always -d --name plex --net="host" -h *your_host_name* -v /*your_config_location*:/config -v /*your_videos_location*:/data timhaak/plex
```

## Configuration
### Environment Varaibles

| Variable Name           | Values                 | Behaviour                                                                            | Default value   |
| ----------------------: | :--------------------: | :----------------------------------------------------------------------------------- | :-------------: |
|     SKIP_CHOWN_CONFIG   |  `TRUE` or `FALSE`     | Startup will be faster and there won't be a permissions check for the configuration  | (unset)         |
|         PLEX_USERNAME   |        String          | Will add this Plex Media Server to that account                                      | (not set)       |
|         PLEX_PASSWORD   |        String          | (Mandatory if username is set) The account password | (not set)                      |                 |
|            PLEX_TOKEN   |   [Plex token][1]      | Plex token if you don't want to write your password | (not set)                      |                 |
|     PLEX_EXTERNALPORT   |       Integer          | The port if you're not using the default one (32400), ie. when using `-p 80:34200`   |  (not set)      |
| PLEX_DISABLE_SECURITY   |      `0` or `1`        | If set to 1, the remote security will be disabled | 1                                |                 |
|           RUN_AS_ROOT   |  `TRUE` or `FALSE`     | *Dangerous* If true, will start Plex as root | true                                  |                 |
| PLEX_ALLOWED_NETWORKS   | Comma-separated list   | List of networks to allow access to. Defaults to the docker network (public Plex)    | (not set)       |

To use an option, set it as a Docker environment variable through the command line:

```
docker run -e RUN_AS_ROOT=TRUE ... timhaak/plex
```

or add it to an envfile that can be included through the command line:

```
docker run --envfile=*filename* ... timhaak/plex
```

## Mac and Apple TV Usage

For Docker on the mac and AppleTV discovery of the server you will need to open up more ports. The reason is that net=host doesn't work as intended. A recommended startup would be something like this :

```
docker run \
--restart=always \
-d             \
--name plex    \
-h *your_host_name*   \
-p 32400:32400 \
-p 1900:1900/udp \
-p 3005:3005 \
-p 5353:5353/udp \
-p 8324:8324 \
-p 32410:32410/udp \
-p 32412:32412/udp \
-p 32413:32413/udp \
-p 32414:32414/udp \
-p 32469:32469 \
-v /*your_config_location*:/config \
-v /*your_videos_location*:/data   \
timhaak/plex
```

[1]: https://support.plex.tv/hc/en-us/articles/204059436-Finding-your-account-token-X-Plex-Token
