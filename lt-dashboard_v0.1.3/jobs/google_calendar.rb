require 'icalendar'

config_file = File.dirname(File.expand_path(__FILE__)) + '/../config/credentials.yml'
config = YAML::load(File.open(config_file))

ical_url = config['ical_url']
uri = URI ical_url

SCHEDULER.every '15s', :first_in => 4 do |job|
  parsed_url = URI.parse(ical_url)
  http = Net::HTTP.new(parsed_url.host, parsed_url.port)
  http.use_ssl = (parsed_url.scheme == "https")
  req = Net::HTTP::Get.new(parsed_url.request_uri)
  result = http.request(req).body.force_encoding('UTF-8')
  calendars = Icalendar::Calendar.parse(result)
  calendar = calendars.first

  events = calendar.events.map do |event|
    {
      start: event.dtstart,
      end: event.dtend,
      summary: event.summary
    }
  end.select { |event| event[:start] > DateTime.now }

  events = events.sort { |a, b| a[:start] <=> b[:start] }

  events = events[0..5]

  send_event('google_calendar', { events: events })
end
