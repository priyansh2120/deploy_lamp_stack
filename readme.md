# LAMP Stack Configuration Script

This script is used to configure a LAMP (Linux, Apache, MySQL, PHP) stack on a single node. It deploys a simple ecommerce application built using PHP and MySQL.

## Prerequisites

- This script assumes a Linux operating system.
- Make sure you have administrative privileges to install packages and configure services.

## Usage

1. Clone the repository to your local machine:

   ```bash
   git clone https://github.com/example/repository.git
   ```

2. Navigate to the cloned repository:

   ```bash
   cd repository
   ```

3. Run the script:

   ```bash
   bash lamp-stack-config.sh
   ```

## Configuration Steps

The script performs the following configuration steps:

1. Installs and configures firewalld.
2. Installs and configures the MySQL database.
3. Adds firewall rules for the database.
4. Creates the necessary database and user.
5. Loads inventory data into the database.
6. Installs Apache web server and PHP.
7. Adds firewall rules for the web server.
8. Updates the Apache configuration file to use index.php as the default page.
9. Starts and enables the Apache web server service.
10. Installs Git.
11. Downloads the ecommerce application code from Git.
12. Replaces the database IP address with localhost in the index.php file.
13. Checks if the web server is running and if the required items are present in the webpage.

## Customization

You can customize the script by modifying the following sections:

- To change the Git repository URL, modify the `git clone` command in the script.
- To change the IP address of the database server, modify the IP address in the `sed` command that replaces the IP address in the index.php file.

## License

This script is open-source and distributed under the [MIT License](https://opensource.org/licenses/MIT). Feel free to modify and use it according to your needs.

## Disclaimer

This script is provided as-is without any warranty. Use it at your own risk.