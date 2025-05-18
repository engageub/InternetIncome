"""
Mysterium service plugin for InternetIncome
"""

import os
import logging
from schema import Schema, Optional

from internetincome.plugin import ServicePlugin

logger = logging.getLogger(__name__)

# Configuration schema for validation
CONFIG_SCHEMA = Schema({
    Optional('enabled', default=False): bool,
    Optional('port', default=4449): int,
    Optional('custom_image'): str
})


class MysteriumPlugin(ServicePlugin):
    """Mysterium service plugin"""
    
    name = "Mysterium"
    description = "Decentralized VPN service that allows you to earn by sharing your bandwidth"
    requires_browser = False
    supports_proxy = False  # Due to current limitations in the tun2socks implementation
    service_image = "mysteriumnetwork/myst:latest"
    data_volume_required = True
    
    def validate_config(self):
        """Validate service configuration"""
        try:
            return CONFIG_SCHEMA.validate(self.config)
        except Exception as e:
            logger.error(f"Error validating Mysterium config: {str(e)}")
            return False
            
    def generate_compose_config(self):
        """Generate Docker Compose configuration for Mysterium"""
        # Validate configuration
        if not self.validate_config():
            logger.error("Invalid Mysterium configuration")
            return None
            
        # Prepare data volume path
        data_path = self.get_data_volume_path()
        if not data_path:
            logger.error("Data volume path not defined")
            return None
            
        # Create data directory if it doesn't exist
        os.makedirs(data_path, exist_ok=True)
        
        # Use port from config or default
        port = self.config.get('port', 4449)
        
        # Generate configuration
        config = {
            'image': self.config.get('custom_image', self.service_image),
            'restart': 'unless-stopped',
            'cap_add': ['NET_ADMIN'],
            'volumes': [f"{data_path}:/var/lib/mysterium-node"],
            'ports': [f"{port}:4449"],
            'command': "service --agreed-terms-and-conditions"
        }
        
        return config
        
    def get_status(self):
        """Return service status information"""
        status = super().get_status()
        
        # Add UI URL if available
        port = self.config.get('port', 4449)
        status['ui_url'] = f"http://localhost:{port}"
        
        return status 