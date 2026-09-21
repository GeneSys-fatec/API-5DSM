package com.backend.tecsys.domain.rf;

import com.backend.tecsys.domain.exception.UnsupportedPropagationModelException;
import com.backend.tecsys.domain.model.PropagationModelType;
import org.springframework.stereotype.Component;

import java.util.EnumMap;
import java.util.List;
import java.util.Map;
import java.util.Set;

@Component
public class PropagationModelRegistry {

    private final Map<PropagationModelType, PropagationModel> models;

    public PropagationModelRegistry(List<PropagationModel> propagationModels) {
        this.models = new EnumMap<>(PropagationModelType.class);
        for (PropagationModel model : propagationModels) {
            this.models.put(model.type(), model);
        }
    }

    public PropagationModel resolve(PropagationModelType type) {
        PropagationModel model = models.get(type);
        if (model == null) {
            throw new UnsupportedPropagationModelException(
                    "Modelo de propagação não suportado: " + type + ".");
        }
        return model;
    }

    public Set<PropagationModelType> supportedModels() {
        return models.keySet();
    }
}
