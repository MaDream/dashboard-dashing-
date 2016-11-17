require 'net/ssh'
require 'net/http'
require 'uri'

config_file = File.dirname(File.expand_path(__FILE__)) + '/../config/credentials.yml'
config = YAML::load(File.open(config_file))

machine1_ip = config['machine1_ip']
machine2_ip = config['machine2_ip']

machine_username = config['machine_username']
machine_pass = config['machine_pass']

servers = config['servers']

    containers_names = Array.new
    containers_sizeInfo = Array.new
    containers_errs = Array.new


SCHEDULER.every '20s', :first_in => 0 do |job|

    statuses1 = Array.new
    statuses2 = Array.new
    statuses3 = Array.new

    Net::SSH.start(machine1_ip, machine_username, :password => machine_pass) do |ssh|

      stdout = ""
      info = Array.new
      things_are_bad_tho = 0
      importantServices = 15
      counterImportantUp = 0
      errs = ""

      ssh.exec!(%q!mpstat 2 1 | awk '$12 ~ /[0-9.]+/ { print 100 - $12"%" }'!) do |channel, stream, data|
        stdout << data if stream == :stdout
      end
      info = stdout.split(" ")
      cpu_usage = "CPU usage: " + info[0]
      stdout.clear
      info.clear

      ssh.exec!("free -m") do |channel, stream, data|
        stdout << data if stream == :stdout
      end
      info = stdout.split(" ")
      stdout.clear
      mem_usage = "RAM usage - total: " + info[7] + "M;\t used: " + info[8] + "M;\t free: " + info[9] + "M."
      info.clear

      ssh.exec!("df -h /dev/sda1") do |channel, stream, data|
        stdout << data if stream == :stdout
      end
      info = stdout.split(" ")
      stdout.clear
      disc_usage = "Disc usage - total: " + info[8] + ";\t in use: " + info[9] + ";\t available: " + info[10] + ";\t " + info[11] + "."
      
      arrow = ""
      color = ""
      result = 1
      statuses1.push({labelInfo: "Machine info:", label: "", value: result, arrow: arrow, color: color})
      statuses1.push({labelInfo: cpu_usage, label: "", value: result, arrow: arrow, color: color})
      statuses1.push({labelInfo: mem_usage, label: "", value: result, arrow: arrow, color: color})
      statuses1.push({labelInfo: disc_usage,label: "", value: result, arrow: arrow, color: color})
      statuses1.push({labelInfo: "______________________________________________________________________________________________________________", label: "", value: result, arrow: arrow, color: color})
      
      stdout.clear

      ssh.exec!("docker ps -s --format '{{.Names}} // {{.Size}}' | sort") do |channel, stream, data|
        stdout << data if stream == :stdout
      end
      availContainers = stdout.clone
      dockerInfo = stdout.clone
      stdout.clear
      ssh.exec!("docker ps -a --format '{{.Names}}' | sort") do |channel, stream, data|  
        stdout << data if stream == :stdout
      end
      allContainers = stdout.clone
      allContainers = allContainers.split("\n")
      dockerInfo = dockerInfo.split("\n")
      namesOnly = Array.new
      dockerInfo.each do |split|
        nameOnly = split[0...split.index('//')]
        namesOnly.push(nameOnly[0...-3])
        sizeInfo = split[split.index('//') + 2...999]
        logFound = false
        servers.each do |server|
            if server['str'][server['str'].index('=')...200].length > 1 then
                if split.scan(server['str'][0...server['str'].index('+') - 1]).length > 0 then
                    stdout.clear
                    ssh.exec!(%q@tail -n 1000 @ + server['str'][server['str'].index('=') + 1...999] + %q: | grep "ERROR\|error" | wc -l:) do |channel, stream, data|
                        stdout << data if stream == :stdout
                    end
                    errs = "Errors in logs: "
                    errs << stdout.clone
                    containers_errs.push(errs.clone)
                    logFound = true
                    stdout.clear
                    errs.clear
                end
            end
            if split.scan(server['str'][0...server['str'].index('+') - 1]).length > 0 then
                if server['str'][server['str'].index('+') + 1] == '!' then
                    counterImportantUp = counterImportantUp + 1
                end
            end
        end
        if (!logFound)
            containers_errs.push("")
        end
        if nameOnly.scan("-test-omni-workspace").size > 0 then
            nameOnly = nameOnly[0, nameOnly.index("-test-omni-workspace")] + nameOnly[nameOnly.index("-test-omni-workspace") + "-test-omni-workspace".length, 999]
            nameOnly = nameOnly.gsub('-', ' ')
            containers_names.push(nameOnly.capitalize)
            containers_sizeInfo.push(sizeInfo)
        else
            nameOnly = nameOnly.gsub('-', ' ')
            containers_names.push(nameOnly.capitalize)
            containers_sizeInfo.push(sizeInfo)
        end
      end

      statuses1.push({label: "Available services:", sizeInfo: "", errorInfo: "", value: 1, arrow: "", color: ""})
      arrow = "icon-ok-sign"
      color = "green"
      result = 1
      for i in 0...containers_names.length do
          if containers_errs[i].present? then
            statuses1.push({label: containers_names[i], sizeInfo: " | " + containers_sizeInfo[i] + " | ", errorInfo: containers_errs[i], value: result, arrow: arrow, color: color})
          else
            statuses1.push({label: containers_names[i], sizeInfo: " | " + containers_sizeInfo[i], errorInfo: containers_errs[i], value: result, arrow: arrow, color: color})
          end
      end
      if allContainers.length > dockerInfo.length
          statuses1.push({label: "Unavailable services:", sizeInfo: "", errorInfo: "", value: 1, arrow: "", color: ""})
          arrow = "icon-warning-sign"
          color = "red"
          result = 0
          allContainers.each do |container|
              if availContainers.scan(container).length == 0 then
                  statuses1.push({label: container.capitalize, value: result, arrow: arrow, color: color})
              end
          end
      end
      containers_names.clear
      containers_sizeInfo.clear
      containers_errs.clear
      if importantServices <= counterImportantUp then
         arrow = "icon-ok-sign"
        color = "green"
        result = 1
      else
        things_are_bad_tho = 1
        arrow = "icon-warning-sign"
        color = "red"
        result = 0 
      end
      statuses3.push({label: "Test-Omni", value: result, arrow: arrow, color: color})
    end
    
    
    
    Net::SSH.start(machine2_ip, machine_username, :password => machine_pass) do |ssh|

      stdout = ""
      info = Array.new
      things_are_bad_tho = 0
      importantServices = 15
      counterImportantUp = 0
      errs = ""

      ssh.exec!(%q!mpstat 2 1 | awk '$12 ~ /[0-9.]+/ { print 100 - $12"%" }'!) do |channel, stream, data|
        stdout << data if stream == :stdout
      end
      info = stdout.split(" ")
      cpu_usage = "CPU usage: " + info[0]
      stdout.clear
      info.clear

      ssh.exec!("free -m") do |channel, stream, data|
        stdout << data if stream == :stdout
      end
      info = stdout.split(" ")
      stdout.clear
      mem_usage = "RAM usage - total: " + info[7] + "M;\t used: " + info[8] + "M;\t free: " + info[9] + "M."
      info.clear

      ssh.exec!("df -h /dev/sda1") do |channel, stream, data|
        stdout << data if stream == :stdout
      end
      info = stdout.split(" ")
      stdout.clear
      disc_usage = "Disc usage - total: " + info[8] + ";\t in use: " + info[9] + ";\t available: " + info[10] + ";\t " + info[11] + "."
      
      arrow = ""
      color = ""
      result = 1
      statuses2.push({labelInfo: "Machine info:", label: "", value: result, arrow: arrow, color: color})
      statuses2.push({labelInfo: cpu_usage, label: "", value: result, arrow: arrow, color: color})
      statuses2.push({labelInfo: mem_usage, label: "", value: result, arrow: arrow, color: color})
      statuses2.push({labelInfo: disc_usage,label: "", value: result, arrow: arrow, color: color})
      statuses2.push({labelInfo: "______________________________________________________________________________________________________________", label: "", value: result, arrow: arrow, color: color})
      
      stdout.clear

      ssh.exec!("docker ps -s --format '{{.Names}} // {{.Size}}' | sort") do |channel, stream, data|
        stdout << data if stream == :stdout
      end
      availContainers = stdout.clone
      dockerInfo = stdout.clone
      stdout.clear
      ssh.exec!("docker ps -a --format '{{.Names}}' | sort") do |channel, stream, data|  
        stdout << data if stream == :stdout
      end
      allContainers = stdout.clone
      allContainers = allContainers.split("\n")
      dockerInfo = dockerInfo.split("\n")
      namesOnly = Array.new
      dockerInfo.each do |split|
        nameOnly = split[0...split.index('//')]
        namesOnly.push(nameOnly[0...-3])
        sizeInfo = split[split.index('//') + 2...999]
        logFound = false
        servers.each do |server|
            if server['str'][server['str'].index('=') + 1...200].length > 0 then
                if split.scan(server['str'][0...server['str'].index('+') - 1]).length > 0 then
                    stdout.clear
                    ssh.exec!(%q@tail -n 1000 @ + server['str'][server['str'].index('=') + 1...999] + %q: | grep "ERROR\|error" | wc -l:) do |channel, stream, data|
                        stdout << data if stream == :stdout
                    end
                    errs = "Errors in logs: "
                    errs << stdout.clone
                    containers_errs.push(errs.clone)
                    logFound = true
                    stdout.clear
                    errs.clear
                end
            end
            if split.scan(server['str'][0...server['str'].index('+') - 1]).length > 0 then
                if server['str'][server['str'].index('+') + 1] == '!' then
                    counterImportantUp = counterImportantUp + 1
                end
            end
        end
        if (!logFound)
            containers_errs.push("")
        end
        if nameOnly.scan("-pre-omni").size > 0 then
            nameOnly = nameOnly[0, nameOnly.index("-pre-omni")] + nameOnly[nameOnly.index("-pre-omni") + "-pre-omni".length, 999]
            nameOnly = nameOnly.gsub('-', ' ')
            containers_names.push(nameOnly.capitalize)
            containers_sizeInfo.push(sizeInfo)
        else
            nameOnly = nameOnly.gsub('-', ' ')
            containers_names.push(nameOnly.capitalize)
            containers_sizeInfo.push(sizeInfo)
        end
      end

      statuses2.push({label: "Available services:", sizeInfo: "", errorInfo: "", value: 1, arrow: "", color: ""})
      arrow = "icon-ok-sign"
      color = "green"
      result = 1
      for i in 0...containers_names.length do
          if containers_errs[i].present? then
            statuses2.push({label: containers_names[i], sizeInfo: " | " + containers_sizeInfo[i] + " | ", errorInfo: containers_errs[i], value: result, arrow: arrow, color: color})
          else
            statuses2.push({label: containers_names[i], sizeInfo: " | " + containers_sizeInfo[i], errorInfo: containers_errs[i], value: result, arrow: arrow, color: color})
          end
      end
      if allContainers.length > dockerInfo.length
          statuses2.push({label: "Unavailable services:", sizeInfo: "", errorInfo: "", value: 1, arrow: "", color: ""})
          arrow = "icon-warning-sign"
          color = "red"
          result = 0
          allContainers.each do |container|
              if availContainers.scan(container).length == 0 then
                  statuses2.push({label: container.capitalize, value: result, arrow: arrow, color: color})
              end
          end
      end
      containers_names.clear
      containers_sizeInfo.clear
      containers_errs.clear
      if importantServices <= counterImportantUp then
         arrow = "icon-ok-sign"
        color = "green"
        result = 1
      else
        things_are_bad_tho = 1
        arrow = "icon-warning-sign"
        color = "red"
        result = 0 
      end
      statuses3.push({label: "Test-Omni", value: result, arrow: arrow, color: color})
    end
    send_event('docker_status1', {items: statuses1})
    send_event('docker_status2', {items: statuses2})
    send_event('main_docker_status', {items: statuses3})
end