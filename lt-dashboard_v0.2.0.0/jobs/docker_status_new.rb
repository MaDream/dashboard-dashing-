require 'net/ssh'
require 'net/http'
require 'uri'

config_file = File.dirname(File.expand_path(__FILE__)) + '/../config/credentials.yml'
config = YAML::load(File.open(config_file))

machine1_ip = config['machine1_ip']
machine2_ip = config['machine2_ip']
machine3_ip = config['machine3_ip']

machine_username = config['machine_username']
machine_pass = config['machine_pass']

serversTest = config['serversTest']
serversPre = config['serversPre']
serversDev = config['serversDev']

    containers_names = Array.new
    containers_sizeInfo = Array.new
    containers_errs = Array.new

docker_status_log = File.open("docker_status.log", "w")
docker_status_log.puts("Job is going to start...\n\n")
docker_status_log.close

bufferP = 0.12

SCHEDULER.every '10s', :first_in => 0 do |job|

    docker_status_log = File.open("docker_status.log", "a+")
    docker_status_log.puts("Job started")

    statuses1 = Array.new
    statuses2 = Array.new
    statuses3 = Array.new
    statuses4 = Array.new
    statuses5 = Array.new
    statuses6 = Array.new
    statuses7 = Array.new

    Net::SSH.start(machine1_ip, machine_username, :password => machine_pass) do |ssh|

      docker_status_log.puts("Connected to test-omni")

      stdout = ""
      info = Array.new
      things_are_bad_tho = 0
      importantServices = serversTest.length
      counterImportantUp = 0
      errs = ""

      ssh.exec!('mpstat') do |channel, stream, data|
        stdout << data if stream == :stdout
      end
      info = stdout.split(" ")
      cpu_usage = "CPU usage: " + (100 - info[-1].clone.to_i).to_s
      int_CPU = 100 - info[-1].clone.to_i
      stdout.clear
      info.clear

      ssh.exec!("free -m") do |channel, stream, data|
        stdout << data if stream == :stdout
      end
      info = stdout.split(" ")
      stdout.clear
      total02 = info[7].clone[/[\d.,]+/].gsub(',','.').to_f * bufferP
      mem_usage = "RAM usage - total: " + info[7] + "M;\t used: " + info[15] + "M;\t free: " + info[16] + "M."
      int_RAM = (((info[15].clone[/[\d.,]+/].gsub(',','.').to_f + total02) / info[7].clone[/[\d.,]+/].gsub(',','.').to_f).to_f * 100).abs.to_s
      info.clear

      ssh.exec!("df -h /dev/sda1") do |channel, stream, data|
        stdout << data if stream == :stdout
      end
      info = stdout.split(" ")
      avail_mem = info[10]
      stdout.clear
      disc_usage = "Disc usage - total: " + info[8] + ";\t in use: " + info[9] + ";\t available: " + info[10] + ";\t " + info[11] + "."
      int_HDD = ((info[9].clone[/[\d.,]+/].gsub(',','.').to_f / info[8].clone[/[\d.,]+/].gsub(',','.').to_f).to_f * 100).abs.to_s
      arrow = ""
      color = ""
      result = 1
      statuses1.push({labelInfo: "Machine info:", label: "", value: result, arrow: arrow, color: color})
      statuses1.push({labelInfo: cpu_usage, label: "", value: result, arrow: arrow, color: color})
      statuses1.push({labelInfo: mem_usage, label: "", value: result, arrow: arrow, color: color})
      statuses1.push({labelInfo: disc_usage,label: "", value: result, arrow: arrow, color: color})
      statuses1.push({labelInfo: "______________________________________________________________________________________________________________", label: "", value: result, arrow: arrow, color: color})

      docker_status_log.puts("Machine info pushed (test-omni)")

      if int_CPU > 80
          color = '#E64040'
      elsif int_CPU > 66
          color = '#E7AA1E'
      else
          color = '#6FD655'
      end
      statuses4.push({label: 'CPU <div style="display:inline-block; color:white; width:33%; background-color:#737373"><div style="width:' + int_CPU.to_s + '%; font-size: 16pt; font-weight: normal; background-color:' + color + '">' + int_CPU.to_s + '%' + '</div></div>', color: color})
      
      int_RAM = int_RAM.to_f.round(2).to_s
      
      if int_RAM.to_f >= 89.to_f
          color = '#E64040'
      elsif int_RAM.to_f >= 75.to_f
          color = '#E7AA1E'
      else
          color = '#6FD655'
      end
      statuses4.push({label: '<br>', color: ''})
      statuses4.push({label: 'RAM <div style="display:inline-block; color:white; width:33%; background-color:#737373"><div style="width:' + int_RAM.to_s + '%; font-size: 16pt; font-weight: normal; background-color:' + color + '">' + int_RAM.to_s + '%' + '</div></div>', color: color})
      
      int_HDD = int_HDD.to_f.round(2).to_s
      
      if int_HDD.to_f >= 91.to_f
          color = '#E64040'
      elsif int_HDD.to_f >= 82.to_f
          color = '#E7AA1E'
      else
          color = '#6FD655'
      end
      statuses4.push({label: '<br>', color: ''})
      statuses4.push({label: 'HDD <div style="display:inline-block; color:white; width:33%; background-color:#737373"><div style="width:' + int_HDD.to_s + '%; font-size: 16pt; font-weight: normal; background-color:' + color + '">' + int_HDD.to_s + '%' + '</div></div>', color: color})
      stdout.clear

      int_HDD = 0
      int_RAM = 0
      int_CPU = 0


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
        serversTest.each do |server|
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
            if split.scan(/^#{Regexp.escape(server['str'][0...server['str'].index('+') - 1])}/).length > 0 then
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

      docker_status_log.puts("Ended for test-omni")
    end
    
    
    
    Net::SSH.start(machine2_ip, machine_username, :password => machine_pass) do |ssh|

      docker_status_log.puts("Connected to pre-omni")

      stdout = ""
      info = Array.new
      things_are_bad_tho = 0
      importantServices = serversPre.length
      counterImportantUp = 0
      errs = ""

      ssh.exec!(%q!mpstat!) do |channel, stream, data|
        stdout << data if stream == :stdout
      end
      info = stdout.split(" ")
      cpu_usage = "CPU usage: " + (100 - info[-1].clone.to_i).to_s
      int_CPU = 100 - info[-1].clone.to_i
      stdout.clear
      info.clear
      ssh.exec!("free -m") do |channel, stream, data|
        stdout << data if stream == :stdout
      end
      info = stdout.split(" ")
      stdout.clear
      total02 = info[7].clone[/[\d.,]+/].gsub(',','.').to_f * bufferP
      mem_usage = "RAM usage - total: " + info[7] + "M;\t used: " + info[15] + "M;\t free: " + info[16] + "M."
      int_RAM = (((info[15].clone[/[\d.,]+/].gsub(',','.').to_f + total02) / info[7].clone[/[\d.,]+/].gsub(',','.').to_f).to_f * 100).abs.to_s
      info.clear

      ssh.exec!("df -h /dev/sda1") do |channel, stream, data|
        stdout << data if stream == :stdout
      end
      info = stdout.split(" ")
      stdout.clear
      puts info[9]
      disc_usage = "Disc usage - total: " + info[9] + ";\t in use: " + info[10] + ";\t available: " + info[11] + ";\t " + info[12] + "."
      int_HDD = ((info[10].clone[/[\d.,]+/].gsub(',','.').to_f / info[9].clone[/[\d.,]+/].gsub(',','.').to_f).to_f * 100).abs.to_s
      arrow = ""
      color = ""
      result = 1
      statuses2.push({labelInfo: "Machine info:", label: "", value: result, arrow: arrow, color: color})
      statuses2.push({labelInfo: cpu_usage, label: "", value: result, arrow: arrow, color: color})
      statuses2.push({labelInfo: mem_usage, label: "", value: result, arrow: arrow, color: color})
      statuses2.push({labelInfo: disc_usage, label: "", value: result, arrow: arrow, color: color})
      statuses2.push({labelInfo: "______________________________________________________________________________________________________________", label: "", value: result, arrow: arrow, color: color})

      docker_status_log.puts("Machine info pushed (pre-omni)")

      if int_CPU.to_f > 80.to_f
          color = '#E64040'
      elsif int_CPU.to_f > 66.to_f
          color = '#E7AA1E'
      else
          color = '#6FD655'
      end
      statuses5.push({label: 'CPU <div style="display:inline-block; color:white; width:33%; background-color:#737373"><div style="width:' + int_CPU.to_s + '%; font-size: 16pt; font-weight: normal; background-color:' + color + '">' + int_CPU.to_s + '%' + '</div></div>', color: color})
      
      int_RAM = int_RAM.to_f.round(2).to_s
      
      if int_RAM.to_f >= 89.to_f
          color = '#E64040'
      elsif int_RAM.to_f >= 75.to_f
          color = '#E7AA1E'
      else
          color = '#6FD655'
      end
      statuses5.push({label: '<br>', color: ''})
      statuses5.push({label: 'RAM <div style="display:inline-block; color:white; width:33%; background-color:#737373"><div style="width:' + int_RAM.to_s + '%; font-size: 16pt; font-weight: normal; background-color:' + color + '">' + int_RAM.to_s + '%' + '</div></div>', color: color})
      
      int_HDD = int_HDD.to_f.round(2).to_s
      
      if int_HDD.to_f >= 91.to_f
          color = '#E64040'
      elsif int_HDD.to_f >= 82.to_f
          color = '#E7AA1E'
      else
          color = '#6FD655'
      end
      statuses5.push({label: '<br>', color: ''})
      statuses5.push({label: 'HDD <div style="display:inline-block; color:white; width:33%; background-color:#737373"><div style="width:' + int_HDD.to_s + '%; font-size: 16pt; font-weight: normal; background-color:' + color + '">' + int_HDD.to_s + '%' + '</div></div>', color: color})
      stdout.clear

      int_HDD = 0
      int_RAM = 0
      int_CPU = 0

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
        serversPre.each do |server|
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
            if split.scan(/^#{Regexp.escape(server['str'][0...server['str'].index('+')])}/).length > 0 then
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
      statuses3.push({label: "Pre-Omni", value: result, arrow: arrow, color: color})

      docker_status_log.puts("Ended for pre-omni")

    end





Net::SSH.start(machine3_ip, machine_username, :password => machine_pass) do |ssh|

      docker_status_log.puts("Connected to dev-omni")

      stdout = ""
      info = Array.new
      things_are_bad_tho = 0
      importantServices = serversDev.length
      counterImportantUp = 0
      errs = ""

      ssh.exec!('mpstat') do |channel, stream, data|
        stdout << data if stream == :stdout
      end
      info = stdout.split(" ")
      cpu_usage = "CPU usage: " + (100 - info[-1].clone.to_i).to_s
      int_CPU = 100 - info[-1].clone.to_i
      stdout.clear
      info.clear

      ssh.exec!("free -m") do |channel, stream, data|
        stdout << data if stream == :stdout
      end
      info = stdout.split(" ")
      stdout.clear
      total02 = info[7].clone[/[\d.,]+/].gsub(',','.').to_f * bufferP
      mem_usage = "RAM usage - total: " + info[7] + "M;\t used: " + info[15] + "M;\t free: " + info[16] + "M."
      int_RAM = (((info[15].clone[/[\d.,]+/].gsub(',','.').to_f + total02) / info[7].clone[/[\d.,]+/].gsub(',','.').to_f).to_f * 100).abs.to_s
      info.clear

      ssh.exec!("df -h /dev/sda1") do |channel, stream, data|
        stdout << data if stream == :stdout
      end
      info = stdout.split(" ")
      avail_mem = info[10]
      stdout.clear
      disc_usage = "Disc usage - total: " + info[8] + ";\t in use: " + info[9] + ";\t available: " + info[10] + ";\t " + info[11] + "."
      int_HDD = ((info[9].clone[/[\d.,]+/].gsub(',','.').to_f / info[8].clone[/[\d.,]+/].gsub(',','.').to_f).to_f * 100).abs.to_s
      arrow = ""
      color = ""
      result = 1
      statuses6.push({labelInfo: "Machine info:", label: "", value: result, arrow: arrow, color: color})
      statuses6.push({labelInfo: cpu_usage, label: "", value: result, arrow: arrow, color: color})
      statuses6.push({labelInfo: mem_usage, label: "", value: result, arrow: arrow, color: color})
      statuses6.push({labelInfo: disc_usage,label: "", value: result, arrow: arrow, color: color})
      statuses6.push({labelInfo: "______________________________________________________________________________________________________________", label: "", value: result, arrow: arrow, color: color})

      docker_status_log.puts("Machine info pushed (dev-omni)")

      if int_CPU > 80
          color = '#E64040'
      elsif int_CPU > 66
          color = '#E7AA1E'
      else
          color = '#6FD655'
      end
      statuses7.push({label: 'CPU <div style="display:inline-block; color:white; width:33%; background-color:#737373"><div style="width:' + int_CPU.to_s + '%; font-size: 16pt; font-weight: normal; background-color:' + color + '">' + int_CPU.to_s + '%' + '</div></div>', color: color})
      
      int_RAM = int_RAM.to_f.round(2).to_s
      
      if int_RAM.to_f >= 89.to_f
          color = '#E64040'
      elsif int_RAM.to_f >= 75.to_f
          color = '#E7AA1E'
      else
          color = '#6FD655'
      end
      statuses7.push({label: '<br>', color: ''})
      statuses7.push({label: 'RAM <div style="display:inline-block; color:white; width:33%; background-color:#737373"><div style="width:' + int_RAM.to_s + '%; font-size: 16pt; font-weight: normal; background-color:' + color + '">' + int_RAM.to_s + '%' + '</div></div>', color: color})
      
      int_HDD = int_HDD.to_f.round(2).to_s
      
      if int_HDD.to_f >= 91.to_f
          color = '#E64040'
      elsif int_HDD.to_f >= 82.to_f
          color = '#E7AA1E'
      else
          color = '#6FD655'
      end
      statuses7.push({label: '<br>', color: ''})
      statuses7.push({label: 'HDD <div style="display:inline-block; color:white; width:33%; background-color:#737373"><div style="width:' + int_HDD.to_s + '%; font-size: 16pt; font-weight: normal; background-color:' + color + '">' + int_HDD.to_s + '%' + '</div></div>', color: color})
      stdout.clear

      int_HDD = 0
      int_RAM = 0
      int_CPU = 0


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
        serversDev.each do |server|
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
            if split.scan(/^#{Regexp.escape(server['str'][0...server['str'].index('+') - 1])}/).length > 0 then
                if server['str'][server['str'].index('+') + 1] == '!' then
                    counterImportantUp = counterImportantUp + 1
                end
            end
        end
        if (!logFound)
            containers_errs.push("")
        end
        if nameOnly.scan("-workspace-dev").size > 0 then
            nameOnly = nameOnly[0, nameOnly.index("-workspace-dev")] + nameOnly[nameOnly.index("-workspace-dev") + "-workspace-dev".length, 999]
        end
            nameOnly = nameOnly.gsub('-', ' ')
            containers_names.push(nameOnly.capitalize)
            containers_sizeInfo.push(sizeInfo)
      end

      statuses6.push({label: "Available services:", sizeInfo: "", errorInfo: "", value: 1, arrow: "", color: ""})
      arrow = "icon-ok-sign"
      color = "green"
      result = 1
      for i in 0...containers_names.length do
          if containers_errs[i].present? then
            statuses6.push({label: containers_names[i], sizeInfo: " | " + containers_sizeInfo[i] + " | ", errorInfo: containers_errs[i], value: result, arrow: arrow, color: color})
          else
            statuses6.push({label: containers_names[i], sizeInfo: " | " + containers_sizeInfo[i], errorInfo: containers_errs[i], value: result, arrow: arrow, color: color})
          end
      end
      if allContainers.length > dockerInfo.length
          statuses6.push({label: "Unavailable services:", sizeInfo: "", errorInfo: "", value: 1, arrow: "", color: ""})
          arrow = "icon-warning-sign"
          color = "red"
          result = 0
          allContainers.each do |container|
              if availContainers.scan(container).length == 0 then
                  statuses6.push({label: container.capitalize, value: result, arrow: arrow, color: color})
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
      statuses3.push({label: "Dev-Omni", value: result, arrow: arrow, color: color})

      docker_status_log.puts("Ended for Dev-Workspace")
    end
    docker_status_log.puts("Sending events")

    send_event('docker_status1', {items: statuses1})
    send_event('docker_status2', {items: statuses2})
    send_event('docker_status3', {items: statuses6})
    send_event('main_docker_status', {items: statuses3})
    send_event('docker_resource1', {items: statuses4})
    send_event('docker_resource2', {items: statuses5})
    send_event('docker_resource3', {items: statuses7})

    docker_status_log.puts("Events sended")

    statuses1.clear
    statuses2.clear
    statuses3.clear
    statuses4.clear
    statuses5.clear
    statuses6.clear
    statuses7.clear

    containers_names.clear
    containers_sizeInfo.clear
    containers_errs.clear

    docker_status_log.puts("Arrays cleared")
    docker_status_log.puts("Job done")
    docker_status_log.puts("_____________________________________________\n\n")
    docker_status_log.close
end


SCHEDULER.every '800000s', :first_in => 800000 do |job|
  docker_status_log = File.open("docker_status.log", "w")
  docker_status_log.close
end