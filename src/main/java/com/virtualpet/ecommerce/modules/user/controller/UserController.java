package com.virtualpet.ecommerce.modules.user.controller;

import com.virtualpet.ecommerce.modules.user.dto.*;
import com.virtualpet.ecommerce.modules.user.service.UserService;
import jakarta.validation.Valid;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/users")
@CrossOrigin(origins = "*")  // Para desarrollo, en producción especificar el dominio
public class UserController {

    @Autowired
    private UserService userService;

    /**
     * POST /api/users/register
     * Registrar nuevo usuario (CLIENT)
     */
    @PostMapping("/register")
    public ResponseEntity<?> register(@Valid @RequestBody RegisterRequest request) {
        try {
            UserResponse response = userService.register(request);
            return ResponseEntity.status(HttpStatus.CREATED).body(response);
        } catch (RuntimeException e) {
            ErrorResponse error = ErrorResponse.builder()
                    .error("ValidationError")
                    .message(e.getMessage())
                    .field("email")
                    .build();
            return ResponseEntity.status(HttpStatus.BAD_REQUEST).body(error);
        }
    }

    /**
     * POST /api/users/login
     * Iniciar sesión y obtener JWT
     */
    @PostMapping("/login")
    public ResponseEntity<?> login(@Valid @RequestBody LoginRequest request) {
        try {
            LoginResponse response = userService.login(request);
            return ResponseEntity.ok(response);
        } catch (RuntimeException e) {
            ErrorResponse error = ErrorResponse.builder()
                    .error("AuthenticationError")
                    .message("Credenciales inválidas")
                    .build();
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED).body(error);
        }
    }

    /**
     * GET /api/users/profile
     * Obtener perfil del usuario autenticado
     */
    @GetMapping("/profile")
    public ResponseEntity<?> getProfile(Authentication authentication) {
        try {
            String email = authentication.getName();
            UserResponse response = userService.getProfile(email);
            return ResponseEntity.ok(response);
        } catch (RuntimeException e) {
            ErrorResponse error = ErrorResponse.builder()
                    .error("NotFound")
                    .message(e.getMessage())
                    .build();
            return ResponseEntity.status(HttpStatus.NOT_FOUND).body(error);
        }
    }

    /**
     * PATCH /api/users/profile
     * Actualizar perfil del usuario autenticado
     */
    @PatchMapping("/profile")
    public ResponseEntity<?> updateProfile(
            @Valid @RequestBody UpdateProfileRequest request,
            Authentication authentication) {
        try {
            String email = authentication.getName();
            UserResponse response = userService.updateProfile(email, request);
            return ResponseEntity.ok(response);
        } catch (RuntimeException e) {
            ErrorResponse error = ErrorResponse.builder()
                    .error("ValidationError")
                    .message(e.getMessage())
                    .build();
            return ResponseEntity.status(HttpStatus.BAD_REQUEST).body(error);
        }
    }
}