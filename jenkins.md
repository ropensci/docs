# Jenkins Server via Docker Compose

Configuration of the main webserver (nginx) looks like this:

```
/docs     ->     data:/docs
/src      ->     data:/src
/*        ->     jenkins
```

## Start the cluster

On a Linux host make sure your user is part of the `docker` group:

```
sudo usermod -aG docker $USER
```

Now start the cluster (use `-d` to run in the background):

```
docker volume create data
docker-compose up
```

On most servers you also need this to give Jenkins permission to run docker (see permission section below):

```
docker exec -u root jenkins chmod 777 /var/run/docker.sock
```

Now navigate to `http://localhost` (or where you are hosting). To unlock Jenkins you need the initial password which you can find with:

```
docker exec jenkins cat /var/jenkins_home/secrets/initialAdminPassword
```

Then continue by installing the suggested plugins and creating an admin user.

## Configure Github API

Configure a global Github API token that has `repo:status` permission (to set pending/success/fail) for commits. I think this users also needs write access to the repo.

Go to __Manage Jenkins__ > __Configure System__. Scroll down to __GitHub Servers__ and press add server:

 - Name: Github
 - API URL: `https://api.github.com`
 - Credential kind: secret text
 - Secret: GITHUB_PAT
 - ID: github-api-pat

If the credential doesn't show up after adding, there might be a problem with the proxy server. More details: https://support.cloudbees.com/hc/en-us/articles/224543927-GitHub-webhook-configuration

## Create Jenkins REST Token

In Jenkins navigate to __People__ and select your user and then __Configure__. Then click __Add New Token__ and save it in your local `~/.Renviron` file like this:

```
JENKINS_PAT=111013192d2fdcab030f9d11f937746ef0
```

Now test connecting with the R client:

```r
# remotes::install_github("jeroen/jenkins")
library(jenkins)
jk <- jenkins("https://dev.ropensci.org")

# Do stuff
jk$project_list()
```

Create a separate Jenkins Job for each repository. We have a template in the betty package:

```r
remotes::install_github("jeroen/betty")
xml <- betty::config_template('https://github.com/ropensci/unrtf')
jk$project_create('unrtf', xml)
jk$project_build('unrtf')
```

This part is likely to change.

## Installing a webhook

To automatically trigger builds, add a webhook on Github (either at repo or org level) to `/github-webhook/` on your Jenkins server. Make sure to put the trailing slash in the webhook:

```
http://jenkins.ropensci.org/github-webhook/
```

The webhook will trigger builds for existing jobs with a matching repository URL. To make the build logs public, go to __Manage Jenkins__ > __Configure Global Security__ and check the box for __anonymous read access__. Or alternatively: check "matrix based security" for fine grained security settings.

## Caching Packages

We cache the package library (with dependencies) in between builds using a package-specific volume:

```
docker run --env R_LIBS_USER=/cache -v ${BASENAME}_cache:/cache ropensci/docs .....
```

This will automatically create a volume named for example `magick_cache` containing the package library for magick builds. To wipe all the caches on the server:

```
docker system prune
docker volume prune
```

This will delete all dangling images and cache volumes. It will not delete the `data` volume as long as it is in use by the nginx container.

## Docker Permission Problems

We need to map the host `/var/run/docker.sock` inside the jenkins container to allow Jenkins to invoke docker on the host. If Jenkins gives permission denied erros when calling docker, try relaxing permissions on `docker.sock` file:

```
docker exec -u root jenkins chmod 777 /var/run/docker.sock
```

This should be solved by adding the `jenkins` user to the `docker` group, but that doesn't always seem to work (at least not on Docker for Mac).

## Custom Theme

The [Simple Theme Plugin](https://wiki.jenkins.io/display/JENKINS/Simple+Theme+Plugin) (not installed by default) allows for adding a CSS file to display custom colors and logo.

I used the [material-theme](http://afonsof.com/jenkins-material-theme/) website to generate [jenkins-ropensci-theme.css](jenkins-ropensci-theme.css) which you can host from anywhere.
