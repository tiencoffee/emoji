require! {
	"fs-extra": fs
	"node-fetch": fetch
}

do !->>
	text = await (await fetch \https://unicode.org/Public/emoji/13.0/emoji-test.txt)text!
	names =
		'#️⃣': \keycap-number-sign
		'#⃣': \keycap-number-sign
		"*️⃣": \keycap-asterisk
		"*⃣": \keycap-asterisk
		"🪅": \pinata
		"🇺🇲": \flag-us-outlying-islands
		"🇻🇮": \flag-us-virgin-islands
		"🇸🇹": \flag-sao-tome-principe
		"🇷🇪": \flag-reunion
		"🇨🇼": \flag-curacao
		"🇨🇮": \flag-cote-divoire
		"🇧🇱": \flag-st-barthelemy
		"🇦🇽": \flag-aland-islands
	removeRegex = /’/g
	emojis = text
		.split \\n
		.filter (is /.+ ; .+ # .+/)
		.map (v) ~>
			v .= split /\ +; | +# /
			a = v.2.split " "
			cp = v.0
				.replace /\ /g \-
				.toLowerCase!
				.replace /(?<=^|-)0+/ ""
			name = names[a.0] ? a
				.slice 2
				.join " "
				.toLowerCase!
				.replace removeRegex, ""
				.replace /\W+/g \-
				.replace /-$/ ""
			name: name
			chr: a.0
			cp: cp
			status: v.1
	findEmoji = (name, status) ->
		emojis.find ~> it.name is name and it.status is status
	for emoji in emojis
		switch emoji.status
		| \minimally-qualified
			emoji2 = findEmoji emoji.name, \fully-qualified
			emoji.cp = emoji2.cp
		| \unqualified
			emoji2 = findEmoji emoji.name, \fully-qualified
			if emoji2.cp.includes \-fe0f-
				emoji.cp = emoji2.cp
			else
				emoji2.cp = emoji.cp
	emojis .= filter (emoji) ~>
		emoji.name not in <[copyright registered trade-mark]> or emoji.status isnt \unqualified
	proms = []
	console.log emojis.length
	n = 1
	for let emoji, i in emojis
		prom = new Promise (resolve) !~>
			setTimeout !~>>
				try
					nn = 0
					while nn++ < 2
						res = await fetch "https://twemoji.maxcdn.com/v/latest/svg/#{emoji.cp}.svg"
						if res.status is 200
							buf = Buffer.from await res.arrayBuffer!
							fs.outputFileSync "svg/#{emoji.name}.svg" buf
							console.log "#n / #{emojis.length} - #{emoji.name}"
							break
						else if nn is 1
							emoji.cp -= /-fe0f(?=-|$)/g
						else
							throw Error "Lỗi #{res.status}"
					resolve!
				catch
					console.log "#n / #{emojis.length} - #{emoji.name} (#{emoji.cp}): #{e.message}"
					process.exit!
				n++
			, i * 100
		proms.push prom
	await Promise.all proms
	data = emojis.map ~> [it.chr, it.name]
	data = Object.fromEntries data
	data = JSON.stringify data
	fs.outputFileSync \emojis.json data
	fs.outputFileSync \../hcu/data/emojis.json data
	regexStr = emojis
		.map (.chr)
		.sort (a, b) ~> b.length - a.length or b.localeCompare a
		.join \|
		.replace /\*/g "\\*"
	fs.outputFileSync \emojisRegex.txt regexStr
