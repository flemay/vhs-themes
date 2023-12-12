FROM golang:alpine as build

# At some point, I wanted to use the vhs command `screenshot` which wasn't available in version 0.6.0.
# I couldn't use `@latest` as it seemed to download the latest released tag in GitHub (0.6.0) even with GOPROXY=direct
# The solution is to download with #main
#RUN go install github.com/charmbracelet/vhs@main

# Currently I don't need the command `screenshot`
RUN go install github.com/charmbracelet/vhs@latest
RUN go install github.com/charmbracelet/gum@latest

FROM ghcr.io/charmbracelet/vhs
RUN <<EOF
# Install vim, make, and docker. Ref: https://docs.docker.com/engine/install/debian/
apt-get update
apt-get install -y --no-install-recommends \
  neovim \
  shellcheck \
  gettext-base \
  git \
  make \
  curl

rm -rf /var/lib/apt/lists/*

# Test tools are installed
nvim --version
envsubst --version
shellcheck --version
git --version
make --version
curl --version
EOF

COPY nvim-init.lua /root/.config/nvim/init.lua
RUN vhs --version
COPY --from=build /go/bin/gum /usr/bin/gum
RUN gum --version
