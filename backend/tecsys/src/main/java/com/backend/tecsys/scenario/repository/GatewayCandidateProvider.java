package com.backend.tecsys.scenario.repository;

import com.backend.tecsys.scenario.model.GatewayCandidate;

import java.util.List;

public interface GatewayCandidateProvider {

    List<GatewayCandidate> getCandidates(Long utilityId);
}
