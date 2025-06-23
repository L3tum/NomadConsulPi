server           = true
datacenter       = "DC0"
bootstrap_expect = 1
bind_addr        = "0.0.0.0"
data_dir         = "/etc/consul/data"
ui               = true
ports {
  grpc = 8502
}
connect {
  enabled = true
}
encrypt = "XXX"
