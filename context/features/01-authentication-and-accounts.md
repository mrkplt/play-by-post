# Authentication & Accounts

## Overview

All authentication is passwordless via magic links. There is no standalone signup flow -- new users enter the platform exclusively through game invitations.

## Requirements

### Magic Link Authentication
- Authentication uses magic links only; there are no passwords
- A sign-in request sends a magic link email to the provided address
- Clicking the magic link authenticates the user and starts a session

### Account Creation
- New users arrive via invitation magic links; there is no standalone signup page
- A magic link from an invitation creates a new account if one does not exist for that email address
- If an account already exists for the email, the invitation links the player to the existing account

### First Login Experience
- After first login, users must set a display name before they can use any other part of the app
- Display names are required and shown throughout the app for authorship attribution
