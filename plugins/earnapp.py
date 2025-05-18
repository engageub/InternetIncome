"""
EarnApp service plugin for InternetIncome
"""

import os
import uuid
import logging
from schema import Schema, Optional

from internetincome.plugin import ServicePlugin

logger = logging.getLogger(__name__)

# Configuration schema for validation
CONFIG_SCHEMA = Schema({
    Optional('enabled', default=False): bool,
    Optional('node_id'): str,
    Optional('custom_image'): str
})


class EarnAppPlugin(ServicePlugin):
    """EarnApp service plugin"""
    
    name = "EarnApp"
    description = "Earn by sharing your internet connection"
    requires_browser = False
    supports_proxy = True
    service_image = "fazalfarhan01/earnapp"
    data_volume_required = True
    
    def validate_config(self):
        """Validate service configuration"""
        try:
            return CONFIG_SCHEMA.validate(self.config)
        except Exception as e:
            logger.error(f"Error validating EarnApp config: {str(e)}")
            return False
            
    def generate_compose_config(self):
        """Generate Docker Compose configuration for EarnApp"""
        # Validate configuration
        if not self.validate_config():
            logger.error("Invalid EarnApp configuration")
            return None
            
        # Prepare data volume path
        data_path = self.get_data_volume_path()
        if not data_path:
            logger.error("Data volume path not defined")
            return None
            
        # Create data directory if it doesn't exist
        os.makedirs(data_path, exist_ok=True)
        
        # Generate configuration
        config = {
            'image': self.config.get('custom_image', self.service_image),
            'restart': 'always',
            'volumes': [f"{data_path}:/etc/earnapp"]
        }
        
        # If we have a node ID, use it
        if 'node_id' in self.config and self.config['node_id']:
            config['environment'] = {
                'EARNAPP_UUID': self.config['node_id']
            }
        else:
            # Generate a new node ID
            node_id = str(uuid.uuid4())
            self.config['node_id'] = node_id
            config['environment'] = {
                'EARNAPP_UUID': node_id
            }
            logger.info(f"Generated new EarnApp node ID: {node_id}")
            
        return config
        
    def get_status(self):
        """Return service status information"""
        status = super().get_status()
        
        # Add node ID if available
        if 'node_id' in self.config and self.config['node_id']:
            status['node_id'] = self.config['node_id']
            status['node_url'] = f"https://earnapp.com/r/{self.config['node_id']}"
            
        return status
        
    def get_service_data(self):
        """Return service-specific data (earnings, etc.)"""
        data = super().get_service_data()
        
        # Add node ID if available
        if 'node_id' in self.config and self.config['node_id']:
            data['node_id'] = self.config['node_id']
            data['node_url'] = f"https://earnapp.com/r/{self.config['node_id']}"
            
        return data 