# Clickboard

To start your Phoenix server:

* Run `mix setup` to install and setup dependencies
* Start Phoenix endpoint with `mix phx.server` or inside IEx with `iex -S mix phx.server`

Now you can visit [`localhost:4000`](http://localhost:4000) from your browser.

Ready to run in production? Please [check our deployment guides](https://phoenix.hexdocs.pm/deployment.html).

## Deploying

The app runs from source under a systemd user service, with nginx reverse
proxying `clickboard.homework.quest` to the Phoenix endpoint on port 4309.

```sh
git clone <repo> ~/clickboard
cd ~/clickboard
mise exec -- mix deps.get --only prod
MIX_ENV=prod mix assets.deploy
ln -sf ~/clickboard/clickboard.service ~/.config/systemd/user/clickboard.service
systemctl --user daemon-reload && systemctl --user enable --now clickboard
# nginx: install clickboard.nginx.conf, obtain TLS cert, reload
```

## Learn more

* Official website: https://www.phoenixframework.org/
* Guides: https://phoenix.hexdocs.pm/overview.html
* Docs: https://phoenix.hexdocs.pm
* Forum: https://elixirforum.com/c/phoenix-forum
* Source: https://github.com/phoenixframework/phoenix
