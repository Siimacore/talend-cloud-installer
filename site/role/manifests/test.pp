#
# Test Instance of the Debug stack
#
class role::test {

  require ::profile::base
  require ::profile::docker::host
  require ::pip

  role::register_role { 'test': }

  pip::install { 'invoke': }

  file { '/opt/talend/ipaas/rt-integration-test/config.ini':
    content => "[ipaas-rt-test]
nexus=${::nexus_host}
infra=${::services_internal_host}
"
  }

}
