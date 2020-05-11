# Group A final report

## System's Perspective

### Design of the _ITU-MiniTwit_ systems

#### MiniTwit Application

The MiniTwit application is structured around a single central `minitwit.rb` file that handles the routing of requests to different endpoints and the logic related to request/response actions. All other logic has been delegated to controllers related to different logical domains. For this we have the `login_controller.rb`, `message_controller.rb`, `register_controller.rb` and `user_controller.rb`. All database interaction is handled through the object-relational mapping (ORM).

![](https://github.com/janschill/uni-devops/raw/report/report/images/mad2.png)


#### MiniTwit API

The MiniTwit API is simple, which is also reflected in the structure of the application programming interface (API). The API consists of a single file that handles all requests, and all logic is handled within this file.

![](https://github.com/janschill/uni-devops/raw/report/report/images/mai2.png)

#### Database Abstraction 

We introduced a database abstraction layer (DAL, also referred to as ORM) in the form of the Ruby library Sequel. The library allows us to create classes representing the entities in the database and allows easy interaction through these model classes. Through Sequel we have created classes that represent entities in the database, namely `User`, `Message`, and `Follower`.

## Architecture of the _ITU-MiniTwit_ systems

The architecture of the system can be seen in the following diagram: 

![](https://github.com/janschill/uni-devops/raw/report/report/images/architecture.png)

The technology stack is described in detail in the following:

### MiniTwit Application and API

The MiniTwit application and API were created as Ruby scripts that handle requests and their routing via the Roda library. The Roda library is based upon the Rack framework.
We decided to use Ruby, because it is a modern and intuitive programming language. It is very developer-friendly, due to its nicely readable syntax and a well-maintained documentation. It is popular in the web development world, leading to a lot of solutions to problems that have occurred to others before.
The single most popular web development framework in the Ruby ecosystem is Ruby on Rails. Ruby on Rails is a large, mainstream framework that brings a lot with the instantiation from a single command. This would have caused a lot of overhead in our use case and we would have gotten a bit ahead of ourselves at the point of the refactoring of the single MiniTwit Python script. For this reason, we did not pick Ruby on Rails and looked for a different framework: Roda and Sinatra.
Roda and Sinatra are web frameworks written in Ruby that bring a lot of common functionality that is needed to build a small-scale web service. Even though both frameworks are lightweight they are not only just meant for small web service. Both frameworks come with an abstraction layer for HTTP routing, which makes it easy and convenient to set up a web service fairly quickly. The main difference between the routing is, that Roda uses a so-called routing tree and Sinatra a list of routes. A routing tree allows the nesting of different routes, for example the routing could be nested on the HTTP GET method, and then in there all different routes that should be handle by GET can be set up. Whereas in a list of routes in the worst-case the running time would be O(N) in a routing tree it is O(log n). This means the routing in Roda is faster and allows less code in the sense of DRY (do not repeat yourself). Because variables or methods, whatever is needed, with a list it has to be done in every item. See this comparison for a comprehensive code snippet: [http://roda.jeremyevans.net/compare_to_sinatra.html](http://roda.jeremyevans.net/compare_to_sinatra.html).
This was the main reason why we chose Roda over Sinatra.

### Database Abstraction Layer

As mentioned, the applications use the Sequel DAL to interact with the database.
Using a DAL (or ORM) has many benefits over using plain SQL queries. Using Sequel brings automatic query sanitization, not allowing query manipulations to execute malicious queries, preventing injection attacks. Also, it abstracts away the need of writing plain SQL, allowing more object-oriented commands in the application code:

```ruby
# SELECT * FROM users WHERE user_id = id LIMIT 1;
User.where(user_id: id).first
```

Furthermore, abstracting out every dependency to a specific relational database management system (RDMS) allows an easier migration to a different system, because – when the DAL supports a different system – the migration is as easy as only changing the form of connecting to the database in a configuration file.

### Database

The original Python system implemented a simple SQLite database in the beginning. When doing the refactoring to the Roda application we kept the changes as simple as possible and focused on the necessary parts of the refactor. Meaning we adapted the usage of an SQLite database.
Later on, when we started scaling our application with a load balancer and multiple droplets, this database architecture was not sufficient anymore and we changed to a DigitalOcean Managed MySQL database cluster. See chapter [Scaling and load balancing](#Scaling-and-load-balancing) for a more thorough explanation.

### Build systems

Rake is the default task-runner for Ruby projects. It is useful for reoccurring and straight-forward tasks that can be easily automated, like creating and seeding a database, starting the application, and exposing it on a web server. When the Rake gem is installed, it will look for a Rakefile in the root of the project. Different tasks can be described in the Rakefile, which will then be executed by typing for example:

```bash
$ bundle exec rake DB:create
```

Because the `control.rb` is doing exactly this, it is not needed once Rake is fully implemented with all the functionality the `control.rb` was doing.

### Virtualization

To be able to create containers and run the applications in identical environments on any system, we introduced Docker. Docker allows us to containerize the application and the API, making their execution environments the same each time. Both the application and the API run in Docker container images based on the very minimal Linux distro Alpine 3.11, running Ruby 2.6.5.

We chose to use Docker because it is known to be a useful tool when it comes to managing lots of instances at once and defining dependency versions in a Dockerfile. Indeed, using container virtualization has made it possible for us to deploy everything in a single time (with one command). It also makes the maintenance easier, if we ever have to change anything in the code base, and the retrieving of this codebase to our servers, as we only need to "pull" the image from Docker Hub.

### NGINX reverse proxy

We made use of NGINX as a reverse proxy such that we could configure subdomains for the different containers. This was very useful as we would have the API on `minitwit-api.janschill.de` and the actual app on `minitwit-app.janschill.de`. This allowed us to access the API without having to specify a certain port, but instead the easier memorable domain name could be used.

### Hosting

The MiniTwit systems are running on two DigitalOcean droplets.

### CI/CD

To implement continuous integration and continuous delivery (CI/CD) we are using Travis CI for automated deployment. The Travis CI pipeline clones the production branch, build and push Docker images to Docker Hub, and pull and run the images on the two droplets.

From GitHub project monitoring to testing Travis CI offers all the features we need and is simple to integrate into a GitHub project. It is also cloud-based which means we did not have to install anything to our server, adding more overhead to our server infrastructure.

### Monitoring

For monitoring we needed a metrics aggregator and a visualization tool. We used Prometheus to aggregate metrics. In our Ruby scripts, we used the Prometheus-Client gem, that allowed us to collect metrics within the app, while also exposing the `/metrics` endpoint. We would then have a Prometheus instance running on the droplets, collecting these metrics. We used the tool Grafana to use and visualize these metrics. Grafana collects the metrics and allows us to create dashboards with information derived from these metrics.

Using the metrics, we are monitoring how many requests are being sent to different endpoints in the systems, and the duration of these requests. We are also monitoring the CPU usage of the droplets and the uptime of the systems.

As a side note, we forgot to capture a screenshot of the dashboard with the metrics before we killed the system, which is why we are unable to include it in this report.

### Logging

To create meaningful logs for the events of our system, we use two different logging methods. The first method is the logging middleware built into Roda, which logs every request and response made to each of the Ruby scripts. The second method is a more manual logging mechanism, which is logging more meaningful events, such as user creation, user session actions (login/logout), message posting etc., and exceptions raised in either of the applications.
To be able to browse and analyze the logs created, we introduced the ELK stack. The ELK stack consists of Elastisearch, Logstash, and Kibana.
Logstash collects and aggregates the logs from the log files, Elastisearch stores and makes the logs searchable and Kibana allows for easy visualization and analysis of them.

## All dependencies of the _ITU-MiniTwit_ systems

### Dependencies for the application and API

![](https://github.com/janschill/uni-devops/raw/report/report/images/minitwit-app.png)

![](https://github.com/janschill/uni-devops/raw/report/report/images/minitwit-api.png)

| System              | App | API | Explanation                |
| ------------------- |:---:|:--: | :------------------------- |
| bcrypt              | x   | x   | Encryption                 |
| cgi                 | x   | x   | Ruby Standard Library      |
| dotenv              | x   |     | Read dotfiles              |
| faker               | x   |     | Generate fake entries      |
| json                | x   | x   | Work with JSON             | 
| literate_randomizer | x   |     | Generate random text       |
| logger              | x   | x   | Rack logging library       |
| mysql2              | x   | x   | MySQL library              |
| prometheus-client   | x   | x   | Prometheus client library  |
| Rack                | x   | x   | Webserver interface        |
| rake                | x   | x   | Task-runner                |
| roda                | x   | x   | Routing web toolkit        |
| rubocop             | x   | x   | Static code analysis       |
| rubocop-rspec       | x   | x   | Rubocop test library       |
| rubycritic          | x   | x   | Static code analysis       |
| sequel              | x   | x   | ORM                        |
| tilt                | x   | x   | Interface template engines |
| usagewatch_ext      | x   |     | CPU, Disk, TCP/UDP         |
| yaml                | x   | x   | Work with YAML             |

### Dependencies for tools, tasks, Bundler

![](https://github.com/janschill/uni-devops/raw/report/report/images/minitwit-utils.png)

| System              | Explanation                            |
| ------------------- |:------------------------------------- |
| fileutils           | Ruby library for file handling         |
| server.pid          | PID of running web server              |
| rackup              | Web server start script                |
| sqlite3             | SQLite library                         |
| kill                | Shell script to kill process           |
| flag_tool           | Database helper script                 |
| securerandom        | Random string generation               |
| rbenv               | [rbenv and Bundler](#rbenv-and-Bundler)|
| .ruby-version       | [rbenv and Bundler](#rbenv-and-Bundler)|

#### rbenv and Bundler

When working with Ruby a convenient way of versioning the releases of Ruby is using the tool rbenv. rbenv hooks into Ruby commands and determines which Ruby version to use specified by the current working directory. One way which we will be using to set the Ruby version is by having a file called `.ruby-version` with the version number as its content, in the root directory. rbenv will parse this file and make sure that this version is installed. In combination with bundler, which is a tool to install exactly the gem versions set by the project, a flawless versioning of Ruby and all the project's gems is given.

### Dependencies for Docker, docker-compose.yml, .travis.yml

![](https://github.com/janschill/uni-devops/raw/report/report/images/minitwit-deployment.png)

### Dependencies for the whole system

![](https://github.com/janschill/uni-devops/raw/report/report/images/minitwit.png)

## Process' perspective

### Interaction as a developer

To communicate within the team, we used Slack. This communication tool has revealed itself to be very useful. After the end of each session, we would meet each other (in real life first, and then on zoom during the COVID-19 crisis) and talk about what has to be done and by whom. We never had to put aside any feature as a result of having to decide which one to implement and which one to throw.

## Development chain 

### Team organization

Throughout the development the team has changed organizations many times. At the very beginning, everyone was doing a bit of everything so we could all have our eyes on the overall system. When the sessions started to get more complex as the task did, some of us started to "specialize" into some parts of the development. For example, some of us would be more onto web development and server maintenance and some of us would handle the CI/CD tools from bottom up. In the end, even though each of us would handle specific parts of the development, we would still all be able to take over someone else's task if we had to, meaning that we were all aware of the who and what for each feature.

### Task distribution and branching strategy

Every time we receive new tasks, we split them into feature and assign them to someone. To keep track of our work, we are using GitHub tools, as the "issues" tab and the Kanban board that is provided. That way we can easily see what needs to be done each week and who is working on what. Working with issues also allows us to quickly respond to problems as we can assign someone to it. Once one of us is assigned to a task, he creates a branch on its own and starts working on it. Once the task is done, the developer will create a pull request to master. Because not everybody gets to work on everything, we have set up a rule on pull requests, such as we should always assign all of us to review it. This way, everybody gets to see everything, even though they did not have the chance to work on it. Further it helps to spot errors or design decisions that might not conform with the opinion of others – it is a good way of discussing new code. Once the review gets approved, it can safely be merged to master. We also have a branch called `production` that we use to trigger the CI tool. Once every week, two of us would take care of deploying the site to production, and to create a release of the codebase.

### The CI/CD chains

An overview of the deployment sequence can be seen in the diagram:

![](https://github.com/janschill/uni-devops/raw/report/report/images/deployment_diagram.png)

### Code analysis

We used different tools in our CI/CD chain for providing static code analysis and ensure the quality and conventions of our codebase. These tools will be run automatically when triggered under specifics rules.

##### Rubocop

Rubocop is a static code analyzer and formatter, based on the community Ruby style guide. [https://docs.rubocop.org](https://docs.rubocop.org). It notes differences in the formatting to the community Ruby style guide. Added to the pipeline it will make the check fail, ensuring an evenly formatted code base. On top of that it also analyses to a limited degree certain code smells, like writing long method bodies.
Rubocop allows the configuration of the rules project-based, this means that when a `.rubocop.yml` file is placed in the home directory, rules can be either enabled or disabled as desired. 

##### RubyCritic

RubyCritic is a code quality reporter. It uses a set of tools like Reek, Flay, and Flog. With all the results from those tools, it then generates a report that can be viewed in an HTML file or JSON. It also evaluates a score from the complete code base. This score can be used to map the code quality over time. This score is not yet elevated other than not allowing a score below a set threshold in our pipelines.
GitHub Actions allows the generation and upload of artifacts, which can be used to upload every report generated by RubyCritic and the workflow that we have integrated. These reports can then be downloaded and viewed and even compared over time to ensure a certain quality for the project.

###### Report for the app

![](https://github.com/janschill/uni-devops/raw/report/report/images/rubycritic-app-overview.png)

###### Example show case for code smell

![](https://github.com/janschill/uni-devops/raw/report/report/images/rubycritic-app-codesmell-1.png)

###### GitHub Actions artifacts

![](https://github.com/janschill/uni-devops/raw/report/report/images/rubycritic-github_actions.png)

##### SonarCloud

SonarCloud is another code analysis tool that we used. SonarCloud can perform analysis on several different languages and does so automatically by detecting the different languages present in the repository. The result of running SonarCloud on the final state of the project repository:

![](https://github.com/janschill/uni-devops/raw/report/report/images/sonarcloud-overview.png)

#### Travis CI

As has already been mentioned earlier; we have two main branches: `master` and `production`. The production branch is updated once a week, the night of the release, whereas the master branch is updated from time to time with our new addition. Knowing that, we have set up a two-stage integration with Travis, called:

- Test
- Deploy

The test build will be triggered every time one of us is trying to open up a pull request (PR) on the master and production branch. This way we can unit test the branch automatically and finally skipping the manual testing. The test build only builds the docker image, and succeed if the image has been created with success. We then have a deploy build, which is triggered only when one of us merges master to production via a PR. This way, a container is built from the PR, and pushed to Docker Hub, and then retrieved from our server to be put up online. The deploy stage takes care of uploading the built docker images to our Docker Hub repository and pull them back to the two droplets. The next step is to start the servers, and to do that Travis sends a `docker-compose up` command to both of them, so the whole setup can be instantiated by itself. 

![](https://github.com/janschill/uni-devops/raw/report/report/images/travis-overview.png)

#### GitHub Actions

With the introduction of static code analysis, we decided to use GitHub Actions to include it into our pipeline. Our full commitment to GitHub as our version control system (VCS), project management tool, documentation host, we were intrigued to check out GitHub Actions. This brings the benefit of having the automation of software workflows a) in the form of the configuration files in our repository and b) direct access to the builds in a GitHub tab.
Even though GitHub Actions is fairly new it already features a wide variety of snippets that can be easily used and integrated to do reoccurring tasks, like uploading files to a remote server, or building a Ruby project.
The integration was flawless and was set up within a few hours, making us regret the decision of using Travis for the building of our Docker images. Travis has its benefits, but because GitHub Actions was so easy to set up, the project would gain value in using only one automation tool.
We use GitHub Actions to use three different static code analysis tools on our whole Ruby code base and to upload the files that we need to build the Docker images on our production server – as our Travis pipeline only uploads the Docker images, causing issues if we need files outside of them.
To connect to a remote server, we need an SSH key and the IP address, those are stored – just like Travis offers – in secrets, which can be found in the repository settings.

### The repository

First of all, we chose to have all our codebase in a single mono-repository, and there are multiple reasons for that: Firstly, everything is located in the same place, which makes code maintenance and CD/CI integration easier. Secondly, since our system is not broad, it does not require any kind of module/multiple repositories. At the root there are directories for the application, the API, which are the core of our project. It also contains every kind of useful file such as the Travis rules or the security proposal. 


![](https://github.com/janschill/uni-devops/raw/report/report/images/github-repository-overview.png)

## Scaling and load balancing

We decided to go with the managed Load Balancer integration provided by DigitalOcean. In the DigitalOcean projects window a Load Balancer can be added as easy as creating a new Droplet. Once created it needs at least two Droplets to evenly distribute the incoming traffic. Using SQLite with this infrastructure would make the synchronization of the data difficult. This is because that the SQLite databases would be stored locally on each droplet which would make synchronization of the databases difficult. This is why we decided to introduce a managed DigitalOcean database. A managed database can also just as easily be created in the DigitalOcean backend. DigitalOcean supports three different database engines on their managed databases: MySQL, PostgresSQL, and Redis. We decided to use MySQL because we have had the most experience with this engine, which would make the migration the easiest for us, so we can focus on the new concepts of scaling an application and database instead of learning a new database engine.

To use MySQL in this managed database setup, we had to migrate our data from the SQLite database file to the new cluster and also make sure the application and API can use a MySQL database. This took some manual work as the SQL dialect for SQLite and MySQL are different. Resulting in some changes in our database schema: such as changing the data type of a field from the SQLite `string` to the MySQL `VARCHAR`. Afterward we had the problem of moving the data contained in the SQLite database onto the managed MySQL database. This proved more difficult as we initially thought because of the sheer volume of data we had to accumulate. We had roughly 50000 user entries, 1.6 million follower entries, and around 2 million messages. This took around 24 hours to migrate. This did not interfere with our uptime though, as the SQLite database was still being used while we migrated the data. This meant that we had to do another migration afterward for all the data added in the last 24 hours, this was a much quicker process, which only resulted in a small amount of downtime.

Regarding a refactor of the codebase to allow for a database change, there was no problem. This was because we were already using Sequel. This allowed us to use the new database with the change of a couple of lines in our database application configuration. The ORM would then automaticly translate our high-level constructs to the correct MySQL dialect, which results in the smooth transitions. This has shown us that one of the great features of using an ORM is the abstraction that allows us to migrate the database easily.

![](https://github.com/janschill/uni-devops/raw/report/report/images/do-load_balancer-overview.png)

![](https://github.com/janschill/uni-devops/raw/report/report/images/do-droplet_1-days_30-overview.png)

![](https://github.com/janschill/uni-devops/raw/report/report/images/do-droplet_2-days_30-overview.png)

![](https://github.com/janschill/uni-devops/raw/report/report/images/do-database-overview.png)

### Direct effect

Since we now have two droplets on which our app and API are hosted, we have reduced our downtime on deployment to zero. Indeed, deployment will first shutdown the first droplet, which will make the load balancer redirect traffic on the other. When the first one has been deployed, the second is shut down and traffic is redirected to the first one. This way users can use and navigate the website without even noticing deployment.

### Monitoring performances

We implemented our gem called Stalker. It can be configured to hit multiple websites in a given frequency. This allows us to deploy it to our server and then run it. It requests the given websites and logs the returned HTTP status code and the response time. These log files will allow us to verify the stated service level agreement (SLA) for any given team. It also allows us to ensure that we are holding up to our SLA.
The choice of implementing something own came with the fact that not too many complex features were needed. It had to ping a different endpoint on a domain and write information gathered into a file.

#### Implementation

Our script is therefore split into two parts: a connector class that handles the connection to the remote server and a writer class that handles the writing to a file in a log-valid format, that being all the gathered information in one single line.
The script once deployed onto the server can be started by using the already in the project introduced task-runner Rake. The script will ping in a set interval the remote server and check how long it took to receive a response, this duration and the HTTP code are logged to a file.

To do the analytics of the monitored logs, a Ruby Jupyter notebook was created, which is essentially the same as a Python Jupyter notebook, but only for the Ruby language. In there we analyzed the distribution of HTTP codes and the response times on different endpoints.

#### Analytics

The results of our monitoring can be seen in the following:

```
Number of requests: 827057
Endpoints: ["/", "/public", "/login", "/register", "/api/latest", "/api/msgs"]
Returned HTTP codes: ["302", "200", "500"]
Occurrences of HTTP codes: {"302"=>206759, "200"=>535497, "500"=>84801}
Average response times:
- /: 59 ms
- /public: 335 ms
- /login: 3 ms
- /register: 2 ms
- /api/latest: 5 ms
- /api/msgs: 45 ms
- all endpoints: 100 ms
```

![Distribution of HTTP codes](https://imgur.com/znG4jEA.png)

The SLA of the monitored group cannot be fulfilled due to the unfortunate event of a what seems to be a crash on their server and unreachable public endpoint for a lot of requests.
The response time on the other hand seems to be fine and compliant to their SLA.

### System security assessment of our System

#### Assets

Our application is divided into multiples assets that can be defined as external and internal. We call "external" an asset that is not properly developed by us or where we have limited access to. An "internal" asset is something that has been designed and created by us or an external asset where customization is possible (or at least made easier).

##### External assets

- GitHub
- Travis CI
- Docker Hub
- DigitalOcean

##### Internal assets

- APP
- API
- Database
- Docker
- Logging system
    - Logstash
    - Kibana
    - Elastisearch
- Monitoring system
- Graphana
- Prometheus
- Target Monitoring system
    - Stalker

#### Risk matrix

We can now with our assets defined use a risk matrix. A risk matrix is used when one wants to know the potential risk of an action over a system. The X-Axis is the likelihood and the Y-Axis is the consequences. Each axis is labeled from very-low to high. 

![](https://github.com/janschill/uni-devops/raw/report/report/images/riskmatrix1.png)

Imagine we would like to change our database from SQLite to MongoDB. We will create multiple stories with potential risks as follows:

- Database migration: The migration could crash, and we would lose our data
- Code reformatting: Bugs and problems could be added
- Framework adaptation: Bugs and problems could be added
- ...

Now that we have defined multiple cases, we can use the risk matrix to see if migrating now is worth the risk. Let's use the "Database migration" with the sub-story "The migration could crash […]". In that case, the likelihood of this event happening is rather "VERY LOW" but the consequences would be tremendous (HIGH). We can thus search in the risk matrix for a very low likelihood and a high consequence to point out the risk:

![](https://github.com/janschill/uni-devops/raw/report/report/images/riskmatrix2.png)

When we finally know what the risk is, we can safely and easily say if implementing this task would be worth it or not.


#### Penetration test

We performed a penetration test of our system looking for OWASP top 10 vulnerabilities. Doing the testing we found several security issues with our Minitwit application.

The first issue we found is #7 on OWASP top 10. It is a Cross-Site Scripting (XSS) issue, and one of the worst types, a stored XSS. The problem occurs when users send a message containing text which can be interpreted as HTML. This will cause the message to be displayed as HTML, and if this HTML contains JavaScript this JavaScript will also be executed in the context of our application. This means that an attacker can post a message, which when viewed by a victim will steal the victims' session and allow the attacker to take over the victims account.

We mitigated this issue by escaping all HTML characters in messages and usernames, such that an attacker is no longer able to inject HTML into these. The fix can be seen [here](https://github.com/janschill/uni-devops/pull/164).

The second issue is #2 on OWASP top 10. It is a Broken Authentication issue, where attackers were able to log in as other users, without these users’ password. This issue was [reported to us](https://github.com/janschill/uni-devops/issues/139) by our partner group. The issue is in our `login_controller.rb`, which is the controller that handles login. The error occurred because of a logical bug in the following snippet.

```ruby
if user.nil?
  error = 'Invalid username'
elsif !user.password == @request.params['password']
  error = 'Invalid password'
end
```

This also alerted us to the fact that we were not checking the hash of the password, but rather checking if the submitted password matched the one for the user. This would report an incorrect password for all login attempts, as passwords are stored as hashes.

We mitigated this issue by using the bcrypt password checking functionality:

```ruby
if user.nil?
  error = 'Invalid username'
elsif BCrypt::Password.new(user.password) != @request.params['password']
  error = 'Invalid password'
end
```

### Test the Security of our Monitored Team

To test the security of our monitored team, we also looked at the OWASP top 10 issues.
The scope of the penetration test was

* the Minitwit App running on http://46.101.119.181:11501/ 
* the Minitwit API running on http://46.101.119.181:11501/api 

we found the following vulnerabilities:
 
The first issue we found was #6 on OWASP top 10, which is Security misconfiguration, and in this case, it is verbose error messages. This can be a problem as error logs can disclose confidential information. Such as source code, secret variables, or the structure of the application. We got verbose error messages on every error we encountered.

```
WebApplication.Exceptions.UnknownUserException: Unknown user with username: $asd
   at WebApplication.Services.UserService.GetUserFromUsername(String username, CancellationToken ct) in /src/WebApplication/Services/UserService.cs:line 60
   at WebApplication.Controllers.TimelineController.UserTimeline(String username, CancellationToken ct) in /src/WebApplication/Controllers/TimelineController.cs:line 130
   at Microsoft.AspNetCore.Mvc.Infrastructure.ActionMethodExecutor.TaskOfIActionResultExecutor.Execute(IActionResultTypeMapper mapper, ObjectMethodExecutor executor, Object controller, Object[] arguments)
   at Microsoft.AspNetCore.Mvc.Infrastructure.ControllerActionInvoker.<InvokeActionMethodAsync>g__Awaited|12_0(ControllerActionInvoker invoker, ValueTask`1 actionResultValueTask)
   at Microsoft.AspNetCore.Mvc.Infrastructure.ControllerActionInvoker.<InvokeNextActionFilterAsync>g__Awaited|10_0(ControllerActionInvoker invoker, Task lastTask, State next, Scope scope, Object state, Boolean isCompleted)
   at Microsoft.AspNetCore.Mvc.Infrastructure.ControllerActionInvoker.Rethrow(ActionExecutedContextSealed context)
   at Microsoft.AspNetCore.Mvc.Infrastructure.ControllerActionInvoker.Next(State& next, Scope& scope, Object& state, Boolean& isCompleted)
   at Microsoft.AspNetCore.Mvc.Infrastructure.ControllerActionInvoker.<InvokeInnerFilterAsync>g__Awaited|13_0(ControllerActionInvoker invoker, Task lastTask, State next, Scope scope, Object state, Boolean isCompleted)
   at Microsoft.AspNetCore.Mvc.Infrastructure.ResourceInvoker.<InvokeNextResourceFilter>g__Awaited|24_0(ResourceInvoker invoker, Task lastTask, State next, Scope scope, Object state, Boolean isCompleted)
   at Microsoft.AspNetCore.Mvc.Infrastructure.ResourceInvoker.Rethrow(ResourceExecutedContextSealed context)
   at Microsoft.AspNetCore.Mvc.Infrastructure.ResourceInvoker.Next(State& next, Scope& scope, Object& state, Boolean& isCompleted)
   at Microsoft.AspNetCore.Mvc.Infrastructure.ResourceInvoker.<InvokeFilterPipelineAsync>g__Awaited|19_0(ResourceInvoker invoker, Task lastTask, State next, Scope scope, Object state, Boolean isCompleted)
   at Microsoft.AspNetCore.Mvc.Infrastructure.ResourceInvoker.<InvokeAsync>g__Awaited|17_0(ResourceInvoker invoker, Task task, IDisposable scope)
   at Microsoft.AspNetCore.Routing.EndpointMiddleware.<Invoke>g__AwaitRequestTask|6_0(Endpoint endpoint, Task requestTask, ILogger logger)
   at Microsoft.AspNetCore.Authorization.AuthorizationMiddleware.Invoke(HttpContext context)
   at WebApplication.Startup.<>c.<<Configure>b__3_2>d.MoveNext() in /src/WebApplication/Startup.cs:line 152
--- End of stack trace from previous location where exception was thrown ---
   at Microsoft.AspNetCore.Authentication.AuthenticationMiddleware.Invoke(HttpContext context)
   at Swashbuckle.AspNetCore.SwaggerUI.SwaggerUIMiddleware.Invoke(HttpContext httpContext)
   at Swashbuckle.AspNetCore.Swagger.SwaggerMiddleware.Invoke(HttpContext httpContext, ISwaggerProvider swaggerProvider)
   at Prometheus.HttpMetrics.HttpRequestDurationMiddleware.Invoke(HttpContext context)
   at Prometheus.HttpMetrics.HttpRequestCountMiddleware.Invoke(HttpContext context)
   at Prometheus.HttpMetrics.HttpInProgressMiddleware.Invoke(HttpContext context)
   at Microsoft.AspNetCore.Diagnostics.DeveloperExceptionPageMiddleware.Invoke(HttpContext context)
```

The second issue we found was #6 on OWASP top 10, which is Security misconfiguration, and in this case it is an information leak on an endpoint, where we can see other users GET requests. This endpoint should require authentication.

```
http://46.101.119.181:11501/metrics
```  

The third issue we found was #5 on OWASP top 10, which is Broken Access Control. The API does not check the authorization header, allowing anyone to make requests to the API. This is a problem since we can post messages on behalf of all users without any password. Using Python and the requests library we can make a post request against the API allowing us to post a message as the user `abc`.

```
requests.post("http://46.101.119.181:11501/api/msgs/abc", data=json.dumps({"content": "I don't have the password"}))
```

The fourth issue we found was #3 on OWASP top 10, which is Sensitive data exposure.
The credentials for Elastisearch are stored in plaintext in the repository, allowing anyone to log into Kibana and look at the system logs.

```
http://elastic:wpv47zN8@134.209.245.96:9200  
http://134.209.245.96:5601/
```

## Lessons Learned Perspective

One of the biggest issues we had was that our droplets were running out of memory very quickly. Indeed, after each session we would be adding a lot of services that would raise the memory usage. This was causing our application to be consequently slow and some of our containers to crash. We solved the issue by raising memory in DigitalOcean. Further we reviewed our codebase to see if some queries were causing trouble. Doing some adjustments did save us memory, but not enough to prevent us from upgrading our droplets.

We had issues with the latest ID not increasing as fast after we introduced a second droplet and a load balancer. This can be seen in the most recent reports of latest ID from the simulator:

![](https://github.com/janschill/uni-devops/raw/report/report/images/simulation-history-lastest_id.png)

As can be seen, the latest ID does not increase as fast towards the end of the lifetime of our system. We realized this was because the latest ID was tied to the MiniTwit API instance, and a request containing a latest ID could be forwarded to one droplet, and another request to get the latest could be forwarded to the other, reporting a wrong latest ID. We did implement a fix to this: adding the latest ID to the database, but we did not manage to deploy it to our droplets, before the simulator was turned off.

In general, throughout the lifetime of the system, we had issues with increasingly slow queries made to the database. During the last DevOps lecture, when the different groups were sharing experiences, some groups mentioned that they had added indices to the tables in their databases to increase the speed at which they were able to retrieve data from the database. We did not know of indices and the performance boost they provide. This is something we are going to take with us from this experience.

Furthermore, we learned a lot about how to split up and delegate tasks, which we found not to be a trivial problem, as many tasks have cross requirements. To solve this, it requires accountability from the members of the team, such that it is clear what needs to be done and at what time it has to be finished. As the project evolved, we got better at this and learned some valuable lessons about working together as a team and on a software project in general.

## What the team thinks of DevOps

From a general perspective, we all have learned a lot from this course. Starting from choosing Ruby as our main language, to adding tools for code analysis. None of us did use DevOps tools previously and learning them was a great deal. We all think that these tools are going to be useful in our foreseeable future. 
However, even though this large pipeline we created to get everything working and tested automatically was great, it is probably not always necessary for every project. We think that having automated testing and analyzing is important, but it should always be evaluated before setting up if it is going to be worth it. For example, including Rubocop in a Ruby project and making it run in GitHub Actions requires maybe one hour and is worth every minute, because it will catch errors and code smells that one can easily oversee.
We think DevOps is an essential part of software projects as it provides the foundation on which software developers can build great software as it both improves the quality of life of the developers when they develop and often increases the maintainability of the project.

