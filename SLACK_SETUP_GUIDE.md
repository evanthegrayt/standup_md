# Slack Setup for StandupMD Posting

## Summary
Create a private Slack app for your workspace, give its bot permission to post
messages, install it, copy the bot token, invite the bot to `#general`, and
configure StandupMD with the bot token plus the channel ID.

Workflow last tested and validated 2026-06-27.

## Assumptions
- You only need to post your standup into one Slack channel.
- The app is just for your own workspace, not a public Slack Marketplace app.
- `chat:write` plus inviting the bot to `#general` is the preferred setup.
- `chat:write.public` is not needed unless you want posting to public channels
  without inviting the bot first.

## Exact Slack Steps
1. From the screen in your screenshot, click **Create an App**.
2. Choose **From scratch**.
3. Set:
   - **App Name:** `StandupMD`
   - **Pick a workspace:** choose the workspace where `#general` lives
4. Click **Create App**.
5. In the app sidebar, go to **OAuth & Permissions**.
6. Under **Scopes** → **Bot Token Scopes**, add:
   - `chat:write`
7. Optional: add `chat:write.public` only if you want the bot to post to public
   channels without being invited first. For the simplest and safest setup, skip
   this and invite the bot to the channel.
8. Scroll up and click **Install to Workspace**.
9. Approve the installation.
10. After installation, stay on **OAuth & Permissions** and copy the **Bot User
    OAuth Token**.
    - It should start with `xoxb-`.
    - Do not use an `xoxp-` user token.
    - Do not use an app configuration token.

## Channel Setup
1. In Slack, go to `#general`.
2. Invite the app/bot:
   ```text
   /invite @StandupMD
   ```
3. Get the channel ID for `#general`.
   - Open `#general`.
   - Click the channel name at the top.
   - Look for **Copy channel ID** in the details or more/options menu.
   - The ID should look like `C1234567890`.

Prefer using the channel ID over `#general` when configuring StandupMD, as the
name can change but the ID won't.

## StandupMD Values
Set your token in the shell:

```sh
export STANDUP_MD_SLACK_TOKEN="xoxb-your-bot-token"
```

Post with the channel ID:

```sh
standup -P slack --post-channel C1234567890
```

Optional config in `~/.standuprc`:

```ruby
StandupMD.configure do |c|
  c.post.configure_adapter(:slack, channel: "C1234567890")
  c.post.title = "%s -- YOUR NAME"
end
```

Then you can run:

```sh
standup -P
```

If you have multiple users using the same bot, the `c.post.title` is important
to specify the user posting the standup, since the bot's name is `StandupMD`.
