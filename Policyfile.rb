name 'observability-host'
default_source :supermarket
run_list 'observability::default', 'observability::chef_metrics'
cookbook 'observability', path: '.'
