package com.virtualpet.ecommerce.modules.user.controller;

import com.virtualpet.ecommerce.modules.user.dto.*;
import com.virtualpet.ecommerce.modules.user.service.UserService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.media.Content;
import io.swagger.v3.oas.annotations.media.ExampleObject;
import io.swagger.v3.oas.annotations.media.Schema;
import io.swagger.v3.oas.annotations.responses.ApiResponse;
import io.swagger.v3.oas.annotations.responses.ApiResponses;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/users")
@CrossOrigin(origins = "*")  // Para desarrollo, en producción especificar el dominio
@Tag(name = "User Management", description = "Gestión de usuarios, registro y autenticación")
public class UserController {

    @Autowired
    private UserService userService;

    @Operation(
            summary = "Registrar nuevo usuario",
            description = "Crea una nueva cuenta de cliente en el sistema"
    )
    @ApiResponses(value = {
            @ApiResponse(
                    responseCode = "201",
                    description = "Usuario registrado exitosamente",
                    content = @Content(schema = @Schema(implementation = UserResponse.class))
            ),
            @ApiResponse(
                    responseCode = "400",
                    description = "Datos de entrada inválidos",
                    content = @Content(
                            schema = @Schema(implementation = ErrorResponse.class),
                            examples = @ExampleObject(
                                    name = "Validación",
                                    value = "{\"status\":400,\"error\":\"Bad Request\",\"message\":\"El email no es válido\",\"path\":\"/api/users/register\",\"timestamp\":\"2025-11-06T15:30:00\",\"field\":\"email\"}"
                            )
                    )
            ),
            @ApiResponse(
                    responseCode = "409",
                    description = "Email ya registrado",
                    content = @Content(
                            schema = @Schema(implementation = ErrorResponse.class),
                            examples = @ExampleObject(
                                    name = "Conflicto",
                                    value = "{\"status\":409,\"error\":\"Conflict\",\"message\":\"El email ya está registrado\",\"path\":\"/api/users/register\",\"timestamp\":\"2025-11-06T15:30:00\"}"
                            )
                    )
            ),
            @ApiResponse(
                    responseCode = "500",
                    description = "Error interno del servidor",
                    content = @Content(
                            schema = @Schema(implementation = ErrorResponse.class),
                            examples = @ExampleObject(
                                    name = "Error del servidor",
                                    value = "{\"status\":500,\"error\":\"Internal Server Error\",\"message\":\"Ha ocurrido un error interno en el servidor\",\"path\":\"/api/users/register\",\"timestamp\":\"2025-11-06T15:30:00\"}"
                            )
                    )
            )
    })
    @PostMapping("/register")
    public ResponseEntity<UserResponse> register(@Valid @RequestBody RegisterRequest request) {
        UserResponse response = userService.register(request);
        return ResponseEntity.status(HttpStatus.CREATED).body(response);
    }

    @Operation(
            summary = "Iniciar sesión",
            description = "Autentica al usuario y retorna un token JWT"
    )
    @ApiResponses(value = {
            @ApiResponse(
                    responseCode = "200",
                    description = "Login exitoso",
                    content = @Content(schema = @Schema(implementation = LoginResponse.class))
            ),
            @ApiResponse(
                    responseCode = "400",
                    description = "Datos de entrada inválidos",
                    content = @Content(
                            schema = @Schema(implementation = ErrorResponse.class),
                            examples = @ExampleObject(
                                    name = "Validación",
                                    value = "{\"status\":400,\"error\":\"Bad Request\",\"message\":\"El email es requerido\",\"path\":\"/api/users/login\",\"timestamp\":\"2025-11-06T15:30:00\",\"field\":\"email\"}"
                            )
                    )
            ),
            @ApiResponse(
                    responseCode = "401",
                    description = "Credenciales inválidas",
                    content = @Content(
                            schema = @Schema(implementation = ErrorResponse.class),
                            examples = @ExampleObject(
                                    name = "No autorizado",
                                    value = "{\"status\":401,\"error\":\"Unauthorized\",\"message\":\"Credenciales inválidas\",\"path\":\"/api/users/login\",\"timestamp\":\"2025-11-06T15:30:00\"}"
                            )
                    )
            ),
            @ApiResponse(
                    responseCode = "500",
                    description = "Error interno del servidor",
                    content = @Content(
                            schema = @Schema(implementation = ErrorResponse.class),
                            examples = @ExampleObject(
                                    name = "Error del servidor",
                                    value = "{\"status\":500,\"error\":\"Internal Server Error\",\"message\":\"Ha ocurrido un error interno en el servidor\",\"path\":\"/api/users/login\",\"timestamp\":\"2025-11-06T15:30:00\"}"
                            )
                    )
            )
    })
    @PostMapping("/login")
    public ResponseEntity<LoginResponse> login(@Valid @RequestBody LoginRequest request) {
        LoginResponse response = userService.login(request);
        return ResponseEntity.ok(response);
    }

    @Operation(
            summary = "Obtener perfil de usuario",
            description = "Retorna la información del usuario autenticado",
            security = @SecurityRequirement(name = "Bearer Authentication")
    )
    @ApiResponses(value = {
            @ApiResponse(
                    responseCode = "200",
                    description = "Perfil obtenido exitosamente",
                    content = @Content(schema = @Schema(implementation = UserResponse.class))
            ),
            @ApiResponse(
                    responseCode = "401",
                    description = "No autenticado o token inválido",
                    content = @Content(
                            schema = @Schema(implementation = ErrorResponse.class),
                            examples = @ExampleObject(
                                    name = "No autorizado",
                                    value = "{\"status\":401,\"error\":\"Unauthorized\",\"message\":\"No autenticado o token inválido\",\"path\":\"/api/users/profile\",\"timestamp\":\"2025-11-06T15:30:00\"}"
                            )
                    )
            ),
            @ApiResponse(
                    responseCode = "404",
                    description = "Usuario no encontrado",
                    content = @Content(
                            schema = @Schema(implementation = ErrorResponse.class),
                            examples = @ExampleObject(
                                    name = "No encontrado",
                                    value = "{\"status\":404,\"error\":\"Not Found\",\"message\":\"Usuario no encontrado\",\"path\":\"/api/users/profile\",\"timestamp\":\"2025-11-06T15:30:00\"}"
                            )
                    )
            ),
            @ApiResponse(
                    responseCode = "500",
                    description = "Error interno del servidor",
                    content = @Content(
                            schema = @Schema(implementation = ErrorResponse.class),
                            examples = @ExampleObject(
                                    name = "Error del servidor",
                                    value = "{\"status\":500,\"error\":\"Internal Server Error\",\"message\":\"Ha ocurrido un error interno en el servidor\",\"path\":\"/api/users/profile\",\"timestamp\":\"2025-11-06T15:30:00\"}"
                            )
                    )
            )
    })
    @GetMapping("/profile")
    public ResponseEntity<UserResponse> getProfile(Authentication authentication) {
        String email = authentication.getName();
        UserResponse response = userService.getProfile(email);
        return ResponseEntity.ok(response);
    }

    @Operation(
            summary = "Actualizar perfil de usuario",
            description = "Permite al usuario autenticado actualizar su información personal",
            security = @SecurityRequirement(name = "Bearer Authentication")
    )
    @ApiResponses(value = {
            @ApiResponse(
                    responseCode = "200",
                    description = "Perfil actualizado exitosamente",
                    content = @Content(schema = @Schema(implementation = UserResponse.class))
            ),
            @ApiResponse(
                    responseCode = "400",
                    description = "Datos inválidos",
                    content = @Content(
                            schema = @Schema(implementation = ErrorResponse.class),
                            examples = @ExampleObject(
                                    name = "Validación",
                                    value = "{\"status\":400,\"error\":\"Bad Request\",\"message\":\"El teléfono no es válido\",\"path\":\"/api/users/profile\",\"timestamp\":\"2025-11-06T15:30:00\",\"field\":\"phone\"}"
                            )
                    )
            ),
            @ApiResponse(
                    responseCode = "401",
                    description = "No autenticado o token inválido",
                    content = @Content(
                            schema = @Schema(implementation = ErrorResponse.class),
                            examples = @ExampleObject(
                                    name = "No autorizado",
                                    value = "{\"status\":401,\"error\":\"Unauthorized\",\"message\":\"No autenticado o token inválido\",\"path\":\"/api/users/profile\",\"timestamp\":\"2025-11-06T15:30:00\"}"
                            )
                    )
            ),
            @ApiResponse(
                    responseCode = "500",
                    description = "Error interno del servidor",
                    content = @Content(
                            schema = @Schema(implementation = ErrorResponse.class),
                            examples = @ExampleObject(
                                    name = "Error del servidor",
                                    value = "{\"status\":500,\"error\":\"Internal Server Error\",\"message\":\"Ha ocurrido un error interno en el servidor\",\"path\":\"/api/users/profile\",\"timestamp\":\"2025-11-06T15:30:00\"}"
                            )
                    )
            )
    })
    @PatchMapping("/profile")
    public ResponseEntity<UserResponse> updateProfile(
            @Valid @RequestBody UpdateProfileRequest request,
            Authentication authentication) {
        String email = authentication.getName();
        UserResponse response = userService.updateProfile(email, request);
        return ResponseEntity.ok(response);
    }
}