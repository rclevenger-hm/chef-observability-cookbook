require 'spec_helper'

describe 'observability::node_exporter' do
  def runner(architecture = 'x86_64')
    ChefSpec::SoloRunner.new(step_into: ['observability_node_exporter']) do |node|
      node.automatic['kernel']['machine'] = architecture
    end
  end

  it 'downloads a checksummed archive and uses an unprivileged systemd service' do
    run = runner.converge(described_recipe)
    archive = run.find_resource(:remote_file, File.join(Chef::Config[:file_cache_path], 'node_exporter-1.10.2.linux-amd64.tar.gz'))
    expect(archive.checksum).to eq('c46e5b6f53948477ff3a19d97c58307394a29fe64a01905646f026ddc32cb65b')
    unit = run.find_resource(:systemd_unit, 'node_exporter.service').content
    expect(unit['Service']['User']).to eq('node_exporter')
    expect(unit['Service']['NoNewPrivileges']).to eq(true)
    expect(unit['Service']['ExecStart']).to include('127.0.0.1:9100')
    expect(run).to create_link('/usr/local/bin/node_exporter')
  end

  it 'selects the ARM64 archive and checksum' do
    run = runner('aarch64').converge(described_recipe)
    archive = run.find_resource(:remote_file, File.join(Chef::Config[:file_cache_path], 'node_exporter-1.10.2.linux-arm64.tar.gz'))
    expect(archive.checksum).to eq('de69ec8341c8068b7c8e4cfe3eb85065d24d984a3b33007f575d307d13eb89a6')
  end

  it 'rejects unsupported architectures before downloads' do
    expect { runner('mips').converge(described_recipe) }.to raise_error(/supports x86_64 and aarch64/)
  end

  it 'requires a new checksum for a custom version' do
    run = runner
    run.node.override['observability']['node_exporter']['version'] = '9.9.9'
    expect { run.converge(described_recipe) }.to raise_error(/SHA-256 checksum/)
  end

  it 'rejects contradictory collectors' do
    run = runner
    run.node.override['observability']['node_exporter']['collectors'] = ['cpu']
    run.node.override['observability']['node_exporter']['disabled_collectors'] = ['cpu']
    expect { run.converge(described_recipe) }.to raise_error(/enabled and disabled/)
  end
end
