"""
Plugin system for InternetIncome services
"""

import os
import logging
import importlib
import pkgutil
from abc import ABC, abstractmethod

logger = logging.getLogger(__name__)

class ServicePlugin(ABC):
    """Base class for service plugins"""
    
    # Required class properties
    name = None
    description = "Generic service plugin"
    requires_browser = False
    supports_proxy = True
    service_image = None
    data_volume_required = False
    
    def __init__(self, config, proxy=None):
        """Initialize the service plugin"""
        self.config = config
        self.proxy = proxy
        self.container_name = None
        
    @abstractmethod
    def validate_config(self):
        """Validate service configuration"""
        pass
        
    @abstractmethod
    def generate_compose_config(self):
        """Generate Docker Compose configuration for this service"""
        pass
        
    def get_status(self):
        """Return service status information"""
        return {
            "name": self.name,
            "enabled": self.config.get("enabled", False),
            "container": self.container_name,
            "proxy": self.proxy is not None
        }
        
    def get_service_data(self):
        """Return service-specific data (earnings, etc.)"""
        return {}
        
    def get_data_volume_path(self):
        """Return path for data volume if required"""
        if not self.data_volume_required:
            return None
        
        # Get the project root directory and create absolute path
        project_root = os.path.abspath(os.path.join(os.path.dirname(__file__), '..'))
        return os.path.join(project_root, 'data', self.name.lower())


class PluginManager:
    """Manager for service plugins"""
    
    def __init__(self, config):
        """Initialize plugin manager"""
        self.config = config
        self.plugins = {}
        self.load_plugins()
        
    def load_plugins(self):
        """Load plugins from the plugins directory"""
        try:
            # Import plugins package
            import plugins
            
            # Discover and load all plugins
            for _, name, is_pkg in pkgutil.iter_modules(plugins.__path__, plugins.__name__ + '.'):
                if not is_pkg:
                    try:
                        module = importlib.import_module(name)
                        for attr_name in dir(module):
                            attr = getattr(module, attr_name)
                            if (isinstance(attr, type) and 
                                issubclass(attr, ServicePlugin) and 
                                attr is not ServicePlugin and
                                attr.name):
                                self.plugins[attr.name.lower()] = attr
                                logger.info(f"Loaded plugin: {attr.name}")
                    except Exception as e:
                        logger.error(f"Error loading plugin {name}: {str(e)}")
                        
            logger.info(f"Loaded {len(self.plugins)} plugins")
        except ImportError:
            logger.error("Failed to import plugins package. The application cannot function without plugins.")
            raise SystemExit("Plugin system initialization failed: No plugins package found. Please ensure the plugins directory exists and is properly installed.")
            
    def get_plugin(self, name):
        """Get plugin by name"""
        return self.plugins.get(name.lower())
        
    def get_all_plugins(self):
        """Get all plugins"""
        return self.plugins
        
    def create_service(self, name, proxy=None):
        """Create service instance from plugin"""
        plugin_class = self.get_plugin(name)
        if not plugin_class:
            logger.error(f"Plugin not found: {name}")
            return None
            
        service_config = self.config.get_service_config(name.lower())
        
        # Check if proxy is supported
        if proxy and not plugin_class.supports_proxy:
            logger.warning(f"Plugin {name} does not support proxies")
            proxy = None
            
        # Create service instance
        service = plugin_class(service_config, proxy)
        
        # Set config_manager reference if the plugin has the attribute
        if hasattr(service, 'config_manager'):
            service.config_manager = self.config
            
        return service
        
    def get_enabled_services(self, with_proxies=False):
        """Get all enabled services with optional proxy assignment"""
        services = []
        proxies = self.config.get_proxies() if with_proxies else []
        
        # First pass: assign proxies to services that support them
        for name, plugin_class in self.plugins.items():
            if self.config.is_service_enabled(name):
                if plugin_class.supports_proxy and proxies and with_proxies:
                    # Assign proxy and create service
                    proxy = proxies.pop(0) if proxies else None
                    service = self.create_service(name, proxy)
                    services.append(service)
                    
                    # If we run out of proxies, break proxy assignment
                    if not proxies:
                        break
        
        # Second pass: assign remaining services without proxies
        for name, plugin_class in self.plugins.items():
            if self.config.is_service_enabled(name):
                # Skip services that already have proxies
                if any(s.name.lower() == name for s in services):
                    continue
                    
                service = self.create_service(name)
                services.append(service)
                
        return services 