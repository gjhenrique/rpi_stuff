## Manual steps
1. Visit [vars.yml](../../app/vars.yml) to enable the features you would like to include

1. Set an RSS URL to automatically add new TV Show episodes. I recommend https://showrss.info to always add a new torrent automatically

1. Add indexers to Jackett. Visit https://rpi:9118 and add the indexers you would like. Public and private trackers are supported

1. The telegram bot is open by default. Send a message `chat-id` and insert the value of the groups or private chats in the variable `torrent_telegram_groups`.

Rune the command in the machine to restart the service

``` bash
systemctl restart compose-torrent
```

1. Add the TV Shows and Movies to your streaming platform. Flexget renames the from the torrents directory to `/home/torrent/media/Movies` and `/home/torrent/media/TV` to TV Shows

1. Flexget sends a telegram message when a new movie or episode is renamed and ready to be watched.
The ansible variable with the group name is called `torrent_Flexget_telegram_receiver`.

Theres is an annoying issue where the bot is already listening to new messages and Flexget doesn't have the opportunity to map the chat id with the group name. You can run a manual task to allow this mapping to be stored in Flexget database as a workaround. It will:

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
ansible-playbook --tags=telegram-flexget-fix  -e add_telegram_to_flexget=true site.yml
```
