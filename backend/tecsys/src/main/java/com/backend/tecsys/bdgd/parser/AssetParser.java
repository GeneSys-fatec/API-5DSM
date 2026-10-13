package com.backend.tecsys.bdgd.parser;

import com.backend.tecsys.bdgd.model.AssetFileRecord;

import java.io.InputStream;
import java.util.List;

public interface AssetParser {
    List<AssetFileRecord> parse(InputStream inputStream, String defaultDistribuidora, String defaultRegiao);
}
