# Next Steps

## 1. Get it running locally

```bash
bin/rails server
```

Visit http://localhost:3000. You'll hit the login page. Since Devise passwordless sends
a real email, configure letter_opener for local dev so magic links open in the browser
instead of going to Mailgun:

```ruby
# Gemfile (development group)
gem "letter_opener"
```

```ruby
# config/environments/development.rb
config.action_mailer.delivery_method = :letter_opener
config.action_mailer.perform_deliveries = true
```

## 2. Git + GitHub

```bash
git init
git add .
git commit -m "Initial Rails app"
gh repo create play-by-post --private --source=. --push
```

## 3. Deploy to Railway

1. Create a new Railway project at railway.app
2. Add a **PostgreSQL** service — Railway injects `DATABASE_URL` automatically
3. Connect your GitHub repo to a **Web** service
4. Set environment variables (see `.env.example`):
   - `SECRET_KEY_BASE` — run `bin/rails secret` to generate
   - `RAILS_ENV=production`
   - `APP_HOST` — your Railway app URL (e.g. `play-by-post.up.railway.app`)
5. Railway will detect `railway.toml` and run `db:migrate` on deploy automatically

## 4. Mailgun

1. Sign up at mailgun.com (free tier: 100 emails/day)
2. Add and verify your domain (or use the Mailgun sandbox for testing)
3. Set `MAILGUN_API_KEY` and `MAILGUN_DOMAIN` in Railway env vars
4. For inbound email (email-to-post):
   - Add a Mailgun inbound route forwarding `scene-*@inbound.yourdomain.com` to
     `https://your-app.up.railway.app/rails/action_mailbox/mailgun/inbound_emails/mime`
   - Set `RAILS_INBOUND_EMAIL_PASSWORD` — a secret you choose, set in both Mailgun
     and Railway env vars (used to authenticate the webhook)

## 5. Cloudflare R2 (file storage)

Skip this initially — the app uses local disk storage in development and you can
defer R2 until you need file uploads in production.

When ready:
1. Create a Cloudflare account → R2 → New bucket
2. Create an API token with R2 read/write permissions
3. Set `R2_ACCESS_KEY_ID`, `R2_SECRET_ACCESS_KEY`, `R2_BUCKET`, `R2_ENDPOINT`
   in Railway env vars

## 6. OpenRouter (inbound email LLM parsing)

Sign up at openrouter.ai — the `google/gemma-3-4b-it:free` model used for stripping
email artifacts is free. Set `OPENROUTER_API_KEY` in Railway env vars.

The app degrades gracefully if the key is missing — it uses the raw email body.

## 7. Things not yet built

- **Image attachments on posts and scenes** — the models have `has_one_attached :image`
  but the composer form doesn't include a file upload field yet. Add it to
  `_composer.html.erb` and render thumbnails in `_post_item.html.erb`.

- **`aws-sdk-s3` gem** — Active Storage with R2 requires the S3 adapter gem.
  Add `gem "aws-sdk-s3", require: false` to the Gemfile before enabling R2.

## 8. Recommended first thing to test end-to-end

1. Start the server locally
2. Go to `/users/sign_in`, enter your email
3. Open the letter_opener browser tab, click the magic link
4. Set your display name
5. Create a game
6. Create a scene
7. Post in the scene
8. Verify the edit link appears and disappears after 10 minutes
