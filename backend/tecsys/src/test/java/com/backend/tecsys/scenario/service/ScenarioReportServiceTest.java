package com.backend.tecsys.scenario.service;

import com.backend.tecsys.scenario.dto.ScenarioReportRequest;
import com.backend.tecsys.scenario.exception.InvalidScenarioReportException;
import org.apache.pdfbox.Loader;
import org.apache.pdfbox.pdmodel.PDDocument;
import org.apache.pdfbox.text.PDFTextStripper;
import org.junit.jupiter.api.Test;

import javax.imageio.ImageIO;
import java.awt.image.BufferedImage;
import java.io.ByteArrayOutputStream;
import java.util.Base64;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assertions.assertTrue;

class ScenarioReportServiceTest {
    private final ScenarioReportService service = new ScenarioReportService();

    @Test
    void generatesPdfWithMapIndicatorsAndScenarioParameters() throws Exception {
        byte[] pdf = service.generate(27L, request(validMapImage(), "Cenario de teste", -84.25));

        try (PDDocument document = Loader.loadPDF(pdf)) {
            assertEquals(2, document.getNumberOfPages());
            String text = new PDFTextStripper().getText(document);

            assertTrue(text.contains("Gerado em"));
            assertTrue(text.contains("Campinas"));

            assertTrue(text.contains("Cobertura total"));
            assertTrue(text.contains("92,50%"));
            assertTrue(text.contains("Gateways utilizados"));
            assertTrue(text.contains("-84,25 dBm"));
            assertTrue(text.contains("Ativos em sombra"));

            assertTrue(text.contains("Parâmetros utilizados"));
            assertTrue(text.contains("915,00 MHz"));

            assertTrue(text.contains("Página 1 de 2"));
            assertTrue(text.contains("Página 2 de 2"));
        }
    }

    @Test
    void showsNotAvailableWhenAverageRssiIsMissing() throws Exception {
        byte[] pdf = service.generate(27L, request(validMapImage(), "Cenario de teste", null));

        try (PDDocument document = Loader.loadPDF(pdf)) {
            String text = new PDFTextStripper().getText(document);
            assertTrue(text.contains("N/A"));
        }
    }

    @Test
    void generatesPdfWhenScenarioNameIsVeryLong() throws Exception {
        String longName = "Cenario com um nome extremamente longo para testar o corte do texto ".repeat(5);

        byte[] pdf = service.generate(27L, request(validMapImage(), longName, -84.25));

        try (PDDocument document = Loader.loadPDF(pdf)) {
            assertEquals(2, document.getNumberOfPages());
        }
    }

    @Test
    void rejectsInvalidScenarioId() throws Exception {
        String image = validMapImage();

        assertThrows(InvalidScenarioReportException.class,
                () -> service.generate(0L, request(image, "Cenario de teste", -84.25)));
        assertThrows(InvalidScenarioReportException.class,
                () -> service.generate(null, request(image, "Cenario de teste", -84.25)));
    }

    @Test
    void rejectsInvalidMapImage() {
        assertThrows(InvalidScenarioReportException.class,
                () -> service.generate(27L, request("not-base64", "Cenario de teste", -84.25)));
    }

    private ScenarioReportRequest request(String mapImageBase64, String scenarioName, Double averageRssiDbm) {
        return new ScenarioReportRequest(
                scenarioName,
                "Campinas",
                mapImageBase64,
                "OKUMURA_HATA_SUBURBAN",
                915.0,
                21.0,
                3.0,
                -120.0,
                6.0,
                5.0,
                2.0,
                90.0,
                5,
                92.5,
                3,
                100,
                92,
                8,
                4500.0,
                averageRssiDbm,
                1500.0,
                3500.0);
    }

    private String validMapImage() throws Exception {
        BufferedImage image = new BufferedImage(2, 2, BufferedImage.TYPE_INT_RGB);
        ByteArrayOutputStream output = new ByteArrayOutputStream();
        ImageIO.write(image, "png", output);
        return Base64.getEncoder().encodeToString(output.toByteArray());
    }
}