 To Actually Deploy
                                                                                                                                                               
  [x] 1. Set up a Railway project and connect your GitHub repo for auto-deploy                                                                                     
  [x] 2. Provision a PostgreSQL database on Railway (it provides DATABASE_URL automatically)
  [x] 3. Push to GitHub — Railway auto-deploys; the entrypoint runs db:prepare automatically  
  [ ] 4. Create Mailgun account
  [ ] 5. Set up Cloudflare R2 bucket for file storage
  [ ] 6. Outbound mail service, is this also mailgun?
  [ ] 7. Create Openrouter API key with budget
  [ ] 8. Set environment variables on Railway:
    - SECRET_KEY_BASE (generate with bin/rails secret)
    - RAILS_ENV=production
    - APP_HOST (your Railway domain)
    - MAILGUN_API_KEY, MAILGUN_DOMAIN
    - OPENROUTER_API_KEY (for inbound email LLM processing)
    - R2_ACCESS_KEY_ID, R2_SECRET_ACCESS_KEY, R2_BUCKET, R2_ENDPOINT
    - RAILS_INBOUND_EMAIL_PASSWORD (Mailgun webhook signing key)
  [ ] 9. Configure Mailgun to route inbound emails to your Railway app's ActionMailbox endpoint