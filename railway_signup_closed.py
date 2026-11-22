"""Answer 403 to any attempt to POST the public sign-up form.

With USERS_CAN_SELF_REGISTER off allauth still renders its "Sign Up Closed" page with status 200 and creates no user. A client that
checks the status code (an agent verifying the deploy, a scanner) cannot tell that from an accepted registration, so refuse the
request outright. Sits first in MIDDLEWARE, so the answer does not depend on a CSRF token being present.
"""
from django.http import HttpResponseForbidden


class SignupClosedMiddleware:
    def __init__(self, get_response):
        self.get_response = get_response

    def __call__(self, request):
        if request.method not in ("GET", "HEAD", "OPTIONS") and request.path.startswith("/accounts/signup"):
            return HttpResponseForbidden("Sign-up is closed.", content_type="text/plain")
        return self.get_response(request)
