define ['react'], (React) ->
  {div, h4, p, img} = React.DOM

  Push = React.createFactory React.createClass
    displayName: 'Push'
    changeText: (event) ->
      if (event.target.value.length > 0)
        @setState
          keyval: event.target.value
          okbtnclass: 'button-primary'
          okbtnclk: @fire
      else
        @setState
          keyval: ''
          okbtnclass: 'disabled'
          okbtnclk: null
    clear: ->
      @setState
        keyval: ''
        okbtnclass: 'disabled'
        okbtnclk: null
    getInitialState: ->
      keyval: ''
      okbtnclass: 'disabled'
      okbtnclk: null
    fire: ->
      @props.f
        clientId: @state.keyval
    render: ->
      div {}, [
        (div {key: "api-cont"}, [
          (React.DOM.label {key: 'label', htmlFor: 'apikey'}, "Client Key")
          (React.DOM.input {key: 'field', className: 'u-full-wdth', id: 'apikey',  ref: 'apikey', value: @state.keyval, onChange: @changeText})
        ]),
        (div {key: "sig-buttons", className: "signature-buttons"}, [
          (React.DOM.button {key: 'clrbtn', onClick: @clear}, "Clear"),
          (React.DOM.button
            key: 'okbtn'
            className: @state.okbtnclass
            onClick: @state.okbtnclk, "Ok")
        ])
      ]

    
  React.createFactory React.createClass
    displayName: 'ReceiveBacon'
    render: ->
      Push f: @props.buttonPress

