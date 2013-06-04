object @user
# show the user data for whoever's page we're on
extends "users/base"

# show profile data for the page
code(:profile) { partial("profile/base", :object => @profile) }