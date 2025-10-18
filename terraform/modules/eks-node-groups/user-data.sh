#!/bin/bash
set -o xtrace

# Bootstrap the node to join the EKS cluster
/etc/eks/bootstrap.sh ${cluster_name} ${bootstrap_arguments}

# Custom configurations can be added here
# Example: Install CloudWatch agent, custom monitoring, etc.
