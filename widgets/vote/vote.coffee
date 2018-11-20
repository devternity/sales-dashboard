class Dashing.Vote extends Dashing.Widget

  ready: ->
    @sessionElem = $(@node).find('.session-container')
    @startCarousel()
    @refreshData()

  startCarousel: ->
    setInterval(@refreshData, 30000)

  refreshData: =>    
    votes = @get 'votes'
    track = @get 'track'
    session = @get 'session'
    @sessionElem.fadeOut =>
      @set 'current_session', votes[track][session]
      $(@node).css('background-color', votes[track][session]['color'])
      @sessionElem.fadeIn()
