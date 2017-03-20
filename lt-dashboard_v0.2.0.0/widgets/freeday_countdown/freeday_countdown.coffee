class Dashing.FreedayCountdown extends Dashing.Widget


  ready: ->
    setInterval(@countDown, 500)

  countDown: =>
    today = new Date()
    # Today is freeday!
    if @parseDate(@get('countdown').date) < today
      @set('name', "Today is "+@get('countdown').name)
      @set('time', '')
      return

    # Calculate time
    @set('name', "till "+@get('countdown').name)
    secs = Math.floor((@parseDate(@get('countdown').date) - today)/1000)
    # add time offset hours if specified
    secs += $(@node).data('time-offset')*3600 if $(@node).data('time-offset')
    @handleSound(secs)
    days = Math.floor(secs/86400)
    secs -= days*86400
    hours = Math.floor(secs/3600)
    secs -= hours*3600
    mins = Math.floor(secs/60)
    secs -= mins*60
    timeString = ''
    timeString = String(days) + " day" if days > 0
    timeString += "s" if days > 1
    timeString += " " if days > 0
    timeString += @formatTime(hours) + ":" + @formatTime(mins) + ":" + @formatTime(secs)
    @set('time', timeString)

  formatTime: (i) ->
    if i < 10 then "0" + i else i

  handleSound: (secs) ->
    sound = "/assets/sounds/Rudimental-Home.mp3"
    sound = $(@node).data('sound') if $(@node).data('sound')
    return if not sound or sound is 'nosound'
    region = @get('region')
    jp = $(@node).find('#jquery_jplayer_'+region)
    if jp.length <= 0 && secs >= 0 && secs <= 200
      $(@node).append('<script type="text/javascript" src="/assets/jplayer/jquery.jplayer.js"></script>')
      $(@node).append('<div id="jquery_jplayer_'+region+'"/>')
      jp = $(@node).find('#jquery_jplayer_'+region)
      jp.jPlayer({ solution: "html", supplied: "mp3" }).jPlayer("setMedia", { mp3: sound }).jPlayer("play")
    jp.remove() if jp.length >0 && secs > 200 || secs < 0

  parseDate: (dStr)->
    new Date(dStr.substr(0,4),Number(dStr.substr(5,2))-1,dStr.substr(8,2), dStr.substr(11,2), dStr.substr(14,2), dStr.substr(17,2))

