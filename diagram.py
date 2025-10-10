#!/usr/bin/env python3
"""
Burger App Architecture Diagrams
Generated with 30+ years of engineering experience perspective
"""

from diagrams import Diagram, Cluster, Edge
from diagrams.azure.compute import ContainerApps, ContainerRegistries
from diagrams.azure.database import DatabaseForPostgresqlServers
from diagrams.azure.network import ApplicationGateway, PublicIpAddresses, VirtualNetworks, Subnets
from diagrams.azure.analytics import LogAnalyticsWorkspaces
from diagrams.azure.general import Usericon
from diagrams.azure.devops import ApplicationInsights, Pipelines, Repos
# from diagrams.azure.storage import BlobStorage
from diagrams.azure.security import KeyVaults
from diagrams.programming.language import Java, JavaScript
from diagrams.programming.framework import React, Spring
from diagrams.onprem.database import PostgreSQL
# from diagrams.onprem.client import Users as ClientUsers
from diagrams.onprem.network import Internet
# from diagrams.aws.storage import S3
# from diagrams.generic.compute import Rack
from diagrams.generic.database import SQL
# from diagrams.generic.network import Subnet

# High-Level Architecture Diagram
def create_high_level_architecture():
    with Diagram("Burger App - High Level Architecture", 
                 filename="high_level_architecture", 
                 direction="TB",
                 show=False):
        
        # External Users
        users = Usericon("Customers")
        
        # Internet Gateway
        internet = Internet("Internet")
        
        # Azure Application Gateway
        with Cluster("Azure Cloud - UK South"):
            # Application Gateway
            app_gateway = ApplicationGateway("Application Gateway\n(Load Balancer)")
            
            # Container Apps Environment
            with Cluster("Container Apps Environment"):
                frontend = ContainerApps("Frontend\n(React + Nginx)")
                backend = ContainerApps("Backend\n(Spring Boot)")
            
            # Database
            database = DatabaseForPostgresqlServers("PostgreSQL\nFlexible Server")
            
            # Monitoring
            with Cluster("Monitoring & Analytics"):
                app_insights = ApplicationInsights("Application Insights")
                log_analytics = LogAnalyticsWorkspaces("Log Analytics")
        
        # Connections
        users >> internet >> app_gateway
        app_gateway >> frontend
        app_gateway >> backend
        backend >> database
        frontend >> backend
        backend >> app_insights
        app_insights >> log_analytics

# Infrastructure Deployment Diagram
def create_infrastructure_diagram():
    with Diagram("Burger App - Infrastructure Deployment", 
                 filename="infrastructure_deployment", 
                 direction="TB",
                 show=False):
        
        # External
        users = Usericon("Internet Users")
        
        with Cluster("Azure Resource Group: filip-bourgerapp"):
            # Public IP
            public_ip = PublicIpAddresses("Public IP\n(Static)")
            
            # Virtual Network
            with Cluster("Virtual Network (10.0.0.0/16)"):
                with Cluster("App Gateway Subnet (10.0.1.0/24)"):
                    app_gateway = ApplicationGateway("Application Gateway v2\nStandard_v2")
                
                with Cluster("Container Apps Subnet (10.0.6.0/24)"):
                    with Cluster("Container Apps Environment"):
                        frontend_app = ContainerApps("Frontend Container\n(React + Nginx)")
                        backend_app = ContainerApps("Backend Container\n(Spring Boot)")
                
                with Cluster("Database Subnet (10.0.2.0/24)"):
                    postgres = DatabaseForPostgresqlServers("PostgreSQL Flexible Server\nGP_Standard_D2s_v3")
            
            # Monitoring
            with Cluster("Monitoring Services"):
                app_insights = ApplicationInsights("Application Insights")
                log_analytics = LogAnalyticsWorkspaces("Log Analytics Workspace")
        
        # Container Registry
        acr = ContainerRegistries("Azure Container Registry\nfilipbourgerappacr.azurecr.io")
        
        # Connections
        users >> public_ip >> app_gateway
        app_gateway >> frontend_app
        app_gateway >> backend_app
        backend_app >> postgres
        frontend_app >> backend_app
        backend_app >> app_insights
        app_insights >> log_analytics
        acr >> frontend_app
        acr >> backend_app

# CI/CD Pipeline Diagram
def create_cicd_diagram():
    with Diagram("Burger App - CI/CD Pipeline", 
                 filename="cicd_pipeline", 
                 direction="LR",
                 show=False):
        
        # Source Control
        with Cluster("Source Control"):
            github = Repos("GitHub Repository")
        
        # CI/CD Pipeline
        with Cluster("GitHub Actions"):
            with Cluster("Code Quality & Analysis"):
                code_quality = Pipelines("Code Quality\n(Lint, Test, SonarCloud)")
            
            with Cluster("Build & Push"):
                build_backend = Pipelines("Build Backend\n(Docker)")
                build_frontend = Pipelines("Build Frontend\n(Docker)")
                push_images = Pipelines("Push to ACR")
            
            with Cluster("Infrastructure"):
                terraform_plan = Pipelines("Terraform Plan")
                terraform_apply = Pipelines("Terraform Apply")
        
        # Container Registry
        acr = ContainerRegistries("Azure Container Registry")
        
        # Deployment
        with Cluster("Azure Container Apps"):
            staging_env = ContainerApps("Staging Environment")
        
        # Connections
        github >> code_quality
        code_quality >> build_backend
        code_quality >> build_frontend
        build_backend >> push_images
        build_frontend >> push_images
        push_images >> acr
        terraform_plan >> terraform_apply
        terraform_apply >> staging_env
        acr >> staging_env

# Application Architecture Diagram
def create_application_architecture():
    with Diagram("Burger App - Application Architecture", 
                 filename="application_architecture", 
                 direction="TB",
                 show=False):
        
        # Client Layer
        with Cluster("Client Layer"):
            browser = Usericon("Web Browser")
            react_app = React("React SPA\n(Vite + TypeScript)")
        
        # API Gateway Layer
        app_gateway = ApplicationGateway("Application Gateway\n(Path-based Routing)")
        
        # Application Layer
        with Cluster("Application Layer"):
            with Cluster("Frontend Service"):
                nginx = ContainerApps("Nginx\n(Static Files)")
                react_bundle = React("React Bundle")
            
            with Cluster("Backend Service"):
                spring_boot = Spring("Spring Boot\n(REST API)")
                with Cluster("Controllers"):
                    ingredient_ctrl = Java("IngredientController")
                    cart_ctrl = Java("CartController")
                    order_ctrl = Java("OrderController")
                    health_ctrl = Java("HealthController")
        
        # Data Layer
        with Cluster("Data Layer"):
            postgres = PostgreSQL("PostgreSQL\n(burgerbuilder)")
            with Cluster("Entities"):
                ingredient_entity = SQL("Ingredient")
                cart_entity = SQL("CartItem")
                order_entity = SQL("Order")
                order_item_entity = SQL("OrderItem")
        
        # Monitoring
        app_insights = ApplicationInsights("Application Insights")
        
        # Connections
        browser >> react_app
        react_app >> app_gateway
        app_gateway >> nginx
        app_gateway >> spring_boot
        nginx >> react_bundle
        spring_boot >> ingredient_ctrl
        spring_boot >> cart_ctrl
        spring_boot >> order_ctrl
        spring_boot >> health_ctrl
        ingredient_ctrl >> postgres
        cart_ctrl >> postgres
        order_ctrl >> postgres
        postgres >> ingredient_entity
        postgres >> cart_entity
        postgres >> order_entity
        postgres >> order_item_entity
        spring_boot >> app_insights

# Network Architecture Diagram
def create_network_architecture():
    with Diagram("Burger App - Network Architecture", 
                 filename="network_architecture", 
                 direction="TB",
                 show=False):
        
        # Internet
        internet = Internet("Internet")
        
        with Cluster("Azure Virtual Network (10.0.0.0/16)"):
            # Public Subnet
            with Cluster("App Gateway Subnet (10.0.1.0/24)"):
                public_ip = PublicIpAddresses("Public IP")
                app_gateway = ApplicationGateway("Application Gateway")
            
            # Private Subnets
            with Cluster("Container Apps Subnet (10.0.6.0/24)"):
                frontend = ContainerApps("Frontend")
                backend = ContainerApps("Backend")
            
            with Cluster("Database Subnet (10.0.2.0/24)"):
                postgres = DatabaseForPostgresqlServers("PostgreSQL")
        
        # Private DNS
        with Cluster("Private DNS Zones"):
            dns_zone = Subnets("Private DNS Zone\n*.container-apps")
        
        # Connections
        internet >> public_ip >> app_gateway
        app_gateway >> frontend
        app_gateway >> backend
        backend >> postgres
        frontend >> backend
        frontend >> dns_zone
        backend >> dns_zone

# Security Architecture Diagram
def create_security_architecture():
    with Diagram("Burger App - Security Architecture", 
                 filename="security_architecture", 
                 direction="TB",
                 show=False):
        
        # External
        users = Usericon("Internet Users")
        
        with Cluster("Azure Security Layers"):
            # Network Security
            with Cluster("Network Security"):
                app_gateway = ApplicationGateway("Application Gateway\n(WAF + SSL Termination)")
                vnet = VirtualNetworks("Virtual Network\n(Private)")
            
            # Application Security
            with Cluster("Application Security"):
                frontend = ContainerApps("Frontend\n(CORS Enabled)")
                backend = ContainerApps("Backend\n(Spring Security)")
            
            # Data Security
            with Cluster("Data Security"):
                postgres = DatabaseForPostgresqlServers("PostgreSQL\n(Private Endpoint)")
                key_vault = KeyVaults("Key Vault\n(Secrets Management)")
            
            # Monitoring Security
            with Cluster("Security Monitoring"):
                app_insights = ApplicationInsights("Application Insights\n(Security Events)")
                log_analytics = LogAnalyticsWorkspaces("Log Analytics\n(Security Logs)")
        
        # Connections
        users >> app_gateway
        app_gateway >> vnet
        vnet >> frontend
        vnet >> backend
        vnet >> postgres
        backend >> postgres
        backend >> key_vault
        backend >> app_insights
        app_insights >> log_analytics

if __name__ == "__main__":
    print("Generating Burger App Architecture Diagrams...")
    
    print("1. Creating High-Level Architecture Diagram...")
    create_high_level_architecture()
    
    print("2. Creating Infrastructure Deployment Diagram...")
    create_infrastructure_diagram()
    
    print("3. Creating CI/CD Pipeline Diagram...")
    create_cicd_diagram()
    
    print("4. Creating Application Architecture Diagram...")
    create_application_architecture()
    
    print("5. Creating Network Architecture Diagram...")
    create_network_architecture()
    
    print("6. Creating Security Architecture Diagram...")
    create_security_architecture()
    
    print("All diagrams generated successfully!")
    print("Generated files:")
    print("- high_level_architecture.png")
    print("- infrastructure_deployment.png")
    print("- cicd_pipeline.png")
    print("- application_architecture.png")
    print("- network_architecture.png")
    print("- security_architecture.png")
