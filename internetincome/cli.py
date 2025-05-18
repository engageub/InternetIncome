"""
Command-line interface for InternetIncome
"""

import os
import sys
import logging
import click
from tabulate import tabulate

from internetincome import __version__
from internetincome.config import Config, migrate_from_properties
from internetincome.plugin import PluginManager
from internetincome.compose import ComposeManager

# Set up logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
    handlers=[
        logging.StreamHandler(sys.stdout)
    ]
)
logger = logging.getLogger(__name__)


@click.group()
@click.version_option(version=__version__)
@click.option('--config', '-c', help='Path to config file', default='config/settings.yaml')
@click.pass_context
def cli(ctx, config):
    """InternetIncome - Passive Internet Bandwidth Sharing Manager"""
    ctx.ensure_object(dict)
    ctx.obj['config'] = Config(config)
    ctx.obj['plugins'] = PluginManager(ctx.obj['config'])
    ctx.obj['compose'] = ComposeManager(ctx.obj['config'])


@cli.command()
@click.pass_context
def start(ctx):
    """Start services"""
    config = ctx.obj['config']
    plugins = ctx.obj['plugins']
    compose = ctx.obj['compose']
    
    click.echo("Starting services...")
    
    # Get enabled services
    services = plugins.get_enabled_services(with_proxies=config.are_proxies_enabled())
    
    if not services:
        click.echo("No services enabled. Please enable services in the configuration.")
        return
    
    # Generate Docker Compose config
    click.echo(f"Generating Docker Compose configuration for {len(services)} services...")
    if not compose.generate_compose(services):
        click.echo("Failed to generate Docker Compose configuration.")
        return
    
    # Start services
    click.echo("Starting services with Docker Compose...")
    success, output = compose.start_services()
    
    if success:
        click.echo("Services started successfully.")
        # Print service status
        status_command(ctx)
    else:
        click.echo(f"Failed to start services: {output}")


@cli.command()
@click.pass_context
def stop(ctx):
    """Stop services"""
    compose = ctx.obj['compose']
    
    click.echo("Stopping services...")
    success, output = compose.stop_services()
    
    if success:
        click.echo("Services stopped successfully.")
    else:
        click.echo(f"Failed to stop services: {output}")


@cli.command()
@click.pass_context
def restart(ctx):
    """Restart services"""
    compose = ctx.obj['compose']
    
    click.echo("Restarting services...")
    success, output = compose.restart_services()
    
    if success:
        click.echo("Services restarted successfully.")
        # Print service status
        status_command(ctx)
    else:
        click.echo(f"Failed to restart services: {output}")


@cli.command(name='status')
@click.pass_context
def status_command(ctx):
    """Show status of services"""
    compose = ctx.obj['compose']
    
    click.echo("Getting service status...")
    success, output = compose.get_service_status()
    
    if success:
        click.echo(output)
    else:
        click.echo(f"Failed to get service status: {output}")


@cli.command()
@click.pass_context
def list(ctx):
    """List available services"""
    plugins = ctx.obj['plugins']
    config = ctx.obj['config']
    
    # Get all plugins
    all_plugins = plugins.get_all_plugins()
    
    if not all_plugins:
        click.echo("No plugins found.")
        return
    
    # Prepare table data
    table_data = []
    for name, plugin_class in all_plugins.items():
        enabled = config.is_service_enabled(name)
        table_data.append([
            name,
            plugin_class.description,
            "Yes" if enabled else "No",
            "Yes" if plugin_class.supports_proxy else "No",
            "Yes" if plugin_class.requires_browser else "No"
        ])
    
    # Print table
    click.echo(tabulate(
        table_data,
        headers=["Name", "Description", "Enabled", "Proxy Support", "Browser Required"],
        tablefmt="grid"
    ))


@cli.command()
@click.argument('service_name')
@click.option('--enable/--disable', default=True, help='Enable or disable service')
@click.pass_context
def service(ctx, service_name, enable):
    """Configure a service"""
    plugins = ctx.obj['plugins']
    config = ctx.obj['config']
    
    # Check if service exists
    plugin_class = plugins.get_plugin(service_name)
    if not plugin_class:
        click.echo(f"Service '{service_name}' not found.")
        return
    
    # Get current service config
    service_config = config.get_service_config(service_name)
    
    # Update enabled status
    service_config['enabled'] = enable
    
    # Save config
    if config.update_service_config(service_name, service_config):
        click.echo(f"Service '{service_name}' {'enabled' if enable else 'disabled'} successfully.")
    else:
        click.echo(f"Failed to {'enable' if enable else 'disable'} service '{service_name}'.")


@cli.command()
@click.argument('properties_path', type=click.Path(exists=True))
@click.option('--output', '-o', help='Output config path', default='config/settings.yaml')
@click.pass_context
def migrate(ctx, properties_path, output):
    """Migrate from properties.conf to YAML config"""
    click.echo(f"Migrating from {properties_path} to {output}...")
    
    if migrate_from_properties(properties_path, output):
        click.echo(f"Migration successful. Config saved to {output}")
        
        # Load the new config
        ctx.obj['config'] = Config(output)
        ctx.obj['plugins'] = PluginManager(ctx.obj['config'])
        ctx.obj['compose'] = ComposeManager(ctx.obj['config'])
        
        # List services
        list(ctx)
    else:
        click.echo("Migration failed.")


@cli.command()
@click.argument('proxy_file', type=click.Path(exists=True))
@click.pass_context
def import_proxies(ctx, proxy_file):
    """Import proxies from a file"""
    config = ctx.obj['config']
    
    click.echo(f"Importing proxies from {proxy_file}...")
    
    # Read proxies from file
    proxies = []
    with open(proxy_file, 'r') as f:
        for line in f:
            line = line.strip()
            if line and not line.startswith('#'):
                proxies.append(line)
    
    if not proxies:
        click.echo("No proxies found in file.")
        return
    
    # Update proxies in config
    if config.update_proxies(proxies):
        click.echo(f"Imported {len(proxies)} proxies successfully.")
    else:
        click.echo("Failed to import proxies.")


def main():
    """Entry point for CLI"""
    try:
        cli(obj={})
    except Exception as e:
        logger.error(f"Error: {str(e)}")
        sys.exit(1)


if __name__ == '__main__':
    main() 