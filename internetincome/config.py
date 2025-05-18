"""
Configuration management for InternetIncome
"""

import os
import yaml
import logging
import platform
from schema import Schema, Optional, And, Or, SchemaError
from pathlib import Path
from dotenv import load_dotenv

# Set up logging
logger = logging.getLogger(__name__)

# Base schema for validation
BASE_SCHEMA = Schema({
    'device_name': str,
    Optional('use_proxies', default=False): bool,
    Optional('enable_logs', default=False): bool,
    Optional('services'): {
        str: {
            Optional('enabled', default=False): bool,
            Optional(str): object  # Allow any service-specific config
        }
    },
    Optional('proxies'): [str]
})


class Config:
    """Configuration manager for InternetIncome"""
    
    def __init__(self, config_path=None):
        """Initialize configuration from file"""
        self.config_path = config_path or os.environ.get('II_CONFIG', 'config/settings.yaml')
        self.config_dir = os.path.dirname(self.config_path)
        self.config = self._load_config()
        self.proxies = self._load_proxies()
        
    def _load_config(self):
        """Load configuration from YAML file"""
        try:
            if not os.path.exists(self.config_path):
                logger.warning(f"Config file not found: {self.config_path}")
                # Create default config
                default_config = {
                    'device_name': platform.node(),
                    'use_proxies': False,
                    'enable_logs': False,
                    'services': {}
                }
                # Ensure directory exists
                os.makedirs(self.config_dir, exist_ok=True)
                # Write default config
                with open(self.config_path, 'w') as f:
                    yaml.safe_dump(default_config, f)
                return default_config
                
            with open(self.config_path, 'r') as f:
                loaded = yaml.safe_load(f) or {}
                # Validate against schema
                return BASE_SCHEMA.validate(loaded)
        except Exception as e:
            logger.error(f"Error loading config: {str(e)}")
            raise
            
    def _load_proxies(self):
        """Load proxies from config or separate file"""
        if 'proxies' in self.config:
            return self.config['proxies']
            
        # Check for separate proxies file
        proxies_path = os.path.join(self.config_dir, 'proxies.yaml')
        if os.path.exists(proxies_path):
            try:
                with open(proxies_path, 'r') as f:
                    proxies_config = yaml.safe_load(f)
                    if proxies_config is None:
                        return []
                    elif isinstance(proxies_config, list):
                        return proxies_config
                    elif isinstance(proxies_config, dict) and 'proxies' in proxies_config:
                        return proxies_config['proxies']
            except Exception as e:
                logger.error(f"Error loading proxies: {str(e)}")
                
        # If no proxies found or error loading
        return []
        
    def save(self):
        """Save configuration to file"""
        try:
            with open(self.config_path, 'w') as f:
                yaml.safe_dump(self.config, f)
            return True
        except Exception as e:
            logger.error(f"Error saving config: {str(e)}")
            return False
            
    def get_service_config(self, service_name):
        """Get configuration for a specific service"""
        if 'services' not in self.config:
            self.config['services'] = {}
        
        if service_name not in self.config['services']:
            self.config['services'][service_name] = {'enabled': False}
            
        return self.config['services'][service_name]
        
    def update_service_config(self, service_name, service_config):
        """Update configuration for a specific service"""
        if 'services' not in self.config:
            self.config['services'] = {}
            
        self.config['services'][service_name] = service_config
        return self.save()
        
    def is_service_enabled(self, service_name):
        """Check if a service is enabled"""
        if 'services' not in self.config:
            return False
            
        if service_name not in self.config['services']:
            return False
            
        return self.config['services'][service_name].get('enabled', False)
        
    def get_device_name(self):
        """Get device name from config"""
        return self.config.get('device_name', platform.node())
        
    def are_logs_enabled(self):
        """Check if logs are enabled"""
        return self.config.get('enable_logs', False)
        
    def are_proxies_enabled(self):
        """Check if proxies are enabled"""
        return self.config.get('use_proxies', False)
        
    def get_proxies(self):
        """Get list of proxies"""
        return self.proxies if self.are_proxies_enabled() else []
        
    def update_proxies(self, proxies):
        """Update list of proxies"""
        self.proxies = proxies
        # Save to separate file
        proxies_path = os.path.join(self.config_dir, 'proxies.yaml')
        try:
            with open(proxies_path, 'w') as f:
                yaml.safe_dump({'proxies': proxies}, f)
            return True
        except Exception as e:
            logger.error(f"Error saving proxies: {str(e)}")
            return False


def migrate_from_properties(properties_path, output_path=None):
    """Migrate from properties.conf to YAML config"""
    if not os.path.exists(properties_path):
        logger.error(f"Properties file not found: {properties_path}")
        return False
        
    output_path = output_path or 'config/settings.yaml'
    output_dir = os.path.dirname(output_path)
    os.makedirs(output_dir, exist_ok=True)
    
    # Default config structure
    config = {
        'device_name': 'internetincome',
        'use_proxies': False,
        'enable_logs': False,
        'services': {}
    }
    
    proxies = []
    
    # Parse properties file
    with open(properties_path, 'r') as f:
        for line in f:
            line = line.strip()
            if not line or line.startswith('#'):
                continue
                
            if '=' in line:
                key, value = line.split('=', 1)
                key = key.strip()
                value = value.strip()
                
                # Remove quotes if present
                if value.startswith("'") and value.endswith("'"):
                    value = value[1:-1]
                    
                # Handle device name
                if key == 'DEVICE_NAME':
                    config['device_name'] = value
                # Handle proxy setting
                elif key == 'USE_PROXIES':
                    config['use_proxies'] = value.lower() == 'true'
                # Handle log setting
                elif key == 'ENABLE_LOGS':
                    config['enable_logs'] = value.lower() == 'true'
                # Handle service configs
                else:
                    service_map = {
                        'REPOCKET': {'email': 'REPOCKET_EMAIL', 'api': 'REPOCKET_API'},
                        'TRAFFMONETIZER': {'token': 'TRAFFMONETIZER_TOKEN'},
                        'CASTAR_SDK': {'key': 'CASTAR_SDK_KEY'},
                        'PACKET_SDK': {'app_key': 'PACKET_SDK_APP_KEY'},
                        'PROXYBASE': {'enabled': 'PROXYBASE'},
                        'PROXYRACK': {'enabled': 'PROXYRACK'},
                        'IPROYALS': {'email': 'IPROYALS_EMAIL', 'password': 'IPROYALS_PASSWORD'},
                        'HONEYGAIN': {'email': 'HONEYGAIN_EMAIL', 'password': 'HONEYGAIN_PASSWORD'},
                        'PEER2PROFIT': {'email': 'PEER2PROFIT_EMAIL'},
                        'PACKETSTREAM': {'cid': 'PACKETSTREAM_CID'},
                        'PROXYLITE': {'user_id': 'PROXYLITE_USER_ID'},
                        'EARN_FM': {'api': 'EARN_FM_API'},
                        'NETWORK3': {'email': 'NETWORK3_EMAIL'},
                        'TITAN': {'hash': 'TITAN_HASH'},
                        'GAGANODE': {'token': 'GAGANODE_TOKEN'},
                        'EARNAPP': {'enabled': 'EARNAPP'},
                        'BITPING': {'email': 'BITPING_EMAIL', 'password': 'BITPING_PASSWORD'},
                        'PACKETSHARE': {'email': 'PACKETSHARE_EMAIL', 'password': 'PACKETSHARE_PASSWORD'},
                        'WIPTER': {'email': 'WIPTER_EMAIL', 'password': 'WIPTER_PASSWORD'},
                        'MYSTERIUM': {'enabled': 'MYSTERIUM'},
                        'GRASS': {'email': 'GRASS_EMAIL', 'password': 'GRASS_PASSWORD'},
                        'GRADIENT': {'email': 'GRADIENT_EMAIL', 'password': 'GRADIENT_PASSWORD'},
                        'EBESUCHER': {'username': 'EBESUCHER_USERNAME'},
                        'ADNADE': {'username': 'ADNADE_USERNAME'}
                    }
                    
                    # Process service configurations
                    for service, config_map in service_map.items():
                        for config_key, prop_key in config_map.items():
                            if key == prop_key:
                                if service not in config['services']:
                                    config['services'][service.lower()] = {}
                                
                                if config_key == 'enabled':
                                    config['services'][service.lower()]['enabled'] = value.lower() == 'true'
                                else:
                                    config['services'][service.lower()][config_key] = value
                                
                                # If value is not empty, enable the service
                                if value and config_key != 'enabled':
                                    config['services'][service.lower()]['enabled'] = True
    
    # Parse proxies file if proxies are enabled
    if config['use_proxies']:
        proxies_path = os.path.join(os.path.dirname(properties_path), 'proxies.txt')
        if os.path.exists(proxies_path):
            with open(proxies_path, 'r') as f:
                for line in f:
                    line = line.strip()
                    if line and not line.startswith('#'):
                        proxies.append(line)
                        
    # Save config
    try:
        with open(output_path, 'w') as f:
            yaml.safe_dump(config, f)
            
        # Save proxies if any
        if proxies:
            proxies_path = os.path.join(output_dir, 'proxies.yaml')
            with open(proxies_path, 'w') as f:
                yaml.safe_dump({'proxies': proxies}, f)
                
        return True
    except Exception as e:
        logger.error(f"Error saving migrated config: {str(e)}")
        return False 