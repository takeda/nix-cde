# Nix-CDE

_Nix-CDE_ (Nix-based Common Development Envrionemnt) provides a reproducible
development environment that abstracts away Nix rough edges through the use
of NixOS modules.

## Motivation

Nix provides great tooling for building projects. The problem I had with it
is that first I had to find those projects, then learn how to use them (which
also assumed knowing well how Nix works), often tweaking things as I learned
more about it. That also created a lot of boilerplate that I had to copy from
project to project, and if I learned something new I had to update it everywhere.
_Nix-CDE's_ goal is to abstract all that boilerplate away.

## Example

### Prerequisites

- you need to have [Nix](https://nixos.org/download.html) installed
- make sure the flake feature is enabled by adding to the `/etc/nix/nix.conf`:
```ini
experimental-features = nix-command flakes
```

### Create following files

```shell
# we are overriding files in later staps, but this is good starting point
nix flake init -t github:takeda/nix-cde 
```

#### Create `flake.nix`
```nix
{
  description = "A simple-app";

  # Nix dependencies for our flake (most of the time you won't change this)
  inputs = {
    flake-utils.url = "github:numtide/flake-utils";
    nix-cde.url = "github:takeda/nix-cde";
  };

  outputs = { self, flake-utils, nix-cde, ... }: flake-utils.lib.eachDefaultSystem (build_system:
  let
    cde = is_shell: nix-cde.lib.mkCDE ./project.nix { inherit build_system is_shell self; };
    # version of CDE that is used for building docker (forces x86_64-linux binaries)
    cde-docker = nix-cde.lib.mkCDE ./project.nix {
      inherit build_system self;
      host_system = "x86_64-linux";
    };
  in {
    # used when invoking `nix develop`
    devShells.default = (cde true).outputs.out_shell;
    # used when invoking `nix build`
    packages.default = (cde false).outputs.out_python;
    # used when invoking `nix build .#docker`
    packages.docker = cde-docker.outputs.out_docker;
  });
}
```

#### Create `project.nix`
```nix
{ config, modulesPath, nix2container, pkgs, ... }:

{
  # modules that our project will use
  require = [
    "${modulesPath}/languages/python-poetry.nix"
    "${modulesPath}/builders/docker-nix2container.nix"
  ];

  # name of our application
  name = "simple-app";

  # files to exclude (there often are files that you need to have in git, but
  # you don't want nix to rebuild your app if they change)
  # simpliarly to .gitignore you can also exclude everything and implicitly
  # list files you want included
  src_exclude = [''
    *
    !/simple_app.py
    !/pyproject.toml
    !/poetry.lock
  ''];

  lean_python = {
    enable = true;
    package = pkgs.python311;
    expat = true;
    zlib = true;
  };

  python = {
    enable = true;
    package = pkgs.python311; # use python3.11
    inject_app_env = true; # add project dependencies to dev shell (simplar to to being in an activated virtualenv)
    prefer_wheels = false; # whether to compile packages ourselves or use wheels
  };

  docker = {
    enable = true;
    # call /bin/hello when running the container
    command = [ "${config.out_python}/bin/hello" ];
    # place python in a separate layer
    layers = with nix2container; [
      (buildLayer { deps = [ pkgs.python311 ]; })
    ];
  };

  # packages that should be available in dev shell
  dev_commands = with pkgs; [
    dive
  ];
}
```

#### Create `simple_app.py`
```python
def cli():
    print("Hello, World!")
```

#### Create `pyproject.toml`
```toml
[tool.poetry]
name = "simple-app"
version = "0.1.0"
description = ""
authors = ["Your Name <you@example.com>"]
packages = [
  { include = "simple_app.py" }
]

[tool.poetry.dependencies]
python = "^3.10"

[tool.poetry.dev-dependencies]

[tool.poetry.scripts]
hello = "simple_app:cli"

[build-system]
requires = ["poetry-core>=1.0.0"]
build-backend = "poetry.core.masonry.api"
```

### Enter dev shell

Create lock file (poetry should be available even if you didn't have it
installed on your computer).
```shell
$ nix develop -c poetry lock
```
Invoke `nix develop` to enter dev shell and run the command to check it works.
`nix develop` essentially creates something similar to Python's `virtualenv` with your
package installed in editable mode. You can make change to your program and your
change will take effect immediately. No need of rebuilding or re-running `nix develop`.

```shell
$ nix develop
$ hello
Hello, World!
```

> Note: It is highly encouraged to install [direnv](https://direnv.net/)
and [nix-direnv](https://github.com/nix-community/nix-direnv).
If you create `.envrc` file with `use flake` then the shell will
automatically change upon entering.


### Build the app

This creates a Nix package with our app and creates `result` symlink that points to it.
```shell
$ nix build
$ ./result/bin/hello
Hello, World!
```

### Building a docker image with our app

```shell
$ nix run .#docker.copyToDockerDaemon
$ docker images
REPOSITORY   TAG                                IMAGE ID       CREATED        SIZE
simple-app   dm3hinmdgp5d4cgjy4x2yxy811bvdp96   a70176be91af   N/A            178MB
$ docker run --rm a70176be91af
Hello, World!
```

> Note: Docker images typically contain linux binaries. This is the main reason
why on Mac docker actually runs on a VM running linux. So while above
example will work without problems on Linux machine you might run into
issues if you use a Mac. To build a docker image on Mac you will need a
remote Linux builder. It could be real linux machine, or you can run one through
[docker](https://github.com/LnL7/nix-docker#running-as-a-remote-builder).

### Reduce size of the docker image

If you noticed, in the above example the container was containing only our
app, but it was still 138MB. This is because python is quite large.
There's a way to shrink it down by excluding some dependencies that
we aren't using in our application.

Here's how to do it:

1. Modify `project.nix` and add `"${modulesPath}/tools/mod-lean-python.nix"`
in the `require` section, like this:
```nix
 require = [
      "${modulesPath}/languages/python-poetry.nix"
      "${modulesPath}/builders/docker-nix2container.nix"
      "${modulesPath}/tools/mod-lean-python.nix"
    ];
```
2. add the following block
```nix
   lean_python = {
     enable = true;
     package = pkgs.python311;
     expat = true;
     zlib = true;
   };
```
3. update `python.package` to point to `config.out_lean_python` instead
of `pkgs.python311`, like this:
```nix
  python = {
    enable = true;
    package = config.out_lean_python;
    inject_app_env = true; # add project dependencies to dev shell (simplar to to being in an activated virtualenv)
    prefer_wheels = false; # whether to compile packages ourselves or use wheels
  };
```
4. update 'docker.layers' ro point to config.out_lean_python instead of `pkgs.python311`, like this:

```nix
  docker = {
    enable = true;
    # call /bin/hello when running the container
    command = [ "${config.out_python}/bin/hello" ];
    # place python in a separate layer
    layers = with nix2container; [
      (buildLayer { deps = [ config.out_lean_python ]; })
    ];
  };
```

5. re-run build:
```shell
$ nix run .#docker.copyToDockerDaemon
# this will take a bit longer than usual, as python is being compiled
# subsequent calls should be quick due to caching
$ docker images
REPOSITORY   TAG                                IMAGE ID       CREATED        SIZE
simple-app   dm3hinmdgp5d4cgjy4x2yxy811bvdp96   a70176be91af   N/A            178MB
simple-app   slgngdkfbds8yfgbil12l04v0k6pwlhv   b503f16dd9fa   N/A            68.9MB
$ docker run --rm b503f16dd9fa
Hello, World!
```
As we can see, this reduced the size of the container to 69MB. It's possible
that it could be reduced even further by using musl, and perhaps bash could be replaced with something else,
unfortunately I don't know yet how to do that.
