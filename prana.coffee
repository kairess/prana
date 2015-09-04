if Meteor.isClient
	@audio = null
	@audioLength = new ReactiveVar 0
	@audioLengthMs = new ReactiveVar 0
	@playTimeMs = new ReactiveVar 0
	@floorPlayTimeMs = new ReactiveVar 0

	@lyrics = [
		{
			startTime: 5000
			endTime: 6500
			context: "for guine"
		}
		{
			startTime: 6500
			endTime: 7000
			context: "prana"
		}
	]

	@lyricEnds = new ReactiveVar false

	@lyricCursor = new ReactiveVar 0

	@setTransition = (start, length, session) ->
		# if playTimeMs.get() >= start and playTimeMs.get() < start + length
		# 	Session.set session, true
		# else
		# 	Session.set session, false

	colors = new Array(
		[255,0,0]
		[255,255,255]
		[0,255,0]
		[0,0,0])

	step = 0
	# //color table indices for:
	# // current color left
	# // next color left
	# // current color right
	# // next color right
	colorIndices = [0,1,2,3]

	# //transition speed
	gradientSpeed = 0.02

	@updateGradient = ->
		c0_0 = colors[colorIndices[0]]
		c0_1 = colors[colorIndices[1]]
		c1_0 = colors[colorIndices[2]]
		c1_1 = colors[colorIndices[3]]

		istep = 1 - step
		r1 = Math.round(istep * c0_0[0] + step * c0_1[0])
		g1 = Math.round(istep * c0_0[1] + step * c0_1[1])
		b1 = Math.round(istep * c0_0[2] + step * c0_1[2])
		color1 = "#"+((r1 << 16) | (g1 << 8) | b1).toString(16)

		r2 = Math.round(istep * c1_0[0] + step * c1_1[0])
		g2 = Math.round(istep * c1_0[1] + step * c1_1[1])
		b2 = Math.round(istep * c1_0[2] + step * c1_1[2])
		color2 = "#"+((r2 << 16) | (g2 << 8) | b2).toString(16)

		$('#gradient').css {background: "-webkit-radial-gradient(circle, "+color1+", transparent), -webkit-radial-gradient(circle, "+color2+", transparent)"}

		step += gradientSpeed
		if step >= 1
			step %= 1
			colorIndices[0] = colorIndices[1]
			colorIndices[2] = colorIndices[3]

			# //pick two new target color indices
			# //do not pick the same as the current one
			colorIndices[1] = ( colorIndices[1] + Math.floor( 1 + Math.random() * (colors.length - 1))) % colors.length
			colorIndices[3] = ( colorIndices[3] + Math.floor( 1 + Math.random() * (colors.length - 1))) % colors.length

	@timer = new Tock
		countdown: true
		interval: 100
		callback: ->
			tempPlayTimeMs = audioLengthMs.get() - @lap()
			playTimeMs.set tempPlayTimeMs

			tempFloorPlayTimeMs = Math.floor(tempPlayTimeMs / 100) * 100
			floorPlayTimeMs.set tempFloorPlayTimeMs

			tempLyricCursor = lyricCursor.get()

			# 표시해야하는 경우
			if not lyricEnds.get() and tempPlayTimeMs >= lyrics[tempLyricCursor].startTime
				console.log lyrics[tempLyricCursor].context

				# 커서 옮기기
				if lyrics.length > tempLyricCursor + 1 and tempPlayTimeMs >= lyrics[tempLyricCursor].endTime
					console.log 'cursor moved!'
					lyricCursor.set tempLyricCursor + 1
				# 마지막이고 끝내는 경우
				else if lyrics.length <= tempLyricCursor + 1 and tempPlayTimeMs > lyrics[tempLyricCursor].endTime
					console.log 'lyric ends'
					lyricEnds.set true
			# console.log floorPlayTimeMs.get()

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
		ms: ->
			if playTimeMs.get()?
				return playTimeMs.get()
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

		Meteor.setInterval updateGradient, 10
