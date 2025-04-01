# Quoting Tool

## Setup

The Quoting Tool is a Dockerized project. You will need to download and install the [Docker Desktop for Mac](https://docs.docker.com/docker-for-mac/install/) in order to use and develop the code.

In the directory where you have cloned the repo, run the following command to configure Webpacker to run as a separate service:

```
$ docker-compose run runner ./bin/setup
```

Next, build the docker containers for the service dependencies (this will take a while). This will build a Rails container, Mongo container, Redis container, and Angular Container:

```
$ docker-compose build
```

Next, create docker containers for the service dependencies. Note that the following two commands will both start a rails server running on localhost:3000. The difference is the first command will run the server process in the terminal window (where log output may be observed) while the second command will daemonize the server in its own background process.

```
$ docker-compose up
```

```
$ docker-compose up -d
```

You can stop the server running in background:

```
$ docker-compose stop rails
```

## Helpful Docker Commands

Following are some useful commands to manage your Docker environment. These commands must be run in the project directory.

Initiate a terminal session in the Docker container context:

```
$ docker-compose run runner
```

Enter CTRL-D to exit the terminal session

Get a list of active containers

```
$ docker-compose ps
```

See log file output for the application and dependent services

```
$ docker-compose logs
```

Start and stop application and all dependent container services. These commands work after the containers are created following successful execution of the `docker-compose up` command above.

```
$ docker-compose start
$ docker-compose stop
```

## Configuration

- Ruby 3.1.6
- Rails 6.0 w/options:
  - --skip-action-cable
  - --skip-active-record
  - --skip-test
  - --skip-system-test
  - --webpack-=angular
- Dependencies
  - Webpacker
  - MongoDb 4.2
  - Redis

## Frontend

The frontend uses the Angular framework to handle user interactions and is built using the Angular-cli generator.

You can visit [`localhost:4200`](http://localhost:4200) from your browser to see the UI.

## Setup UI in a new project

- Copy contents of clients to your new app.
- In clients > html angular.json change references from 'quoting-tool' to 'your apps name' will be 8 total
- In the In clients > html package.json change line 2 from 'quoting-tool' to 'your apps name'
- Now run docker-compose build, then docker-compose up

## Typescript

AEQT uses [TypeScript](https://www.typescriptlang.org) for all front-end code. TS is a superset of JS that adds static typing, allowing for more robust code and enhanced tools like code autocomplete.
Writing logic in TypeScript looks just like writing in JavaScript, but with additional type indicators for function arguments and component properties.

## Linting and formatting

TS code is linted with tslint, specifically the `tslint:recommended`, and `ng lint` rulesets. Run `ng lint` to check code, or integrate tslint in your editor for live feedback.

We've also installed prettier, which autoformats code and enforces some style decisions. To format [integrate it into your editor](https://prettier.io/docs/en/editors.html).

## Testing

Testing is handled with Karma, and components are tested with Angular Cli Testing Library. Tests are usually stored beside the file they're testing. Run `ng test` to watch files as you test and see the detail test coverage across the app.

## Organization

Inside the clients/html/src, the directories look roughly like this:

- `/app`
  - Contains the root files for the app - Router, Services, and Components.
- `/data`
  - Contains the json files that will be used to populate SIC codes, ZipCodes, Tooltips, and QHP/QDP data.
- `/services`
  - Contains the files used to communicate data across compoents and also make HTTP request to external systems if required.
- `/assets/scss`
  - Contains global style info, like themes, fonts, and common functions

## Helpful UI Resources

[`Angular`](https://angular.io/)

[`Angular cli`](https://cli.angular.io/)

[`Monster Angular Dashboard Template`](https://www.wrappixel.com/demos/angular-admin-templates/monster-angular/docs/documentation.html)
