# Docker DB Template

This project consists of two shell scripts designed to help manage PostgreSQL databases running in Docker containers. It allows you to create a development template for a PostgreSQL database and later reuse it.

## Scripts
* `docker-db-create-template.sh`: This script sets up a PostgreSQL database in a Docker container, loads a SQL dump into it, and creates a reusable development template.
* `docker-db-use-template.sh`: This script starts a new Docker container using the previously created database template, making it available for use in development.

## Usage
### Creating a Database Template

Use `docker-db-create-template.sh` to set up a PostgreSQL container, load a SQL dump file, and create a reusable development template.

``` bash
./docker-db-create-template.sh [--pg-version=your_version] [--pg-user=your_user] project_name file_path
```

* `--pg-version`: (Optional) PostgreSQL version. Default is `latest`.
* `--pg-user`: (Optional) PostgreSQL user. Default is the current user.
* `project_name`: The name of your project. This will be used to name the Docker container, volume, and database.
* `file_path`: The SQL dump file to be loaded into the database.

**Example**

``` bash
./docker-db-create-template.sh --pg-version=16.4 --pg-user=myuser my_project db_dump.sql
```

This command will:

* Stop and remove any existing container named `my_project-development-template`.
* Create a new Docker volume for the database.
* Start a new PostgreSQL 16.4 container.
* Load the SQL dump (`db_dump.sq`l) into the `my_project_development` database.

### Using the Database Template

Use `docker-db-use-template.sh` to spin up a new PostgreSQL container using the previously created template.

``` bash
./docker-db-use-template.sh [--pg-version=your_version] [--pg-user=your_user] project_name
```

* `--pg-version`: (Optional) PostgreSQL version. Default is `latest`.
* `--pg-user`: (Optional) PostgreSQL user. Default is the current user.
* `project_name`: The name of your project, corresponding to the template you created earlier.

**Example**

``` bash
./docker-db-use-template.sh --pg-version=16.4 --pg-user=myuser my_project
```

This command will:

* Stop and remove any existing container named `my_project-development`.
* Create a new `my_project-development` volume and copy the data from the template into it.
* Start a new PostgreSQL container using the `my_project-development` volume.

## Notes
If you don't specify `--pg-version` or --pg-user, the script will default to the latest PostgreSQL version and use the current system user.
If a Docker container or volume with the same name already exists, the script will stop and remove it before proceeding.

## License
This project is open-source and licensed under the MIT License.
