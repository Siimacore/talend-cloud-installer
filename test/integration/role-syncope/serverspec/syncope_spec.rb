require 'spec_helper'

describe 'role::syncope' do
  it_behaves_like 'profile::base'
  it_behaves_like 'profile::syncope'
  it_behaves_like 'role::defined', 'syncope'
end
