package com.virtualpet.ecommerce.config;

import io.swagger.v3.oas.models.Components;
import io.swagger.v3.oas.models.OpenAPI;
import io.swagger.v3.oas.models.info.Contact;
import io.swagger.v3.oas.models.info.Info;
import io.swagger.v3.oas.models.info.License;
import io.swagger.v3.oas.models.security.SecurityScheme;
import io.swagger.v3.oas.models.servers.Server;
import org.springdoc.core.models.GroupedOpenApi;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

import java.util.List;

/**
 * Configuración de OpenAPI/Swagger para documentación de la API
 */
@Configuration
public class OpenApiConfig {

    @Bean
    public OpenAPI virtualPetOpenAPI() {
        // Definir servidor de producción
        Server productionServer = new Server();
        productionServer.setUrl("https://petshop-cloud.rj.r.appspot.com");
        productionServer.setDescription("Servidor de producción (GCP App Engine)");

        // Definir servidor local
        Server localServer = new Server();
        localServer.setUrl("http://localhost:8080");
        localServer.setDescription("Servidor de desarrollo local");

        // Información de contacto
        Contact contact = new Contact();
        contact.setEmail("dev@virtualpet.com");
        contact.setName("Virtual Pet Team");
        contact.setUrl("https://github.com/virtualpet/ecommerce");

        // Licencia
        License mitLicense = new License()
                .name("MIT License")
                .url("https://choosealicense.com/licenses/mit/");

        // Información general de la API
        Info info = new Info()
                .title("Virtual Pet E-Commerce API")
                .version("1.0.0")
                .contact(contact)
                .description("API REST para e-commerce de productos para mascotas. " +
                        "Incluye gestión de usuarios, catálogo de productos, carrito de compras y gestión de pedidos.")
                .termsOfService("https://virtualpet.com/terms")
                .license(mitLicense);

        // Esquema de seguridad JWT
        SecurityScheme securityScheme = new SecurityScheme()
                .type(SecurityScheme.Type.HTTP)
                .scheme("bearer")
                .bearerFormat("JWT")
                .in(SecurityScheme.In.HEADER)
                .name("Authorization")
                .description("Token JWT obtenido al hacer login. Formato: Bearer {token}");

        // NO aplicar seguridad global, se aplica por controlador/endpoint con @SecurityRequirement
        return new OpenAPI()
                .info(info)
                .servers(List.of(productionServer, localServer))
                .components(new Components()
                        .addSecuritySchemes("Bearer Authentication", securityScheme));
    }

    @Bean
    public GroupedOpenApi publicApi() {
        return GroupedOpenApi.builder()
                .group("virtual-pet-api")
                .packagesToScan("com.virtualpet.ecommerce.modules")
                .pathsToMatch("/api/**")
                .build();
    }
}

