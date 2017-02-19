include_recipe "java"
include_recipe "hops::wrap"

my_ip = my_private_ip()

group node.presto.group do
  action :create
  not_if "getent group #{node.presto.group}"
end

user node.presto.user do
  home "/home/#{node.presto.user}"
  action :create
  shell "/bin/bash"
  manage_home true
  not_if "getent passwd #{node.presto.user}"
end

group node.presto.group do
  action :modify
  members ["#{node.presto.user}"]
  append true
end

directory node.presto.data_dir do
  owner node.presto.user
  group node.presto.group
  mode "750"
  action :create
  recursive true
  not_if { File.directory?("#{node.presto.data_dir}") }
end


package_url = "#{node.presto.url}"
base_package_filename = File.basename(package_url)
cached_package_filename = "/tmp/#{base_package_filename}"

remote_file cached_package_filename do
  source package_url
  owner "#{node.presto.user}"
  mode "0644"
  action :create_if_missing
end

presto_downloaded = "#{node.presto.home}/.presto_extracted_#{node.presto.version}"

bash 'extract-presto' do
        user "root"
        group node.presto.group
        code <<-EOH
                set -e
                tar zxf #{cached_package_filename} -C /tmp
                mv /tmp/presto-server-#{node.presto.version} #{node.presto.dir}
                # remove old symbolic link, if any
                rm -f #{node.presto.base_dir}
                ln -s #{node.presto.home} #{node.presto.base_dir}
                chown -R #{node.presto.user}:#{node.presto.group} #{node.presto.home}
                chown -R #{node.presto.user}:#{node.presto.group} #{node.presto.base_dir}
                touch #{presto_downloaded}
                chown -R #{node.presto.user}:#{node.presto.group} #{presto_downloaded}
        EOH
     not_if { ::File.exists?( "#{presto_downloaded}" ) }
end


directory node.presto.base_dir + "/etc" do
  owner node.presto.user
  group node.presto.group
  mode "750"
  action :create
  not_if { File.directory?("#{node.presto.base_dir}/etc") }
end

directory node.presto.base_dir + "/etc/catalog" do
  owner node.presto.user
  group node.presto.group
  mode "750"
  action :create
  not_if { File.directory?("#{node.presto.base_dir}/etc/catalog") }
end

template "/etc/security/limits.d/presto.conf" do
  source "presto.conf.erb"
  owner "root"
  group "root"
  mode 0754
end


cookbook_file "#{node.presto.base_dir}/lib/#{node.presto.jdbc_driver}" do
  source node.presto.jdbc_driver
  owner node.presto.user
  group node.presto.group
  mode "0644"
end

