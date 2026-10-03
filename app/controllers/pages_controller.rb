# Public information pages (no sign-in needed)
class PagesController < ApplicationController
  allow_unauthenticated_access

  # GET /privacy: the privacy policy. Its URL is entered in the Facebook app settings
  # (Privacy policy URL) and can be used for Google's OAuth consent screen too.
  def privacy
  end
end
