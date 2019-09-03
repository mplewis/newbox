USER = 'mplewis'
APT_PACKAGES = %w(
  dos2unix
  golang-go
  inetutils-tools
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

APT_PACKAGES.each do |pkg|
  apt_package pkg
end

git_user USER do
  full_name 'Matt Lewis'
  email 'matt@mplewis.com'
end

execute 'fix_gopath' do
  not_if { ENV['GOPATH'] }
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

bash 'install_scm_breeze' do
  not_if { ::File.directory?("#{HOME}/.scm_breeze") }
  cwd HOME
  code <<~CMDS
    git clone git://github.com/scmbreeze/scm_breeze.git ~/.scm_breeze
    ~/.scm_breeze/install.sh
    source ~/.zshrc
  CMDS
end

execute 'install_krypton' do
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
