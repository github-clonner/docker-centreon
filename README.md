# Centreon Docker images

This is a "work in progress" project. It’s not usuable so far.

Despite having "alpine" in its name, this project makes only a little use of Alpine Linux. I gave up with the idea of building the Centreon stack under this distribution, only the MariaDB database image is made from the Alpine official image.

I’m currently trying to build the last Centreon source code using the CentOS 7 image.

## A bit of history

On [Docker Hub](https://hub.docker.com/search/?isAutomated=0&isOfficial=0&page=1&pullCount=0&q=centreon&starCount=0), the most starred and pulled image has been made by one of the Centreon author, Julien Mathis, but it hasn’t been updated for three years and is for a standalone setup of Centreon.

There seems to be some [interesting](https://github.com/jpdurot/docker-centreon) [ressources](https://github.com/padelt/docker-centreon) on Docker Hub but I’m trying to do it myself, rather than testing those.

One of the goals of this work is to learn Docker, and getting a better knowledge of Centreon’s internal, plus, I won’t bet the images available will work out-of-the-box nor will be easily adaptable for our current setup.

## What is done so far

A central image with CLib, Broker, Engine, Connectors and Centreon Web. The setup (install.sh) is done during image creation but the Centreon configuration itself must be realized once the container is running. Having '/etc' being a Docker volume the configuration will persist across container restarts.

Once the setup has took place, you must manually rename the '/centreon/www/install' directory (as '/centreon/www/install.done' for example) to prevent the installation to restart again and again. This may be a bug, I don’t know.

### Database image

It’s based on Alpine and it’s not as complete as the Debian based official MariaDB docker image. To run Centreon you may (and probably should) use the official image as your backend.

MariaDB is installed from the packages available in Alpine 3.6. The image is named 'centreondb'.

If '/var/lib/mysql/mysql' is not a directory then MariaDB is run once to:

 1) execute its initial configuration
 2) set the root password (from an env. variable)
 3) set grants necessary for root to connect from the central with password
 
Then (or if the server is already configured) MariaDB is run to listen to requests.

The 'mysqld' process is killed with SIGTERM (so is gracefuly terminated) whatever the container receive SIGINT, SIGTERM, SIGQUIT or SIGSTOP.

'/var/lib/mysql' is, of course, a Docker volume.

### Central image

The Centreon application itself is written in PHP and Perl. As a downside for integration, it depends on PHP < 5.5 (NB: strictly inferior).

Running Centreon with separated PHP and Web servers, seems a bit out of hand, at least for me. To simplify the problem I will try to have one container with all the necessary things. This image will, at first, be a Centreon poller too.

In the first place, I stick to Apache for the web server. Nginx may be another good choice to consider. I find it quite simpler to configure and operate, but being unaware of how Centreon is dependent of Apache I stay with the latter. 

Centreon, in contrast, is being built from source. I’m using the [sources available on GitHub](https://github.com/centreon/centreon), the branch of every component may be chosen using build arguments.

I’m aware of the availability of Centreon packaged in RPM. While this is (very) easy to deploy a standalone, and quite outdated, Centreon solution, it’s not well suited to deploy a multi-host supervision. Beside, being able to follow the developpement of the product and mastering its deployement (what is made possible installing from the source), seems to be a useful advantage to make things done.

The builds are made on the container itself (ie: there is no separate builder). I should probably change that in the futur but it’s not a priority for me (except if someone convince me of the contrary).

The image is named `centreon`

### [Centreon CLib](https://github.com/centreon/centreon-clib)

This is the base part of Centreon. No particular problem to build it. On CentOS as on Alpine.

#### [Centreon Broker](https://github.com/centreon/centreon-broker)

Build on Alpine (so using Musl as standard library) with many warnings. OK on CentOS with the GNU libc (and definitively faster).

#### [Centreon Engine](https://github.com/centreon/centreon-engine)

The monitoring engine is independent (ie: may be used without Centreon).

Using Alpine I discovered many compatibility problems in the source code. I tried to fix some, then I gave up. It’s OK on CentOS.

### [Centreon Connectors](https://github.com/centreon/centreon-connectors)

Both SSH and Perl connectors are built but some configuration remains to do. Connectors aren’t use in out current setup but are a promising functionality.

The SSH connector permits to maintain SSH connections between the poller and the supervised hosts, thus permiting to issue checks by SSH at a quite low cost.

## Docker volumes

### centreondb

#### centreondb-var-lib-mysql:/var/lib/mysql
 
This is the MariaDB $DATADIR.
 
### centreon

#### centreon-etc:/etc

The configuration of our Centreon server

### centreon-centreon-www:/centreon/www

The Centreon Web’s document root

## Directories

 - /centreon
 - /var/lib/centreon
 - /var/lib/centreon-engine
 - /var/lib/centreon-broker
 - /var/log/centreon
 - /var/log/centreon-engine
 - /var/log/centreon-broker
 - /etc/centreon
 - /etc/centreon-engine
 - /etc/centreon-broker

## What’s left to do

##### Centreon Connector Perl

Persistent Perl interpreter that executes Perl plugins very fast.

##### Centreon Connector SSH

Maintain SSH connexions opened to reduce overhead of plugin execution over SSH

#### Nagios plugins

Legacy monitoring plugins are currently installed from the package available in the system.

#### [Centreon](https://github.com/centreon/centreon)

Most of the application is written in PHP. As a downside for integration, it depends on PHP < 5.5 (NB: strictly inferior)

CentOS 7 is nice for this. We don’t have to install PHP from source as the distribution proposes PHP 5.4

#### Centreon files and directories 

All binaries related to Centreon are in /centreon (it’s used as installation prefix for all builds)

 - /centreon
 
As it’s used for installation, it also contains the default configurations, but we will never use those files.

Configuration, logs and variable data (metrics, status) are stored in the system default directories:

 - /var/lib/centreon-broker
 - /var/lib/centreon-engine
 - /var/lib/centreon
 - /var/log/centreon-engine
 - /var/log/centreon-broker
 - /var/log/centreon
 - /etc/centreon
 - /etc/centreon-engine
 - /etc/centreon-broker

## If this POC is successful 

What’s next…

### Downtimes

A container for our downtime manager.

### Inventory

A container for our inventory synchronization tool.

### Supervision Request

A container for our supervision requests tool.

### Centreon installation

Master all the Centreon toolchain, middleware + applications, from PHP to Centreon, by following the different upstreams and installing from source.

 - PHP
 - MariaDB
 - RRDTool
 - …
 - Nagios plugins
 - …



