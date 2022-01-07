variable "forward_zones" {
  description = "The map of DNS zones and DNS server IP addresses to forward dns requests to"
  type        = map(string)
}