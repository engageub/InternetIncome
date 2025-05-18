"""
Docker Compose management for InternetIncome
"""

import copy
import os
import uuid
import logging
import yaml
import subprocess
from pathlib import Path

logger = logging.getLogger(__name__)

# Default Docker Compose template
DEFAULT_COMPOSE = {
    'version': '3',
    'networks': {
        'internet_income': {
            'driver': 'bridge'
        }
    },
    'services': {}
}

# TUN proxy template
TUN_PROXY_TEMPLATE = {
    'image': 'xjasonlyu/tun2socks:v2.5.2',
    'restart': 'always',
    'cap_add': ['NET_ADMIN'],
    'volumes': ['/dev/net/tun:/dev/net/tun'],
    'environment': {
        'LOGLEVEL': 'silent',
        # PROXY will be set per service
    }
}


class ComposeManager:
    """Docker Compose manager for InternetIncome"""
    
    def __init__(self, config, compose_file='docker/docker-compose.yml'):
        """Initialize Docker Compose manager"""
        self.config = config
        self.compose_file = compose_file
        self.compose_dir = os.path.dirname(compose_file)
        self.compose_data = self._load_compose()
        
    def _load_compose(self):
        """Load Docker Compose file or create default"""
        try:
            if not os.path.exists(self.compose_file):
                logger.info(f"Creating new Docker Compose file: {self.compose_file}")
                
                # Ensure directory exists
                os.makedirs(self.compose_dir, exist_ok=True)
                
                # Create default compose file
                with open(self.compose_file, 'w') as f:
                    yaml.safe_dump(DEFAULT_COMPOSE, f)
                    
                return DEFAULT_COMPOSE
            
            # Load existing compose file
            with open(self.compose_file, 'r') as f:
                return yaml.safe_load(f)
                
        except Exception as e:
            logger.error(f"Error loading Docker Compose file: {str(e)}")
            return DEFAULT_COMPOSE
            
    def save_compose(self):
        """Save Docker Compose configuration"""
        try:
            # Ensure directory exists
            os.makedirs(self.compose_dir, exist_ok=True)
            
            # Save compose file
            with open(self.compose_file, 'w') as f:
                yaml.safe_dump(self.compose_data, f)
                
            return True
        except Exception as e:
            logger.error(f"Error saving Docker Compose file: {str(e)}")
            return False
            
    def generate_compose(self, services):
        """Generate Docker Compose configuration from services"""
        # Start with a *deep* copy so nested structures are isolated
        self.compose_data = copy.deepcopy(DEFAULT_COMPOSE)
        self.compose_data['services'] = {}
        
        # Process services with proxies first
        proxy_services = [s for s in services if s.proxy]
        direct_services = [s for s in services if not s.proxy]
        
        # Add proxy services
        for service in proxy_services:
            proxy_name = f"tun-proxy-{uuid.uuid4().hex[:8]}"
            service.container_name = f"{service.name.lower()}-{uuid.uuid4().hex[:8]}"
            
            # Add TUN proxy service
            proxy_config = TUN_PROXY_TEMPLATE.copy()
            proxy_config['environment'] = {
                'LOGLEVEL': 'debug' if self.config.are_logs_enabled() else 'silent',
                'PROXY': service.proxy
            }
            
            # Add service with proxy dependency
            service_config = service.generate_compose_config()
            if service_config:
                # Link service to proxy
                service_config['network_mode'] = f"service:{proxy_name}"
                service_config['depends_on'] = [proxy_name]
                
                # Add service and proxy to compose
                self.compose_data['services'][proxy_name] = proxy_config
                self.compose_data['services'][service.container_name] = service_config
            
        # Add services without proxies
        for service in direct_services:
            service.container_name = f"{service.name.lower()}-{uuid.uuid4().hex[:8]}"
            service_config = service.generate_compose_config()
            
            if service_config:
                # Add network if not using proxy
                service_config['networks'] = ['internet_income']
                
                # Add service to compose
                self.compose_data['services'][service.container_name] = service_config
                
        return self.save_compose()
        
    def start_services(self):
        """Start services with Docker Compose"""
        try:
            compose_cmd = ['docker', 'compose', '-f', self.compose_file, 'up', '-d']
            
            logger.info(f"Starting services: {' '.join(compose_cmd)}")
            result = subprocess.run(compose_cmd, capture_output=True, text=True)
            
            if result.returncode == 0:
                logger.info("Services started successfully")
                return True, result.stdout
            else:
                logger.error(f"Error starting services: {result.stderr}")
                return False, result.stderr
        except Exception as e:
            logger.error(f"Exception starting services: {str(e)}")
            return False, str(e)
            
    def stop_services(self):
        """Stop services with Docker Compose"""
        try:
            compose_cmd = ['docker-compose', '-f', self.compose_file, 'down']
            
            logger.info(f"Stopping services: {' '.join(compose_cmd)}")
            result = subprocess.run(compose_cmd, capture_output=True, text=True)
            
            if result.returncode == 0:
                logger.info("Services stopped successfully")
                return True, result.stdout
            else:
                logger.error(f"Error stopping services: {result.stderr}")
                return False, result.stderr
        except Exception as e:
            logger.error(f"Exception stopping services: {str(e)}")
            return False, str(e)
            
    def restart_services(self):
        """Restart services with Docker Compose"""
        try:
            compose_cmd = ['docker-compose', '-f', self.compose_file, 'restart']
            
            logger.info(f"Restarting services: {' '.join(compose_cmd)}")
            result = subprocess.run(compose_cmd, capture_output=True, text=True)
            
            if result.returncode == 0:
                logger.info("Services restarted successfully")
                return True, result.stdout
            else:
                logger.error(f"Error restarting services: {result.stderr}")
                return False, result.stderr
        except Exception as e:
            logger.error(f"Exception restarting services: {str(e)}")
            return False, str(e)
            
    def get_service_status(self):
        """Get status of services"""
        try:
            compose_cmd = ['docker-compose', '-f', self.compose_file, 'ps']
            
            logger.info(f"Getting service status: {' '.join(compose_cmd)}")
            result = subprocess.run(compose_cmd, capture_output=True, text=True)
            
            if result.returncode == 0:
                return True, result.stdout
            else:
                logger.error(f"Error getting service status: {result.stderr}")
                return False, result.stderr
        except Exception as e:
            logger.error(f"Exception getting service status: {str(e)}")
            return False, str(e) 