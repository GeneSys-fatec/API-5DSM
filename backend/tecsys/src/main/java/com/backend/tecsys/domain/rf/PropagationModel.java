package com.backend.tecsys.domain.rf;

import com.backend.tecsys.domain.model.PropagationModelType;

public interface PropagationModel {

    PropagationModelType type();

    double calculatePropagationLossDb(PropagationInput input);
}
