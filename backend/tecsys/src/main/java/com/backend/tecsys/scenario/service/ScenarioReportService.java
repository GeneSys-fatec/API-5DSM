package com.backend.tecsys.scenario.service;

import com.backend.tecsys.scenario.dto.ScenarioReportRequest;
import com.backend.tecsys.scenario.exception.InvalidScenarioReportException;
import com.backend.tecsys.scenario.exception.ScenarioReportGenerationException;
import org.apache.pdfbox.pdmodel.PDDocument;
import org.apache.pdfbox.pdmodel.PDPage;
import org.apache.pdfbox.pdmodel.PDPageContentStream;
import org.apache.pdfbox.pdmodel.common.PDRectangle;
import org.apache.pdfbox.pdmodel.font.PDFont;
import org.apache.pdfbox.pdmodel.font.PDType1Font;
import org.apache.pdfbox.pdmodel.font.Standard14Fonts;
import org.apache.pdfbox.pdmodel.graphics.image.LosslessFactory;
import org.apache.pdfbox.pdmodel.graphics.image.PDImageXObject;
import org.springframework.stereotype.Service;

import javax.imageio.ImageIO;
import javax.imageio.ImageReader;
import javax.imageio.stream.ImageInputStream;
import java.awt.Color;
import java.awt.image.BufferedImage;
import java.io.ByteArrayInputStream;
import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.time.ZoneId;
import java.time.ZonedDateTime;
import java.time.format.DateTimeFormatter;
import java.util.ArrayList;
import java.util.Base64;
import java.util.Iterator;
import java.util.List;
import java.util.Locale;

@Service
public class ScenarioReportService {
    private static final int MAX_IMAGE_BYTES = 10 * 1024 * 1024;
    private static final long MAX_IMAGE_PIXELS = 20_000_000L;

    private static final float MARGIN = 40f;
    private static final float FOOTER_HEIGHT = 30f;

    private static final Color PRIMARY = new Color(0x5B, 0x21, 0xB6);
    private static final Color PRIMARY_LIGHT = new Color(0xF5, 0xF3, 0xFF);
    private static final Color BORDER = new Color(0xDD, 0xD6, 0xFE);
    private static final Color TEXT = new Color(0x1F, 0x29, 0x37);
    private static final Color MUTED = new Color(0x6B, 0x72, 0x80);
    private static final Color SUCCESS = new Color(0x15, 0x80, 0x3D);
    private static final Color DANGER = new Color(0xB9, 0x1C, 0x1C);

    private static final PDType1Font REGULAR = new PDType1Font(Standard14Fonts.FontName.HELVETICA);
    private static final PDType1Font BOLD = new PDType1Font(Standard14Fonts.FontName.HELVETICA_BOLD);

    private static final Locale PT_BR = Locale.forLanguageTag("pt-BR");
    private static final ZoneId ZONE = ZoneId.of("America/Sao_Paulo");
    private static final DateTimeFormatter DATE_TIME = DateTimeFormatter.ofPattern("dd/MM/yyyy HH:mm");

    public byte[] generate(Long scenarioId, ScenarioReportRequest request) {
        if (scenarioId == null || scenarioId <= 0) {
            throw new InvalidScenarioReportException("O identificador do cenário deve ser positivo.");
        }

        BufferedImage mapImage = decodeMapImage(request.mapImageBase64());
        try (PDDocument document = new PDDocument(); ByteArrayOutputStream output = new ByteArrayOutputStream()) {
            addSummaryPage(document, request, mapImage);
            addParametersPage(document, request);
            addFooters(document);
            document.save(output);
            return output.toByteArray();
        } catch (IOException exception) {
            throw new ScenarioReportGenerationException("Não foi possível gerar o relatório do cenário.", exception);
        }
    }

    private BufferedImage decodeMapImage(String encoded) {
        try {
            String imageContent = encoded.startsWith("data:")
                    ? encoded.substring(encoded.indexOf(',') + 1)
                    : encoded;
            byte[] imageBytes = Base64.getDecoder().decode(imageContent);
            if (imageBytes.length == 0 || imageBytes.length > MAX_IMAGE_BYTES) {
                throw new InvalidScenarioReportException("A imagem do mapa deve ter no maximo 10 MB.");
            }

            try (ImageInputStream imageInput = ImageIO.createImageInputStream(
                    new ByteArrayInputStream(imageBytes))) {
                Iterator<ImageReader> readers = ImageIO.getImageReaders(imageInput);
                if (!readers.hasNext()) {
                    throw new InvalidScenarioReportException("A imagem do mapa deve ser PNG ou JPEG valido.");
                }
                ImageReader reader = readers.next();
                try {
                    reader.setInput(imageInput, true, true);
                    String format = reader.getFormatName();
                    if (!format.equalsIgnoreCase("png") && !format.equalsIgnoreCase("jpeg")) {
                        throw new InvalidScenarioReportException("A imagem do mapa deve estar no formato PNG ou JPEG.");
                    }
                    if ((long) reader.getWidth(0) * reader.getHeight(0) > MAX_IMAGE_PIXELS) {
                        throw new InvalidScenarioReportException("A imagem do mapa deve ter no maximo 20 milhões de pixels.");
                    }
                    return reader.read(0);
                } finally {
                    reader.dispose();
                }
            }
        } catch (IllegalArgumentException | IOException exception) {
            throw new InvalidScenarioReportException("A imagem do mapa nao esta em Base64 ou possui formato inválido.");
        }
    }

    private void addSummaryPage(PDDocument document, ScenarioReportRequest request,
                                BufferedImage mapImage) throws IOException {
        PDPage page = new PDPage(PDRectangle.A4);
        document.addPage(page);
        float pageWidth = page.getMediaBox().getWidth();
        float pageHeight = page.getMediaBox().getHeight();
        float contentWidth = pageWidth - MARGIN * 2;
        PDImageXObject image = LosslessFactory.createFromImage(document, mapImage);

        try (PDPageContentStream content = new PDPageContentStream(document, page)) {
            float headerHeight = 80f;
            drawHeader(content, pageWidth, pageHeight, headerHeight, "Relatório do Cenário");

            float y = pageHeight - headerHeight - 24;
            float halfWidth = contentWidth / 2;
            drawLabelValue(content, "Região:", valueOrDash(request.regionName()), MARGIN, y, halfWidth - 10);
            drawLabelValue(content, "Modelo de propagação:", valueOrDash(request.propagationModel()),
                    MARGIN + halfWidth, y, halfWidth);

            float gap = 10f;
            float cardWidth = (contentWidth - gap * 3) / 4;
            float cardHeight = 52f;
            float rowTop = y - 18;

            Number coverage = request.totalCoveragePct();
            Number target = request.coverageTargetPct();
            Color coverageColor = PRIMARY;
            if (coverage != null && target != null) {
                coverageColor = coverage.doubleValue() >= target.doubleValue() ? SUCCESS : DANGER;
            }

            String[][] firstRow = {
                {"Cobertura total", coverage == null ? "N/A" : format(coverage) + "%"},
                {"Meta de cobertura", target == null ? "N/A" : format(target) + "%"},
                {"Gateways utilizados", String.valueOf(request.gatewayCount())},
                {"RSSI médio", request.averageRssiDbm() == null
                        ? "N/A" : format(request.averageRssiDbm()) + " dBm"}
            };
            String[][] secondRow = {
                    {"Total de ativos", String.valueOf(request.totalAssetCount())},
                    {"Ativos conectados", String.valueOf(request.connectedAssetCount())},
                    {"Ativos em sombra", String.valueOf(request.shadowedAssetCount())}
            };
            drawCardRow(content, firstRow, MARGIN, rowTop, cardWidth, cardHeight, gap, coverageColor);
            drawCardRow(content, secondRow, MARGIN, rowTop - cardHeight - gap, cardWidth, cardHeight, gap, PRIMARY);

            float mapHeadingY = rowTop - (cardHeight * 2 + gap) - 28;
            drawText(content, BOLD, 12, TEXT, "Mapa do resultado", MARGIN, mapHeadingY);
            float mapTop = mapHeadingY - 10;
            float mapBottom = MARGIN + FOOTER_HEIGHT;
            float maxWidth = contentWidth;
            float maxHeight = mapTop - mapBottom;
            float scale = Math.min(maxWidth / image.getWidth(), maxHeight / image.getHeight());
            float width = image.getWidth() * scale;
            float height = image.getHeight() * scale;
            float imageX = MARGIN + (contentWidth - width) / 2;
            float imageY = mapTop - height;
            content.drawImage(image, imageX, imageY, width, height);
            strokeRect(content, BORDER, imageX, imageY, width, height);
        }
    }

    private void addParametersPage(PDDocument document, ScenarioReportRequest request)
            throws IOException {
        PDPage page = new PDPage(PDRectangle.A4);
        document.addPage(page);
        float pageWidth = page.getMediaBox().getWidth();
        float pageHeight = page.getMediaBox().getHeight();
        float contentWidth = pageWidth - MARGIN * 2;

        List<String[]> rows = new ArrayList<>();
        rows.add(new String[]{"Frequência", formatOptional(request.frequencyMhz(), " MHz")});
        rows.add(new String[]{"Potência de transmissão", formatOptional(request.txPowerDbm(), " dBm")});
        rows.add(new String[]{"Ganho da antena", formatOptional(request.antennaGainDbi(), " dBi")});
        rows.add(new String[]{"Sensibilidade do receptor", formatOptional(request.receiverSensitivityDbm(), " dBm")});
        rows.add(new String[]{"Perdas do sistema", formatOptional(request.systemLossDb(), " dB")});
        rows.add(new String[]{"Meta de cobertura", formatOptional(request.coverageTargetPct(), "%")});
        rows.add(new String[]{"Limite de gateways", valueOrDash(request.maxGateways())});
        rows.add(new String[]{"Raio da busca", request.searchRadiusMeters() == null
                ? "N/A" : format(request.searchRadiusMeters()) + " m"});

        try (PDPageContentStream content = new PDPageContentStream(document, page)) {
            float headerHeight = 60f;
            drawHeader(content, pageWidth, pageHeight, headerHeight, "Parâmetros utilizados");
            
            float rowHeight = 26f;
            float labelColumn = contentWidth * 0.6f;
            float y = pageHeight - headerHeight - 30;

            fillRect(content, PRIMARY, MARGIN, y - rowHeight, contentWidth, rowHeight);
            drawText(content, BOLD, 10, Color.WHITE, "Parâmetro", MARGIN + 10, y - 17);
            drawText(content, BOLD, 10, Color.WHITE, "Valor", MARGIN + labelColumn, y - 17);
            y -= rowHeight;

            for (int i = 0; i < rows.size(); i++) {
                if (i % 2 == 0) {
                    fillRect(content, PRIMARY_LIGHT, MARGIN, y - rowHeight, contentWidth, rowHeight);
                }
                drawText(content, REGULAR, 10, MUTED, rows.get(i)[0], MARGIN + 10, y - 17);
                drawText(content, BOLD, 10, TEXT, rows.get(i)[1], MARGIN + labelColumn, y - 17);
                y -= rowHeight;
            }
            strokeRect(content, BORDER, MARGIN, y, contentWidth, rows.size() * rowHeight + rowHeight);
        }
    }

    private void addFooters(PDDocument document) throws IOException {
        int total = document.getNumberOfPages();
        for (int i = 0; i < total; i++) {
            PDPage page = document.getPage(i);
            float pageWidth = page.getMediaBox().getWidth();
            try (PDPageContentStream content = new PDPageContentStream(
                    document, page, PDPageContentStream.AppendMode.APPEND, true, true)) {
                content.setStrokingColor(BORDER);
                content.setLineWidth(0.6f);
                content.moveTo(MARGIN, MARGIN + 14);
                content.lineTo(pageWidth - MARGIN, MARGIN + 14);
                content.stroke();
                drawText(content, REGULAR, 8, MUTED, "TECSYS - Planejamento Inteligente", MARGIN, MARGIN);
                drawTextRight(content, REGULAR, 8, MUTED, "Página " + (i + 1) + " de " + total,
                        pageWidth - MARGIN, MARGIN);
            }
        }
    }

    private void drawHeader(PDPageContentStream content, float pageWidth, float pageHeight, float headerHeight,
                            String title) throws IOException {
        fillRect(content, PRIMARY, 0, pageHeight - headerHeight, pageWidth, headerHeight);
        float titleY = pageHeight - 36;
        float subtitleY = pageHeight - 56;
        drawText(content, BOLD, 20, Color.WHITE, title, MARGIN, titleY);
        drawText(content, REGULAR, 11, new Color(0xDD, 0xD6, 0xFE),
                "Gerado em " + ZonedDateTime.now(ZONE).format(DATE_TIME), MARGIN, subtitleY);
    }

    private void drawCardRow(PDPageContentStream content, String[][] cards, float x, float top,
                             float cardWidth, float cardHeight, float gap, Color firstValueColor)
            throws IOException {
        for (int i = 0; i < cards.length; i++) {
            float cardX = x + i * (cardWidth + gap);
            float cardY = top - cardHeight;
            fillRect(content, PRIMARY_LIGHT, cardX, cardY, cardWidth, cardHeight);
            strokeRect(content, BORDER, cardX, cardY, cardWidth, cardHeight);
            drawText(content, REGULAR, 8, MUTED, fit(REGULAR, 8, cards[i][0], cardWidth - 16),
                    cardX + 8, top - 16);
            Color valueColor = i == 0 ? firstValueColor : PRIMARY;
            drawText(content, BOLD, 14, valueColor, fit(BOLD, 14, cards[i][1], cardWidth - 16),
                    cardX + 8, top - 38);
        }
    }

    private void drawLabelValue(PDPageContentStream content, String label, String value, float x, float y,
                                float maxWidth) throws IOException {
        drawText(content, BOLD, 10, MUTED, label, x, y);
        float labelWidth = textWidth(BOLD, 10, sanitize(label)) + 5;
        drawText(content, REGULAR, 10, TEXT, fit(REGULAR, 10, value, maxWidth - labelWidth), x + labelWidth, y);
    }

    private void drawText(PDPageContentStream content, PDFont font, float size, Color color, String value,
                          float x, float y) throws IOException {
        content.beginText();
        content.setFont(font, size);
        content.setNonStrokingColor(color);
        content.newLineAtOffset(x, y);
        content.showText(sanitize(value));
        content.endText();
    }

    private void drawTextRight(PDPageContentStream content, PDFont font, float size, Color color, String value,
                               float rightX, float y) throws IOException {
        float width = textWidth(font, size, sanitize(value));
        drawText(content, font, size, color, value, rightX - width, y);
    }

    private void fillRect(PDPageContentStream content, Color color, float x, float y, float width, float height)
            throws IOException {
        content.setNonStrokingColor(color);
        content.addRect(x, y, width, height);
        content.fill();
    }

    private void strokeRect(PDPageContentStream content, Color color, float x, float y, float width,
                            float height) throws IOException {
        content.setStrokingColor(color);
        content.setLineWidth(0.8f);
        content.addRect(x, y, width, height);
        content.stroke();
    }

    private String sanitize(String value) {
        if (value == null) {
            return "";
        }
        StringBuilder result = new StringBuilder();
        value.codePoints().forEach(codePoint -> {
            if (codePoint < 0x20) {
                result.append(' ');
                return;
            }
            String character = new String(Character.toChars(codePoint));
            try {
                REGULAR.encode(character);
                result.append(character);
            } catch (IOException | IllegalArgumentException exception) {
                result.append('?');
            }
        });
        return result.toString();
    }

    private float textWidth(PDFont font, float size, String sanitizedValue) throws IOException {
        return font.getStringWidth(sanitizedValue) / 1000f * size;
    }

    private String fit(PDFont font, float size, String value, float maxWidth) throws IOException {
        String text = sanitize(value);
        if (textWidth(font, size, text) <= maxWidth) {
            return text;
        }
        String ellipsis = "...";
        while (!text.isEmpty() && textWidth(font, size, text + ellipsis) > maxWidth) {
            text = text.substring(0, text.length() - 1);
        }
        return text + ellipsis;
    }

    private String valueOrDash(Object value) {
        return value == null || value.toString().isBlank() ? "-" : value.toString();
    }

    private String format(Number value) {
        return String.format(PT_BR, "%.2f", value.doubleValue());
    }

    private String formatOptional(Number value, String suffix) {
        return value == null ? "N/A" : format(value) + suffix;
    }

    private String currency(Number value) {
        return value == null ? "N/A" : String.format(PT_BR, "R$ %,.2f", value.doubleValue());
    }

    private String currencyOptional(Number value) {
        return currency(value);
    }
}
