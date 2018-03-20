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

Then you can deploy with:
```
mix phx.digest
nanobox deploy
```

