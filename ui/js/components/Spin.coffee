define ['jquery', 'react', 'spinner'], ($, React, Spinner) ->
  React.createFactory React.createClass
    displayName: 'Spinner'
    opts:
      lines: 9 # The number of lines to draw
      length: 30 # The length of each line
      width: 14 # The line thickness
      radius: 40 # The radius of the inner circle
      scale: 0.25 # Scales overall size of the spinner
      corners: 1 # Corner roundness (0..1)
      color: '#333' # #rgb or #rrggbb or array of colors
      opacity: 0.1 # Opacity of the lines
      rotate: 0 # The rotation offset
      direction: 1 # 1: clockwise, -1: counterclockwise
      speed: 2.5 # Rounds per second
      trail: 47 # Afterglow percentage
      fps: 20 # Frames per second when using setTimeout() as a fallback for CSS
      zIndex: 2e9 # The z-index (defaults to 2000000000)
      className: 'spinner' # The CSS class to assign to the spinner
      top: '75%' # Top position relative to parent
      left: '50%' # Left position relative to parent
      shadow: false # Whether to render a shadow
      hwaccel: false # Whether to use hardware acceleration
      position: 'absolute' # Element positioning
    componentDidMount: ->
      sp = new Spinner(@opts)
      sp.spin(@refs.spin.getDOMNode())
    render: ->
      React.DOM.div {ref: "spin", key: 'spinspin'}