package com.backend.tecsys.domain.provider;

import com.backend.tecsys.domain.model.GatewayCandidate;

import java.util.List;

public interface GatewayCandidateProvider {

    List<GatewayCandidate> getCandidates(Long utilityId);
}
