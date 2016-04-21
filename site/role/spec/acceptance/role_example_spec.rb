require 'spec_helper_acceptance'

describe "role::example", :unless => UNSUPPORTED_PLATFORMS.include?(fact('osfamily')) do


  context 'default install' do

    it 'should provision base role' do
      pp = <<-EOS
        class { 'role::example':
        }
      EOS

      # With the version of java that ships with pe on debian wheezy, update-alternatives
      # throws an error on the first run due to missing alternative for policytool. It still
      # updates the alternatives for java
      apply_manifest(pp, :catch_failures => true, :modulepath => '/tmp/puppet/site:/tmp/puppet/modules')

      apply_manifest(pp, :catch_changes => true, :modulepath => '/tmp/puppet/site:/tmp/puppet/modules',  :opts => {})

    end

    describe package('nginx') do
      it { is_expected.to be_installed }
    end

    describe service('nginx') do
      it { is_expected.to be_enabled }
      it { is_expected.to be_running }
    end

    describe port(80) do
      it { should be_listening }
    end

    describe port(8080) do
      it { should be_listening }
    end

    describe process("tomcat-instance1") do
      its(:user) { should eq "tomcat" }
      its(:args) { should match /tomcat-instance1/ }
    end

  end
end
