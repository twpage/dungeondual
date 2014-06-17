from django.contrib import admin
from ddual.models import DDGame, DDGameKeySeedMap, WhoDied, WhoWon, ProgressTracker


class DDGameAdmin(admin.ModelAdmin):
	list_display = ("id", "gamekey", "created_by", "created_dt", "joined_by")

class DDGameKeySeedMapAdmin(admin.ModelAdmin):
	list_display = ("id", "gamekey", "level_no", "level_seed")

class WhoDiedAdmin(admin.ModelAdmin):
	list_display = ("id", "game", "user", "on_level", "at_time")

class WhoWonAdmin(admin.ModelAdmin):
	list_display = ("id", "game", "at_time")

class ProgressTrackerAdmin(admin.ModelAdmin):
	list_display = ("id", "game", "user", "depth")

# Register your models here.
admin.site.register(DDGame, DDGameAdmin)
admin.site.register(DDGameKeySeedMap, DDGameKeySeedMapAdmin)
admin.site.register(WhoDied, WhoDiedAdmin)
admin.site.register(WhoWon, WhoWonAdmin)
admin.site.register(ProgressTracker, ProgressTrackerAdmin)

