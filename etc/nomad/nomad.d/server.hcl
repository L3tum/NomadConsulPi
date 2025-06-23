data_dir   = "/etc/nomad/conf"
bind_addr  = "0.0.0.0"
datacenter = "DC0"

ports {
  http = 4646
  rpc  = 4647
  serf = 4648
}

server {
  enabled          = true
}

consul {
  address        = "127.0.0.1:8500"
  auto_advertise = true
}

acl {
  enabled    = false
  token_ttl  = "30s"
  policy_ttl = "60s"
}
