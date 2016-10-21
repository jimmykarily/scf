#!/bin/bash
set -e

# Installs tools needed to build and run HCF
bin_dir="${bin_dir:-/home/vagrant/bin}"
tools_dir="${tools_dir:-/home/vagrant/tools}"
ubuntu_image="${ubuntu_image:-ubuntu:14.04}"
configgin_url="${configgin_url:-https://concourse-hpe.s3.amazonaws.com/configgin-1.1.0%2B4.g999ac54.develop-linux-amd64.tgz}"
fissile_url="${fissile_url:-https://concourse-hpe.s3.amazonaws.com/fissile-2.0.2%2B51.g950d3d3.develop-linux.amd64.tgz}"
cf_url="${cf_url:-https://cli.run.pivotal.io/stable?release=linux64-binary&version=6.21.1&source=github-rel}"

mkdir -p $bin_dir
mkdir -p $tools_dir

echo "Fetching configgin ..."
wget -q "$configgin_url" -O $tools_dir/configgin.tgz
echo "Fetching cf CLI ..."
wget -q "$cf_url"        -O $tools_dir/cf.tgz
echo "Fetching fissile ..."
wget -q "$fissile_url"   -O - | tar xz -C $bin_dir fissile

echo "Unpacking cf CLI ..."
tar -xzf $tools_dir/cf.tgz -C $bin_dir

echo "Making binaries executable ..."
chmod +x $bin_dir/fissile
chmod +x $bin_dir/cf

echo "Pulling base image ..."
docker pull ${ubuntu_image}

echo "Adding HPE license to base image ..."
TMPDIR=$(mktemp -d)
cp "$(dirname "${0}")/container-LICENSE.txt" "${TMPDIR}"
cat >"${TMPDIR}/Dockerfile" <<-EOF
    FROM ${ubuntu_image}
    ADD container-LICENSE.txt /usr/share/doc/stackato/LICENSE.txt
EOF
docker build -q -t hpe-license-on-${ubuntu_image} "${TMPDIR}"
rm -rf "${TMPDIR}"

echo "Pulling ruby bosh image ..."
docker pull helioncf/hcf-pipeline-ruby-bosh

echo "Done."
