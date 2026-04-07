 To Actually Deploy
     
  [x] 1. Set up a Railway project and connect your GitHub repo for auto-deploy                                                                                     
  [x] 2. Provision a PostgreSQL database on Railway (it provides DATABASE_URL automatically)
  [x] 3. Push to GitHub — Railway auto-deploys; the entrypoint runs db:prepare automatically  
  [x] 5. Set up railway bucket for file storage
  [x] 4. Create Mailgun account
  [x] 6. Outbound mail service, is this also mailgun?
  [x] 7. Create Openrouter API key with budget
  [x] 8. Set environment variables on Railway:
    - [x] SECRET_KEY_BASE (generate with bin/rails secret)
    - [x] RAILS_ENV=production
    - [x] APP_HOST (your Railway domain)
    - [x] MAILGUN_API_KEY, MAILGUN_DOMAIN
    - [x] OPENROUTER_API_KEY (for inbound email LLM processing)
    - [x] STORAGE_ACCESS_KEY_ID, STORAGE_SECRET_ACCESS_KEY, STORAGE_BUCKET, STORAGE_ENDPOINT, STORAGE_REGION
    - [x] RAILS_INBOUND_EMAIL_PASSWORD (Mailgun webhook signing key)
  [ ] 9. Configure Mailgun to route inbound emails to your Railway app's ActionMailbox endpoint