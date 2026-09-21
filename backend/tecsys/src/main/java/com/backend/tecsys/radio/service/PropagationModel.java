package com.backend.tecsys.radio.service;import com.backend.tecsys.radio.model.PropagationInput;


import com.backend.tecsys.scenario.model.PropagationModelType;

public interface PropagationModel {

    PropagationModelType type();

    double calculatePropagationLossDb(PropagationInput input);
}
