package br.com.fiap.hospital.historico;

import org.springframework.boot.SpringApplication;

public class TestHistoricoServiceApplication {

	public static void main(String[] args) {
		SpringApplication.from(HistoricoServiceApplication::main).with(TestcontainersConfiguration.class).run(args);
	}

}
