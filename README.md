# linux-random-service

Harvest random bytes service.

## Introduction

__Linux::Random::Service__ provides a simple REST API to enqueue jobs to
retrieve data from the Linux kernel random pools.
The service is based on the __Linux::Random__
[package](https://github.com/tschaefer/linux-random).

## Installation

Follow the instruction to install the __Linux::Random__ package.

Install required databasei service.

    $ sudo apt install postgresql

Install optional notification service.

    $ sudo apt install redis-server
    $ cpanm Mojo::Redis

Install package.

    $ perl Makefile.PL
    $ make dist
    $ VERSION=$(perl -Ilib -le 'require "./lib/Linux/Random/Service.pm"; print $Linux::Random::Service::VERSION;')
    $ cpanm Linux-Random-Service-$VERSION.tar.gz

## Usage

Create database.

    $ su --login postgres --command \
        "psql -c \"CREATE ROLE bender WITH LOGIN PASSWORD 'rocks';\""
    $ su --login postgres --command \
        "psql -c \"CREATE DATABASE random OWNER bender;\""

Create configuration file.

    $ cat > /etc/linux-random-service.conf <<EOF
    {
      postgres => 'postgresql://bender:rocks@127.0.0.1:5433/random',
      secrets  => ['65ca7be5-7d76-4f56-8397-d1f8646a9278'],
      redis    => {url  => 'redis://127.0.0.1:6379', channel  => 'Random::Service::Notifications',},
      admin    => {user => 'bender',                 password => 'rocks',},
      root     => '/random',
      log      => {level => 'info',},
    }
    EOF

The notification service (redis) and the admin interface are optional. For
disabling just comment or remove the related setting.

Start job queue worker (minion).

    $ RANDOM_SERVICE_CONFIG = /etc/linux-random-service.conf rnd-service minion worker

Start REST API service (mojo).

    $ RANDOM_SERVICE_CONFIG = /etc/linux-random-service.conf rnd-service daemon --listen http://127.0.0.1:3000

Enqueue job.

    $ curl --silent --request POST --header 'Accept: application/json' --header 'Content-Type: application/json' http://127.0.0.1:5000/random/job/enqueue?bytes=512
    {"id":2}

Get job status;

    $ curl --silent --request GET --header 'Accept: application/json' --header 'Content-Type: application/json' http://127.0.0.1:5000/random/job/status/2
    {"id":2,"info":{"args":["512",null],"attempts":1,"children":[],"created":1675113822.09616,"delayed":1675113822.09616,"expires":null,"finished":1675113822.12773,"lax":0,"notes":{},"parents":[],"priority":0,"queue":"default","retried":null,"retries":0,"started":1675113822.10722,"state":"finished","task":"randomness","time":1675113915.16747,"worker":2}}

Fetch job result.

    $ curl --silent --request GET --header 'Accept: application/json' --header 'Content-Type: application/json' http://127.0.0.1:5000/random/job/result/2
    {"id":2,"result":"-----BEGIN RANDOM DATA-----\nAaHUCTlxMzSXx0BGEjmrR2CjpzBrFT8RLtNlUN89BO4tSETN63DGvO9nUsnK76TjwA3jsSzCihm8\nXxNIWs6CcyLRqxYt+H0MLf6xGuQ7eN09IvVxnNjNIa8p2mVCvoNyOQiQihbpGgCCvOXYM4UFSQaE\nDiE7O6DHXAGKK+LdIitPEvJJ\/sj+EorBa938H5YRnnw4G2R5LpY79P8rUB0ri5gkU+yrvz2pbmGG\nrC9IlQRV6vOqFywXht09pcCDtFO3lG9U0\/WmJUfHWA3OZOPMPeSGEziL2m0Htxa+e7mYVbep5cqX\nmcM6cYYntVmwUyQ4ZVLFLZzyanJV4AYQkaF+aFVI8kaD9GXhPGocgOX9Cc1Yzd4zgmPzb8P6wO97\nqFpYFaZvKH3Dbe7uiphsLCVJr62QgF+uqKioeQfVusOmFtXMynGdEWXyKf7sD0kHp3JYIXuSGc1C\n1Xwfl7aEpXPbvSzPbzcWquwNqhfC91Rv\/QCU9MF11GZAmQctE+Y2RisoRFtNS\/p+vGshiCFS5gy6\nakrSFPcVqv4KcNqpKCImXd2WFJyMNRVn9DIVvvBU932KQArAPG9i\/sC103UE\/nmvHwebM1VR15c4\nHFhFXaAPgnaJHj7a168wI4YJn9kY8l0TtzX\/AXittavtzdA83TD8a5hWk3sXeqCpPamLeMQODd4=\n-----END RANDOM DATA-----"}

## License

[The "Artistic License"](http://dev.perl.org/licenses/artistic.html).

## Is it any good?

[Yes](https://news.ycombinator.com/item?id=3067434)
