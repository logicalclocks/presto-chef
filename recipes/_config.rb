include_recipe "hops::wrap"

my_ip = my_private_ip()
nn_endpoint = private_recipe_ip("apache_hadoop", "nn") + ":#{node.apache_hadoop.nn.port}"

mysql_endpoint = private_recipe_ip("ndb", "mysqld") + ":#{node.ndb.mysql_port}"

hive_metastore_endpoint = private_recipe_ip("hive2", "metastore") + ":9803"

zk_ips = private_recipe_ips('kzookeeper', 'default')
zk_endpoints = zk_ips.join(",")

home = "/user/" + node.presto.user

magic_shell_environment 'HADOOP_HOME' do
  value "#{node.apache_hadoop.base_dir}"
end

magic_shell_environment 'PRESTO_HOME' do
  value "#{node.presto.base_dir}"
end

magic_shell_environment 'PATH' do
  value "$PATH:#{node.apache_hadoop.base_dir}/bin:#{node.presto.base_dir}/bin"
end

file "#{node.presto.base_dir}/etc/node.properties" do
  action :delete
end

template "#{node.presto.base_dir}/etc/node.properties" do
  source "node.properties.erb"
  owner node.presto.user
  group node.presto.group
  mode 0655
  variables({ 
              :private_ip => my_ip,
            })
end

file "#{node.presto.base_dir}/etc/jvm.config" do
  action :delete
end

template "#{node.presto.base_dir}/etc/jvm.config" do
  source "jvm.config.erb"
  owner node.presto.user
  group node.presto.group
  mode 0655
end

# file "#{node.presto.base_dir}/bin/launcher.properties" do
#   action :delete
# end

# template "#{node.presto.base_dir}/bin/launcher.properties" do
#   source "jvm.config.erb"
#   owner node.presto.user
#   group node.presto.group
#   mode 0655
# end


file "#{node.presto.base_dir}/etc/config.properties" do
  action :delete
end

if node.presto.role == "coordinator"
  template "#{node.presto.base_dir}/etc/config.properties" do
    source "config-coordinator.properties.erb"
    owner node.presto.user
    group node.presto.group
    mode 0655
    variables({ 
                :private_ip => my_ip
              })
  end
elsif node.presto.role == "worker"
  template "#{node.presto.base_dir}/etc/config.properties" do
    source "config-worker.properties.erb"
    owner node.presto.user
    group node.presto.group
    mode 0655
    variables({ 
                :private_ip => my_ip
              })
  end
elsif node.presto.role == "localhost"
  template "#{node.presto.base_dir}/etc/config.properties" do
    source "config-localhost.properties.erb"
    owner node.presto.user
    group node.presto.group
    mode 0655
    variables({ 
                :private_ip => my_ip
              })
  end
else
  raise "Undefined role: #{node.presto.role}. You should set presto.role to one of 'coordinator', 'worker', or 'localhost'"
end

file "#{node.presto.base_dir}/etc/log.properties" do
  action :delete
end

template "#{node.presto.base_dir}/etc/log.properties" do
  source "log.properties.erb"
  owner node.presto.user
  group node.presto.group
  mode 0655
end

file "#{node.presto.base_dir}/etc/catalog/jmx.properties" do
  action :delete
end

template "#{node.presto.base_dir}/etc/catalog/jmx.properties" do
  source "jmx.properties.erb"
  owner node.presto.user
  group node.presto.group
  mode 0655
end

file "#{node.presto.base_dir}/etc/catalog/hive.properties" do
  action :delete
end

template "#{node.presto.base_dir}/etc/catalog/hive.properties" do
  source "hive.properties.erb"
  owner node.presto.user
  group node.presto.group
  mode 0655
  variables({ 
      :hive_metastore_endpoint => hive_metastore_endpoint
  })
end

file "#{node.presto.base_dir}/etc/node.properties" do
  action :delete
end

template "#{node.presto.base_dir}/etc/catalog/mysql.properties" do
  source "mysql.properties.erb"
  owner node.presto.user
  group node.presto.group
  mode 0655
  variables({ 
              :mysql_endpoint => mysql_endpoint,
            })
end



template "#{node.presto.base_dir}/bin/start-presto.sh" do
  source "start-presto.sh.erb"
  owner node.presto.user
  group node.presto.group
  mode 0751
end

template "#{node.presto.base_dir}/bin/stop-presto.sh" do
  source "stop-presto.sh.erb"
  owner node.presto.user
  group node.presto.group
  mode 0751
end

presto_downloaded = node.presto.base_dir + "/.presto_setup"
bash 'setup-presto' do
  user "root"
  group node.presto.group
  code <<-EOH
        #{node.ndb.scripts_dir}/mysql-client.sh -e \"CREATE USER '#{node.presto.mysql_user}'@'localhost' IDENTIFIED BY '#{node.presto.mysql_password}'\"
        #{node.ndb.scripts_dir}/mysql-client.sh -e \"REVOKE ALL PRIVILEGES, GRANT OPTION FROM '#{node.presto.mysql_user}'@'localhost'\"
        #{node.ndb.scripts_dir}/mysql-client.sh -e \"CREATE DATABASE IF NOT EXISTS metastore CHARACTER SET latin1\"
        #{node.ndb.scripts_dir}/mysql-client.sh metastore -e \"SOURCE #{node.presto.base_dir}/scripts/metastore/upgrade/mysql/presto-schema-2.2.0.mysql.sql\"
        #{node.ndb.scripts_dir}/mysql-client.sh -e \"GRANT SELECT,INSERT,UPDATE,DELETE,LOCK TABLES,EXECUTE ON metastore.* TO '#{node.presto.mysql_user}'@'localhost'\"
        #{node.ndb.scripts_dir}/mysql-client.sh -e \"FLUSH PRIVILEGES\"
#       #{node.presto.base_dir}/bin/schematool -dbType mysql -initSchema
        EOH
  not_if "#{node.ndb.scripts_dir}/mysql-client.sh -e \"SHOW DATABASES\" | grep metastore|"
end




case node.platform
when "ubuntu"
  if node.platform_version.to_f <= 14.04
    node.override.presto.systemd = "false"
  end
end


service_name="presto"

if node.presto.systemd == "true"

  service service_name do
    provider Chef::Provider::Service::Systemd
    supports :restart => true, :stop => true, :start => true, :status => true
    action :nothing
  end

  case node.platform_family
  when "rhel"
    systemd_script = "/usr/lib/systemd/system/#{service_name}.service" 
  else
    systemd_script = "/lib/systemd/system/#{service_name}.service"
  end

  template systemd_script do
    source "#{service_name}.service.erb"
    owner "root"
    group "root"
    mode 0754
    if node.services.enabled == "true"
      notifies :enable, resources(:service => service_name)
    end
    notifies :start, resources(:service => service_name), :immediately
  end

  kagent_config "reload_#{service_name}" do
    action :systemd_reload
  end  

else #sysv

  service service_name do
    provider Chef::Provider::Service::Init::Debian
    supports :restart => true, :stop => true, :start => true, :status => true
    action :nothing
  end

  template "/etc/init.d/#{service_name}" do
    source "#{service_name}.erb"
    owner "root"
    group "root"
    mode 0754
    if node.services.enabled == "true"
      notifies :enable, resources(:service => service_name)
    end
    notifies :start, resources(:service => service_name), :immediately
  end

end

if node.kagent.enabled == "true" 
  kagent_config service_name do
    service service_name
    log_file "#{node.presto.data_dir}/var/log/server.log"
#    log_file2 "#{node.presto.data_dir}/var/log/launcher.log"    
  end
end

