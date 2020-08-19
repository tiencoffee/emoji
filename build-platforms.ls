require! {
	"fs-extra": fs
	"node-fetch": fetch
}

do !->>
	text = await (await fetch \https://unicode.org/Public/emoji/13.0/emoji-test.txt)text!
	names =
		"0023-fe0f-20e3": \keycap-number-sign
		"0023-20e3": \keycap-number-sign
		"002a-fe0f-20e3": \keycap-asterisk
		"002a-20e3": \keycap-asterisk
	emojis = text
		.split \\n
		.filter (is /.+ ; .+ # .+/)
		.map (v) ~>
			v .= split /\ +; | +# /
			a = v.2.split " "
			cp = v.0.replace(/\ /g \-).toLowerCase!
			name: names[cp] or a.slice(2).join(" ").replace(/\W+/g \-).replace(/-$/ "").toLowerCase!
			chr: a.0
			cp: cp
			status: v.1
	for emoji in emojis
		if emoji.status in [\minimally-qualified \unqualified]
			fulEmoji = emojis.find (.name is emoji.name)
			emoji.cp = fulEmoji.cp
	platforms = <[apple facebook google messenger mozilla twitter]>
	proms = []
	for let emoji, i in emojis
		for let platform, j in platforms
			prom = new Promise (resolve) !~>
				setTimeout !~>>
					res = await fetch "https://emojigraph.org/media/#platform/#{emoji.name}_#{emoji.cp}.png"
					if res.status is 200
						buf = await res.arrayBuffer!
						buf = Buffer.from buf
						fs.outputFile "#platform/#{emoji.chr}.png" buf, (err) !~>
							if err => console.log "#{emoji.name} #{err.message}"
							else console.log "#{emoji.name} (#platform)"
							emoji[platform] = yes
							resolve!
					else
						resolve!
				, i * platforms.length * 100 + j * 100
			proms.push prom
	await Promise.all proms
	fs.outputJsonSync \emojis.json emojis, spaces: \\t
	console.log \DONE!
