## 0. Prerequisites

### 0.1 `./cosmocc` — you must provide this

This repo does **not** ship the compiler. `./cosmocc` must exist and hold a
Cosmopolitan toolchain, either as a real directory or as a symlink to one:

```sh
# A) download it here
curl -o cosmocc.zip https://cosmo.zip/pub/cosmocc/cosmocc.zip
unzip cosmocc.zip -d cosmocc        # -> ./cosmocc/{bin,include,<arch>-linux-cosmo}

# B) or point at a toolchain you already manage (xmake, system install, ...)
ln -s /path/to/your/cosmocc ./cosmocc
```

### 0.2 APE loader (Linux hosts)

`ncurses` compiles and runs `tic` during `make install`, and `hello.com` is an
APE binary. On Linux both need the loader registered:


```sh
./ape_loader_init.sh
```

Cross-building `aarch64` additionally needs qemu:

```sh
sudo dnf install qemu-user-static      # Fedora
sudo apt install qemu-user-static      # Debian/Ubuntu
```

### 0.3 Tools

`make`, `cmake` ≥ 3.15, `git`, `patch`, `curl` or `wget`, `sha256sum`, `g++`
(only for the toolchain self-test).

---

## 1. Build

From the repository root:

```sh
git submodule update --init     # fetches tv/tvision

make -C ncurses                 # libncursesw.a, libtinfow.a, ... -> ncurses/out/<arch>
make -C tv                      # libtvision.a                    -> ncurses/out/<arch>
```

Both default to `x86_64` + `aarch64`. To skip aarch64 (no qemu needed):

```sh
make -C ncurses ARCHS=x86_64
make -C tv ARCHS=x86_64
```


## 2. Run the demo

From the repository root(x86_64):

```sh
export COSMOS=$PWD/out/x86_64
$PWD/build/cosmocc-shadow/bin/x86_64-unknown-cosmo-c++ -o hello.com \
    tv/tvision/hello.cpp -I$COSMOS/include -L$COSMOS/lib \
    -ltvision -lncursesw -ltinfow

TERM=xterm-256color ./hello.com
```
