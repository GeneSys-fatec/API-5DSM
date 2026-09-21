package com.backend.tecsys;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.scheduling.annotation.EnableAsync;

import com.fasterxml.jackson.databind.ObjectMapper;
import org.springframework.context.annotation.Bean;

@SpringBootApplication
@EnableAsync
public class TecsysApplication {

	public static void main(String[] args) {
		SpringApplication.run(TecsysApplication.class, args);
	}

	@Bean
	public ObjectMapper objectMapper() {
		return new ObjectMapper();
	}
}
