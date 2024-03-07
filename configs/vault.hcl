ui = true

api_addr     = "http://{{ GetPrivateIP }}:8200"
cluster_addr = "http://{{ GetPrivateIP }}:8201"

listener "tcp" {
  address     = "0.0.0.0:8200"
  tls_disable = "true"
}

storage "file" {
  path = "/vault/file"
}
