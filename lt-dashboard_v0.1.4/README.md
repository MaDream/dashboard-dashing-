### Info ###

1. Tools
 - Ruby (higher than 2.2.2)
 - Dashing framework (check out http://shopify.github.com/dashing for more information.)
2. [Third party widgets](https://github.com/Shopify/dashing/wiki/Additional-Widgets)
 - [Google calendar](https://gist.github.com/jsyeo/39d3fde3afbffdd31093)
 - [Atlassian Jira Agile: Tasks left in sprint](https://github.com/SocialbitGmbH/DashingJiraTasksLeftWidget)
 - [Atlassian Jira Agile: Tasks done in sprint](https://github.com/SocialbitGmbH/DashingJiraTasksDoneWidget)
 - [TeamCity LABS](https://github.com/FizzBuzz791/TeamCity-LABS)
 - [Server status](https://gist.github.com/willjohnson/6313986)
3. Custom widgets
 - Jira tasks (just 2in1)
 - Server status docker
    - Getting remote machines stats (CPU usage, RAM usage, HDD usage)
    - Looking for docker containers on remote machines
    - Showing running and stopped containers
    - Showing if environments are up or down depends on running and stopped containers 

### Configuring ###

1. Clone rep  
2. Create your credentials.yml using example
3. Bundle
```
    > bundler install
```
### Starting dashboard ###
```
    > dashing start
```
### Demo ###

![](http://i.imgur.com/O3s0M2p.png "Example")