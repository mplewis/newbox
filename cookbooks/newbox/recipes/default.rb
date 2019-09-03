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
  command 'sh -c "$(curl -fsSL https://raw.githubusercontent.com/robbyrussell/oh-my-zsh/master/tools/install.sh)"'
  not_if { ::File.directory?("#{HOME}/.oh-my-zsh") }
end

user USER do
  action :modify
  shell 'zsh'
end
