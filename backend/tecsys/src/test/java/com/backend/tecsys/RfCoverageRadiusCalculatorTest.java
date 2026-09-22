package com.backend.tecsys;

import com.backend.tecsys.radio.model.RfParameter;
import com.backend.tecsys.radio.service.FreeSpacePathLossModel;
import com.backend.tecsys.radio.service.LinkBudgetCalculator;
import com.backend.tecsys.radio.service.OkumuraHataSuburbanModel;
import com.backend.tecsys.radio.service.RfCoverageRadiusCalculator;
import com.backend.tecsys.radio.service.ThreeGppRuralMacroModel;
import com.backend.tecsys.radio.service.TwoRayGroundReflectionModel;
import com.backend.tecsys.scenario.exception.InvalidSimulationParameterException;
import com.backend.tecsys.scenario.model.PropagationModelType;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assertions.assertTrue;

class RfCoverageRadiusCalculatorTest {

    private RfCoverageRadiusCalculator radiusCalculator;
    private TwoRayGroundReflectionModel twoRayModel;
    private FreeSpacePathLossModel freeSpaceModel;
    private OkumuraHataSuburbanModel okumuraHataModel;
    private ThreeGppRuralMacroModel threeGppModel;

    @BeforeEach
    void setUp() {
        LinkBudgetCalculator linkBudgetCalculator = new LinkBudgetCalculator();
        radiusCalculator = new RfCoverageRadiusCalculator(linkBudgetCalculator);
        twoRayModel = new TwoRayGroundReflectionModel();
        freeSpaceModel = new FreeSpacePathLossModel();
        okumuraHataModel = new OkumuraHataSuburbanModel();
        threeGppModel = new ThreeGppRuralMacroModel();
    }

    @Test
    void shouldCalculateCoverageRadiusForTwoRayGroundModel() {
        RfParameter rf = RfParameter.defaults();
        RfCoverageRadiusCalculator.CoverageRadiusResult result =
                radiusCalculator.calculateCoverageRadius(rf, twoRayModel);

        assertNotNull(result);
        assertEquals(141.0, result.maxPathLossDb(), 0.001);
        assertEquals(PropagationModelType.TWO_RAY_GROUND, result.modelType());

        assertEquals(18346.0, result.radiusMeters(), 50.0);
    }

    @Test
    void shouldCalculateCoverageRadiusForFreeSpaceModel() {
        RfParameter rf = RfParameter.builder()
                .frequencyMhz(915.0)
                .transmitPowerDbm(10.0)
                .receiverSensitivityDbm(-80.0)
                .antennaHeightM(6.0)
                .deviceHeightM(5.0)
                .antennaGainDbi(0.0)
                .systemLossDb(0.0)
                .build();

        double radius = radiusCalculator.calculateRadiusMeters(rf, freeSpaceModel);
        assertEquals(824.0, radius, 5.0);
    }

    @Test
    void shouldCalculateCoverageRadiusForOkumuraHataSuburban() {
        RfParameter rf = RfParameter.defaults();
        double radius = radiusCalculator.calculateRadiusMeters(rf, okumuraHataModel);

        assertTrue(radius > 1000.0);
        assertTrue(radius < 20000.0);
    }

    @Test
    void shouldCalculateCoverageRadiusForThreeGppRuralMacroUsingBinarySearch() {
        RfParameter rf = RfParameter.defaults();
        double radius = radiusCalculator.calculateRadiusMeters(rf, threeGppModel);

        assertTrue(radius > 500.0);
        assertTrue(radius < 50000.0);
    }

    @Test
    void shouldIncreaseRadiusWhenGatewayHeightIncreases() {
        RfParameter base = RfParameter.defaults();
        RfParameter elevated = RfParameter.builder()
                .frequencyMhz(base.getFrequencyMhz())
                .transmitPowerDbm(base.getTransmitPowerDbm())
                .receiverSensitivityDbm(base.getReceiverSensitivityDbm())
                .antennaHeightM(12.0)
                .deviceHeightM(base.getDeviceHeightM())
                .antennaGainDbi(base.getAntennaGainDbi())
                .systemLossDb(base.getSystemLossDb())
                .build();

        double radiusBase = radiusCalculator.calculateRadiusMeters(base, twoRayModel);
        double radiusElevated = radiusCalculator.calculateRadiusMeters(elevated, twoRayModel);

        assertTrue(radiusElevated > radiusBase);
        assertEquals(1.414, radiusElevated / radiusBase, 0.02);
    }

    @Test
    void shouldIncreaseRadiusWhenDeviceHeightIncreases() {
        RfParameter base = RfParameter.defaults();
        RfParameter elevatedDev = RfParameter.builder()
                .frequencyMhz(base.getFrequencyMhz())
                .transmitPowerDbm(base.getTransmitPowerDbm())
                .receiverSensitivityDbm(base.getReceiverSensitivityDbm())
                .antennaHeightM(base.getAntennaHeightM())
                .deviceHeightM(10.0)
                .antennaGainDbi(base.getAntennaGainDbi())
                .systemLossDb(base.getSystemLossDb())
                .build();

        double radiusBase = radiusCalculator.calculateRadiusMeters(base, twoRayModel);
        double radiusElevated = radiusCalculator.calculateRadiusMeters(elevatedDev, twoRayModel);

        assertTrue(radiusElevated > radiusBase);
        assertEquals(1.414, radiusElevated / radiusBase, 0.02);
    }

    @Test
    void shouldIncreaseRadiusWhenTransmitPowerIncreases() {
        RfParameter base = RfParameter.defaults();
        RfParameter boosted = RfParameter.builder()
                .frequencyMhz(base.getFrequencyMhz())
                .transmitPowerDbm(27.0)
                .receiverSensitivityDbm(base.getReceiverSensitivityDbm())
                .antennaHeightM(base.getAntennaHeightM())
                .deviceHeightM(base.getDeviceHeightM())
                .antennaGainDbi(base.getAntennaGainDbi())
                .systemLossDb(base.getSystemLossDb())
                .build();

        double radiusBase = radiusCalculator.calculateRadiusMeters(base, twoRayModel);
        double radiusBoosted = radiusCalculator.calculateRadiusMeters(boosted, twoRayModel);

        assertTrue(radiusBoosted > radiusBase);
    }

    @Test
    void shouldDecreaseRadiusWhenReceiverSensitivityIsWorse() {
        RfParameter sensitive = RfParameter.defaults();
        RfParameter lessSensitive = RfParameter.builder()
                .frequencyMhz(sensitive.getFrequencyMhz())
                .transmitPowerDbm(sensitive.getTransmitPowerDbm())
                .receiverSensitivityDbm(-100.0)
                .antennaHeightM(sensitive.getAntennaHeightM())
                .deviceHeightM(sensitive.getDeviceHeightM())
                .antennaGainDbi(sensitive.getAntennaGainDbi())
                .systemLossDb(sensitive.getSystemLossDb())
                .build();

        double radiusSensitive = radiusCalculator.calculateRadiusMeters(sensitive, twoRayModel);
        double radiusLessSensitive = radiusCalculator.calculateRadiusMeters(lessSensitive, twoRayModel);

        assertTrue(radiusLessSensitive < radiusSensitive);
    }

    @Test
    void shouldRejectInvalidRfParameter() {
        RfParameter invalid = RfParameter.builder()
                .frequencyMhz(0.0)
                .transmitPowerDbm(21.0)
                .receiverSensitivityDbm(-120.0)
                .antennaHeightM(6.0)
                .deviceHeightM(5.0)
                .build();

        assertThrows(InvalidSimulationParameterException.class,
                () -> radiusCalculator.calculateCoverageRadius(invalid, twoRayModel));
    }
}
