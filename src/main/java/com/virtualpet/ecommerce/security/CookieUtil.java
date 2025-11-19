package com.virtualpet.ecommerce.security;

import jakarta.servlet.http.Cookie;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;

/**
 * Utilidad para gestionar cookies HttpOnly de autenticación
 */
@Component
public class CookieUtil {

    @Value("${cookie.secure:true}")
    private boolean secure;

    @Value("${cookie.same-site:None}")
    private String sameSite;

    @Value("${cookie.max-age:3600}")
    private int maxAge;

    private static final String ACCESS_TOKEN_COOKIE_NAME = "accessToken";
    private static final String REFRESH_TOKEN_COOKIE_NAME = "refreshToken";

    /**
     * Crea una cookie HttpOnly con el token de acceso
     */
    public Cookie createAccessTokenCookie(String token) {
        Cookie cookie = new Cookie(ACCESS_TOKEN_COOKIE_NAME, token);
        cookie.setHttpOnly(true);
        cookie.setSecure(secure);
        cookie.setPath("/");
        cookie.setMaxAge(maxAge);
        cookie.setAttribute("SameSite", sameSite);
        return cookie;
    }

    /**
     * Crea una cookie HttpOnly con el token de refresco
     */
    public Cookie createRefreshTokenCookie(String token) {
        Cookie cookie = new Cookie(REFRESH_TOKEN_COOKIE_NAME, token);
        cookie.setHttpOnly(true);
        cookie.setSecure(secure);
        cookie.setPath("/");
        cookie.setMaxAge(maxAge);
        cookie.setAttribute("SameSite", sameSite);
        return cookie;
    }

    /**
     * Elimina la cookie de acceso
     */
    public Cookie deleteAccessTokenCookie() {
        Cookie cookie = new Cookie(ACCESS_TOKEN_COOKIE_NAME, null);
        cookie.setHttpOnly(true);
        cookie.setSecure(secure);
        cookie.setPath("/");
        cookie.setMaxAge(0);
        cookie.setAttribute("SameSite", sameSite);
        return cookie;
    }

    /**
     * Elimina la cookie de refresco
     */
    public Cookie deleteRefreshTokenCookie() {
        Cookie cookie = new Cookie(REFRESH_TOKEN_COOKIE_NAME, null);
        cookie.setHttpOnly(true);
        cookie.setSecure(secure);
        cookie.setPath("/");
        cookie.setMaxAge(0);
        cookie.setAttribute("SameSite", sameSite);
        return cookie;
    }

    /**
     * Extrae el token de acceso desde las cookies
     */
    public String extractAccessToken(HttpServletRequest request) {
        return extractCookieValue(request, ACCESS_TOKEN_COOKIE_NAME);
    }

    /**
     * Extrae el token de refresco desde las cookies
     */
    public String extractRefreshToken(HttpServletRequest request) {
        return extractCookieValue(request, REFRESH_TOKEN_COOKIE_NAME);
    }

    /**
     * Extrae el valor de una cookie por nombre
     */
    private String extractCookieValue(HttpServletRequest request, String cookieName) {
        Cookie[] cookies = request.getCookies();
        if (cookies != null) {
            for (Cookie cookie : cookies) {
                if (cookieName.equals(cookie.getName())) {
                    return cookie.getValue();
                }
            }
        }
        return null;
    }

    /**
     * Agrega las cookies de autenticación a la respuesta
     */
    public void addAuthCookies(HttpServletResponse response, String accessToken, String refreshToken) {
        response.addCookie(createAccessTokenCookie(accessToken));
        response.addCookie(createRefreshTokenCookie(refreshToken));
    }

    /**
     * Elimina las cookies de autenticación
     */
    public void deleteAuthCookies(HttpServletResponse response) {
        response.addCookie(deleteAccessTokenCookie());
        response.addCookie(deleteRefreshTokenCookie());
    }
}

