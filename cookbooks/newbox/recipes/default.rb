USER = 'mplewis'
APT_PACKAGES = %w(
  build-essential
  dos2unix
  golang-go
  inetutils-tools
  libssl-dev
  molly-guard
  sl
  unzip
  zip
  zsh
)

HOME = node['etc']['passwd'][USER]['dir']

# https://github.com/golang/go/wiki/Ubuntu
execute 'add_golang_backports_repo' do
  # https://askubuntu.com/a/148954
  not_if 'grep ^ /etc/apt/sources.list /etc/apt/sources.list.d/* | grep longsleep-ubuntu-golang-backports'
  command 'sudo add-apt-repository ppa:longsleep/golang-backports'
end

execute 'import_rvm_keys' do
  not_if 'gpg --list-keys | grep "RVM signing"'
  command 'gpg --keyserver hkp://pool.sks-keyservers.net --recv-keys 409B6B1796C275462A1703113804BB82D39DC0E3 7D2BAF1CF37B13E2069D6956105BD0E739499BDB'
end

APT_PACKAGES.each do |pkg|
  apt_package pkg
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

execute 'install_oh-my-zsh' do
  not_if { ::File.directory?("#{HOME}/.oh-my-zsh") }
  command 'sh -c "$(curl -fsSL https://raw.githubusercontent.com/robbyrussell/oh-my-zsh/master/tools/install.sh)"'
end

user USER do
  action :modify
  shell 'zsh'
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

bash 'install_bat' do
  not_if 'which bat'
  code <<~CMDS
    wget https://github.com/sharkdp/bat/releases/download/v0.12.0/bat_0.12.0_amd64.deb -O /tmp/bat.deb
    dpkg -i /tmp/bat.deb
    rm /tmp/bat.deb
  CMDS
end

execute 'install_rvm_and_ruby' do
  user USER
  not_if 'which rvm'
  command 'curl -sSL https://get.rvm.io | bash -s stable --ruby --auto-dotfiles'
end

execute 'fix_perms' do
  command "chown -R #{USER} #{HOME}"
end
