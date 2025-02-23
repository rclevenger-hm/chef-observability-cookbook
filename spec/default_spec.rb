require 'spec_helper'

describe 'observability::default' do
  subject(:run) { ChefSpec::SoloRunner.new.converge(described_recipe) }

  it 'installs host metrics by default without enabling commercial agents' do
    expect(run).to include_recipe('observability::node_exporter')
    expect(run).not_to include_recipe('observability::datadog')
    expect(run).not_to include_recipe('observability::splunk')
  end

  it 'allows a fully disabled profile' do
    run = ChefSpec::SoloRunner.new do |node|
      node.override['observability']['node_exporter']['enabled'] = false
    end.converge(described_recipe)
    expect(run).not_to include_recipe('observability::node_exporter')
  end
end
