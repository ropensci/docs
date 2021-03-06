# rOpenSci docs [![badge](https://images.microbadger.com/badges/image/ropensci/docs.svg)](https://cloud.docker.com/u/ropensci/repository/docker/ropensci/docs/general)

Tooling to generate pkgdown sites and more.

## Create a Volume

First create a persistent volume `data` which will hold the websites and source packages:

```
docker volume create data
```

Then use any standard webserver container to host the `data` volume:

```
docker run -d -p 80:8043 -v data:/srv/http --name httpd pierrezemb/gostatic
```

Now navigate to http://localhost in your browser. Use `docker stop` and `docker start` to pause and restart the webserver:

```
docker stop httpd
```

The `data` volume persists after killing or restarting webserver. To manually explore the `data` volume, just mount it in any container with a shell:

```
docker run --rm -it -v data:/data busybox
```


## Building and host locally

Build packages from their git url using the `ropensci/docs` image with arguments `build {git_url}`. These may run in parallel:

``` 
docker run --rm -it -v data:/data ropensci/docs build https://github.com/jeroen/openssl
docker run --rm -it -v data:/data ropensci/docs build https://github.com/ropensci/magick
docker run --rm -it -v data:/data ropensci/docs build https://github.com/ropensci/tesseract
```

Alternatively you can build from a local path. For example to copy the current directory in the container and build that:

```
docker create --name builder --rm -it -v data:/data ropensci/docs build "/sources"
docker cp $PWD "builder:/sources"
docker start builder --attach
```

Upon success, websites are saved to `/data` will be available in http://localhost/docs

## Deploy to Github

To also deploy to Github you need to provide a `GITHUB_PAT` variable with permission to your Github org. Then run `deploy` to upload all the sites to your github org.


```
docker run --rm -it --env-file=env.txt -v data:/data ropensci/docs deploy
```

In `env.txt` you can also set `GIT_USER` and `GIT_EMAIL` variables to commit as a specific git user.

## Cleanup

Stop the webserver (if any) and remove the `data` volume:

```
docker stop httpd && docker rm httpd
docker volume rm data
```

## Jenkins CI Server

Checkout [jenkins.md](jenkins.md) for how to setup a Jenkins server based on docker compose.
