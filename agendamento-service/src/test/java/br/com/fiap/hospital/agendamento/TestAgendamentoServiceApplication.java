package br.com.fiap.hospital.agendamento;

import org.springframework.boot.SpringApplication;

public class TestAgendamentoServiceApplication {

	public static void main(String[] args) {
		SpringApplication.from(AgendamentoServiceApplication::main).with(TestcontainersConfiguration.class).run(args);
	}

}
