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
import jakarta.servlet.http.Cookie;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.validation.Valid;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

import java.util.HashMap;
import java.util.Map;

@RestController
@RequestMapping("/api/users")
@Tag(name = "User Management", description = "Gestión de usuarios, registro y autenticación")
public class UserController {
    @Value("${cookie.secure:true}")
    private boolean secure;

    @Value("${cookie.same-site:None}")
    private String sameSite;
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
            description = "Autentica al usuario y establece una cookie HttpOnly con el token JWT"
    )
    @ApiResponses(value = {
            @ApiResponse(
                    responseCode = "200",
                    description = "Login exitoso - Cookie establecida",
                    content = @Content(
                            schema = @Schema(implementation = Map.class),
                            examples = @ExampleObject(
                                    name = "Success",
                                    value = "{\"message\":\"Login exitoso\",\"user\":{\"id\":1,\"email\":\"user@example.com\",\"role\":\"CLIENT\"}}"
                            )
                    )
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
    public ResponseEntity<Map<String, Object>> login(
            @Valid @RequestBody LoginRequest request,
            HttpServletResponse response) {

        LoginResponse loginResponse = userService.login(request);

        // Crear cookie HttpOnly con el access token
        Cookie accessTokenCookie = new Cookie("accessToken", loginResponse.getAccessToken());
        accessTokenCookie.setHttpOnly(true);  // No accesible desde JavaScript
        accessTokenCookie.setSecure(secure);    // En producción cambiar a true (requiere HTTPS)
        accessTokenCookie.setPath("/");
        accessTokenCookie.setMaxAge(3600);     // 1 hora (en segundos)
        accessTokenCookie.setAttribute("SameSite", sameSite); // Protección contra CSRF

        // Crear cookie HttpOnly con el refresh token
        Cookie refreshTokenCookie = new Cookie("refreshToken", loginResponse.getRefreshToken());
        refreshTokenCookie.setHttpOnly(true);
        refreshTokenCookie.setSecure(secure);   // En producción cambiar a true
        refreshTokenCookie.setPath("/");
        refreshTokenCookie.setMaxAge(3600);    // 1 hora (ajustar según necesites)
        refreshTokenCookie.setAttribute("SameSite", sameSite);

        // Agregar cookies a la respuesta
        response.addCookie(accessTokenCookie);
        response.addCookie(refreshTokenCookie);

        // Retornar respuesta sin exponer los tokens en el body
        Map<String, Object> responseBody = new HashMap<>();
        responseBody.put("message", "Login exitoso");
        responseBody.put("user", loginResponse.getUser());

        return ResponseEntity.ok(responseBody);
    }

    @Operation(
            summary = "Cerrar sesión",
            description = "Elimina las cookies de autenticación"
    )
    @ApiResponses(value = {
            @ApiResponse(
                    responseCode = "200",
                    description = "Logout exitoso",
                    content = @Content(
                            schema = @Schema(implementation = Map.class),
                            examples = @ExampleObject(
                                    name = "Success",
                                    value = "{\"message\":\"Logout exitoso\"}"
                            )
                    )
            )
    })
    @PostMapping("/logout")
    public ResponseEntity<Map<String, String>> logout(HttpServletResponse response) {
        // Eliminar cookie de access token
        Cookie accessTokenCookie = new Cookie("accessToken", null);
        accessTokenCookie.setHttpOnly(true);
        accessTokenCookie.setSecure(secure);
        accessTokenCookie.setPath("/");
        accessTokenCookie.setMaxAge(0); // Eliminar inmediatamente

        // Eliminar cookie de refresh token
        Cookie refreshTokenCookie = new Cookie("refreshToken", null);
        refreshTokenCookie.setHttpOnly(true);
        refreshTokenCookie.setSecure(secure);
        refreshTokenCookie.setPath("/");
        refreshTokenCookie.setMaxAge(0); // Eliminar inmediatamente

        response.addCookie(accessTokenCookie);
        response.addCookie(refreshTokenCookie);

        Map<String, String> responseBody = new HashMap<>();
        responseBody.put("message", "Logout exitoso");

        return ResponseEntity.ok(responseBody);
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
