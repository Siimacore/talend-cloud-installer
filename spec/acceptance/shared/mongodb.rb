shared_examples 'profile::mongodb' do

  it_behaves_like 'profile::defined', 'mongodb'
  it_behaves_like 'profile::common::packages'

  it_behaves_like 'profile::common::cloudwatchlog_files', %w(
    /var/log/mongodb/mongod.log
  )

  describe 'Verifying mongod conf' do
     describe file('/etc/mongod.conf') do
       it { should be_file }
       its(:content) { should include '#mongodb.conf - generated from Puppet' }
       its(:content) { should include '#System Log' }
       its(:content) { should include 'systemLog.destination: syslog' }
    end
  end

  describe 'Verifying mongod ulimits' do
    describe file('/etc/security/limits.d/mongod.conf') do
      it { should be_file }
      its(:content) { should include '# File managed by Pupppet, do not edit manually' }
      its(:content) { should match /\nmongod\s+soft\s+nproc\s+64000\s*\n/ }
      its(:content) { should match /\nmongod\s+hard\s+nproc\s+64000\s*\n/ }
    end
    describe command('/bin/bash -c \'/bin/cat /proc/$(/bin/pgrep mongo)/limits\'') do
      its(:stdout) { should include 'Max processes             64000                64000                processes' }
    end
  end

  describe 'Verifying mongodb logging' do
    describe file('/etc/rsyslog.d/10_mongod.conf') do
      it { should be_file }
      its(:content) { should include '# This file is managed by Puppet, changes may be overwritten' }
    end
    describe file('/var/log/mongodb/mongod.log') do
      it { should be_file }
    end
    describe command('/bin/test $(/bin/egrep \'^[a-zA-Z]{3} [0-9]{2} [0-9]{2}:[0-9]{2}:[0-9]{2} \' /var/log/mongodb/mongod.log | /bin/wc -l) -gt 3') do
      its(:exit_status) { should eq 0 }
    end
    describe command('/bin/test $(/bin/egrep \'^\s*$\' /var/log/mongodb/mongod.log | /bin/wc -l) -eq 0') do
      its(:exit_status) { should eq 0 }
    end
  end

  describe service('mongod') do
    it { is_expected.to be_enabled }
    it { is_expected.to be_running }
  end

  describe package('mongodb-org-tools') do
      it { should be_installed }
  end

  describe port(27017) do
    it { should be_listening }
  end

  describe file('/var/lib/mongo') do
    it do
      should be_mounted.with(
        :type    => 'xfs',
        :options => {
          :rw         => true,
          :noatime    => true,
          :nodiratime => true,
          :noexec     => true
        }
      )
    end
  end

  describe command('/usr/bin/lsblk -o KNAME,SIZE,FSTYPE -n /dev/sdb') do
    its(:stdout) { should include 'sdb' }
    its(:stdout) { should include '10G' }
    its(:stdout) { should include 'xfs' }
  end

  describe command('/usr/bin/mongo -u admin -p mypassword ipaas --eval "printjson(db.getUser(\'admin\'));" | /usr/bin/tr -d "\t\n "') do
    its(:stdout) { should include '{"role":"userAdminAnyDatabase","db":"admin"}' }
    its(:stdout) { should include '{"role":"dbAdminAnyDatabase","db":"admin"}' }
    its(:stdout) { should include '{"role":"readWriteAnyDatabase","db":"admin"}' }
    its(:stdout) { should include '{"role":"dbOwner","db":"ipaas"}' }
  end

  describe command('/usr/bin/mongo -u tpsvc_config -p mypassword configuration --eval "printjson(db.getUser(\'tpsvc_config\'));" | /usr/bin/tr -d "\t\n "') do
    its(:stdout) { should include '{"role":"dbOwner","db":"configuration"}' }
  end

  describe command('/usr/bin/mongo -u backup -p mypassword admin --eval "printjson(db.getUser(\'backup\'));" | /usr/bin/tr -d "\t\n "') do
    its(:stdout) { should include '{"role":"backupRole","db":"admin"}' }
  end

  describe command('/usr/bin/mongo -u monitor -p mypassword admin --eval "printjson(db.getUser(\'monitor\'));" | /usr/bin/tr -d "\t\n "') do
    its(:stdout) { should include '{"role":"clusterMonitor","db":"admin"}' }
  end

  describe command('/usr/bin/mongo -u datadog -p mypassword admin --eval "printjson(db.getUser(\'datadog\'));" | /usr/bin/tr -d "\t\n "') do
    its(:stdout) { should include '{"role":"clusterMonitor","db":"admin"}' }
  end

  describe command('/usr/bin/mongo -u dqdict-user -p mypassword dqdict --eval "printjson(db.getUser(\'dqdict-user\'));" | /usr/bin/tr -d "\t\n "') do
    its(:stdout) { should include '{"role":"dbOwner","db":"dqdict"}' }
  end

  describe command('/usr/bin/mongo -u dqdict-user -p mypassword dqdict --eval "printjson(db.Document.getIndexes());" | /usr/bin/tr -d "\t\n "') do
    its(:stdout) { should include '{"published.values":1}' }
  end

  describe command('/usr/bin/mongo -u dqdict-user -p mypassword dqdict --eval "printjson(db.Upload.getIndexes());" | /usr/bin/tr -d "\t\n "') do
    its(:stdout) { should include '{"createdAt":1}' }
  end

  describe command('/usr/bin/mongo -u tds -p mypassword tds --eval "printjson(db.getUser(\'tds\'));" | /usr/bin/tr -d "\t\n "') do
    its(:stdout) { should include '{"role":"dbOwner","db":"tds"}' }
  end

  describe 'Logrotate configuration' do
    describe file('/etc/logrotate.d/hourly/mongodb_log') do
      it { should be_file }
      its(:content) { should include '# THIS FILE IS AUTOMATICALLY DISTRIBUTED BY PUPPET.' }
      its(:content) { should include '/var/log/mongodb/mongod.log' }
      its(:content) { should include 'compress' }
    end
    describe file('/etc/cron.hourly/logrotate') do
      it { should be_file }
      its(:content) { should include '# THIS FILE IS AUTOMATICALLY DISTRIBUTED BY PUPPET.' }
      its(:content) { should include ' /etc/logrotate.d/hourly ' }
    end
  end

  %w(
    mongo0.com
    mongo0.net
    mongo0.org
    mongo0.io
    mongo1.com
    mongo1.net
    mongo1.org
    mongo1.io
  ).each do |h|
    describe host(h) do
      it { should be_resolvable.by('hosts') }
    end
  end

  describe 'Cloudwatch MongoDB specific' do
     subject { file('/opt/cloudwatch-agent/metrics.yaml').content }
     it { should include '    DiskSpaceMongoDB:' }
  end

end
