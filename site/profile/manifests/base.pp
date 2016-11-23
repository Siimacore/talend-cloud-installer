# The base profile should include component modules that will be on all nodes
#
# -*- mode: puppet -*-
# vi: set ft=puppet
#
# === Authors
# Andreas Heumaier <andreas.heumaier@nordcloud.com>
#
class profile::base {

  include ::profile::common::packagecloud_repos
  include ::profile::common::packages
  include ::profile::common::cloudwatchlogs
  include ::profile::common::ssm

  include ::profile::common::concat
  include ::profile::common::accounts

  #contain(::profile::common::cloudwatch, ::awscli)
  #Class['::profile::common::cloudwatch'] -> Class['::awscli']

  profile::register_profile { 'base': order => 1, }

  if $::osfamily == 'RedHat' and $::selinux == 'true' {
    include ::selinux
  }

  if $::ec2_metadata {
    include ::awscli
    include profile::common::helper_scripts
  }

  # This distributes the custom fact to the host(-pluginsync)
  # on using puppet apply
  file { $::settings::libdir:
    ensure  => directory,
    source  => 'puppet:///plugins',
    recurse => true,
    purge   => true,
    backup  => false,
    noop    => false,
  }

}
