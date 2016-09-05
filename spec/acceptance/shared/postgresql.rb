shared_examples 'profile::postgresql' do |role, databases = []|

  it_behaves_like 'profile::defined', 'postgresql'

  describe package('postgresql-server') do
    it { is_expected.to be_installed }
  end

  describe package('postgresql') do
    it { is_expected.to be_installed }
  end

  describe port(5432) do
    it { should be_listening }
  end

  describe 'ActiveMQ system user password' do
    subject { command('PGPASSWORD=mypassword /usr/bin/psql -P pager -h localhost -U ams -d ams -c "select password from amqsec_system_users where username=\'tadmin\'"') }
    its(:stdout) { should include 'mypassword' }
  end

  databases.each do |db|
    describe command("PGPASSWORD=mypassword /usr/bin/psql -P pager -h localhost -U #{role} -d #{role} -c '\\dt'") do
      its(:stdout) { should include db }
    end
  end

end
