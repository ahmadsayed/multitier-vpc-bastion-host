data "template_cloudinit_config" "app_userdata" {
  base64_encode = false
  gzip          = false

  part {
    content = <<EOF
#cloud-config
manage_etc_hosts: true
package_upgrade: false
packages:
- httpd
- python2-pip
runcmd:
- 'cp /usr/share/httpd/noindex/index.html /var/www/html' 
- 'systemctl start httpd'
-  pip install certifi
final_message: "The system is finally up, after $UPTIME seconds"
EOF

  }
}
