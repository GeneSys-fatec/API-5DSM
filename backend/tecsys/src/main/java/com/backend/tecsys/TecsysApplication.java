package com.backend.tecsys;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.scheduling.annotation.EnableAsync;

@SpringBootApplication
@EnableAsync
public class TecsysApplication {

	public static void main(String[] args) {
		SpringApplication.run(TecsysApplication.class, args);
	}
}

