## standard libraries
import json

## django libraries
from django.shortcuts import render, redirect
from django.http import HttpResponse
from django.template import RequestContext, loader
from django.contrib import messages
from django.contrib.auth.decorators import login_required
from django.contrib.auth import logout
from django.contrib.auth.models import User

## custom libraries
import tools

# Create your views here.

def home(request):

	template = loader.get_template('ddual/index.html')
	context = RequestContext(request, {
		"games": tools.getJoinableGames(request.user),
		"deaths": tools.getRecentDeaths(),
		"victories": tools.getRecentVictories()
		})
	return HttpResponse(template.render(context))

@login_required
def create_game(request):
	user_gamekey = str(request.POST.get("user_gamekey", ""))
	
	if user_gamekey:
		## make sure its a valid 8char gamekey 
		is_valid = tools.isValidGameKey(user_gamekey)

		## if not, return error message and go back to main page
		if not is_valid:
			messages.add_message(request, messages.ERROR, str.format("Invalid Game Key: {0}", user_gamekey))
			return redirect("home")

		gamekey = user_gamekey

	else:
		## if not given by the user just make a random one
		gamekey = tools.generateRandomGameKey()

	## create the game
	newGame = tools.createGame(
		user=request.user,
		gamekey=gamekey
	)
	
	return redirect("view_game", newGame.id)

@login_required
def view_game(request, game_id):
	myGame = tools.getGameFromGameId(int(game_id))

	[can_join, errmsg] = tools.canJoin(myGame, request.user)

	if not can_join:
		messages.add_message(request, messages.WARNING, errmsg)
		return redirect("home")

	if can_join and (not myGame.created_by == request.user) and myGame.joined_by == None:
		myGame.joined_by = request.user
		myGame.save()

	template = loader.get_template('ddual/game.html')
	context = RequestContext(request, {
		"game": myGame
		})
	return HttpResponse(template.render(context))

def dd_logout(request):
	logout(request)
	return redirect("home")

def view_user_profile(request):
	return redirect("home")

def ajax_levelseeds(request, gamekey):
	"""
	Return a list of level seeds for a given gamekey
	"""
	seed_lst = tools.getLevelSeedsFromGameKey(gamekey)
	data_response = {
		"data": seed_lst,
		"status": "OK"
	}
	return HttpResponse(json.dumps(data_response), content_type="application/json")

def ajax_register(request, username, password):
	"""
	register a user on the fly because i hate users in django
	"""
	user = User.objects.create_user(username, "", password)
	if not user:
		status = "ERROR"
		message = "Invalid username or password"

	else:
		user.save()
		status = "OK"
		message = str.format("Created user '{0}', you may login now", username)

	response = {
		"status": status,
		"message": message
	}

	return HttpResponse(json.dumps(response), content_type="application/json")

def ajax_died(request, game_id, user_id, depth, reason):
	"""
	log a death in the database
	"""
	myGame = tools.getGameFromGameId(int(game_id))
	myUser = tools.getUserFromUserId(int(user_id))

	tools.logDeath(myGame, myUser, int(depth), str(reason))

	response = {
		"status": "OK",
		"message": "logged death"
	}

	return HttpResponse(json.dumps(response), content_type="application/json")

def ajax_victory(request, game_id):
	"""
	log a win in the database
	"""
	myGame = tools.getGameFromGameId(int(game_id))

	tools.logVictory(myGame)

	response = {
		"status": "OK",
		"message": "logged victory"
	}

	return HttpResponse(json.dumps(response), content_type="application/json")

def ajax_progress(request, game_id, user_id, depth):
	"""
	log level progress for stat keeping
	"""
	myGame = tools.getGameFromGameId(int(game_id))
	myUser = tools.getUserFromUserId(int(user_id))

	tools.logProgress(myGame, myUser, int(depth))

	response = {
		"status": "OK",
		"message": "logged progress"
	}

	return HttpResponse(json.dumps(response), content_type="application/json")

def levelgen_test(request):
	template = loader.get_template('ddual/levelgen.html')
	context = RequestContext(request, {})
	return HttpResponse(template.render(context))