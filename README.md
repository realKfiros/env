# My environment for running projects

This repository contains basic configuration files and scripts for setting up a development environment. It includes configurations for various tools and services that I use regularly in my projects.

## Features

* Docker Compose setup for easy container management with services such as Apache, MySQL, and PHP
* Scripts for automating common tasks related to database management and environment setup
* A structured directory for organizing configuration files and scripts
* A focus on simplicity and ease of use, making it accessible for developers of all levels

## Setup instructions

1.  Clone the repository to your local machine:
    
    ```shell
    git clone https://github.com/realKfiros/env.git
    ```
    
2.  Create a dotenv file:
    
    ```shell
    ./scripts/create_environment.sh
    ```
    
3.  Build the docker containers:
    
    ```shell
    docker compose up -d
    ```
    

### Scripts included in `./scripts` directory

* `create_environment.sh`: This script creates a `.env` file with the necessary environment variables for the project. It prompts the user to input values for each variable and saves them in the `.env` file.
* `mysql_source.sh <dbname>.sql`: This script creates a database in the `db` container and imports data from a specified SQL file. It takes the name of the SQL file as an argument and executes the necessary commands to set up the database.
* `mysql_drop.sh`: This script drops specified databses from the `db` container.
* `mysql_clear.sh`: This script clears all databases from the `db` container.
* `dotenv.sh`: This script validates the `.env` file

### Attention – chmod

Sometimes you may encounter permission issues when running scripts. To resolve this, you can change the permissions of the script using the following command:

```shell
chmod u+x ./scripts/<script>.sh
```
