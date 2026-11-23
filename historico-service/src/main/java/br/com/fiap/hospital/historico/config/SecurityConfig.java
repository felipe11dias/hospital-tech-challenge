package br.com.fiap.hospital.historico.config;

import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.security.config.Customizer;
import org.springframework.security.config.annotation.method.configuration.EnableMethodSecurity;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.config.annotation.web.configuration.EnableWebSecurity;
import org.springframework.security.config.http.SessionCreationPolicy;
import org.springframework.security.web.SecurityFilterChain;

/**
 * Esqueleto de seguranca do Sprint 0.
 *
 * <p>Nao implementa a F1: nao emite token, nao le usuario do banco e nao conhece perfil.
 * Existe para que o Principio III da constituicao ("tudo autenticado por padrao, liberacao
 * explicita e limitada a /actuator/health e ao GraphiQL") valha desde o primeiro commit, em vez
 * de o servico subir aberto ou subir com o login gerado automaticamente barrando o health check.
 *
 * <p>A spec specs/001-autenticacao substitui esta classe por duas cadeias de filtros: HTTP Basic em
 * /auth/token e Resource Server JWT no restante.
 */
@Configuration
@EnableWebSecurity
@EnableMethodSecurity
public class SecurityConfig {

    @Bean
    SecurityFilterChain filterChain(HttpSecurity http) throws Exception {
        http.authorizeHttpRequests(auth -> auth
                        .requestMatchers("/actuator/health", "/actuator/health/**", "/actuator/info", "/actuator/prometheus").permitAll()
                        .requestMatchers("/graphiql/**").permitAll()
                        .anyRequest().authenticated())
                .httpBasic(Customizer.withDefaults())
                .csrf(csrf -> csrf.disable())
                .sessionManagement(session -> session.sessionCreationPolicy(SessionCreationPolicy.STATELESS));
        return http.build();
    }
}
