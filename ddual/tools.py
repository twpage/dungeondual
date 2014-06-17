import random
from models import *

KEY_LETTERS = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz"
MAX_DEPTH = 10

def createGame(user, gamekey, password=""):
	newGame = DDGame(
		gamekey=gamekey,
		password=password,
		created_by=user
		)
	newGame.save()

	## make up level seeds for this gamekey 
	generateLevelSeedsForGameKey(gamekey)

	return newGame

def getJoinableGames(user=None):
	all_games = DDGame.objects.all()
	if user.is_authenticated():
		return [g for g in all_games if canJoin(g, user)[0]]
	else:
		return [g for g in all_games if (not g.joined_by) and (not alreadyDied(g, g.created_by))]

def isValidGameKey(test_key):
	return all([(f in KEY_LETTERS) for f in test_key])
	
def generateRandomGameKey():
	"""
	Generate a new 8-letter code
	"""
	gamekey = "".join([random.choice(KEY_LETTERS) for i in range(8)])
	return gamekey

def generateLevelSeedsForGameKey(gamekey):
	has_seeds = DDGameKeySeedMap.objects.filter(gamekey=gamekey).exists()
	if has_seeds:
		raise GameModelError(str.format("Game {0} already has level seeds", gamekey))

	level_seed_lst = []

	for i in range(MAX_DEPTH):
		xseed = random.randint(1, 999999999)
		seed = DDGameKeySeedMap(
			gamekey=gamekey,
			level_no=i,
			level_seed=xseed
			)
		seed.save()
		level_seed_lst.append(xseed)

	return level_seed_lst	


def getLevelSeedsFromGameKey(gamekey):
	seeds = DDGameKeySeedMap.objects.filter(gamekey=gamekey)
	if seeds.count() == 0:
		## no seeds generated, make new ones
		return generateLevelSeedsForGameKey(gamekey)

	## already have seeds, return what we have
	seeds.order_by('-level_no')
	level_seed_lst = [s.level_seed for s in seeds]
	return level_seed_lst

def getGameFromGameId(game_id):
	return DDGame.objects.get(id=game_id)
	
def getUserFromUserId(user_id):
	return User.objects.get(id=user_id)

def logDeath(ddgame, user, depth, reason):
	wd = WhoDied(
		game=ddgame,
		user=user,
		on_level=depth,
		reason=reason)
	wd.save()
	return True

def logProgress(ddgame, user, depth):
	prog = ProgressTracker(
		game=ddgame,
		user=user,
		depth=depth)
	prog.save()
	return True

def logVictory(ddgame):
	ww = WhoWon(game=ddgame)
	ww.save()
	return True

def alreadyDied(ddgame, user):
	wd = WhoDied.objects.filter(game=ddgame, user=user)
	return wd.count() > 0

def alreadyWon(ddgame):
	won = WhoWon.objects.filter(game=ddgame)
	return won.count() > 0

def getRecentDeaths():
	"""
	Return a list of all/recent game deaths
	"""
	deaths = WhoDied.objects.all().order_by("-id")
	# deaths.order_by("-id")
	return deaths[:12]

def getRecentVictories():
	"""
	Return a list of all/recent game wins
	"""
	wins = WhoWon.objects.all().order_by("-id")
	# deaths.order_by("-id")
	return wins[:12]

def canJoin(myGame, myUser):
	# you can join if you created it
	is_creator = myGame.created_by == myUser

	# or you joined it
	is_joiner = myGame.joined_by == myUser

	# and you haven't died yet
	has_died = alreadyDied(myGame, myUser)

	# and you haven't won yet
	has_won = alreadyWon(myGame)

	# creator already died
	if alreadyDied(myGame, myGame.created_by):
		return (False, str.format("The creator of this game has already died. Try starting a new one!"))

	elif has_won:
		return (False, "This game has already been won! Try starting a new one.")

	elif (is_creator or is_joiner) and has_died:
		return (False, str.format("You already died in game {0}, try starting a new one!", myGame.id))

	elif (is_creator or is_joiner) and not has_died:
		return (True, "re-joining")

	elif alreadyDied(myGame, myGame.created_by):
		return (False, str.format("{0} has already died! Try starting a new game.", myGame.created_by.username))

	elif myGame.joined_by != None:
		return (False, "Game is full")
	
	# or if it's empty
	else:
		return (True, "joining")

class GameModelError(Exception):
	pass

