define ['react', 'jquery'], (React, $) ->
  {div, button, input, label, thead, tbody, table, tr, td, th} = React.DOM

  SelectDate = React.createFactory React.createClass
    displayName: 'SelectDate'
    getInitialState: ->
      inputval: ''
      okbtnclass: 'disabled'
      okbtnclk: null
    checkState: (ev) ->
      if ev.target.value.length > 0
        @setState
          inputval: ev.target.value
          okbtnclass: 'button-primary'
          okbtnclk: @fire
      else
        @setState
          inputval: ''
          okbtnclass: 'disabled'
          okbtnclk: null
    fire: ->
      @props.f
        date: @state.inputval
    render: ->
      (div className: 'row',
        (div className: 'six columns',
          (label htmlFor: 'dateInput', "Weigh-ins before:"),
          (input
            className: 'u-full-width'
            type: 'date'
            placeholder: 'MM/DD/YYYY'
            id: 'dateInput'
            value: @state.inputval
            disabled: @state.sent
            onChange: @checkState)
        ),
        (div className: 'six columns',
          (button
            className: if @props.sent then 'disabled' else @state.okbtnclass
            onClick: (if @props.sent then null else @state.okbtnclk),
              "Query"
          ),
          (button
            className: if @props.weightsLoaded && !@props.sent then 'button-primary' else 'disabled'
            onClick: (if @props.weightsLoaded && !@props.sent then @props.send else null),
              "Send Data to Fitbit"
          )
        )
      )

  DataRow = React.createFactory React.createClass
    displayName: 'DataRow'
    render: ->
      tr {},
        (td {}, @props.k),
        (td {}, @props.v.w),
        (td {}, @props.v.d)

  DataTable = React.createFactory React.createClass
    displayName: 'DataTable'
    render: ->
      els = for key, val of @props.data
        DataRow
          key: key
          k: key
          v: val

      div {},
        (table className: 'u-full-width',
          (thead {},
            (tr {},
              (th {}, "Date"),
              (th {}, "Weight"),
              (th {}, "Submitted")
            )
          ),
          (tbody {}, els)
        )


    
  React.createFactory React.createClass
    displayName: 'ReceiveBacon'
    getInitialState: ->
      endDate: null
      sent: false
      weightsLoaded: false
      weightData: null
    dateSet: (s) ->
      console.log "Yay! #{s.date}"
      # Mangle Date
      sdate = s.date.replace(/\//g, "-")
      # Build url
      url = "#{@props.url}/getWeights/#{sdate}"
      console.log "Requesting: #{url}"

      # Submit request
      ($.get url, ((result) ->
          data = result
          for key, val of data
            data[key] = {w: val, d: 'no'}
          
          @setState
            weightsLoaded: true
            weightData: data
        ).bind(this)
      ).fail((obj, status, err) ->
        console.log "Failure: #{status}"
        console.log "   Reason: #{err}"
      )
      @setState
        endDate: s.date
    gotMessage: (ev) ->
      console.log "MESSAGE:"
      console.log ev.data
      j = JSON.parse(ev.data)
      d = @state.weightData
      d[j.Date].d = j.Error
      @setState
        weightData: d

    sendToFitbit: () ->
      console.log "Initializing websocket"
      if window["WebSocket"]
        conn = new WebSocket("ws://#{location.host}/ws")
        connState = @state
        connProps = @props
        setState = @setState
        conn.onclose = (ev) ->
          console.log "Conn closed:"
          console.dir ev
        conn.onerror = (ev) ->
          console.log "Error in websocket:"
          console.dir ev
          conn.close()
        conn.onopen = () ->
          console.log "Socket Opened. Sending command!"
          conn.send JSON.stringify(
            EndDate: connState.endDate
            FitToken: connProps.token
            UserID: connProps.uid
          )
        conn.onmessage = @gotMessage
      else
        console.log "Websockets are unsupported"

      console.log "Send in progress"
      @setState
        sent: true
        queryEnabled: false
    displayName: 'ReceiveBacon'
    render: ->
      (div {},
        (SelectDate
          f: @dateSet
          send: @sendToFitbit
          sent: @state.sent
          weightsLoaded: @state.weightsLoaded
        ),
        (DataTable
          data: @state.weightData
        )
      )

