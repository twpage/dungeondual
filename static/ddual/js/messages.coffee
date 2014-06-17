messages = 
	"scared": [
		"Aahhhhh!"
		"Run away!"
		"Save yourselves!!"
		"I want my mommy!"
	]

	"burning": [
		"It burns!"
		"Auuugh!"
		"Fire! Fire! Fire!"
		"FIIIRRE!!"
		"It tastes like burning!"
	]

	"alarm": [
		"Hey!"
		""
		""
		"There you are!"
		"Get them!"
		"Ah hah!"
		""
		"!!!"
		""
	]

window.Brew.Messages =
	getRandom: (msgtype) ->
		if msgtype not of messages
			console.error("No messages of type #{msgtype}")
			return "..."

		return messages[msgtype].random()