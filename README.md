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
_Nix-CDE's_ goal is to abstract all that boiler plate away.

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

  outputs = { self, flake-utils, nix-cde, nixpkgs }: flake-utils.lib.eachDefaultSystem (build_system:
  let
    cde = is_shell: nix-cde.lib.mkCDE ./project.nix { inherit build_system is_shell; };
    # version of CDE that is used for building docker (forces x86_64-linux binaries)
    cde-docker = nix-cde.lib.mkCDE ./project.nix {
      inherit build_system;
      host_system = "x86_64-linux";
    };
  in {
    # used when invoking `nix build .#docker`
    packages.docker = cde-docker.outputs.out_docker;
    # used when invoking `nix build`
    defaultPackage = (cde false).outputs.out_python;
    # used when invoking `nix develop`
    devShell = (cde true).outputs.out_shell;
  });
}
```

#### Create `project.nix`
```nix
{ config, modulesPath, pkgs, ... }:

{
  # modules that our project will use
  require = [
    "${modulesPath}/languages/python-poetry.nix"
    "${modulesPath}/deployments/build-docker.nix"
  ];

  # name of our application
  name = "simple-app";
  
  # source code of our application
  # (same directory as the file, usually doesn't change)
  src = ./.;

  python = {
    enable = true;
    package = pkgs.python310; # use python3.10
  };

  docker = {
    enable = true;
    # call /bin/hello when running the container
    command = [ "${config.out_python}/bin/hello" ];
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
$ nix build .#docker
$ docker load <result
$ docker images
REPOSITORY          TAG                                IMAGE ID       CREATED          SIZE
simple-app          l0d7ynxr4swybdwbs9wjb98zp2ryms7s   b02a1f83e8c2   2 minutes ago    138MB
$ docker run --rm b02a1f83e8c2
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
     "${modulesPath}/deployments/build-docker.nix"
     "${modulesPath}/tools/mod-lean-python.nix"
   ];
```
2. add the following block
```nix
   lean_python = {
     enable = true;
     package = pkgs.python310;
     expat = true;
     zlib = true;
     libffi = true;
   };
```
3. update `python.package` to point to `config.out_lean_python` instead
of `pkgs.python310`, like this:
```nix
   python = {
     enable = true;
     package = config.out_lean_python;
   };
```
4. re-run build:
```shell
$ nix build .#docker
# this will take a bit longer as usual, as python is being compiled
# subsequent calls should be quick due to caching
$ docker load <result
$ docker images
REPOSITORY          TAG                                IMAGE ID       CREATED          SIZE
simple-app          1pjjhhsixmx0j4zgljb91cpg7s6pvcss   12bad943bc8b   41 seconds ago   63.8MB
simple-app          l0d7ynxr4swybdwbs9wjb98zp2ryms7s   b02a1f83e8c2   47 minutes ago   138MB
$ docker run --rm 12bad943bc8b
Hello, World!
```
As we can see, this reduced the size of the container to 63MB. It's possible
that it could be reduced even further once I figure out how to use python
compiled with musl to
[work with poetry2nix](https://github.com/nix-community/poetry2nix/issues/598)
and also remove (setuptools) or replace with smaller versions (bash) some
packages.
