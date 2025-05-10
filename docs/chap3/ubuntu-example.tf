terraform {
  required_version = ">= 0.13"
  required_providers {
    libvirt = {
      source = "dmacvicar/libvirt"
    }
  }
}

provider "libvirt" {
  uri = "qemu:///system"
}

# Storage pool for our resources
resource "libvirt_pool" "wordpress_pool" {
  name = "wordpress_pool"
  type = "dir"
  
  target {
    path = "/home/maybetuandat/Downloads/packer-notes/docs/chap3/tmp/terraform-provider-libvirt-pool-wordpress"
  }
}
# We use the Ubuntu image created by Packer
resource "libvirt_volume" "ubuntu_image" {
  name   = "wordpress-ubuntu-image"
  pool   = libvirt_pool.wordpress_pool.name
  source = "/home/maybetuandat/Downloads/packer-notes/docs/chap2/output-jammy/ubuntu-jammy.img"
  format = "qcow2"
}

# Create user-data file with our cloud-init configuration
# data "template_file" "user_data" {
#   template = <<-EOF
#     #cloud-config
#     # Set password and enable password auth
#     password: test321
#     ssh_pwauth: true
#     chpasswd:
#       expire: false
    
#     # Configure SSH banner
#     write_files:
#       - path: /etc/ssh_banner
#         content: |
#           Welcome to Application WordPress
#         permissions: '0644'
#       - path: /tmp/wordpress_setup.sh
#         content: |
#           #!/bin/bash
          
#           # Update system
#           apt-get update
#           apt-get upgrade -y
          
#           # Install LAMP stack and WordPress dependencies
#           apt-get install -y apache2 mariadb-server php php-mysql php-curl php-gd php-mbstring php-xml php-xmlrpc php-soap php-intl php-zip
          
#           # Configure UFW
#           apt-get install -y ufw
#           ufw allow 22
#           ufw allow 80
#           ufw allow 443
#           ufw --force enable
          
#           # Configure SSH banner
#           sed -i 's/#Banner.*/Banner \/etc\/ssh_banner/' /etc/ssh/sshd_config
#           systemctl restart sshd
          
#           # Set up MariaDB for WordPress
#           mysql -u root <<MYSQL_SCRIPT
#           CREATE DATABASE wordpress;
#           CREATE USER 'wpuser'@'localhost' IDENTIFIED BY 'wppassword';
#           GRANT ALL PRIVILEGES ON wordpress.* TO 'wpuser'@'localhost';
#           FLUSH PRIVILEGES;
#           MYSQL_SCRIPT
          
#           # Download and configure WordPress
#           wget https://wordpress.org/latest.tar.gz -P /tmp
#           tar -xzf /tmp/latest.tar.gz -C /tmp
          
#           # Set up Apache virtual host for WordPress
#           cp -R /tmp/wordpress/* /var/www/html/
#           chown -R www-data:www-data /var/www/html/
#           chmod -R 755 /var/www/html/
          
#           # Create WordPress config
#           cp /var/www/html/wp-config-sample.php /var/www/html/wp-config.php
#           sed -i 's/database_name_here/wordpress/' /var/www/html/wp-config.php
#           sed -i 's/username_here/wpuser/' /var/www/html/wp-config.php
#           sed -i 's/password_here/wppassword/' /var/www/html/wp-config.php
          
#           # Generate WordPress salts
#           SALTS=$(curl -s https://api.wordpress.org/secret-key/1.1/salt/)
#           SALTS=$(echo "$SALTS" | sed -e "s/'//g" -e 's/"//g' -e 's/\$/\\$/g')
          
#           # Replace salts in config 
#           sed -i "/define('AUTH_KEY/,/define('NONCE_SALT/d" /var/www/html/wp-config.php
#           sed -i "/Put your unique phrase here/a\\$SALTS" /var/www/html/wp-config.php
          
#           # Restart services
#           systemctl restart apache2
#           systemctl restart mariadb
#         permissions: '0755'
    
#     # Run commands on first boot
#     runcmd:
#        - [ sudo, bash, /tmp/wordpress_setup.sh ]
#   EOF
# }
data "template_file" "user_data" {
  template = <<-EOF
    #cloud-config
    # Set password and enable password auth
    password: test321
    ssh_pwauth: true
    chpasswd:
      expire: false
    
    # Configure packages and scripts
    packages:
      - ufw
      - apache2
      - mariadb-server
      - php
      - php-mysql
      - php-curl
      - php-gd
      - php-mbstring
      - php-xml
      - php-xmlrpc
      - php-soap
      - php-intl
      - php-zip
    
    # Tạo các file cần thiết
    write_files:
      # SSH Banner
      - path: /etc/ssh_banner
        content: |
          Welcome to Application WordPress
        permissions: '0644'
      
      # Script thiết lập UFW
      - path: /usr/local/bin/setup-ufw.sh
        content: |
          #!/bin/bash
          echo "Configuring UFW..."
          ufw --force disable
          ufw default deny incoming
          ufw default allow outgoing
          ufw allow 22/tcp
          ufw allow 80/tcp
          ufw allow 443/tcp
          echo "y" | ufw enable
          echo "UFW Status:"
          ufw status verbose
          exit 0
        permissions: '0755'
      
      # Script thiết lập WordPress
      - path: /usr/local/bin/setup-wordpress.sh
        content: |
          #!/bin/bash
          # Script chỉ cài đặt WordPress, không liên quan đến UFW
          
          # Set up MariaDB for WordPress
          mysql -u root <<MYSQL_SCRIPT
          CREATE DATABASE wordpress;
          CREATE USER 'wpuser'@'localhost' IDENTIFIED BY 'wppassword';
          GRANT ALL PRIVILEGES ON wordpress.* TO 'wpuser'@'localhost';
          FLUSH PRIVILEGES;
          MYSQL_SCRIPT
          
          # Download and configure WordPress
          wget https://wordpress.org/latest.tar.gz -P /tmp
          tar -xzf /tmp/latest.tar.gz -C /tmp
          
          # Set up Apache virtual host for WordPress
          cp -R /tmp/wordpress/* /var/www/html/
          chown -R www-data:www-data /var/www/html/
          chmod -R 755 /var/www/html/
          
          # Create WordPress config
          cp /var/www/html/wp-config-sample.php /var/www/html/wp-config.php
          sed -i 's/database_name_here/wordpress/' /var/www/html/wp-config.php
          sed -i 's/username_here/wpuser/' /var/www/html/wp-config.php
          sed -i 's/password_here/wppassword/' /var/www/html/wp-config.php
          
          # Generate WordPress salts
          SALTS=$(curl -s https://api.wordpress.org/secret-key/1.1/salt/)
          SALTS=$(echo "$SALTS" | sed -e "s/'//g" -e 's/"//g' -e 's/\$/\\$/g')
          
          # Replace salts in config 
          sed -i "/define('AUTH_KEY/,/define('NONCE_SALT/d" /var/www/html/wp-config.php
          sed -i "/Put your unique phrase here/a\\$SALTS" /var/www/html/wp-config.php
          
          # Restart services
          systemctl restart apache2
          systemctl restart mariadb
          exit 0
        permissions: '0755'
      
      # Service để bật UFW
      - path: /etc/systemd/system/ufw-enable.service
        content: |
          [Unit]
          Description=Enable UFW Firewall
          After=network.target
          
          [Service]
          Type=oneshot
          ExecStart=/usr/local/bin/setup-ufw.sh
          RemainAfterExit=true
          
          [Install]
          WantedBy=multi-user.target
        permissions: '0644'
      
      # Service để thiết lập WordPress
      - path: /etc/systemd/system/wordpress-setup.service
        content: |
          [Unit]
          Description=Set up WordPress
          After=mariadb.service apache2.service
          Requires=mariadb.service apache2.service
          
          [Service]
          Type=oneshot
          ExecStart=/usr/local/bin/setup-wordpress.sh
          RemainAfterExit=true
          
          [Install]
          WantedBy=multi-user.target
        permissions: '0644'
      
      # Script custom init
      - path: /usr/local/bin/custom-init.sh
        permissions: '0755'
        content: |
          #!/bin/bash
          exec > /var/log/custom-init.log 2>&1
          echo "=== Bắt đầu custom-init === $(date)"

          # SSH Banner
          sed -i 's/#Banner.*/Banner \/etc\/ssh_banner/' /etc/ssh/sshd_config
          systemctl restart sshd

          # Firewall setup
          ufw --force disable
          ufw default deny incoming
          ufw default allow outgoing
          ufw allow 22/tcp
          ufw allow 80/tcp
          ufw allow 443/tcp
          echo "y" | ufw enable

          # Start systemd services
          systemctl daemon-reexec
          systemctl daemon-reload
          systemctl enable ufw-enable.service
          systemctl start ufw-enable.service
          systemctl enable wordpress-setup.service
          systemctl start wordpress-setup.service

          ufw status verbose
          echo "=== Kết thúc custom-init === $(date)"

      # Service custom init
      - path: /etc/systemd/system/custom-init.service
        permissions: '0644'
        content: |
          [Unit]
          Description=Custom initialization after boot
          After=network-online.target
          Wants=network-online.target

          [Service]
          Type=oneshot
          ExecStart=/usr/local/bin/custom-init.sh

          [Install]
          WantedBy=multi-user.target

    # Các lệnh thực thi khi boot
    runcmd:
      - [ systemctl, daemon-reload ]
      - [ systemctl, enable, custom-init.service ]
      - [ systemctl, start, custom-init.service ]
  EOF
}

# Create network config
data "template_file" "network_config" {
  template = <<-EOF
    version: 2
    ethernets:
      ens3:
        dhcp4: true
  EOF
}

# Create cloud-init disk
resource "libvirt_cloudinit_disk" "wordpress_cloudinit" {
  name           = "wordpress_cloudinit.iso"
  user_data      = data.template_file.user_data.rendered
  network_config = data.template_file.network_config.rendered
  pool           = libvirt_pool.wordpress_pool.name
}

# Create the virtual machine
resource "libvirt_domain" "wordpress_server" {
  name   = "wordpress-server"
  memory = "4096"
  vcpu   = 2

  cloudinit = libvirt_cloudinit_disk.wordpress_cloudinit.id

  network_interface {
    network_name = "default"
    wait_for_lease = true
  }

  console {
    type        = "pty"
    target_port = "0"
    target_type = "serial"
  }

  console {
    type        = "pty"
    target_type = "virtio"
    target_port = "1"
  }

  disk {
    volume_id = libvirt_volume.ubuntu_image.id
  }

  graphics {
    type        = "spice"
    listen_type = "address"
    autoport    = true
  }
}

# Output the IP address
output "server_ip" {
  value = libvirt_domain.wordpress_server.network_interface.0.addresses.0
  description = "The IP address of the WordPress server"
}