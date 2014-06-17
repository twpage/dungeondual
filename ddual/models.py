from django.db import models
from django.contrib.auth.models import User

class DDGame(models.Model):
	gamekey = models.CharField(max_length=8)
	password = models.CharField(max_length=20)

	created_by = models.ForeignKey(User)
	created_dt = models.DateTimeField(auto_now=True)

	joined_by = models.ForeignKey(User, blank=True, null=True, related_name="joined")

class DDGameKeySeedMap(models.Model):
	gamekey = models.CharField(max_length=8)
	level_no = models.IntegerField()
	level_seed = models.IntegerField()

class WhoDied(models.Model):
	game = models.ForeignKey(DDGame)
	user = models.ForeignKey(User)
	on_level = models.IntegerField()
	at_time = models.DateTimeField(auto_now=True)
	reason = models.CharField(max_length=140)
	score = models.IntegerField(default=0)


class WhoWon(models.Model):
	game = models.ForeignKey(DDGame)
	at_time = models.DateTimeField(auto_now=True)
	score = models.IntegerField(default=0)


class ProgressTracker(models.Model):
	game = models.ForeignKey(DDGame)
	user = models.ForeignKey(User)
	depth = models.IntegerField()
	at_time = models.DateTimeField(auto_now=True)
