FROM ruby:3.3-bookworm
SHELL ["/bin/bash", "-o", "pipefail", "-c"]
RUN apt-get update && apt-get install -y --no-install-recommends libarchive13 ca-certificates \
    && rm -rf /var/lib/apt/lists/* \
    && gem install chef --version '~> 18.0' --no-document \
    && gem install ruby-shadow --version '~> 2.5' --no-document
COPY . /cookbooks/observability
RUN printf "cookbook_path ['/cookbooks']\nfile_cache_path '/tmp/chef-cache'\n" > /tmp/client.rb \
    && ruby /cookbooks/observability/scripts/chef_client.rb -z -c /tmp/client.rb -o 'recipe[observability::demo]' --chef-license accept-no-persist \
    && ruby /cookbooks/observability/scripts/chef_client.rb -z -c /tmp/client.rb -o 'recipe[observability::demo]' --chef-license accept-no-persist \
       | tee /tmp/second-converge.log \
    && grep -q '0/.* resources updated' /tmp/second-converge.log
USER node_exporter
EXPOSE 9100
ENTRYPOINT ["/usr/local/bin/node_exporter"]
CMD ["--web.listen-address=0.0.0.0:9100", "--collector.textfile.directory=/var/lib/node_exporter/textfile_collector"]
