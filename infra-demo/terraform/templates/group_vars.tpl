---
# Application variables
app_name: "${app_name}"
app_port: ${app_port}
app_user: "appuser"
app_directory: "/opt/{{ app_name }}"
node_version: "${node_version}"
environment: "${environment}"

# Performance tuning based on environment
%{ if environment == "production" ~}
pm2_instances: 4
pm2_max_memory_restart: "500M"
%{ else ~}
pm2_instances: 2
pm2_max_memory_restart: "300M"
%{ endif ~}
