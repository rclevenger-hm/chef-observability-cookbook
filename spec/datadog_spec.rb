require 'spec_helper'

describe 'observability::datadog' do
  it 'fails clearly when an enabled agent has no credential' do
    allow(ENV).to receive(:[]).and_call_original
    allow(ENV).to receive(:[]).with('OBSERVABILITY_DATADOG_API_KEY').and_return(nil)
    expect { ChefSpec::SoloRunner.new.converge(described_recipe) }.to raise_error(/Provide Datadog API key/)
  end

  it 'keeps runtime credentials out of node attributes and protects the file' do
    run = ChefSpec::SoloRunner.new(step_into: ['observability_datadog_agent']) do |node|
      node.run_state['observability'] = { 'datadog_api_key' => 'a' * 32 }
    end.converge(described_recipe)
    resource = run.find_resource(:file, '/etc/datadog-agent/datadog.yaml')
    expect(resource.mode).to eq('0600')
    expect(resource.sensitive).to eq(true)
    expect(JSON.parse(resource.content)['api_key']).to eq('a' * 32)
    expect(run.node['observability']['datadog'].to_json).not_to include('a' * 32)
  end

  it 'requires a pinned package version when installation is requested' do
    run = ChefSpec::SoloRunner.new(step_into: ['observability_datadog_agent']) do |node|
      node.run_state['observability'] = { 'datadog_api_key' => 'a' * 32 }
      node.override['observability']['datadog']['manage_package'] = true
    end
    expect { run.converge(described_recipe) }.to raise_error(/package_version is required/)
  end
end
