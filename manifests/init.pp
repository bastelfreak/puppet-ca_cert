# == Class: ca_cert
#
# This module manages the user installed certificate authority (CA)
# certificates installed on the server. It does not manage operating
# system defaults CA certificates.
#
# === Parameters
#
# [*always_update_certs*]
#   Run the appropriate update CA certificates command for your operating
#   system on every Puppet run whether it is needed or not.
# [*purge_unmanaged_CAs*]
#   When set to true (default: false), user installed CA
#   certificates (in the appropriate directories) not managed by this
#   module will be purged.
# [*install_package*]
#   Whether or not this module should install the ca_certificates package.
#   The package contains the system default (typically Mozilla) CA
#   certificates, as well as the tools required for managing other installed
#   CA certificates.
# [*ca_certs*]
#   A hash of CA certificates that should be installed as part of the class
#   declaration
# [*package_ensure*]
#   The ensure parameter to pass to the package resource
#
# === Examples
#
# class { 'ca_cert': }
#
# class { 'ca_cert':
#   manage_all_user_CAs => true,
# }
#
# === Authors
#
# Phil Fenstermacher <phillip.fenstermacher@gmail.com>
#
class ca_cert (
  Boolean $always_update_certs = false,
  Boolean $purge_unmanaged_CAs = false,
  Boolean $install_package     = true,
  Hash    $ca_certs            = {},
  String  $package_ensure      = present,
  String  $package_name        = $ca_cert::params::package_name,
) inherits ca_cert::params {

  include ::ca_cert::params
  include ::ca_cert::update

  if $always_update_certs == true {
    Exec <| title=='ca_cert_update' |> {
      refreshonly => false,
    }
  }

  if $install_package {
    Class['::ca_cert'] -> Ca_cert::Ca <| |>
  }

  $trusted_cert_dir = $ca_cert::params::trusted_cert_dir
  $cert_dir_group   = $ca_cert::params::cert_dir_group
  $cert_dir_mode    = $ca_cert::params::cert_dir_mode

  file { 'trusted_certs':
    ensure  => directory,
    path    => $trusted_cert_dir,
    owner   => 'root',
    group   => $cert_dir_group,
    mode    => $cert_dir_mode,
    purge   => $purge_unmanaged_CAs,
    recurse => $purge_unmanaged_CAs,
    notify  => Exec['ca_cert_update'],
  }

  if $install_package == true {
    if $package_ensure == present or $package_ensure == installed {
      ensure_packages([$package_name])
    }
    else {
      package { 'ca-certificates':
        ensure => $package_ensure,
        name   => $package_name,
      }
    }
  }

  if !empty($ca_certs) {
    create_resources('ca_cert::ca', $ca_certs)
  }
}
