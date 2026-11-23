package br.com.fiap.hospital.notificacao;

import org.springframework.boot.SpringApplication;

public class TestNotificacaoServiceApplication {

	public static void main(String[] args) {
		SpringApplication.from(NotificacaoServiceApplication::main).with(TestcontainersConfiguration.class).run(args);
	}

}
