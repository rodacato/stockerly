# Devcontainer

How credentials reach this container, what survives a rebuild, and what deploy tooling can do
from inside it. For getting the app running, see [GETTING_STARTED.md](../GETTING_STARTED.md).

## Host requirements

- **Docker** with Compose **2.24 or later** — the optional `env_file` entries need it.
- **VS Code** with the **Dev Containers** extension.
- **A GitHub token scoped to this repository** — optional, for `gh` inside the container: a
  fine-grained personal access token with only this repository selected and an expiry. The
  container never inherits the host's own `gh` login.
- **An SSH agent with your key loaded** — only for deploy tooling and server access. `ssh-add -l`
  on the host should list it.

## What the container inherits

| Credential | How it arrives | Survives a rebuild? |
|---|---|---|
| `git push` / `git pull` over SSH | VS Code forwards the host's SSH agent (`SSH_AUTH_SOCK`) | Yes |
| SSH to your server (Kamal, `bin/prod-sync`) | The same forwarded agent | Yes |
| `gh` CLI | Not inherited. You log it in from the host with the scoped token (First open, step 4) | **No** — log in again after a rebuild |
| `GITHUB_REPOSITORY`, `GITHUB_REPOSITORY_OWNER`, `GITHUB_ACTOR` | `initialize.sh` derives them from the `origin` remote | Yes |
| Git author name and email | VS Code copies the host's `~/.gitconfig` | Yes |
| `HOST_IP`, `APP_HOST` | `local.env`, which you write | Yes |
| AI coding agents (Claude Code, Codex…) | Not part of this devcontainer: install and log in the one you use, from the host or inside | Only if its home is kept outside the container layer |
| Production secrets | Not inherited, by design — they live in the GitHub Environment | **No** |

`initializeCommand` runs `initialize.sh` **on the host** before every start. It writes
`.devcontainer/.host.env` (mode 600, gitignored) with no credential in it, and always exits 0,
so a host without `git` still opens the container. Compose loads `.host.env` and then `local.env`
as environment files; both are optional, and a variable set in `local.env` wins.

Environment files are read when the container is **created**. Reopening an existing container
keeps the old values; **Dev Containers: Rebuild Container** picks up new ones.

## First open

1. On the host, optionally: `ssh-add` your key.
2. Only if you will use deploy tooling, before opening:
   ```bash
   cp .devcontainer/local.env.example .devcontainer/local.env
   $EDITOR .devcontainer/local.env    # HOST_IP and APP_HOST
   ```
   Doing this after the container exists works too, followed by a rebuild.
3. Open the folder in VS Code and run **Dev Containers: Reopen in Container**. `post-create.sh`
   prepares the databases on first creation.
4. For `gh`, on the host, from this folder, with the scoped token in `$TOKEN`:
   ```bash
   printf '%s\n' "$TOKEN" | docker exec -i -u vscode \
     "$(docker ps -q --filter label=devcontainer.local_folder="$PWD")" \
     gh auth login -h github.com --with-token
   ```
   The token goes through stdin, never an argument or an environment variable. A rebuild drops the
   login; run it again.
5. Check, in a container terminal:
   ```bash
   gh auth status          # logged in, after step 4
   env | grep ^GITHUB_     # the three derived values
   ```

## Deploy tooling from the container

`config/deploy.yml` renders from `GITHUB_REPOSITORY`, `GITHUB_ACTOR`, `HOST_IP` and `APP_HOST`, and
every one of them is in the environment. Commands that only read, or that run inside a container
already up on the server, need no secret:

```bash
bin/kamal config                      # resolved config — check it before anything else
bin/kamal app details                 # running containers, image, uptime
bin/kamal accessory details postgres
bin/kamal app logs -r job -n 200
bin/kamal audit
bin/kamal console                     # also: shell, db, logs
bin/kamal app exec --reuse --roles web 'bin/rails about'
bin/prod-sync status
```

**Why the aliases use `--reuse`.** Without it Kamal starts a fresh container, and that begins with
a registry login on the server — `KAMAL_REGISTRY_PASSWORD`, which exists only in CI. With
`--reuse --interactive` Kamal runs `docker exec` over SSH into the running container and never
logs in (`Kamal::Cli::App#exec`, Kamal 2.12). Confirmed with `bin/kamal console` from a rebuilt
container; `shell` passes the same flags to the same command.

**To verify:** `bin/kamal db` goes through `accessory exec --reuse --interactive`, a different
command path that has not been run from a container yet.

**What does not work here**, and must not be forced: `deploy`, `redeploy`, `rollback`, `setup`,
`build`, `app boot`, and `app exec` without `--reuse`. They push an image, need the registry, or
write the container's env file from `.kamal/secrets` — which in this container resolves every
secret to an empty string, silently. Run them through GitHub Actions (`deploy.yml`), or from the
host with the secrets exported, per [docs/ops/deploy.md](../docs/ops/deploy.md).

## Security model

- **The devcontainer's own files carry no credential.** `.host.env` holds only the three
  `GITHUB_*` values; nothing in `devcontainer.json`, Compose or `local.env` holds a token.
- **The token you log `gh` in with is the whole exposure.** `gh` stores it in plain text in
  `~/.config/gh/hosts.yml`, since the container has no keyring, and every process in the
  container can read it — extensions, AI agents, package install scripts. Scoped to this one
  repository and with an expiry, a leak reaches this repository for a limited time and nothing
  else: not your other repositories, not private ones, not your account.
- **Never pass it as `GH_TOKEN`** in `local.env` or the Compose environment: an environment
  variable beats the stored login, shows up in `docker inspect`, and survives in the container's
  configuration.
- **GitHub Projects owned by a user account are out of reach for fine-grained tokens.** If you
  work a board from here, use a separate classic token with only `project`, `read:org` and
  `read:discussion` for it, never a wider one.
- **On Windows**, `initializeCommand` runs under `cmd.exe`. With Git for Windows' `sh` on the
  `PATH` it behaves as above; without it the command falls through, no `.host.env` is written,
  and the `GITHUB_*` values have to go in `local.env`. Untested on Windows. Under WSL it is Linux.
- **In Codespaces**, Codespaces provides its own `GITHUB_TOKEN`; step 4 is not needed.

## Troubleshooting

| Symptom | Cause | Fix |
|---|---|---|
| Kamal aborts with `GITHUB_REPOSITORY is not set` (or `GITHUB_ACTOR`) | The variable is not in the environment: no `origin` remote, `initialize.sh` did not run, or the container predates it | On the host, `cat .devcontainer/.host.env`; then **Rebuild Container** |
| Kamal aborts with `HOST_IP is not set` or `key not found: "APP_HOST"` | No `local.env`, or the container predates it | Create it from `local.env.example`, then **Rebuild Container** |
| `gh` asks you to log in | The container was rebuilt, or step 4 of First open never ran | Step 4, on the host |
| `gh` answers `Bad credentials`, or 403/404 on another repository | The token expired — or it is scoped to this repository, by design | A new token; another repository gets its own |
| An edit to `local.env` has no effect | Environment files are read at creation; reopening does not recreate | **Rebuild Container** |
| `ssh-add -l` says it cannot connect to the agent, or SSH fails with `Permission denied (publickey)` | The agent is forwarded only to processes VS Code starts; `docker exec` and outside terminals have no `SSH_AUTH_SOCK`, and the host agent may hold no key | Use a VS Code terminal; on the host, `ssh-add` your key |
