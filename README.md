# 💻 Internet Income 💸 (Python + Docker Compose Version)

<img src="https://i.ibb.co/DKbwPN1/imgonline-com-ua-twotoone-2ck-Xl1-JPvw2t-D1.jpg" width="100%" height="300"/>

This project lets you earn income by sharing your internet bandwidth. The income is passive and you don't have to do anything after the setup but keep getting payouts to your account.

**Note:** This is a rewrite of the [original bash-based InternetIncome](https://github.com/engageub/InternetIncome) using Python and Docker Compose for improved maintainability and extensibility.

## Features

- **Docker Compose Integration** - Modern container orchestration
- **Plugin System** - Easily add new services without changing core code
- **Multi-Proxy Support** - Run multiple services through different proxies
- **Configuration Management** - YAML-based configuration for easy editing
- **Simple CLI** - Command-line interface for easy management
- **Migration Tool** - Easy migration from the original bash version

## Prerequisites

### Install Dependencies

#### Install Docker and Docker Compose
```bash
# Docker
sudo apt-get update
sudo apt-get -y install docker.io

# Docker Compose
sudo apt-get -y install docker-compose
```

For ARM or AARCH Architectures, additional setup may be needed:
```bash
sudo docker run --privileged --rm tonistiigi/binfmt --install all
sudo apt-get install qemu binfmt-support qemu-user-static
```

#### Install Python Requirements
```bash
# Create virtual environment (optional but recommended)
python -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate

# Install requirements
pip install -r requirements.txt
```

## Migration from Bash Version

If you're migrating from the original bash version, use the migration tool:

```bash
python main.py migrate properties.conf
```

This will:
1. Convert your `properties.conf` to YAML configuration
2. Import proxies from `proxies.txt` (if enabled)
3. Preserve service IDs and tokens

## Configuration

Edit `config/settings.yaml` to configure your services:

```yaml
device_name: ubuntu
use_proxies: false
enable_logs: false
services:
  earnapp:
    enabled: true
    # Node ID will be auto-generated if not provided
  mysterium:
    enabled: true
    port: 4449
  # Additional services...
```

If using proxies, edit `config/proxies.yaml`:

```yaml
proxies:
  - socks5://user:pass@ip:port
  - http://ip:port
  # Additional proxies...
```

## Usage

### Available Commands

```bash
# Start all enabled services
python main.py start

# Stop all services
python main.py stop

# Restart all services
python main.py restart

# Show service status
python main.py status

# List available services
python main.py list

# Enable or disable a service
python main.py service earnapp --enable
python main.py service mysterium --disable

# Import proxies from a file
python main.py import-proxies proxies.txt

# Get help
python main.py --help
```

## Adding Services

New services can be added by creating plugins in the `plugins/` directory. Each plugin should:

1. Define a class that inherits from `ServicePlugin`
2. Implement required methods (`validate_config`, `generate_compose_config`)
3. Set required class properties (`name`, `description`, `service_image`, etc.)

See existing plugins for examples.

## FAQ

### How does this differ from the bash version?

- **Improved Maintainability**: Python code with clear structure vs. bash scripts
- **Docker Compose**: Modern container orchestration vs. direct docker commands
- **Plugin System**: Easily extensible with new services
- **Configuration**: YAML-based configuration that's easier to edit

### Can I use my existing service configurations?

Yes! Use the migration tool to convert your existing `properties.conf` to the new format.

### Where is the data stored?

Service data is stored in the `data/` directory, with each service having its own subdirectory.

## License

This software is licensed under the same terms as the original InternetIncome project.

## Disclaimer

This script is provided "as is" and without warranty of any kind.  
The author makes no warranties, express or implied, that this script is free of errors, defects, or suitable for any particular purpose.  
The author shall not be liable for any damages suffered by any user of this script, whether direct, indirect, incidental, consequential, or special, arising from the use of or inability to use this script or its documentation, even if the author has been advised of the possibility of such damages.
