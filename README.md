# docker_walg

```
git clone https://github.com/codesshaman/docker_walg.git
```

```
cd docker_walg
```

```
make env
```

Change .env using necessary data:

```
nano .env
```

Build configuration:

```
make build
```

And use

``make help`` to view all commands
``make incr`` for incremental backup,
``make full`` for full backup,
``make latest`` for restore latest backup (not work now)
