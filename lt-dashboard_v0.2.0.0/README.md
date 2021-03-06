### Info ###		
		
 1. Tools		
  - Ruby (higher than 2.2.2)		
  - Dashing framework (check http://shopify.github.com/dashing for more information.)		
 2. [Third party widgets](https://github.com/Shopify/dashing/wiki/Additional-Widgets)		
  - [Google calendar](https://gist.github.com/jsyeo/39d3fde3afbffdd31093)		
  - [Atlassian Jira Agile: Tasks left in sprint](https://github.com/SocialbitGmbH/DashingJiraTasksLeftWidget)		
  - [Atlassian Jira Agile: Tasks done in sprint](https://github.com/SocialbitGmbH/DashingJiraTasksDoneWidget)		
  - [TeamCity LABS](https://github.com/FizzBuzz791/TeamCity-LABS)		
  - [Server status](https://gist.github.com/willjohnson/6313986)		
 3. Custom widgets		
  - Jira tasks (just 2in1 and critical / blocker filter in addition)		
  - Server status docker		
     - Getting remote machines stats (CPU usage, RAM usage, HDD usage)		
     - Looking for docker containers on remote machines		
     - Showing running and stopped containers		
     - Showing if environments are up or down depends on running and stopped containers 
  - docker resource - using remote machine stats from server status job and views it as a status bars 
 		
 ### Configuring ###		
 		
 1. Clone rep  		
 2. Create your credentials.yml using example		
 3. Bundle		
 ```		
     > bundle install		
 ```		
 ### Starting dashboard ###		
 ```		
     > dashing start		
 ```		
 ### Demo ###		
 		
 ![](http://i.imgur.com/xxwY67q.png "Example")
