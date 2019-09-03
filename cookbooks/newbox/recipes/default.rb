USER = 'mplewis'
APT_PACKAGES = %w(
  inetutils-tools
  dos2unix
  zip
  unzip
  zsh
)

HOME = node['etc']['passwd'][USER]['dir']

APT_PACKAGES.each do |pkg|
  apt_package pkg
end

git_user USER do
  full_name 'Matt Lewis'
  email 'matt@mplewis.com'
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
