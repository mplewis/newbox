require 'etc'

APT_PACKAGES = %w(
  bat
  build-essential
  dos2unix
  golang-go
  inetutils-tools
  libssl-dev
  molly-guard
  shellcheck
  sl
  unzip
  zip
  zsh
)

BREW_PACKAGES = %w(
  autoconf
  automake
  awscli
  bat
  exa
  go
  jq
  jump
  libtool
  pipenv
  pyenv
  python3
  shellcheck
  sl
  wget
  zsh
)

BREW_CASKS = %w(
  aws-vault
  gpg-suite
  mollyguard
)

USER = Etc.getlogin
HOME = node['etc']['passwd'][USER]['dir']
MACOS = node[:platform] == 'mac_os_x'

if MACOS
  BREW_PACKAGES.each do |pkg|
    package pkg
  end
  
  BREW_CASKS.each do |pkg|
    homebrew_cask pkg
  end
else
  # https://github.com/golang/go/wiki/Ubuntu
  execute 'add_golang_backports_repo' do
    # https://askubuntu.com/a/148954
    not_if 'grep ^ /etc/apt/sources.list /etc/apt/sources.list.d/* | grep longsleep-ubuntu-golang-backports'
    command 'sudo add-apt-repository ppa:longsleep/golang-backports'
  end

  APT_PACKAGES.each do |pkg|
    apt_package pkg
  end
end

git_user USER do
  not_if 'cat ~/.gitconfig'
  full_name 'Matt Lewis'
  email 'matt@mplewis.com'
end

execute 'fix_gopath' do
  user USER
  not_if { !!ENV['GOPATH'] }
  command 'export GOPATH=~/.gopath'
end

script 'install_prezto' do
  interpreter 'zsh'
  not_if { ::File.directory?("#{HOME}/.zprezto") }
  code <<~CMDS
    git clone --recursive https://github.com/sorin-ionescu/prezto.git "${ZDOTDIR:-$HOME}/.zprezto"
    setopt EXTENDED_GLOB
    for rcfile in "${ZDOTDIR:-$HOME}"/.zprezto/runcoms/^README.md(.N); do
      ln -s "$rcfile" "${ZDOTDIR:-$HOME}/.${rcfile:t}"
    done
  CMDS
end

user USER do
  not_if { MACOS }
  action :modify
  shell 'zsh'
end

execute 'import_rvm_keys' do
  not_if 'gpg --list-keys | grep "RVM signing"'
  command 'gpg --keyserver hkp://pool.sks-keyservers.net --recv-keys 409B6B1796C275462A1703113804BB82D39DC0E3 7D2BAF1CF37B13E2069D6956105BD0E739499BDB'
end

group 'rvm' do
  append true
  members USER
end

bash 'install_scm_breeze' do
  user USER
  not_if { ::File.directory?("#{HOME}/.scm_breeze") }
  cwd HOME
  code <<~CMDS
    git clone git://github.com/scmbreeze/scm_breeze.git ~/.scm_breeze
    ~/.scm_breeze/install.sh
    source ~/.zshrc
  CMDS
end

execute 'install_krypton' do
  user USER
  not_if 'which kr'
  command 'curl https://krypt.co/kr | sh'
end

bash 'install_hub' do
  not_if 'which hub'
  code <<~CMDS
    git clone \
      --config transfer.fsckobjects=false \
      --config receive.fsckobjects=false \
      --config fetch.fsckobjects=false \
      https://github.com/github/hub.git /tmp/hub
    cd /tmp/hub
    make install prefix=/usr/local
    rm -rf /tmp/hub
  CMDS
end

bash 'install_exa' do
  not_if 'which exa'
  not_if { MACOS }
  code <<~CMDS
    wget https://github.com/ogham/exa/releases/download/v0.9.0/exa-linux-x86_64-0.9.0.zip -O /tmp/exa.zip
    unzip /tmp/exa.zip
    mv exa-linux-x86_64 /usr/local/bin/exa
    rm /tmp/exa.zip
  CMDS
end

bash 'install_fasd' do
  not_if 'which fasd'
  code <<~CMDS
    wget https://github.com/clvv/fasd/zipball/1.0.1 -O /tmp/fasd.zip
    unzip /tmp/fasd.zip
    mv clvv-fasd-4822024/fasd /usr/local/bin/fasd
    rm -rf fasd.zip clvv-fasd-4822024
  CMDS
end

bash 'install_fzf' do
  user USER
  not_if 'which fzf'
  code <<~CMDS
    git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf
    ~/.fzf/install --key-bindings --completion --update-rc
  CMDS
end

execute 'install_nvm' do
  user USER
  not_if 'which nvm'
  command 'curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.34.0/install.sh | bash'
end

bash 'install_diff-so-fancy' do
  not_if 'which diff-so-fancy'
  code <<~CMDS
    curl https://raw.githubusercontent.com/so-fancy/diff-so-fancy/master/third_party/build_fatpack/diff-so-fancy > /tmp/diff-so-fancy
    chmod a+x /tmp/diff-so-fancy
    mv /tmp/diff-so-fancy /usr/local/bin/diff-so-fancy

    su - #{USER}
    git config --global core.pager "diff-so-fancy | less --tabs=4 -RFX"
    git config --global color.ui true
    git config --global color.diff-highlight.oldNormal    "red bold"
    git config --global color.diff-highlight.oldHighlight "red bold 52"
    git config --global color.diff-highlight.newNormal    "green bold"
    git config --global color.diff-highlight.newHighlight "green bold 22"
    git config --global color.diff.meta       "11"
    git config --global color.diff.frag       "magenta bold"
    git config --global color.diff.commit     "yellow bold"
    git config --global color.diff.old        "red bold"
    git config --global color.diff.new        "green bold"
    git config --global color.diff.whitespace "red reverse"
  CMDS
end

bash 'install_k9s' do
  not_if 'which k9s'
  code <<~CMDS
    wget https://github.com/derailed/k9s/releases/download/0.8.4/k9s_0.8.4_Linux_x86_64.tar.gz -O /tmp/k9s.tgz
    tar xvf /tmp/k9s.tgz k9s
    mv k9s /usr/local/bin/k9s
    rm /tmp/k9s.tgz
  CMDS
end

bash 'install_argocd' do
  not_if 'which argocd'
  code <<~CMDS
    wget https://github.com/argoproj/argo-cd/releases/download/v1.2.1/argocd-linux-amd64 -O /usr/local/bin/argocd
    chmod a+x /usr/local/bin/argocd
  CMDS
end

bash 'install_jump' do
  not_if 'which jump'
  not_if { MACOS }
  code <<~CMDS
    wget https://github.com/gsamokovarov/jump/releases/download/v0.23.0/jump_linux_amd64_binary -O /usr/local/bin/jump
    chmod a+x /usr/local/bin/jump
    echo 'eval "$(jump shell)"' >> ~/.zshrc
  CMDS
end

execute 'install_rvm_and_ruby' do
  user USER
  not_if 'which rvm'
  command 'curl -sSL https://get.rvm.io | bash -s stable --ruby --auto-dotfiles'
end

bash 'install_helm' do
  not_if 'which helm'
  code <<~CMDS
    cd /tmp
    wget https://get.helm.sh/helm-v3.0.0-beta.4-linux-amd64.tar.gz -O helm.tar.gz
    tar xvf helm.tar.gz
    mv /tmp/linux-amd64/helm /usr/local/bin/helm
    rm -rf helm.tar.gz linux-amd64
  CMDS
end

bash 'install_fluxctl' do
  not_if 'which fluxctl'
  code <<~CMDS
    wget https://github.com/fluxcd/flux/releases/download/1.15.0/fluxctl_linux_amd64 -O /tmp/fluxctl
    mv /tmp/fluxctl /usr/local/bin/fluxctl
    chmod a+x /usr/local/bin/fluxctl
  CMDS
end

bash 'install_ngrok' do
  not_if 'which ngrok'
  code <<~CMDS
    cd /tmp
    wget https://bin.equinox.io/c/4VmDzA7iaHb/ngrok-stable-linux-amd64.zip -O ngrok.zip
    unzip ngrok.zip
    mv ngrok /usr/local/bin/ngrok
    rm ngrok.zip
  CMDS
end

bash 'install_skaffold' do
  not_if 'which skaffold'
  code <<~CMDS
    curl -Lo skaffold https://storage.googleapis.com/skaffold/builds/latest/skaffold-linux-amd64
    chmod +x skaffold
    sudo mv skaffold /usr/local/bin
  CMDS
end

execute 'fix_perms' do
  command "chown -R #{USER} #{HOME}"
end
