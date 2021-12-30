## Manual steps
1. Visit [vars.yml](../../app/vars.yml) to enable the features you would like to include

1. Set an RSS URL to automatically add new TV Show episodes. I recommend https://showrss.info to always add a new torrent automatically

1. Add indexers to Jackett. Visit https://rpi:9118 and add the indexers you would like. Public and private trackers are supported

1. The telegram bot is open by default. Send a message `chat-id` and insert the value of the groups or private chats in the variable `torrent_telegram_groups`.

Run only the `telegram-bot` tasks to restart the bot to restrict only these people to talk with the bot

``` bash
# Replace with your ssh credentials
ansible-playbook --tags=telegram-bot --extra-vars='ansible_user=pi' --extra-vars='ansible_ssh_pass=raspberry' site.yml
```

1. Add the TV Shows and Movies to your streaming platform. `/home/torrent/media/Movies` is where Flexget renames the movies from Transmission and `/home/torrent/media/TV` is for TV Shows.

1. Flexget sends a telegram message when a new movie or episode is renamed and ready to be watched.
The ansible variable with the group name is called `torrent_Flexget_telegram_receiver`.

The issue is that the bot is already listening to new messages and Flexget doesn't have the opportunity to map the chat id with the group name. You can run a manual task to allow this mapping to be stored in Flexget database as a workaround. It will:

- Stop telegram-bot service
- Stop Flexget service
- Add a fake movie (Matrix)
- Run Flexget to move this mock movie to the destination directory
- Start telegram-bot
- Start Flexget
- Delete the fake movie

**Note:** Be careful; this will overwrite a possible Matrix movie you already have installed.

The command is:
``` bash
ansible-playbook --tags=telegram-Flexget-fix  -e add_telegram_to_flexget=true --extra-vars='ansible_user=pi' --extra-vars='ansible_ssh_pass=raspberry' site.yml
```
