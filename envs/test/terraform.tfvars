
# System Node Groups (labels, taints and capacity are applied by the module)
system_node_groups = {
  system-a = {
    desired_size   = 2
    min_size       = 1
    max_size       = 3
    instance_types = ["t3.medium"]
  }
}
