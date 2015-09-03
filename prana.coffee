if Meteor.isClient
	@audio = null
	@audioLength = new ReactiveVar 0
	@audioLengthMs = new ReactiveVar 0
	@playTimeMs = new ReactiveVar 0

	@setTransition = (start, length, session) ->
		if playTimeMs.get() >= start and playTimeMs.get() < start + length
			Session.set session, true
		else
			Session.set session, false

	@timer = new Tock
		countdown: true
		interval: 100
		callback: ->
			playTimeMs.set audioLengthMs.get() - @lap()

			setTransition 5000, 1000, 'red'

		complete: ->
			console.log 'Timer completed!'

	Session.setDefault "show", false

	Template.hello.helpers
		show: ->
			return Session.get "show"
		red: ->
			if Session.get "red"
				return 'red'
			return ''
		swing: ->
			if Session.get "show"
				return 'swing'
			return ''
		count: ->
			if playTimeMs.get()?
				return (Math.round((playTimeMs.get() / audioLengthMs.get() * 100 * 100)) / 100).toFixed 2
			return 0


	Template.hello.events
		"click .click": (event, template) ->
			Session.set "show", not Session.get "show"

			console.log Meteor.audio

	Template.hello.rendered = ->
		new WOW().init()

		Meteor.audio = new Howl
			src: ['2.mp3']
			autoplay: true
			volume: 1
			onload: ->
			onplay: ->
				tempAudioLengthMs = parseInt(@duration() * 1000)
				audioLength.set @duration()
				audioLengthMs.set tempAudioLengthMs

				timer.start(tempAudioLengthMs)
			onend: ->
				timer.stop()

				console.log('Music finished!')
