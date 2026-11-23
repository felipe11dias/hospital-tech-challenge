package br.com.fiap.hospital.agendamento;

import org.junit.jupiter.api.Test;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.context.annotation.Import;

@Import(TestcontainersConfiguration.class)
@SpringBootTest
class AgendamentoServiceApplicationTests {

	@Test
	void contextLoads() {
	}

}
