requirejs.config
  paths:
    components: 'components'
    jquery: '/libs/jquery-2.1.4.min'
    react: 'https://fb.me/react-with-addons-0.13.3'
    spinner: '/libs/spin.min'


require ['jquery', 'react', 'components/PushButton', 'components/ReceiveBacon', 'components/Spin'], ($, React, PushButton, ReceiveBacon, Spin) ->
  {div, h4, p, img} = React.DOM

  getParameterByName = (name) ->
    name = name.replace(/[\[]/, "\\[").replace(/[\]]/, "\\]")
    regex = new RegExp("[\\?&]" + name + "=([^&#]*)")
    results = regex.exec(location.hash)
    if results == null then  "" else decodeURIComponent(results[1].replace(/\+/g, " "))

  Ui = React.createFactory React.createClass
    okpressed: (apiinfo) ->
      # Redirect 
      str = "https://www.fitbit.com/oauth2/authorize?response_type=token&client_id=#{apiinfo.clientId}&redirect_uri=#{encodeURIComponent(window.location.href)}&scope=weight"
      window.setTimeout(() ->
        window.location.href = str
      , 250)

    getInitialState: ->
      ret =
        error: false
        errstr: null
        authed: false
        authinfo: null
        apientered: false
      if location.hash.length > 0
        err = getParameterByName 'error'
        if err.length > 0
           ret.error = true
           ret.errstr = err
        else
          ret.authed = true
          ret.accessToken = getParameterByName 'access_token'
          ret.userId = getParameterByName 'user_id'
          console.log ret.accessToken
          console.log ret.userId

      ret
    render: ->
      content = null
      if !@state.apientered && !@state.authed
        content = PushButton buttonPress: @okpressed
      else if !@state.authed
        content = Spin {}
      else
        content = ReceiveBacon
          url: window.location.origin
          token: @state.accessToken
          uid: @state.userId

      (div className: "container",
        (div className: "section", content))
      
  $ ->
    $("#loading").remove()
    React.render (Ui {}), document.body

