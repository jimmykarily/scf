#!/usr/bin/env ruby

require 'yaml'
require 'json'

def get_roles(path)
  return YAML.load_file(path)

  # Loaded structure
  ##
  # the_roles.roles[].name				/string
  # the_roles.roles[].type				/string (allowed "bosh-task")
  # the_roles.roles[].scripts[]				/string
  # the_roles.roles[].jobs[].name			/string
  # the_roles.roles[].jobs[].release_name		/string
  # the_roles.roles[].processes[].name			/string
  # the_roles.roles[].configuration.variables[].name	/string
  # the_roles.roles[].configuration.variables[].default	/string
  # the_roles.roles[].configuration.templates.<any>	/string
  # the_roles.configuration.variables[].name		/string
  # the_roles.configuration.variables[].default		/string
  # the_roles.configuration.templates.<any>		/string
end

def add_parameters(component, variables)
    para = component["parameters"]

    variables.each do |var|
      vname    = var["name"]
      vdefault = var["default"]

      the_para = {
        "name"        => vname,
        "description" => "",
        "default"     => vdefault,
        "example"     => "",
        "required"    => true,
        "secret"      => false,
      }

      para.push the_para
    end
end

def roles_to_ucp(roles)
  the_ucp = {
    "name"       => "HDP CF",	# TODO Specify via option?
    "version"    => "0.0.0",	# s.a.
    "vendor"     => "HPE",	# s.a.
    "volumes"    => [],		# We do not generate volumes, leave empty
    "components" => [],		# Fill from the roles, see below
  }

  comp = the_ucp["components"]
  roles["roles"].each do |role|
    rname = role["name"]
    ename = rname # TODO construct proper external name
    iname = rname # TODO construct proper image name

    the_comp = {
      "name"          => rname,
      "version"       => "0.0.0",	# See also toplevel version
      "vendor"        => "HPE",		# See also toplevel vendor
      "external_name" => ename,
      "image"         => iname,
      "min_RAM_mb"    => 128,		# Pulled out of thin air
      "min_disk_gb"   => 1,		# Ditto
      "min_VCPU"      => 1,
      "platform"      => "linux-x86_64",
      "capabilities"  => ["ALL"],	# This could be role-specific (privileged vs not)
      "depends_on"    => [],		# No dependency info in the RM
      "affinity"      => [],		# No affinity info in the RM
      "labels"        => [rname],	# TODO Maybe also label with the jobs inside ?
      "min_instances" => 1,
      "max_instances" => 1,
      "service_ports" => [],		# This might require role-specific alteration
      "volume_mounts" => [],
      "parameters"    => [],		# Fill from role configuration, see below
    }

    # Global parameters
    if roles["configuration"] && roles["configuration"]["variables"]
      add_parameters(the_comp, roles["configuration"]["variables"])
    end

    # Per role parameters
    if role["configuration"] && role["configuration"]["variables"]
      add_parameters(the_comp, role["configuration"]["variables"])
    end

    # TODO: Should check that the intersection of between global and
    # role parameters is empty.

    comp.push the_comp
  end

  return the_ucp
  # Generated structure
  ##
  # the_ucp.name
  # the_ucp.version
  # the_ucp.vendor
  # the_ucp.volumes[].name
  # the_ucp.volumes[].size_gb
  # the_ucp.volumes[].filesystem
  # the_ucp.volumes[].shared
  # the_ucp.components[].name
  # the_ucp.components[].version
  # the_ucp.components[].vendor
  # the_ucp.components[].external_name
  # the_ucp.components[].image
  # the_ucp.components[].min_RAM_mb		/float
  # the_ucp.components[].min_disk_gb		/float
  # the_ucp.components[].min_VCPU		/int
  # the_ucp.components[].platform
  # the_ucp.components[].capabilities[]
  # the_ucp.components[].depends_on[].name	/string \See 1st 3 comp attributes
  # the_ucp.components[].depends_on[].version	/string \
  # the_ucp.components[].depends_on[].vendor	/string \
  # the_ucp.components[].affinity[]		/?
  # the_ucp.components[].labels[]
  # the_ucp.components[].min_instances		/int
  # the_ucp.components[].max_instances		/int
  # the_ucp.components[].service_ports[].name
  # the_ucp.components[].service_ports[].protocol
  # the_ucp.components[].service_ports[].source_port
  # the_ucp.components[].service_ports[].target_port
  # the_ucp.components[].service_ports[].public		/bool
  # the_ucp.components[].volume_mounts[].volume_name
  # the_ucp.components[].volume_mounts[].mountpoint
  # the_ucp.components[].parameters[].name
  # the_ucp.components[].parameters[].description
  # the_ucp.components[].parameters[].default
  # the_ucp.components[].parameters[].example
  # the_ucp.components[].parameters[].required		/bool
  # the_ucp.components[].parameters[].secret		/bool
end

def save_ucp(path,ucp)
  File.open(path,"w") do |handle|
    #handle.puts (JSON.generate ucp)

    # While in dev I want something at least semi-readable
    handle.puts (JSON.pretty_generate ucp)
  end
end

def main
  # Syntax: <roles-manifest.yml> <ucp-manifest.json>
  # Process arguments
  # - origin      = roles manifest
  # - destination = ucp manifest

  origin      = ARGV[0]
  destination = ARGV[1]

  # Read roles manifest
  # Generate ucp manifest
  # Write ucp manifest

  save_ucp(destination, roles_to_ucp(get_roles(origin)))
end

main
