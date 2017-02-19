include_attribute "kagent"
include_attribute "ndb"
include_attribute "apache_hadoop"
include_attribute "kzookeeper"
include_attribute "hive2"

default.presto.user                    = "presto"
default.presto.group                   = node.apache_hadoop.group
default.presto.version                 = "0.166"
default.presto.url                     = "#{node.download_url}/presto-server-#{node.presto.version}.tar.gz"
default.presto.http.port               = "18080"
default.presto.dir                     = "/srv"
default.presto.home                    = node.presto.dir + "/presto-server-" + node.presto.version
default.presto.base_dir                = node.presto.dir + "/presto-server"
default.presto.data_dir                = node.presto.dir + "/presto-data" 
default.presto.keystore                = node.kagent.keystore
default.presto.keystore_password       = node.kagent.keystore_password


default.presto.role                               = "localhost"
default.presto.node_scheduler.include_coordinator = "false"
default.presto.jvm.max_heap_size                  = "1G"
default.presto.jvm.max_heap_size                  = "1G"
default.presto.query.max_memory                   = "50GB"
default.presto.query.max_memory_per_node          = "1GB"
default.presto.discovery_server.enabled           = "true"


default.presto.mysql_user              = "presto"
default.presto.mysql_password          = "presto"

default.presto.pid_file                = node.presto.data_dir + "/var/run/launcher.pid"
default.presto.log                     = "#{node.presto.base_dir}/presto.log"
default.presto.systemd                 = "true"

default.presto.rmiport                 = "50333"

#
# Hive properties
#

# Enforce data locality for presto. Set to 'true' when presto workers are co-located with HDFS datanodes.
default.presto.hive.force_local_scheduling               = "false"
default.presto.hive.max_partitions_per_writers           = 100
default.presto.hive.metastore.authentication.type        = "NONE"
default.presto.hive.hdfs.authentication.type             = "NONE"
default.presto.hive.hdfs.impersonation.enabled           = "true"



#default.presto.coordinator.public_ips                   = [''] 
#default.presto.worker.public_ips                        = ['']
default.presto.coordinator.private_ips                  = [''] 
default.presto.worker.private_ips                       = ['']
