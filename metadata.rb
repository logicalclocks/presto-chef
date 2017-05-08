name             "presto"
maintainer       "Jim Dowling"
maintainer_email "jdowling@kth.se"
license          "Apache v2"
description      'Installs/Configures Hive Server'
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version          "0.1.0"
source_url       "https://github.com/hopshadoop/presto-chef"



depends          "ndb"
depends          "hops"
depends          "kagent"
depends          "java"
depends          "kzookeeper"
depends          "magic_shell"
depends          "hive2"

recipe           "install", "Installs prestodb binaries"
recipe           "coordinator", "Starts  a Presto Coordinator"
recipe           "worker", "Starts  a Presto Worker"
recipe           "localhost", "Starts  a Presto Localhost setup (Coordinator and Worker)"
recipe           "purge", "Removes and deletes an installed Hive Server"
recipe           "_config", "Subrecipe"

attribute "java/jdk_version",
          :description =>  "Jdk version",
          :type => 'string'

attribute "java/install_flavor",
          :description =>  "Oracle (default) or openjdk",
          :type => 'string'

attribute "presto/user",
          :description => "User to install/run as",
          :type => 'string'

attribute "presto/dir",
          :description => "base dir for installation",
          :type => 'string'

attribute "presto/version",
          :dscription => "presto version",
          :type => "string"

attribute "presto/url",
          :dscription => "presto download url",
          :type => "string"

attribute "presto/http/port",
          :dscription => "presto http port",
          :type => "string"

attribute "presto/home",
          :dscription => "presto installation directory",
          :type => "string"

attribute "presto/keystore",
          :dscription => "ssl/tls keystore",
          :type => "string"

attribute "presto/keystore_password",
          :dscription => "ssl/tls keystore_password",
          :type => "string"

attribute "presto/coordinator/private_ips",
          :description => "Set ip addresses",
          :type => "array"

attribute "presto/worker/private_ips",
          :description => "Set ip addresses",
          :type => "array"

attribute "install/dir",
          :description => "Set to a base directory under which we will install.",
          :type => "string"

attribute "install/user",
          :description => "User to install the services as",
          :type => "string"

