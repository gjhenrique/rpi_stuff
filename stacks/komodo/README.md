Komodo not managed by komodo to avoid chicken and egg problems

Manually run:

1. To decrypt secres.env
`git-crypt unlock`

2. Export these envs

``` shell
export TS_HOSTNAME=<hostname>
export TS_TAG=<tag>
export TS_OAUTH_CLIENT=<oauth_client>
export TS_OAUTH_SECRET=<oauth_secret>
export EXT_PATH=<path>
```

Or `source komodo-ts.env`

3. Run docker compose command **on stacks directory**:

- docker compose --env-file=komodo/secrets.env -p komodo -f tailscale/compose.yaml -f komodo/compose.yaml up -d
