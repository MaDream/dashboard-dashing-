#!/usr/bin/env ruby

require 'json'
require 'net/http'
require 'openssl'

# Config

config_file = File.dirname(File.expand_path(__FILE__)) + '/../config/credentials.yml'
config = YAML::load(File.open(config_file))

jira_board_id      = config['jira_board_id2']
jira_username      = config['jira_username']
jira_password      = config['jira_password']
jira_url           = config['jira_url']

def getTasksLeftForActiveSprint (jira_board_id, jira_username, jira_password, jira_url)
	tasksLeft = 0
	
	sprintUri = URI("https://#{jira_url}/rest/agile/1.0/board/#{jira_board_id}/sprint?state=active")

	
	Net::HTTP.start(sprintUri.host, sprintUri.port,
		:use_ssl     => sprintUri.scheme == 'https', 
		:verify_mode => OpenSSL::SSL::VERIFY_NONE) do |http|

		request = Net::HTTP::Get.new sprintUri.request_uri
		request.basic_auth jira_username, jira_password

		sprintResponse     = http.request request
		sprintResponseJson = JSON.parse(sprintResponse.body)

		sprintId  = sprintResponseJson['values'][0]['id'];  
		issues    = []
		startAt   = 0;
		
		loop do 
		
			issuesUri = URI("https://#{jira_url}/rest/agile/1.0/sprint/#{sprintId}/issue?startAt=#{startAt}")
			hadIssues = true
		  
			Net::HTTP.start(issuesUri.host, issuesUri.port,
				:use_ssl     => issuesUri.scheme == 'https', 
				:verify_mode => OpenSSL::SSL::VERIFY_NONE) do |http|

				request = Net::HTTP::Get.new issuesUri.request_uri
				request.basic_auth jira_username, jira_password

				issuesResponse = http.request request
				issuesResponseJson = JSON.parse(issuesResponse.body)

				newIssues = issuesResponseJson['issues'];
				
				if newIssues.length > 0
					issues = issues + newIssues
				else
				    hadIssues = false
				end
			end
			
		    startAt = startAt + 50
		
		    break if !hadIssues
		end 
		
		issues.each { |issue|
			fields = issue['fields'];

			if (!fields['resolutiondate'] || fields['resolutiondate'].length == 0)
			    tasksLeft = tasksLeft + 1
			end
		}
	end
 
	puts "... tasks left: #{tasksLeft}"
 
	return tasksLeft
end


def getTasksDoneForActiveSprint (jira_board_id, jira_username, jira_password, jira_url)
	tasksDone = 0
	
	sprintUri = URI("https://#{jira_url}/rest/agile/1.0/board/#{jira_board_id}/sprint?state=active")

	puts "... requesting #{sprintUri.request_uri}"
	
	Net::HTTP.start(sprintUri.host, sprintUri.port,
		:use_ssl     => sprintUri.scheme == 'https', 
		:verify_mode => OpenSSL::SSL::VERIFY_NONE) do |http|

		request = Net::HTTP::Get.new sprintUri.request_uri
		request.basic_auth jira_username, jira_password

		sprintResponse     = http.request request
		sprintResponseJson = JSON.parse(sprintResponse.body)

		sprintId  = sprintResponseJson['values'][0]['id'];  
		issues    = []
		startAt   = 0;
		
		loop do 
		
			issuesUri = URI("https://#{jira_url}/rest/agile/1.0/sprint/#{sprintId}/issue?startAt=#{startAt}")
			hadIssues = true
		  
			puts "... requesting #{issuesUri.request_uri}"
		  
			Net::HTTP.start(issuesUri.host, issuesUri.port,
				:use_ssl     => issuesUri.scheme == 'https', 
				:verify_mode => OpenSSL::SSL::VERIFY_NONE) do |http|

				request = Net::HTTP::Get.new issuesUri.request_uri
				request.basic_auth jira_username, jira_password

				issuesResponse = http.request request
				issuesResponseJson = JSON.parse(issuesResponse.body)

				newIssues = issuesResponseJson['issues'];
				
				if newIssues.length > 0
					issues = issues + newIssues
				else
				    hadIssues = false
				end
			end
			
		    startAt = startAt + 50
		
		    break if !hadIssues
		end 
		
		issues.each { |issue|
			fields = issue['fields'];

			if (fields['resolutiondate'] && fields['resolutiondate'].length > 0)
			    tasksDone = tasksDone + 1
			end
		}
	end
 
	puts "... tasks done: #{tasksDone}"
 
	return tasksDone
end

def getBlockerAndCritTasks (jira_board_id, jira_username, jira_password, jira_url)
	tasksBlockAndCrit = 0
	
	sprintUri = URI("https://#{jira_url}/rest/agile/1.0/board/#{jira_board_id}/sprint?state=active")

	
	Net::HTTP.start(sprintUri.host, sprintUri.port,
		:use_ssl     => sprintUri.scheme == 'https', 
		:verify_mode => OpenSSL::SSL::VERIFY_NONE) do |http|

		request = Net::HTTP::Get.new sprintUri.request_uri
		request.basic_auth jira_username, jira_password

		sprintResponse     = http.request request
		sprintResponseJson = JSON.parse(sprintResponse.body)

		sprintId  = sprintResponseJson['values'][0]['id'];  
		issues    = []
		startAt   = 0;
		
		loop do 
		
			issuesUri = URI("https://#{jira_url}/rest/agile/1.0/sprint/#{sprintId}/issue?startAt=#{startAt}")
			hadIssues = true
		  
			Net::HTTP.start(issuesUri.host, issuesUri.port,
				:use_ssl     => issuesUri.scheme == 'https', 
				:verify_mode => OpenSSL::SSL::VERIFY_NONE) do |http|

				request = Net::HTTP::Get.new issuesUri.request_uri
				request.basic_auth jira_username, jira_password

				issuesResponse = http.request request
				issuesResponseJson = JSON.parse(issuesResponse.body)

				newIssues = issuesResponseJson['issues'];
				
				if newIssues.length > 0
					issues = issues + newIssues
				else
				    hadIssues = false
				end
			end
			
		    startAt = startAt + 50
		
		    break if !hadIssues
		end 
		
		issues.each { |issue|
			fields = issue['fields'];

			if (!fields['resolutiondate'] || fields['resolutiondate'].length == 0)
				if (fields['priority']['name'] == 'Блокирующий' || fields['priority']['name'] == 'Критичный')
			    	tasksBlockAndCrit = tasksBlockAndCrit + 1
				end
			end
		}
	end
 
	puts "... blocker and crit tasks left: #{tasksBlockAndCrit}"
 
	return tasksBlockAndCrit
end

SCHEDULER.every '5m', :first_in => 0 do |job|
	count_left = getTasksLeftForActiveSprint(jira_board_id, jira_username, jira_password, jira_url)
	count_done = getTasksDoneForActiveSprint(jira_board_id, jira_username, jira_password, jira_url)
	count_crit = getBlockerAndCritTasks(jira_board_id, jira_username, jira_password, jira_url)
	if (count_crit >= 1)
		color = "<h3 class='value' style='margin-left: 5px; font-size: 200%; width: 340px; border: solid black 2px; background-color: #E64040; display: inline-block;'>Blocker & crit: #{count_crit.to_s}</h3>"
	else
		color = "<h3 class='value' style='margin-left: 5px; font-size: 200%; width: 340px; border: solid black 2px; background-color: #6fd655; display: inline-block;'>Blocker & crit: #{count_crit.to_s}</h3>"
	end
	count = count_done.to_s + "/" + (count_left.to_i + count_done.to_i).to_s
	send_event('jira_tasks_left2', current: count, color: color)
end