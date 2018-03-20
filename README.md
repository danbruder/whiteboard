# Whiteboard

A multi-user whiteboard written in Elm and Elixir/Phoenix.

![screenshot](https://github.com/danbruder/whiteboard/raw/master/screenshot.png)

## Installation

```
git clone git@github.com:danbruder/whiteboard.git
cd whiteboard
mix deps.get
cd assets && yarn install
```

## Development

```
mix phx.server
```

## Deploy

Setup your [nanobox account](https://nanobox.io) and create a project.

```
nanobox remote add [nanobox project name]
```

Update `config/prod.ex` with the live url: 

```elixir
config :whiteboard, WhiteboardWeb.Endpoint,
  load_from_system_env: true,
  url: [host: YOUR_URL_HERE, port: 80],
  cache_static_manifest: "priv/static/cache_manifest.json"
```

Then you can deploy with:
```
mix phx.digest
nanobox deploy
```
