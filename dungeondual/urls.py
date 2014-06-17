from django.conf.urls import patterns, include, url
from django.contrib import admin
admin.autodiscover()

from django.conf import settings
from django.conf.urls.static import static

import ddual

urlpatterns = patterns('',
    # Examples:
    # url(r'^$', 'myproject.views.home', name='home'),
    # url(r'^blog/', include('blog.urls')),

    url(r'^$', 'ddual.views.home', name='home'),

    url(r'^creategame/', 'ddual.views.create_game', name='create_game'),
    
    url(r'^game/(\d+)$', 'ddual.views.view_game', name='view_game'),

    url(r'^admin/', include(admin.site.urls)),
    
    url(r'^accounts/login/$', 'django.contrib.auth.views.login'),

    url(r'^accounts/logout/$', 'ddual.views.dd_logout'),

    url(r'^accounts/profile/$', 'ddual.views.view_user_profile'),

    url(r'^ajax/levelseeds/(.*)$', 'ddual.views.ajax_levelseeds'),

    # url(r'^ajax/joingame/(\d+)/(\d+)$', 'ddual.views.ajax_joingame'),

    url(r'^ajax/register/(.*?)/(.*)/$', 'ddual.views.ajax_register'),

    url(r'^ajax/died/(\d+)/(\d+)/(\d+)/(.*?)/$', 'ddual.views.ajax_died'),

    url(r'^ajax/victory/(\d+)/$', 'ddual.views.ajax_victory'),

    url(r'^ajax/progress/(\d+)/(\d+)/(\d+)/$', 'ddual.views.ajax_progress'),

    url(r'^levelgen_test/$', 'ddual.views.levelgen_test', name='levelgen_test'),

) + static(settings.STATIC_URL, document_root=settings.STATIC_ROOT)

